---
ma_tai_lieu: D03-08
ten: Hồ sơ đề xuất cấp độ và phương án bảo vệ (bản mẫu)
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: Cơ quan chủ quản, Bộ phận chuyên trách an ninh mạng, Đơn vị thẩm định, Hội đồng thẩm định, Đơn vị vận hành, Nhà cung cấp nền tảng
---

# D03-08 · Hồ sơ đề xuất cấp độ và phương án bảo vệ (bản mẫu)

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

Trong toàn bản mẫu, đoạn chỉ áp dụng cho một hồ sơ được mở đầu bằng nhãn **[HT-A]** hoặc **[HT-B]**; đoạn không có nhãn áp dụng cho cả hai.

### 1.4. Quy ước chỗ điền

Chỗ điền được viết trong ngoặc vuông, ví dụ `[Tên tỉnh]`, `[Cơ quan chủ quản]`, `[Số dân]`. Mỗi chỗ điền có một mã `TT-nn` (trường thông tin) tổng hợp ở Phụ lục C, kèm nguồn số liệu và người chịu trách nhiệm cung cấp. Số liệu ước tính trong bản mẫu (lấy từ hồ sơ quy mô D03-09) được đánh dấu "ước tính" và **phải được thay bằng số liệu khảo sát của tỉnh** trước khi trình; đơn vị thẩm định có quyền yêu cầu giải trình phương pháp tính. Bản mẫu không chứa địa chỉ IP, tên máy chủ hay bí mật thật; dải địa chỉ trong sơ đồ là ví dụ giả lập.

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

### 3.2. Vai trò các bên

Bốn bên chịu trách nhiệm an ninh mạng cho Datahub, theo mô hình trách nhiệm chia sẻ ở D03-07 mục 12. **Chủ quản** chịu trách nhiệm cuối cùng: phê duyệt cấp độ, ban hành quy chế, bố trí bộ phận chuyên trách, chấp nhận rủi ro tồn dư và thực hiện nghĩa vụ thông báo. **Đơn vị vận hành** vận hành hằng ngày, giám sát và xử lý sự cố mức đầu. **Nhà cung cấp nền tảng** chịu trách nhiệm an toàn của phần mềm (vòng đời phát triển an toàn, bản vá, chuỗi cung ứng), và ở hồ sơ `HT-B` chịu thêm trách nhiệm vận hành an toàn toàn bộ phần nền tảng. **Bên cung cấp hạ tầng** chịu trách nhiệm an toàn vật lý, mạng nền, ảo hóa. Ranh giới giữa các bên được ghi trong hợp đồng, vì Điều 30 Nghị định 331/2026 cho phép hệ cấp độ 3–4 dùng chung hạ tầng cloud hoặc TTDL đạt yêu cầu và trách nhiệm phải phân định được khi kiểm tra.

**[HT-A]** Chủ quản và đơn vị vận hành thuộc cùng một tỉnh; nhà cung cấp hỗ trợ theo hợp đồng bảo trì; TTDL tỉnh là bên cung cấp hạ tầng. Bộ phận chuyên trách an ninh mạng của chủ quản thẩm định hồ sơ (nếu Q321 xác nhận) và kiểm tra định kỳ.

**[HT-B]** Có hai tầng chủ quản. Chủ quản nền tảng chịu trách nhiệm về toàn bộ nền tảng và hồ sơ cấp độ của nền tảng; chủ quản của mỗi tỉnh chịu trách nhiệm về phần cấu hình, người dùng, HTTT kết nối và dữ liệu trong tenant của tỉnh mình, và là bên kiểm soát dữ liệu cá nhân của tỉnh (D03-07 §6.2). Mục 5.6 trình bày cách hai tầng hồ sơ quan hệ với nhau.

