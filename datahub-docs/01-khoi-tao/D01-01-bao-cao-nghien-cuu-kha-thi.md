---
ma_tai_lieu: D01-01
ten: Báo cáo nghiên cứu khả thi dự án Datahub
phien_ban: 0.3
ngay: 2026-11-26
trang_thai: Dự thảo hoàn chỉnh, chờ chủ đầu tư rà soát
nguoi_doc: Hội đồng thẩm định, Chủ đầu tư, Cơ quan chủ quản, Quản lý dự án
mo_ta: Thuyết minh sự cần thiết, mục tiêu, phương án, thiết kế cơ sở, tổng mức đầu tư, tiến độ, hiệu quả và rủi ro của dự án Datahub cho tỉnh thí điểm, làm căn cứ để cấp có thẩm quyền thẩm định và quyết định đầu tư.
tai_lieu_lien_quan: D01-00 Bộ giả định nền; D01-02 Kế hoạch dự án; D02-02 SRS; D03-01 SAD; D03-07 Thiết kế ATTT; D03-08 Hồ sơ đề xuất cấp độ; D03-09 Hạ tầng, HA/DR; D03-10 Thiết kế đa tenant
---

# D01-01 · Báo cáo nghiên cứu khả thi

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Dự án thay hệ LGSP cũ của tỉnh bằng Datahub, một nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh xây mới trên nền mã nguồn mở, làm đầu mối duy nhất cho mọi trao đổi dữ liệu giữa các hệ thống thông tin (HTTT) trong tỉnh và giữa tỉnh với các nền tảng, cơ sở dữ liệu quốc gia. Nền tảng được thiết kế là sản phẩm đa tenant để các tỉnh khác dùng lại với chi phí biên thấp. Báo cáo cho cấp có thẩm quyền biết vì sao cần đầu tư, chọn phương án nào, tốn bao nhiêu, làm trong bao lâu và thu được gì.

**Phạm vi.** Một tỉnh thí điểm `T01` quy mô vừa (cỡ M, khoảng 200 HTTT) và một tỉnh thứ hai được khởi tạo ở cuối dự án. Datahub gồm 20 phân hệ PH-01 đến PH-20 chia ba đợt: MVP 12 phân hệ nghiệm thu ở T0+10 tháng, đợt 2 gồm 4 phân hệ, đợt 3 gồm 4 phân hệ nghiệm thu ở T0+18 tháng. Hạ tầng khuyến nghị H1: PROD, STAGING, DR tại trung tâm dữ liệu tỉnh, DEV và TEST thuê cloud chính phủ. Báo cáo gồm 12 chương theo khung nội dung của khoản 2 Điều 47 Luật Đầu tư công và Điều 45, 46 Nghị định 224/2026/NĐ-CP, kèm thiết kế cơ sở ở các Chương 5 đến 7.

**Căn cứ pháp lý.** CMP-LAW-14 (Nghị định 224/2026/NĐ-CP, khung lập báo cáo và thiết kế cơ sở), CMP-LAW-25 (Luật Đầu tư công), CMP-LAW-23 (Thông tư 39/2026/TT-BKHCN, lập chi phí), CMP-LAW-21 (Luật Chuyển đổi số), CMP-LAW-01 và CMP-LAW-03 (Luật Dữ liệu, Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu), CMP-LAW-05 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15), CMP-LAW-16, CMP-LAW-06 và CMP-LAW-08 (Luật An ninh mạng 116/2025/QH15, Nghị định 331/2026/NĐ-CP, TCVN 14423:2026), CMP-LAW-09 và CMP-LAW-10 (Công văn 631/THH-THHT, Khung Kiến trúc Chính phủ điện tử 3.0). Danh mục đầy đủ ở mục 1.2.

**Những điểm hội đồng cần lưu ý.** (1) Hệ LGSP cũ có nhiều thành phần đã hết vòng đời hỗ trợ, không đáp ứng yêu cầu an ninh mạng và kết nối mới, nên đầu tư là cần thiết (Chương 2). (2) Phương án PA3 và phương án PA2a (mua hoặc thuê LGSP trong nước) có TCO năm năm gần bằng nhau khi chỉ xét một tỉnh (62.651 so với 61.840 triệu đồng, chênh khoảng 1,3%); PA3 được đề xuất vì làm chủ mã nguồn, không phụ thuộc nhà cung cấp và rẻ rõ rệt khi nhân rộng (Chương 4, mục 8.10). (3) H1 cần vốn đầu tư cao hơn H2 khoảng 7,2 tỷ đồng nhưng TCO năm năm thấp hơn khoảng 9,6 tỷ đồng; điều kiện của trung tâm dữ liệu tỉnh chưa được xác minh (Q-D0101-42, Q-D0101-52). (4) Một số điều khoản mới, như Nghị định 331/2026/NĐ-CP, ngưỡng phân nhóm dự án và định mức chi phí của Thông tư 39/2026/TT-BKHCN, mới được đọc qua nguồn thứ cấp và cần đối chiếu Công báo trước khi trình (Q-D0101-11, 71, 81, 87). (5) Số liệu của tỉnh thí điểm là giả định GĐ-01 đến GĐ-07, các ô **[ĐIỀN]** do chủ đầu tư hoàn thiện. (6) Hiệu quả chỉ xuất hiện khi các sở, ngành thực sự chuyển kết nối sang nền tảng theo lịch cắt chuyển (mục 10.8).

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Tổng mức đầu tư sơ bộ, PA3 với H1 | 40.702 triệu đồng trước thuế GTGT (42.236 triệu đồng gồm thuế GTGT ước tính), mục 8.6 |
| Tổng mức đầu tư sơ bộ, PA3 với H2 (thuê toàn bộ cloud) | 33.460 triệu đồng trước thuế GTGT (34.401 triệu đồng gồm thuế), mục 8.6 |
| Phần mềm nội bộ | 399,5 người-tháng, 15.980 triệu đồng, chiếm khoảng 39% tổng mức H1 |
| TCO năm năm, một tỉnh | H1 62.651 triệu đồng, H2 72.271 triệu đồng; H1 thấp hơn 9.620 triệu đồng (13%), mục 8.8 |
| Chi phí vận hành một năm đầy đủ (Năm 4) | H1 6.130 triệu đồng, H2 11.179 triệu đồng, mục 8.7 |
| TCO năm năm, hai tỉnh | PA3 khoảng 72.812 triệu đồng, PA1 khoảng 99.200, PA2a khoảng 100.200 triệu đồng, mục 8.10 |
| Chi phí biên của tỉnh thứ hai (chế độ dùng chung) | Khoảng 6.417 triệu đồng một lần và 900 triệu đồng mỗi năm, mục 8.11 |
| Tiến độ | 18 tháng thực hiện từ T0 (MVP nghiệm thu T0+10, vận hành chính thức T0+13, hoàn thành T0+18), bảo hành 12 tháng đến T0+30, mục 9.3 |
| Công sức một kết nối mới | Giảm 65% (từ 10 xuống 3,5 ngày công), mục 10.2 |
| Nhân rộng | Tiết kiệm 415 đến 435 người-tháng cho tỉnh thứ hai; giảm 73% đến 76% tổng nỗ lực với năm tỉnh, mục 10.2.5 |
| Gián đoạn dịch vụ | Từ tối đa 876 giờ mỗi năm xuống khoảng 8,8 giờ mỗi năm theo cam kết, mục 10.2.6 |

: Con số chính của báo cáo nghiên cứu khả thi

## Giới thiệu tài liệu

Báo cáo này thuyết minh sự cần thiết, mục tiêu, phương án và hiệu quả của dự án "Xây dựng Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub)", kèm thiết kế cơ sở, để cấp có thẩm quyền thẩm định và quyết định đầu tư theo Nghị định 224/2026/NĐ-CP (CMP-LAW-14) và khoản 2 Điều 47 Luật Đầu tư công (CMP-LAW-25). Mọi con số, mốc thời gian và quy mô lấy từ bộ giả định nền [D01-00](_gia-dinh-nen.md); các giả định thay cho dữ liệu thật của tỉnh thí điểm được ghi là GĐ-01 đến GĐ-07 theo sổ giả định ở phụ lục D02-01. Tỉnh thí điểm được gọi chung là `T01`, quy mô vừa (cỡ M, khoảng 200 HTTT).

Báo cáo có 12 chương. Chương 1 đến 3 trình bày căn cứ, hiện trạng và mục tiêu; Chương 4 so sánh phương án; Chương 5 đến 7 là thiết kế cơ sở về công nghệ, hạ tầng và an toàn thông tin; Chương 8 là tổng mức đầu tư và TCO; Chương 9 là tổ chức thực hiện, tiến độ, lựa chọn nhà thầu và phương án khai thác; Chương 10 và 11 là hiệu quả và rủi ro; Chương 12 là đánh giá tuân thủ, kết luận và kiến nghị. Mỗi chương mở đầu bằng phần tóm tắt cho hội đồng thẩm định và kết thúc bằng các câu hỏi mở `Q-D0101-nn` cần chủ đầu tư trả lời trước khi trình. Bảng tính quy mô hạ tầng nằm ở [phụ lục](phu-luc/D01-01-ha-tang-sizing.csv).

### Mục đích của tài liệu

Báo cáo là hồ sơ để cấp có thẩm quyền thẩm định và quyết định đầu tư dự án Datahub. Báo cáo trả lời năm câu hỏi: vì sao phải đầu tư (Chương 2), đầu tư để đạt gì ở quy mô nào (Chương 3), chọn phương án nào (Chương 4), thiết kế cơ sở ra sao (Chương 5 đến 7), tốn bao nhiêu, ai làm, khi nào xong và hiệu quả, rủi ro thế nào (Chương 8 đến 11). Chương 12 kiểm tra mức tuân thủ và nêu kết luận, kiến nghị. Báo cáo cũng là đầu vào cho kế hoạch dự án D01-02 và cho các tài liệu thiết kế chi tiết sau khi dự án được phê duyệt.

### Phạm vi

Báo cáo bao trùm toàn bộ vòng đời đầu tư của Datahub cho tỉnh thí điểm `T01` (từ chuẩn bị đầu tư, thực hiện 18 tháng, bảo hành 12 tháng đến vận hành năm năm) và chi phí biên khi nhân rộng sang tỉnh khác. Báo cáo không thay thế thiết kế chi tiết, đặc tả yêu cầu hay kế hoạch kiểm thử; các nội dung đó nằm ở bộ tài liệu D02, D03, D05 và chỉ được dẫn lại ở mức cần để thẩm định. Việc ngoài phạm vi dự án được liệt kê ở mục 3.6.2.

### Người đọc và cách đọc

Bảng dưới đây gợi ý mỗi nhóm người đọc nên đọc phần nào trước. Mọi nhóm đều nên đọc Tóm tắt ở đầu báo cáo và phần tóm tắt đầu từng chương.

| Người đọc | Đọc phần | Mục đích |
|---|---|---|
| Hội đồng thẩm định | Tóm tắt, Chương 1, 2, 4, 8, 10, 12 | Đánh giá sự cần thiết, tính hợp lý của phương án, tổng mức đầu tư, hiệu quả và mức tuân thủ |
| Chủ đầu tư | Chương 3, 8, 9 và các câu hỏi mở cuối chương | Quyết định phương án hạ tầng, gói thầu, nguồn vốn và trả lời các câu hỏi còn treo |
| Cơ quan chủ quản | Tóm tắt, Chương 1, 3, 10, 12 | Xem sự phù hợp với kế hoạch chuyển đổi số của tỉnh và các kiến nghị |
| Quản lý dự án, kỹ sư thiết kế | Chương 5, 6, 7, 9, 11 | Nắm thiết kế cơ sở, quy mô hạ tầng, an toàn thông tin, tiến độ và rủi ro |

: Người đọc, phần cần đọc và mục đích

### Thuật ngữ và chữ viết tắt

Bảng dưới đây giải thích các thuật ngữ và chữ viết tắt riêng của báo cáo; thuật ngữ chung của bộ tài liệu nằm ở D00-01.

| Thuật ngữ | Giải thích |
|---|---|
| LGSP | Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh đang vận hành (hệ cũ) |
| Datahub | Nền tảng thế hệ mới do dự án xây dựng, thay thế LGSP |
| HTTT | Hệ thống thông tin của sở, ngành, UBND cấp xã kết nối vào nền tảng |
| NDXP, NGSP | Nền tảng chia sẻ, điều phối dữ liệu quốc gia (NDXP) và trục tích hợp quốc gia mà phụ lục kết nối của hệ cũ gọi là NGSP |
| T0 | Ngày bắt đầu thực hiện (khởi công) của dự án; mốc thời gian khác ghi T0 ± số tháng |
| G0 đến G5 | Sáu cổng nghiệm thu của giai đoạn thực hiện (Chương 9) |
| W0 đến W5 | Sáu wave triển khai, mỗi wave gồm các sprint hai tuần |
| PA1, PA2a, PA2b, PA3 | Bốn phương án đầu tư: nâng cấp hệ cũ, nền tảng thương mại trong nước, nền tảng thương mại quốc tế, xây mới Datahub (đề xuất) |
| H1, H2, H3 | Ba phương án hạ tầng: mua sắm đặt tại chỗ, thuê cloud chính phủ, thuê trọn gói |
| Cỡ S, M, L | Ba cỡ quy mô tỉnh; tỉnh thí điểm là cỡ M |
| TCO | Chi phí sở hữu tổng cộng năm năm kể từ T0, gồm đầu tư, bảo hành và vận hành |
| GĐ, ĐN, BO, KPI | Mã giả định, điểm nghẽn, mục tiêu nghiệp vụ, chỉ số đo kết quả dùng xuyên suốt báo cáo |
| RLS | Cách ly dữ liệu theo dòng ở tầng cơ sở dữ liệu (Row-Level Security) |
| RPO, RTO | Lượng dữ liệu tối đa chấp nhận mất, thời gian tối đa để khôi phục dịch vụ |

: Thuật ngữ và chữ viết tắt riêng của báo cáo

### Tài liệu tham chiếu

Bảng dưới đây nêu các tài liệu của bộ datahub-docs mà báo cáo dẫn lại và vai trò của từng tài liệu; văn bản pháp luật được liệt kê riêng ở mục 1.2.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| D01-00 | Bộ giả định nền | Nguồn số liệu, mốc thời gian và quy mô dùng chung cho báo cáo và kế hoạch dự án |
| D01-02 | Kế hoạch dự án Datahub | Tiến độ, WBS, nhân sự và sổ rủi ro mà Chương 8, 9, 11 dẫn lại |
| D02-02 | Đặc tả yêu cầu phần mềm (SRS) | Yêu cầu chức năng và phi chức năng làm cơ sở cho Chương 5 |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | Kiến trúc, đơn vị triển khai, vùng mạng của Chương 5 và 6 |
| D03-07 | Thiết kế an toàn thông tin | Biện pháp bảo vệ cho Chương 7 |
| D03-08 | Hồ sơ đề xuất cấp độ | Mẫu hồ sơ cấp độ 3 và 4 mà Chương 7 dẫn lại |
| D03-09 | Thiết kế hạ tầng, triển khai, HA/DR/BCP | Cấu hình, sao lưu, dự phòng cho Chương 6 |
| D03-10 | Thiết kế đa tenant | Mô hình tenant và nhân rộng cho mục 4.7 và 8.11 |
| D00-01 | Thuật ngữ và quy ước chung | Thuật ngữ và quy ước đặt mã |

: Tài liệu tham chiếu của báo cáo

### Cấu trúc tài liệu

Báo cáo có 12 chương, sắp theo khung nội dung của hồ sơ nghiên cứu khả thi. Mỗi chương mở đầu bằng phần tóm tắt cho hội đồng thẩm định và kết thúc bằng các câu hỏi mở.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 1 | Thông tin chung và căn cứ pháp lý | Hội đồng thẩm định, Cơ quan chủ quản |
| 2 | Hiện trạng hệ LGSP cũ và sự cần thiết đầu tư | Hội đồng thẩm định, Chủ đầu tư |
| 3 | Mục tiêu, quy mô, địa điểm, phạm vi đầu tư | Hội đồng thẩm định, Chủ đầu tư |
| 4 | So sánh và lựa chọn phương án đầu tư, hạ tầng, tenant, chuyển đổi | Hội đồng thẩm định, Chủ đầu tư |
| 5 | Giải pháp công nghệ và thiết kế cơ sở | Hội đồng thẩm định, Quản lý dự án, kỹ sư |
| 6 | Giải pháp hạ tầng kỹ thuật | Quản lý dự án, kỹ sư |
| 7 | Phương án an toàn thông tin và an ninh mạng | Hội đồng thẩm định, kỹ sư ATTT |
| 8 | Tổng mức đầu tư, chi phí vận hành và TCO năm năm | Hội đồng thẩm định, Chủ đầu tư |
| 9 | Tổ chức thực hiện, tiến độ, lựa chọn nhà thầu, phương án khai thác | Chủ đầu tư, Quản lý dự án |
| 10 | Hiệu quả kinh tế - xã hội | Hội đồng thẩm định, Cơ quan chủ quản |
| 11 | Phân tích rủi ro và biện pháp quản lý | Hội đồng thẩm định, Quản lý dự án |
| 12 | Đánh giá tuân thủ, kết luận và kiến nghị | Hội đồng thẩm định, Cơ quan chủ quản |

: Cấu trúc tài liệu: chương, nội dung và người đọc chính

## 1. Thông tin chung và căn cứ pháp lý

**Tóm tắt cho hội đồng thẩm định.** Dự án "Xây dựng Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub)" là dự án đầu tư hệ thống chuyển đổi số sử dụng ngân sách nhà nước. Dự án chưa có quyết định đầu tư trước ngày 01/7/2026, nên theo khoản 1 Điều 91 Nghị định 224/2026/NĐ-CP, dự án áp dụng Nghị định 224/2026/NĐ-CP quy định chi tiết Luật Chuyển đổi số, không áp dụng Nghị định 45/2026/NĐ-CP (đã hết hiệu lực từ 01/7/2026) hay Nghị định 73/2019/NĐ-CP. Báo cáo được lập theo khung nội dung của khoản 2 Điều 47 Luật Đầu tư công, kèm các yêu cầu thuyết minh bổ sung tại Điều 45 và thiết kế cơ sở theo Điều 46 Nghị định 224/2026/NĐ-CP; bảng ở mục 1.4 chỉ rõ từng nội dung bắt buộc nằm ở chương nào. Chi phí được lập theo Thông tư 39/2026/TT-BKHCN. Dự án không phát sinh giải phóng mặt bằng và không có tác động môi trường đáng kể. Về an ninh mạng, báo cáo áp dụng Luật An ninh mạng 116/2025/QH15, Nghị định 331/2026/NĐ-CP và TCVN 14423:2026; một số điều khoản mới đọc qua nguồn thứ cấp được nêu thành câu hỏi mở để chủ đầu tư đối chiếu Công báo trước khi trình.

### 1.1. Thông tin chung về dự án

Bảng dưới đây tóm tắt các thông tin định danh của dự án. Các ô có nhãn **[ĐIỀN]** do chủ đầu tư điền khi hoàn thiện hồ sơ trình; các giá trị có nhãn **[GĐ]** là giả định của bộ giả định nền và cần chủ đầu tư xác nhận.

| Trường | Nội dung |
|---|---|
| Tên dự án | Xây dựng Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub) |
| Loại dự án | Dự án đầu tư hệ thống chuyển đổi số, có hạng mục phần mềm nội bộ, theo Nghị định 224/2026/NĐ-CP |
| Người quyết định đầu tư, cơ quan chủ quản | **[ĐIỀN]**, giả định UBND tỉnh thí điểm **[GĐ]** |
| Chủ đầu tư | **[ĐIỀN]**, giả định Sở Khoa học và Công nghệ tỉnh thí điểm **[GĐ]** |
| Đơn vị tiếp nhận, vận hành | **[ĐIỀN]**, giả định Trung tâm Chuyển đổi số hoặc Trung tâm dữ liệu tỉnh **[GĐ]** |
| Địa điểm đầu tư | Tỉnh **[ĐIỀN]**; hạ tầng đặt tại Trung tâm dữ liệu tỉnh (PROD, STAGING, DR) và thuê cloud chính phủ (DEV, TEST) theo khuyến nghị Chương 4 mục 4.6.3; chi tiết ở Chương 3 mục 3.5 và Chương 6 |
| Nguồn vốn | Ngân sách nhà nước: chi đầu tư phát triển cho giai đoạn thực hiện, chi thường xuyên cho quản trị, vận hành sau đầu tư **[GĐ]** |
| Hình thức đầu tư | Xây dựng mới phần mềm nội bộ trên nền mã nguồn mở, kết hợp mua sắm thiết bị và thuê dịch vụ công nghệ số (phương án PA3, Chương 4) |
| Thiết kế | Thiết kế hai bước: thiết kế cơ sở trong báo cáo này (Chương 5, Chương 6, Chương 7), thiết kế chi tiết và dự toán lập sau khi dự án được phê duyệt |
| Nhóm dự án | Xác định theo tổng mức đầu tư tại Chương 8 và tiêu chí phân loại của Luật Đầu tư công (mục 1.1.1) |
| Thời gian thực hiện | 18 tháng kể từ T0 (ngày khởi động hợp đồng thực hiện), bảo hành 12 tháng; mốc ghi tương đối theo T0, xem Chương 9 |

: Thông tin định danh của dự án Datahub

#### 1.1.1. Nhóm dự án và thẩm quyền

Luật Đầu tư công phân dự án thành nhóm A, B, C theo tính chất và tổng mức đầu tư, và khoản 4 Điều 65 Nghị định 224/2026/NĐ-CP dẫn chiếu cách phân loại này để xác định thẩm quyền quyết định đầu tư đối với dự án chuyển đổi số. Báo cáo chưa xác minh được ngưỡng tổng mức đầu tư cụ thể của từng nhóm sau khi Luật Đầu tư công số 58/2024/QH15 được sửa đổi bởi Luật số 90/2025/QH15. Vì vậy báo cáo không tự kết luận nhóm dự án ở chương này mà để Chương 8 so tổng mức đầu tư với ngưỡng được chủ đầu tư xác nhận (Q-D0101-11). Theo hiểu biết trước đây, dự án công nghệ thông tin cấp tỉnh có quy mô như Datahub thường rơi vào nhóm B hoặc nhóm C; nếu là nhóm B, dự án phải có quyết định chủ trương đầu tư của cấp có thẩm quyền theo Luật Đầu tư công trước khi lập báo cáo này, và giai đoạn chuẩn bị đầu tư ở Chương 9 đã chừa bước này từ T0 − 7 đến T0 − 6 tháng.

#### 1.1.2. Bối cảnh tổ chức

Hai thay đổi tổ chức năm 2025 chi phối cách gọi tên các chủ thể trong báo cáo. Bộ Thông tin và Truyền thông đã hợp nhất vào Bộ Khoa học và Công nghệ, nên các văn bản do Bộ Thông tin và Truyền thông ban hành trước đây (Khung Kiến trúc Chính phủ điện tử 3.0, Thông tư 13/2017/TT-BTTTT, Thông tư 39/2017/TT-BTTTT) nay thuộc thẩm quyền sửa đổi của Bộ Khoa học và Công nghệ, và ở cấp tỉnh Sở Khoa học và Công nghệ là cơ quan chủ quản công nghệ thông tin. Chính quyền địa phương chuyển sang mô hình hai cấp (tỉnh, xã) với 34 đơn vị hành chính cấp tỉnh, nên danh mục đơn vị hành chính của Datahub phải lưu được lịch sử sáp nhập và mô hình đa tenant phải xử lý được việc gộp tenant (D03-10 §5.4).

### 1.2. Căn cứ pháp lý

Các bảng dưới đây liệt kê văn bản làm căn cứ lập báo cáo, nhóm theo cấp văn bản. Cột "Trạng thái xác minh" dùng ba mức: **Đã xác minh** nghĩa là số hiệu, ngày và hiệu lực đã được đối chiếu trên trang có địa chỉ ở cột Nguồn (các trang này chưa phải Công báo, nên trước khi trình chính thức vẫn phải đối chiếu bản Công báo); **Xác minh tiêu đề** nghĩa là chỉ thấy số hiệu và trích yếu trên trang nguồn, chưa đọc nội dung; **Chưa xác minh** nghĩa là văn bản được dẫn theo hồ sơ của repo hoặc hiểu biết trước, phải kiểm tra lại. Văn bản đã có mã trong D00-01 §7 được ghi mã CMP-LAW; các văn bản mới được cấp mã CMP-LAW-21 đến CMP-LAW-26 trong D00-01 §7 cùng đợt hoàn thiện báo cáo này.

#### 1.2.1. Luật

| Mã | Văn bản | Ngày hiệu lực | Vai trò đối với dự án | Trạng thái xác minh, nguồn |
|---|---|---|---|---|
| CMP-LAW-21 | Luật Chuyển đổi số số 148/2025/QH15 | 01/7/2026 | Luật gốc của Nghị định 224/2026/NĐ-CP; quy định đầu tư, mua sắm, thuê dịch vụ cho chuyển đổi số | Đã xác minh số hiệu; ngày hiệu lực suy ra từ Nghị định 224/2026/NĐ-CP ([luatvietnam](https://luatvietnam.vn/khoa-hoc/nghi-dinh-224-2026-nd-cp-quy-dinh-chi-tiet-luat-chuyen-doi-so-hieu-luc-tu-01-07-2026-439083-d1.html)) |
| CMP-LAW-25 | Luật Đầu tư công số 58/2024/QH15, được sửa đổi bởi Luật số 90/2025/QH15 | 01/01/2025; phần sửa đổi từ 01/7/2025 | Phân loại nhóm dự án, chủ trương đầu tư; khoản 2 Điều 47 là khung nội dung báo cáo | Luật 90/2025/QH15 đã xác minh số hiệu, ngày ([VBHN 74/VBHN-VPQH](https://datafiles.chinhphu.vn/cpp/files/vbpq/2026/3/74-vbhn-vpqh.pdf)); ngày hiệu lực Luật 58/2024/QH15 và ngưỡng nhóm chưa xác minh |
| CMP-LAW-26 | Luật Đấu thầu số 22/2023/QH15, sửa đổi bởi Luật 57/2024/QH15 và Luật 90/2025/QH15 | 01/01/2024 | Lựa chọn nhà thầu (Chương 9 mục 9.4) | Đã xác minh ([VBHN 74/VBHN-VPQH](https://datafiles.chinhphu.vn/cpp/files/vbpq/2026/3/74-vbhn-vpqh.pdf)) |
| CMP-LAW-01 | Luật Dữ liệu số 60/2024/QH15 | 01/7/2025 | Quản trị, phân loại, kết nối, chia sẻ dữ liệu; dữ liệu dùng chung | Đã đối chiếu với repo; chưa xác minh trên nguồn chính thức trong lượt này |
| CMP-LAW-05 | Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 | 01/01/2026 | Xử lý dữ liệu cá nhân, đánh giá tác động, dữ liệu nhạy cảm | Xác minh tiêu đề số hiệu ([luatvietnam](https://luatvietnam.vn/tin-van-ban-moi/da-co-luat-bao-ve-du-lieu-ca-nhan-2025-so-91-2025-qh15-186-102925-article.html)); ngày hiệu lực đã xác minh qua bản tóm tắt ([EY](https://www.ey.com/vi_vn/technical/tax/tax-and-law-updates/nghi-dinh-so-356-2025-nd-cp-quy-dinh-chi-tiet-mot-so-dieu-va-bien-phap-thi-hanh-luat-bao-ve-du-lieu-ca-nhan)) |
| CMP-LAW-16 | Luật An ninh mạng số 116/2025/QH15, ngày 10/12/2025 | 01/7/2026 | Phân loại 5 cấp độ hệ thống thông tin (Điều 8), nghĩa vụ chủ quản (Điều 10, 11), lưu trữ dữ liệu trong nước; thay Luật An toàn thông tin mạng 86/2015/QH13 và Luật An ninh mạng 24/2018/QH14 | Đã xác minh ([hethongphapluat](https://hethongphapluat.com/law-no-116-2025-qh15-dated-december-10-2025-on-cybersecurity.html)) |
| CMP-LAW-95 | Luật Giao dịch điện tử số 20/2023/QH15 | 01/7/2024 | Luật gốc của Nghị định 194/2025/NĐ-CP về kết nối, chia sẻ dữ liệu | Chưa xác minh |

: Các luật làm căn cứ lập báo cáo

#### 1.2.2. Nghị định

| Mã | Văn bản | Ngày hiệu lực | Vai trò đối với dự án | Trạng thái xác minh, nguồn |
|---|---|---|---|---|
| CMP-LAW-14 | **Nghị định 224/2026/NĐ-CP** ngày 24/6/2026 quy định chi tiết một số điều và biện pháp thi hành Luật Chuyển đổi số | 01/7/2026 | **Căn cứ chính** về quản lý đầu tư: nội dung báo cáo (Điều 45), thiết kế cơ sở (Điều 46), tổng mức đầu tư (Điều 49), tuân thủ khung kiến trúc (Điều 37), thẩm định (Điều 66), chuyển tiếp (Điều 91) | Đã xác minh, nguồn [hethongphapluat Điều 45](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-45), [Điều 46](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-46), [Điều 90](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-90), [Điều 91](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-91); chưa đối chiếu Công báo |
| (không áp dụng) | Nghị định 45/2026/NĐ-CP; Nghị định 73/2019/NĐ-CP; Nghị định 82/2024/NĐ-CP | Hết hiệu lực | Chỉ nêu để giải thích; không viện dẫn làm căn cứ | Nghị định 45/2026/NĐ-CP hết hiệu lực theo Điều 90 Nghị định 224/2026/NĐ-CP (đã xác minh) |
| CMP-LAW-02 | Nghị định 165/2025/NĐ-CP ngày 30/6/2025 quy định chi tiết Luật Dữ liệu | Chưa xác minh | Truy cập, khai thác, mã hóa dữ liệu, hỗ trợ chủ quản dữ liệu kết nối chia sẻ | Chưa xác minh trong lượt này |
| CMP-LAW-22 | Nghị định 194/2025/NĐ-CP ngày 03/7/2025 quy định chi tiết một số điều của Luật Giao dịch điện tử về cơ sở dữ liệu quốc gia, kết nối và chia sẻ dữ liệu, dữ liệu mở phục vụ giao dịch điện tử của cơ quan nhà nước | Chưa xác minh | Điểm đ khoản 2 Điều 46 Nghị định 224/2026/NĐ-CP yêu cầu thiết kế cơ sở nêu hạng mục kết nối, chia sẻ theo khoản 1 Điều 21 của nghị định này | Xác minh tiêu đề ([hethongphapluat](https://hethongphapluat.com/decree-no-194-2025-nd-cp-dated-july-03-2025-on-elaborating-on-certain-articles-of-the-law-on-electronic-transactions-regarding-the-national-database-data-connection-and-sharing-and-open-data-serving-electronic-transactions-of-regulatory-agencies.html), [Cổng Nghệ An](https://hcc.nghean.gov.vn/laws/detail/Nghi-dinh-so-194-2025-ND-CP-cua-Chinh-phu-Quy-dinh-chi-tiet-mot-so-dieu-cua-Luat-Giao-dich-dien-tu-ve-co-so-du-lieu-quoc-gia-ket-noi-va-chia-se-du-lieu-du-lieu-mo-phuc-vu-giao-dich-dien-tu-cua-co-quan-nha-nuoc-1902/)); nội dung Điều 21 chưa đọc |
| CMP-LAW-03 | Nghị định 278/2025/NĐ-CP ngày 22/10/2025 về kết nối, chia sẻ dữ liệu (thay toàn bộ Nghị định 47/2020/NĐ-CP) | 22/10/2025 | Nghĩa vụ chia sẻ dữ liệu mà Datahub là công cụ thực hiện ở cấp tỉnh; kết nối qua Nền tảng chia sẻ, điều phối dữ liệu của Trung tâm dữ liệu quốc gia; hạn chuẩn hóa 31/12/2026 | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| CMP-LAW-04 | Nghị định 356/2025/NĐ-CP ngày 31/12/2025 quy định chi tiết Luật Bảo vệ dữ liệu cá nhân (thay Nghị định 13/2023/NĐ-CP) | 01/01/2026 | Hồ sơ đánh giá tác động xử lý dữ liệu cá nhân thẩm định trước, người phụ trách bảo vệ dữ liệu, dữ liệu nhạy cảm mở rộng | Đã xác minh qua bản tóm tắt ([EY](https://www.ey.com/vi_vn/technical/tax/tax-and-law-updates/nghi-dinh-so-356-2025-nd-cp-quy-dinh-chi-tiet-mot-so-dieu-va-bien-phap-thi-hanh-luat-bao-ve-du-lieu-ca-nhan)); chưa đọc nguyên văn |
| CMP-LAW-06 | Nghị định 331/2026/NĐ-CP ngày 19/8/2026 quy định chi tiết Luật An ninh mạng về bảo vệ an ninh mạng đối với hệ thống thông tin (kế nhiệm Nghị định 85/2016/NĐ-CP) | 19/8/2026 | **Căn cứ chính** về cấp độ: 5 cấp độ; cấp độ 3 do đơn vị chuyên trách an ninh mạng thẩm định và chủ quản phê duyệt, cấp độ 4 do Bộ Công an thẩm định; ngưỡng dữ liệu cá nhân của cấp độ 3; chuyển tiếp tại Điều 39 | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| (tham khảo) | Nghị định 343/2026/NĐ-CP ngày 03/9/2026 quy định chi tiết Luật An ninh mạng thuộc phạm vi quản lý của Bộ Quốc phòng | 03/9/2026 | Không áp dụng trực tiếp; cho thấy cấu trúc thẩm định hồ sơ cấp độ theo Luật mới | Đã xác minh ([thuvienphapluat bản tiếng Anh](https://thuvienphapluat.vn/van-ban/EN/Cong-nghe-thong-tin/Decree-343-2026-ND-CP-elaborating-on-Law-Cybersecurity/730583/tieng-anh.aspx)) |
| (kế thừa) | Nghị định 85/2016/NĐ-CP về bảo đảm an toàn hệ thống thông tin theo cấp độ | Được thay bởi Nghị định 331/2026/NĐ-CP | Chỉ dùng ở cột kế thừa, chuyển tiếp; Datahub là hệ mới nên không lập hồ sơ theo văn bản này | Theo D00-01 §7 |
| CMP-LAW-15 | Nghị định 30/2020/NĐ-CP về công tác văn thư | Chưa xác minh | Thể thức văn bản điện tử, trình bày hồ sơ | Chưa xác minh |

: Các nghị định làm căn cứ lập báo cáo

#### 1.2.3. Thông tư và tiêu chuẩn, quy chuẩn

| Mã | Văn bản | Ngày hiệu lực | Vai trò đối với dự án | Trạng thái xác minh, nguồn |
|---|---|---|---|---|
| CMP-LAW-23 | **Thông tư 39/2026/TT-BKHCN** quy định lập và quản lý chi phí trong hoạt động đầu tư, mua sắm, thuê dịch vụ cho chuyển đổi số sử dụng ngân sách nhà nước (thay Thông tư 18/2024/TT-BTTTT) | 01/7/2026 | Cơ cấu tổng mức đầu tư, dự phòng tối đa 10% (Chương 8) | Đã xác minh ([dauthaumuasam](https://dauthaumuasam.vn/thong-tu-so-39-2026-tt-bkhcn-cua-bo-khoa-hoc-va-cong-nghe-quy-dinh-lap-va-quan-ly-chi-phi-trong-hoat-dong-dau-tu-mua-sam-thue-dich-vu-cho-chuyen-doi-so-su-dung-ngan-sach-nha-nuoc/)) |
| CMP-LAW-24 | **Thông tư 41/2026/TT-BKHCN** hướng dẫn Nghị định 224/2026/NĐ-CP về phát triển thử nghiệm, khảo sát, triển khai, nhật ký, giám sát, kiểm thử, nghiệm thu | 01/7/2026 | Báo cáo khảo sát, nhật ký triển khai, kiểm thử phần mềm nội bộ (Điều 10), nghiệm thu (Chương 9) | Đã xác minh hiệu lực và cấu trúc qua bản trích ([thuviennhadat](https://thuviennhadat.vn/vbpl/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so-712767.html)) |
| CMP-LAW-07 | Thông tư 12/2022/TT-BTTTT hướng dẫn Nghị định 85/2016/NĐ-CP | Chưa rõ còn áp dụng | Giữ làm đối chiếu cho tới khi có hướng dẫn của Nghị định 331/2026/NĐ-CP | Chưa xác minh tình trạng sau 01/7/2026 |
| CMP-LAW-12 | Thông tư 13/2017/TT-BTTTT về yêu cầu kỹ thuật kết nối với cơ sở dữ liệu quốc gia | Chưa xác minh | Kết nối NDXP (PH-14) | Đã đối chiếu với repo |
| CMP-LAW-13 | Thông tư 39/2017/TT-BTTTT về danh mục tiêu chuẩn kỹ thuật ứng dụng công nghệ thông tin trong cơ quan nhà nước | Chưa xác minh | Danh mục tiêu chuẩn (Chương 5 mục 5.6) | Cần xác minh văn bản thay thế |
| CMP-LAW-08 | TCVN 14423:2026 về yêu cầu bảo đảm an toàn hệ thống thông tin theo cấp độ (thay TCVN 14423:2025 và TCVN 11930:2017) | 2026 | Khung yêu cầu cho Chương 7 và D03-08: chương 3 đến 7 của tiêu chuẩn tương ứng cấp độ 1 đến 5; cấp độ 3 gồm 18 nhóm yêu cầu (5.1 đến 5.18) | Đã đối chiếu nguồn thứ cấp, chưa đối chiếu Công báo |
| (tham khảo) | QĐ 671/QĐ-BTTTT ngày 26/4/2024 hướng dẫn xác định chi phí phần mềm nội bộ | Từ ngày ký | Phương pháp điểm trường hợp sử dụng (Chương 8) | Nội dung đã xác minh; hiệu lực sau 01/7/2026 chưa xác minh vì căn cứ ban hành đã hết hiệu lực |

: Thông tư và tiêu chuẩn làm căn cứ lập báo cáo

#### 1.2.4. Quyết định, khung kiến trúc và văn bản kỹ thuật chuyên ngành

| Mã | Văn bản | Vai trò đối với dự án | Trạng thái xác minh |
|---|---|---|---|
| CMP-LAW-10 | Quyết định 2568/QĐ-BTTTT ngày 29/12/2023 (Khung Kiến trúc Chính phủ điện tử Việt Nam phiên bản 3.0) và Quyết định 1729/QĐ-BTTTT ngày 09/10/2024 sửa đổi | Khung kiến trúc đã ban hành; ánh xạ ở Chương 5 mục 5.7 | Đã đối chiếu với repo |
| CMP-LAW-11 | Khung Kiến trúc tổng thể quốc gia số | Điều 37 và điểm a khoản 1 Điều 46 Nghị định 224/2026/NĐ-CP yêu cầu tuân thủ | Yêu cầu tuân thủ đã xác minh; số quyết định ban hành khung chưa xác minh (repo ghi là dự thảo) |
| CMP-LAW-09 | Công văn 631/THH-THHT ngày 21/5/2020 hướng dẫn yêu cầu chức năng, tính năng kỹ thuật của nền tảng chia sẻ, tích hợp dùng chung cấp bộ, cấp tỉnh | Đối chiếu chức năng LGSP | Đã đối chiếu với repo |
| (chưa có mã) | Kế hoạch chuyển đổi số 5 năm và hằng năm của tỉnh thí điểm | Điều 45 khoản 1 Nghị định 224/2026/NĐ-CP yêu cầu thuyết minh sự phù hợp | **[ĐIỀN]** số, ngày của kế hoạch |
| (chưa có mã) | Văn bản hướng dẫn kết nối NDXP, NDOP, nền tảng thanh toán PayGov | Đặc tả kết nối của PH-14, PH-19 | Chưa xác minh văn bản hiện hành |

: Quyết định, khung kiến trúc và văn bản kỹ thuật chuyên ngành làm căn cứ

#### 1.2.5. Tiêu chuẩn kỹ thuật quốc tế

Các tiêu chuẩn kỹ thuật quốc tế (OpenAPI 3.1, AsyncAPI 3.0, OAuth 2.0, OpenID Connect, TLS 1.3, OWASP ASVS 5.0, WCAG 2.2, ISO/IEC/IEEE 29148 và 29119-3) đã được liệt kê đầy đủ ở Chương 5 mục 5.6 và D00-01 §7 (STD-01 đến STD-05). Chương này không chép lại; chỉ lưu ý rằng các tiêu chuẩn này là lựa chọn kỹ thuật của dự án để đáp ứng yêu cầu "tuân thủ tiêu chuẩn, quy chuẩn" tại điểm b khoản 1 Điều 46 Nghị định 224/2026/NĐ-CP, không phải văn bản pháp luật bắt buộc.

### 1.3. Lựa chọn khung báo cáo

#### 1.3.1. Vì sao áp dụng Nghị định 224/2026/NĐ-CP

Nghị định 224/2026/NĐ-CP có hiệu lực từ 01/7/2026. Khoản 2 Điều 90 của nghị định chấm dứt hiệu lực Nghị định 45/2026/NĐ-CP, Nghị định 42/2022/NĐ-CP và Nghị định 64/2007/NĐ-CP. Khoản 1 Điều 91 quy định dự án chưa được quyết định đầu tư trước ngày 01/7/2026 thì áp dụng Nghị định 224/2026/NĐ-CP. Datahub đang ở giai đoạn lập báo cáo nghiên cứu khả thi, chưa có quyết định đầu tư, nên thuộc trường hợp này. Hệ quả thực tế có ba điểm. Thứ nhất, báo cáo dùng thuật ngữ mới của nghị định: "dự án đầu tư hệ thống chuyển đổi số" thay cho "dự án ứng dụng công nghệ thông tin", "thuê dịch vụ công nghệ số" thay cho "thuê dịch vụ công nghệ thông tin". Thứ hai, chi phí được lập theo Thông tư 39/2026/TT-BKHCN thay cho Thông tư 18/2024/TT-BTTTT. Thứ ba, các hoạt động khảo sát, nhật ký triển khai, kiểm thử và nghiệm thu tuân theo Thông tư 41/2026/TT-BKHCN.

#### 1.3.2. Cấu trúc ba lớp yêu cầu nội dung

Nội dung báo cáo nghiên cứu khả thi của Datahub chịu ba lớp yêu cầu chồng lên nhau, và báo cáo được tổ chức để đáp ứng cả ba mà không lặp lại.

Lớp thứ nhất là khoản 2 Điều 47 Luật Đầu tư công, quy định 12 nội dung (điểm a đến điểm m) của mọi báo cáo nghiên cứu khả thi dự án đầu tư công. Điều 45 khoản 1 Nghị định 224/2026/NĐ-CP dẫn chiếu trực tiếp khoản này, nên đây là khung chương của báo cáo.

Lớp thứ hai là các yêu cầu thuyết minh bổ sung tại Điều 45 Nghị định 224/2026/NĐ-CP dành riêng cho dự án đầu tư hệ thống chuyển đổi số. Khoản 1 yêu cầu thuyết minh rõ sự phù hợp với Kế hoạch chuyển đổi số 5 năm hoặc hằng năm của địa phương, và kèm thiết kế cơ sở theo Điều 46 (đối với thiết kế hai bước). Khoản 3 yêu cầu, đối với hạng mục thuê dịch vụ công nghệ số, thuyết minh việc tuân thủ khung kiến trúc theo Điều 37, yêu cầu chất lượng dịch vụ, kết nối, liên thông, chia sẻ dữ liệu, sở hữu dữ liệu hình thành và phương án chuyển giao; yêu cầu này áp dụng cho hạng mục thuê cloud chính phủ làm môi trường DEV, TEST và cho kịch bản DR trên cloud. Khoản 5 yêu cầu tổng mức đầu tư xác định theo Điều 49.

Lớp thứ ba là nội dung thiết kế cơ sở theo Điều 46. Khoản 1 đặt bốn yêu cầu: tuân thủ khung kiến trúc (Điều 37), tuân thủ tiêu chuẩn, quy chuẩn và quy định về kết nối, chia sẻ dữ liệu, thể hiện thông số và chức năng chính, và đủ để xác định tổng mức đầu tư. Khoản 2 quy định bảy nhóm nội dung (điểm a đến điểm g), từ thuyết minh, sơ đồ, chỉ tiêu kỹ thuật, yêu cầu phần mềm nội bộ, hạng mục kết nối cơ sở dữ liệu, khối lượng đào tạo đến yêu cầu bảo đảm an ninh mạng. Chương 5 mục 5.1 đã có bảng ánh xạ chi tiết khoản 2 Điều 46 vào các mục của Chương 5, Chương 6 và Chương 7, nên bảng ở mục 1.4 chỉ ghi ở mức chương.

Báo cáo tách nội dung "giải pháp công nghệ", "hạ tầng" và "an toàn thông tin" thành ba chương riêng (5, 6, 7) dù khoản 2 Điều 47 Luật Đầu tư công gom chúng vào điểm c. Lý do là thiết kế cơ sở của một nền tảng tích hợp có khối lượng lớn, và hội đồng thẩm định thiết kế (thời hạn không quá 10 ngày làm việc) cần đọc riêng từng phần. Tương tự, nội dung rủi ro (Chương 11) và đánh giá tuân thủ (Chương 12) không phải điểm bắt buộc riêng của khoản 2 Điều 47, nhưng được bổ sung vì hai lý do: tóm tắt pháp lý cho thấy nội dung thẩm định tại khoản 7 Điều 66 Nghị định 224/2026/NĐ-CP gồm sự phù hợp với khung kiến trúc, và người quyết định đầu tư cần thấy rủi ro của phương án được chọn trước khi phê duyệt.

### 1.4. Bảng ánh xạ nội dung bắt buộc với các chương của báo cáo

Bảng dưới đây là công cụ để cơ quan thẩm định kiểm tra tính đầy đủ của hồ sơ. Mỗi dòng là một nội dung bắt buộc, kèm điều khoản gốc và chương, mục của báo cáo trình bày nội dung đó. Tên các điểm của khoản 2 Điều 47 Luật Đầu tư công được ghi theo tóm lược của nguồn đã đọc, chưa phải nguyên văn.

| Nội dung bắt buộc | Điều khoản | Chương, mục trong báo cáo |
|---|---|---|
| Sự cần thiết đầu tư | Điểm a khoản 2 Điều 47 Luật Đầu tư công | Chương 2 |
| Sự phù hợp với quy hoạch, kế hoạch chuyển đổi số | Điểm b khoản 2 Điều 47; khoản 1 Điều 45 Nghị định 224/2026/NĐ-CP | Chương 2 (căn cứ), Chương 12 mục 12.2 (ma trận tuân thủ) |
| Mục tiêu, nhiệm vụ, kết quả đầu ra, quy mô, hình thức đầu tư | Điểm c khoản 2 Điều 47 | Chương 3; Chương 4 (hình thức, phương án) |
| Thuyết minh thiết kế cơ sở | Điểm c khoản 2 Điều 47; khoản 1 Điều 45; Điều 46 | Chương 5, Chương 6, Chương 7 (bảng chi tiết tại Chương 5 mục 5.1) |
| Tuân thủ Khung kiến trúc tổng thể quốc gia số | Điều 37; điểm a khoản 1 Điều 46 | Chương 5 mục 5.7; Chương 12 mục 12.2 |
| Kết nối, liên thông, IPv6, an ninh mạng trong thiết kế cơ sở | Điểm a, đ, g khoản 2 Điều 46 | Chương 5 mục 5.8 đến 5.10; Chương 7 |
| Yêu cầu kỹ thuật phần mềm nội bộ | Điểm d khoản 2 Điều 46; Điều 48 | Chương 5 mục 5.13 |
| Khối lượng đào tạo, tập huấn | Điểm e khoản 2 Điều 46 | Chương 6 mục 6.11; Chương 9 mục 9.5.5 |
| Điều kiện tự nhiên, kinh tế - kỹ thuật, địa điểm | Điểm d khoản 2 Điều 47 | Chương 3 mục 3.5; Chương 6 mục 6.1 |
| Phương án tổ chức quản lý, khai thác, sử dụng | Điểm đ khoản 2 Điều 47 | Chương 9 mục 9.5 |
| Đánh giá tác động môi trường | Điểm e khoản 2 Điều 47 | Mục 1.5 chương này; Chương 12 mục 12.5 |
| Đền bù, giải phóng mặt bằng (nếu có) | Điểm g khoản 2 Điều 47 | Mục 1.5 chương này (không phát sinh) |
| Tiến độ, các mốc chính | Điểm h khoản 2 Điều 47 | Chương 9 mục 9.3 |
| Tổng mức đầu tư, cơ cấu nguồn vốn | Điểm i khoản 2 Điều 47; khoản 5 Điều 45; Điều 49 | Chương 8 |
| Chi phí liên quan, chi phí vận hành | Điểm k khoản 2 Điều 47 | Chương 8 (TCO 5 năm) |
| Tổ chức quản lý dự án, hình thức quản lý, trách nhiệm các chủ thể | Điểm l khoản 2 Điều 47 | Chương 9 mục 9.1, 9.2 |
| Hiệu quả đầu tư, kinh tế - xã hội, quốc phòng, an ninh, thu hồi vốn | Điểm m khoản 2 Điều 47 | Chương 10; Chương 12 mục 12.6 |
| Thuê dịch vụ công nghệ số: kiến trúc, chất lượng dịch vụ, sở hữu dữ liệu, chuyển giao | Khoản 3 Điều 45 | Chương 4 mục 4.6; Chương 6 mục 6.7.2; Chương 9 mục 9.5 |
| Rủi ro và biện pháp quản lý (bổ sung) | Phục vụ thẩm định | Chương 11 |
| Kết luận, kiến nghị | Thông lệ hồ sơ trình | Chương 12 mục 12.7 |

: Ánh xạ nội dung bắt buộc của hồ sơ thẩm định tới chương của báo cáo

### 1.5. Tác động môi trường và giải phóng mặt bằng

**Đánh giá tác động môi trường.** Dự án không xây dựng công trình, không thay đổi mục đích sử dụng đất và không tạo chất thải công nghiệp trong quá trình thực hiện. Thiết bị được lắp đặt trong phòng máy hiện có của Trung tâm dữ liệu tỉnh (phương án H1) hoặc không có thiết bị mới tại tỉnh (phương án H2). Tác động duy nhất đáng ghi nhận là điện năng tiêu thụ của 9 máy chủ vật lý cùng thiết bị mạng và lưu trữ đi kèm (Chương 6 mục 6.7.1), vốn nằm trong công suất thiết kế của trung tâm dữ liệu và không làm thay đổi phạm vi đánh giá môi trường của trung tâm. Vì vậy báo cáo kết luận dự án không thuộc diện phải lập báo cáo đánh giá tác động môi trường; chủ đầu tư xác nhận lại với cơ quan quản lý môi trường của tỉnh nếu có yêu cầu riêng (Q-D0101-12). Chương 12 mục 12.5 trình bày thêm về tiêu thụ điện và xử lý thiết bị cũ.

**Đền bù, giải phóng mặt bằng, tái định cư.** Không phát sinh, vì dự án không sử dụng đất và không có công trình xây dựng.

### 1.6. Trình tự thủ tục đầu tư áp dụng

Trình tự dưới đây là tổng hợp từ Luật Đầu tư công, Nghị định 224/2026/NĐ-CP và Thông tư 41/2026/TT-BKHCN. Thời hạn thẩm định và phê duyệt đã xác minh tại nguồn đọc được; các bước khác ghi theo thông lệ và cần đối chiếu nguyên văn. Thời gian tương đối của từng bước khớp với bộ giả định nền và Chương 9.

| Bước | Nội dung | Căn cứ | Thời gian tương đối |
|---|---|---|---|
| 1 | Đưa dự án vào Kế hoạch chuyển đổi số và kế hoạch đầu tư công trung hạn của tỉnh | Luật Đầu tư công; khoản 1 Điều 45 Nghị định 224/2026/NĐ-CP | Trước T0 − 7 |
| 2 | Lập, thẩm định nguồn vốn, quyết định chủ trương đầu tư (nếu thuộc diện) | Luật Đầu tư công | T0 − 7 đến T0 − 6 |
| 3 | Khảo sát, lập báo cáo khảo sát | Thông tư 41/2026/TT-BKHCN | Song song bước 4 |
| 4 | Lập Báo cáo nghiên cứu khả thi kèm thiết kế cơ sở (báo cáo này) | Điều 45, 46 Nghị định 224/2026/NĐ-CP | T0 − 7 đến T0 − 5 |
| 5 | Thẩm định dự án, gồm thẩm định thiết kế cơ sở; quyết định đầu tư | Điều 66 Nghị định 224/2026/NĐ-CP: thẩm định không quá 20 ngày làm việc, trong đó thẩm định thiết kế không quá 10 ngày làm việc; phê duyệt không quá 03 ngày làm việc | T0 − 4 đến T0 − 3 |
| 6 | Lập, thẩm định, phê duyệt thiết kế chi tiết và dự toán | Nghị định 224/2026/NĐ-CP; Thông tư 39/2026/TT-BKHCN | T0 − 3 đến T0 − 2 |
| 7 | Lựa chọn nhà thầu | Luật Đấu thầu; khoản 6 Điều 65 Nghị định 224/2026/NĐ-CP (mẫu hồ sơ mời thầu hàng hóa cho phần mềm nội bộ) | T0 − 2 đến T0 |
| 8 | Triển khai, giám sát, nhật ký triển khai; lập và trình hồ sơ đề xuất cấp độ an toàn thông tin | Thông tư 41/2026/TT-BKHCN; Luật An ninh mạng 2025 | T0 đến T0+18 |
| 9 | Kiểm thử phần mềm nội bộ, vận hành thử | Điều 10 Thông tư 41/2026/TT-BKHCN; điểm a khoản 7 Điều 65 Nghị định 224/2026/NĐ-CP | Trong từng wave, trước mỗi cổng |
| 10 | Nghiệm thu, bàn giao, quyết toán | Nghị định 224/2026/NĐ-CP (điều khoản nghiệm thu chưa đối chiếu) | Theo cổng G0 đến G5, hoàn thành tại T0+18 |
| 11 | Quản trị, vận hành, bảo trì sau đầu tư | Nghị định 224/2026/NĐ-CP; Thông tư 39/2026/TT-BKHCN (chi phí vận hành) | Từ G3, chính thức sau G5 |

: Trình tự thủ tục đầu tư và thời gian tương đối từng bước

```{.mermaid caption="Trình tự thủ tục đầu tư từ chuẩn bị đến vận hành"}
flowchart TB
    subgraph CB["Chuẩn bị đầu tư, từ T0 - 7 đến T0"]
        B1["Bước 1-2<br/>Kế hoạch, chủ trương"] --> B4["Bước 3-4<br/>Khảo sát, lập báo cáo này"]
        B4 --> B5["Bước 5<br/>Thẩm định, quyết định đầu tư"]
        B5 --> B6["Bước 6<br/>Thiết kế chi tiết, dự toán"]
        B6 --> B7["Bước 7<br/>Lựa chọn nhà thầu"]
    end
    subgraph TH["Thực hiện, từ T0 đến T0+18"]
        B8["Bước 8<br/>Triển khai, hồ sơ cấp độ"] --> B9["Bước 9<br/>Kiểm thử, vận hành thử"]
        B9 --> B10["Bước 10<br/>Nghiệm thu, quyết toán"]
        B9 -.->|"lặp lại trong từng wave"| B8
    end
    subgraph KT["Khai thác"]
        B11["Bước 11<br/>Vận hành, bảo trì"]
    end
    B7 --> B8
    B10 --> B11
```

Sơ đồ nhóm mười một bước của bảng trên thành ba giai đoạn. Báo cáo này nằm ở bước 4 và là đầu vào của bước 5, nơi cấp có thẩm quyền thẩm định và quyết định đầu tư. Nét đứt ở giai đoạn thực hiện cho thấy kiểm thử diễn ra trong từng wave trước mỗi cổng nghiệm thu chứ không chỉ một lần ở cuối.

Bước 8 đặt việc lập hồ sơ đề xuất cấp độ trong giai đoạn thực hiện chứ không trong giai đoạn chuẩn bị, vì hồ sơ cấp độ cần thiết kế chi tiết và cấu hình hạ tầng thật. Kế hoạch dự án đặt mốc nộp hồ sơ tại T0+8 và mục tiêu có quyết định phê duyệt tại T0+10, muộn nhất T0+12 (D01-02 §4.2, M-09 và M-12), trước khi đưa hệ thống vào vận hành chính thức ở cổng G3.

### 1.7. Các cơ chế mới của Nghị định 224/2026/NĐ-CP có lợi cho dự án

Nghị định 224/2026/NĐ-CP đưa vào một số cơ chế mới nhằm tháo gỡ vướng mắc trong đầu tư chuyển đổi số. Bốn cơ chế dưới đây có ảnh hưởng trực tiếp tới cách tổ chức thực hiện Datahub. Các cơ chế được nêu theo bản phân tích trên Tạp chí Quản lý nhà nước ([quanlynhanuoc.vn, 22/7/2026](https://www.quanlynhanuoc.vn/2026/07/22/6-co-che-moi-thao-go-vuong-mac-trong-dau-tu-mua-sam-cho-chuyen-doi-so/)) và bản trích điều khoản; điều khoản cụ thể cần đối chiếu nguyên văn trước khi đưa vào hồ sơ mời thầu.

**Một doanh nghiệp vừa thiết kế chi tiết vừa triển khai phần mềm nội bộ.** Trước đây, đơn vị lập thiết kế chi tiết và đơn vị triển khai thường phải tách riêng, dẫn đến tình trạng nhà thầu triển khai phải làm lại thiết kế cho phù hợp công nghệ của mình. Nghị định 224/2026/NĐ-CP cho phép một doanh nghiệp đảm nhận cả hai, và gói thầu thiết kế chi tiết kèm triển khai phần mềm nội bộ áp dụng loại gói EP. Với Datahub, cơ chế này phù hợp với mô hình phát triển lặp theo sprint ở D01-02 §3: thiết kế chi tiết từng phân hệ được hoàn thiện trong wave của nó, nên giao cho cùng một đơn vị giảm rủi ro hiểu sai yêu cầu và rút ngắn khoảng T0 − 3 đến T0 − 2. Chương 9 mục 9.4 trình bày hai phương án đóng gói thầu theo cơ chế này.

**Chỉ định doanh nghiệp đã phát triển phần mềm làm quản trị, vận hành.** Một nền tảng tích hợp có khoảng hai mươi thành phần nguồn mở phải nâng phiên bản hằng năm, và người hiểu mã nguồn nhất là đội đã viết nó. Cơ chế này cho phép hợp đồng hỗ trợ kỹ thuật sau bảo hành (2 đến 3 FTE từ T0+30, D01-02 §6.10) được giao cho nhà thầu phát triển mà không phải đấu thầu lại, đồng thời không bắt buộc chủ đầu tư phải dùng. Chương 9 mục 9.5 giữ cả hai lựa chọn.

**Thuê dịch vụ công nghệ số nhiều năm.** Theo điểm b khoản 1 Điều 65, dịch vụ sẵn có trên thị trường được thuê nhiều năm, giá thuê theo báo giá tại thời điểm thuê; dịch vụ không sẵn có phải lập kế hoạch thuê theo Điều 67. Datahub áp dụng nhánh thứ nhất cho hạ tầng cloud chính phủ của môi trường DEV, TEST trong suốt 30 tháng thực hiện và bảo hành, và cho kịch bản DR trên cloud. Nhánh thứ hai là cơ sở pháp lý cho phương án H3 khi nhân rộng nhiều tỉnh.

**Trách nhiệm khi lấy báo giá.** Chủ đầu tư lấy báo giá đầy đủ, công khai, minh bạch thì không chịu trách nhiệm nếu doanh nghiệp báo giá nâng khống. Cơ chế này giảm rủi ro cho chủ đầu tư khi Chương 8 xác định giá thiết bị và dịch vụ cloud theo báo giá.

Hai cơ chế còn lại trong bản phân tích là hỗ trợ phát triển thử nghiệm (tối đa 30% chi phí, không quá 15 tỷ đồng mỗi doanh nghiệp mỗi nhiệm vụ) và cơ chế đặc thù cho nền tảng số quốc gia. Datahub là nền tảng cấp tỉnh nên chưa rõ có thuộc phạm vi cơ chế đặc thù hay không (Q-D0101-13); nếu sau này được công nhận là nền tảng dùng chung cho nhiều địa phương, chủ đầu tư có thể xem xét lại.

### 1.8. Câu hỏi mở

Các câu hỏi dưới đây là những điểm về nhóm dự án, thẩm quyền, thủ tục môi trường và căn cứ pháp lý mà chủ đầu tư cần xác nhận với cơ quan có thẩm quyền trước khi trình hồ sơ.

- **Q-D0101-11.** Ngưỡng tổng mức đầu tư của nhóm B và nhóm C theo Luật Đầu tư công sau sửa đổi bởi Luật 90/2025/QH15 là bao nhiêu, và với tổng mức đầu tư ở Chương 8 thì dự án có phải có quyết định chủ trương đầu tư hay không? Cấp nào quyết định chủ trương và quyết định đầu tư?
- **Q-D0101-12.** Cơ quan quản lý môi trường của tỉnh có yêu cầu văn bản xác nhận riêng về việc dự án không thuộc diện đánh giá tác động môi trường hay không?
- **Q-D0101-13.** Datahub, với mô hình sản phẩm đa tenant dùng cho nhiều tỉnh, có thể được xem xét theo cơ chế dành cho nền tảng số dùng chung hoặc nền tảng số quốc gia của Nghị định 224/2026/NĐ-CP hay không?
- **Q-D0101-14.** Số hiệu và ngày ban hành của Kế hoạch chuyển đổi số 5 năm và năm hiện hành của tỉnh thí điểm là gì, và dự án đã có tên trong danh mục của kế hoạch chưa?
- **Q-D0101-15.** Khung Kiến trúc tổng thể quốc gia số đã được ban hành chính thức bằng văn bản nào? Nếu chưa, chủ đầu tư có đồng ý xin ý kiến Bộ Khoa học và Công nghệ về việc dùng Khung Kiến trúc Chính phủ điện tử 3.0 làm căn cứ tuân thủ tạm thời hay không?
- **Q-D0101-16.** Thông tư 12/2022/TT-BTTTT còn được dùng làm hướng dẫn mẫu hồ sơ cấp độ trong thời gian chờ văn bản hướng dẫn Nghị định 331/2026/NĐ-CP hay không? (Chi tiết ở Chương 7 mục 7.1.)


## 2. Hiện trạng và sự cần thiết đầu tư

> **Tóm tắt cho hội đồng thẩm định.** Tỉnh thí điểm đang vận hành một hệ LGSP do Viettel xây dựng năm 2021, gồm năm khối (Bus, Hub, API Management, Danh mục dùng chung Aita, Payment) với 183 chức năng đã được kiểm kê tại D00-03. Hệ thống này được thiết kế trên Java 8, Spring Boot 2, Angular 7, CentOS 6 và PostgreSQL 13, toàn bộ các thành phần nền này đã hết hoặc sắp hết vòng đời hỗ trợ của nhà phát hành tính đến thời điểm lập báo cáo. Cam kết chất lượng trong hồ sơ thiết kế của hệ cũ là độ sẵn sàng 90% mỗi năm và thời gian phản hồi không quá 5 giây với 10 người dùng đồng thời, thấp hơn nhiều so với yêu cầu của một nền tảng dùng chung cấp tỉnh sau sắp xếp đơn vị hành chính. Hệ cũ không có lớp dữ liệu chủ, không có quản lý chất lượng dữ liệu, không có cơ chế bảo vệ dữ liệu cá nhân, không có đối soát thanh toán và không hỗ trợ nhiều tỉnh trên một bản sản phẩm, trong khi các yêu cầu này đã trở thành bắt buộc theo CMP-LAW-01, CMP-LAW-02 và CMP-LAW-03. Báo cáo xác định 14 điểm nghẽn có mã từ ĐN-01 đến ĐN-14 và kết luận rằng việc đầu tư một nền tảng thế hệ mới là cần thiết về cả bốn phương diện pháp lý, nghiệp vụ, kỹ thuật và kinh tế. Số liệu vận hành thực tế của hệ cũ (lượng giao dịch, số HTTT đang kết nối, số sự cố) chưa có trong hồ sơ và cần chủ đầu tư cung cấp; trong khi chờ, báo cáo dùng quy mô tham chiếu cỡ M của bộ giả định nền.

### 2.1. Hiện trạng chung về hạ tầng, ứng dụng và dữ liệu chia sẻ cấp tỉnh

#### 2.1.1. Bối cảnh tổ chức sau sắp xếp đơn vị hành chính

Từ ngày 01/07/2025, chính quyền địa phương được tổ chức theo mô hình hai cấp gồm cấp tỉnh và cấp xã, và số đơn vị hành chính cấp tỉnh của cả nước còn 34. Thay đổi này tác động trực tiếp tới nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh theo ba hướng. Thứ nhất, quy mô mỗi tỉnh lớn hơn trước vì phần lớn các tỉnh mới được hình thành từ hai hoặc ba tỉnh cũ, kéo theo số HTTT phải kết nối, số cơ quan khai thác dữ liệu và lượng giao dịch đều tăng. Thứ hai, cấp huyện không còn, nên các HTTT trước đây do cấp huyện vận hành phải được chuyển giao lên cấp tỉnh hoặc xuống cấp xã, và mọi danh mục, mọi luồng tích hợp có tham chiếu tới đơn vị hành chính cấp huyện đều phải được chuyển đổi mà vẫn giữ được lịch sử. Thứ ba, một tỉnh mới có thể thừa hưởng cùng lúc nhiều hệ LGSP của các tỉnh cũ, được xây dựng bởi các nhà cung cấp khác nhau, và phải hợp nhất về một nền tảng duy nhất để bảo đảm nguyên tắc mỗi địa phương có một đầu mối tích hợp, chia sẻ dữ liệu.

Về cơ quan quản lý nhà nước, chức năng quản lý chuyển đổi số đã chuyển về Bộ Khoa học và Công nghệ sau khi hợp nhất với Bộ Thông tin và Truyền thông, và ở địa phương là Sở Khoa học và Công nghệ. Các văn bản thiết kế của hệ cũ được lập năm 2021 vẫn ghi theo cơ cấu tổ chức trước đây, do đó khi đối chiếu phải được hiểu theo cơ cấu mới (xem D00-01 §7).

#### 2.1.2. Hiện trạng hạ tầng kỹ thuật

Hạ tầng phục vụ nền tảng tích hợp của tỉnh thí điểm đặt tại trung tâm dữ liệu của tỉnh. Theo hồ sơ cài đặt của hệ cũ, mỗi khối chức năng được yêu cầu một máy chủ riêng, trên đó cài chung cả máy chủ ứng dụng và hệ quản trị cơ sở dữ liệu, với cấu hình tối thiểu là bộ xử lý Intel Xeon E5-2670 v3 tốc độ 2,30 GHz, bộ nhớ trong 32 GB, một ổ SSD 120 GB cùng hai ổ SATA 1 TB và hai cổng mạng 1 Gbps. Đây là mô hình máy chủ đơn lẻ, cài đặt thủ công trực tiếp trên hệ điều hành, không dùng công nghệ container và không có lớp điều phối tài nguyên. Hệ quả là năng lực xử lý của từng khối bị giới hạn bởi một máy chủ, việc tăng năng lực đòi hỏi mua thêm phần cứng và cài đặt lại bằng tay, và một máy chủ hỏng đồng nghĩa với việc cả ứng dụng lẫn cơ sở dữ liệu của khối đó ngừng hoạt động.

Hồ sơ hệ cũ không mô tả phân vùng mạng, tường lửa ứng dụng web, hệ thống sao lưu tập trung hay địa điểm dự phòng thảm họa. Phần "Kiến trúc sao lưu và phục hồi dữ liệu" trong các tài liệu thiết kế tổng thể chỉ liệt kê tên các chủ đề cần giải quyết (dự phòng, phân tải, sao lưu, nâng cấp nóng, giám sát) mà không có nội dung giải pháp. Vì vậy, hiện trạng thực tế của hạ tầng mạng, lưu trữ, sao lưu và năng lực còn trống của trung tâm dữ liệu tỉnh phải được khảo sát bổ sung trong giai đoạn thiết kế chi tiết (câu hỏi mở Q-D0101-21).

#### 2.1.3. Hiện trạng ứng dụng và kết nối

Các HTTT của tỉnh kết nối với nhau và với các hệ thống của bộ, ngành theo ba cách cùng tồn tại. Cách thứ nhất là kết nối qua hệ LGSP hiện có, bao gồm các luồng tích hợp chạy trên khối Bus, các kênh nhắn tin trên khối Hub và các API được bọc qua khối API Management. Cách thứ hai là kết nối lên nền tảng quốc gia thông qua cổng trung gian của trục quốc gia: phụ lục kết nối NGSP của hệ cũ ghi nhận bảy nhóm dịch vụ đã được tích hợp là lý lịch tư pháp, hộ tịch, bảo hiểm xã hội, cấp mã số đơn vị có quan hệ với ngân sách, đăng ký doanh nghiệp, danh mục dùng chung quốc gia và văn bản quy phạm pháp luật, với hơn 30 mã dịch vụ (service-code). Cách thứ ba là kết nối trực tiếp điểm tới điểm giữa hai HTTT mà không qua nền tảng dùng chung; số lượng kết nối loại này không được ghi nhận trong hồ sơ hệ cũ và cần chủ đầu tư thống kê (Q-D0101-22).

Sự tồn tại của kết nối điểm tới điểm là dấu hiệu nền tảng dùng chung chưa đủ thuận tiện hoặc chưa đủ tin cậy để các đơn vị lựa chọn. Mỗi kết nối như vậy có cơ chế xác thực riêng, không được ghi nhật ký tập trung, không có hạn mức và không ai có bức tranh tổng thể về việc dữ liệu nào đang được chia sẻ cho ai. Đây cũng là tình trạng mà CMP-LAW-03 yêu cầu chấm dứt khi quy định việc chia sẻ dữ liệu giữa các cơ quan nhà nước phải thực hiện qua dịch vụ chia sẻ dữ liệu được công bố và quản lý.

#### 2.1.4. Hiện trạng dữ liệu dùng chung

Về dữ liệu dùng chung, tỉnh hiện chỉ có một thành phần là khối Danh mục dùng chung (Aita) của hệ cũ. Khối này cho phép khai báo danh mục, khai báo thuộc tính động cho từng danh mục, nhập và xuất dữ liệu bằng tệp Excel, CSV hoặc qua API. Tuy nhiên, danh mục trong hệ cũ không có phiên bản, không có ngày hiệu lực, không có cơ chế duyệt trước khi phát hành và không được đồng bộ tự động với danh mục dùng chung quốc gia. Khi đơn vị hành chính thay đổi hàng loạt như trong năm 2025, mỗi HTTT phải tự cập nhật bảng mã của mình, dẫn đến tình trạng cùng một xã mang các mã khác nhau ở các hệ thống khác nhau trong một thời gian dài.

Tỉnh chưa có dữ liệu chủ (master data) theo nghĩa của CMP-LAW-03, tức là chưa có một bản ghi thống nhất, được hợp nhất từ nhiều nguồn, cho các thực thể cốt lõi như công dân, tổ chức, cán bộ công chức hay thủ tục hành chính. Tỉnh cũng chưa có công cụ đo chất lượng dữ liệu được chia sẻ, chưa có danh mục dữ liệu để biết tỉnh đang có những tập dữ liệu nào, do cơ quan nào làm chủ quản và được phân loại ở mức nào. Thiếu các năng lực này, tỉnh không thể thực hiện đầy đủ nghĩa vụ kiểm tra, đánh giá chất lượng dữ liệu định kỳ và nghĩa vụ phân loại, công bố dữ liệu theo CMP-LAW-01 và CMP-LAW-02.

### 2.2. Hiện trạng hệ LGSP đang vận hành

#### 2.2.1. Nguồn thông tin và giới hạn của việc khảo sát

Phần mô tả dưới đây được lập từ hồ sơ kỹ thuật của hệ cũ do chủ đầu tư cung cấp, gồm tài liệu thiết kế tổng thể, phân tích yêu cầu, thiết kế chi tiết, thiết kế cơ sở dữ liệu, hướng dẫn sử dụng, hướng dẫn vận hành và hướng dẫn cài đặt của từng khối, cùng phụ lục kết nối NGSP. Các tài liệu được lập trong năm 2021; tài liệu thiết kế tổng thể khối Bus ghi phiên bản 1.0, ngày 01/04/2021. Sản phẩm được nhà cung cấp đặt tên là Nền tảng tích hợp Viettel (Viettel Integration Platform).

Việc khảo sát có ba giới hạn cần hội đồng lưu ý. Một là, hồ sơ là hồ sơ thiết kế và hướng dẫn, không phải số liệu đo đạc; báo cáo chưa có nhật ký vận hành, số liệu giao dịch hay biên bản sự cố. Hai là, sáu tài liệu hướng dẫn cài đặt (Bus, Tooling, Hub, API, Aita, Payment) có nội dung giống nhau gần như hoàn toàn, chỉ khác tên khối và tên tệp triển khai, và còn sót các chi tiết của một sản phẩm khác; các tài liệu này không có hướng dẫn cài đặt Apache Pulsar, cổng API hay Keycloak. Ba là, các tài liệu hướng dẫn vận hành dẫn chiếu tới các phụ lục PL1, PL2, PL5 và tới "tài liệu chuẩn" nội bộ của đơn vị vận hành thuộc nhà cung cấp, nhưng các phụ lục này không có trong hồ sơ. Vì ba lý do đó, mọi nhận định về phiên bản và mô hình triển khai trong mục này phản ánh hồ sơ thiết kế, và phải được kiểm kê lại trên hệ thống thực trước khi lập kế hoạch di trú chi tiết (Q-D0101-23).

#### 2.2.2. Kiến trúc tổng thể của hệ cũ

Sơ đồ dưới đây thể hiện các khối của hệ cũ, quan hệ giữa chúng và với các hệ thống bên ngoài, theo đúng mô tả trong hồ sơ thiết kế.

```{.mermaid caption="Sơ đồ khối của hệ LGSP cũ và các hệ thống bên ngoài"}
flowchart TB
    subgraph NGUOIDUNG["Người dùng và hệ thống bên ngoài"]
        QT["Cán bộ quản trị, vận hành"]
        HTTT["Các HTTT của sở, ngành, địa phương"]
        NGSP["Trục quốc gia NGSP và các CSDL quốc gia"]
        PAYGOV["Nền tảng thanh toán PayGov"]
    end

    subgraph LGSPCU["Hệ LGSP cũ, năm 2021"]
        KC["Keycloak, đăng nhập một lần"]
        subgraph BUS["Khối Bus, 70 chức năng"]
            ADM["Quản trị trục tích hợp, 41 chức năng"]
            TOOL["Productivity Tooling, 29 chức năng"]
            AG["Các agent Apache Camel"]
        end
        subgraph HUB["Khối Hub, 14 chức năng"]
            VCC["Giao diện quản trị nhắn tin"]
            PUL["Apache Pulsar"]
        end
        subgraph APIM["Khối API Management, 27 chức năng"]
            GW["Cổng API kiểu Gravitee"]
            MGT["Quản trị API và Plan"]
        end
        AITA["Khối Danh mục dùng chung Aita, 19 chức năng"]
        PAY["Khối Payment, 23 chức năng"]
        GRAY["Graylog, quản lý log"]
        DB[("PostgreSQL 13, mỗi khối một CSDL")]
    end

    QT --> KC
    KC --> ADM
    KC --> VCC
    KC --> MGT
    KC --> AITA
    KC --> PAY
    TOOL -->|"Sinh Camel XML và tệp pom"| AG
    ADM -->|"Đọc số liệu và điều khiển qua JMX, Jolokia"| AG
    HTTT --> GW
    GW --> AG
    HTTT --> PUL
    AG --> NGSP
    PAY --> PAYGOV
    HTTT --> PAY
    HTTT --> AITA
    AG --> GRAY
    ADM --> DB
    VCC --> DB
    MGT --> DB
    AITA --> DB
    PAY --> DB
```

Sơ đồ cho thấy hệ cũ là một tập hợp năm ứng dụng tương đối độc lập, dùng chung dịch vụ đăng nhập một lần Keycloak và cùng loại hệ quản trị cơ sở dữ liệu, nhưng mỗi khối có cơ sở dữ liệu, giao diện và quy trình triển khai riêng. Các khối không chia sẻ một mô hình dữ liệu chung về "HTTT thành viên": khối API Management gọi bên khai thác là ứng dụng (application), khối Hub gọi là publisher và subscriber, khối Payment gọi là đối tác (partner). Một HTTT muốn dùng cả ba năng lực phải được khai báo ba lần ở ba nơi. Dữ liệu vận hành cũng phân tán: số liệu của các luồng tích hợp được đọc trực tiếp từ từng agent qua giao thức JMX, nhật ký nằm ở Graylog, số liệu thanh toán nằm trong cơ sở dữ liệu của khối Payment, và không có một màn hình tổng hợp cho toàn hệ thống.

#### 2.2.3. Năm khối chức năng

**Khối Bus (trục tích hợp)** là thành phần thực hiện tích hợp ứng dụng với ứng dụng. Lõi xử lý là Apache Camel, tổ chức theo đơn vị gọi là agent: mỗi agent là một tiến trình Camel chạy trên một máy chủ xác định bằng địa chỉ và cổng, bên trong chứa nhiều tuyến xử lý (route). Khối Bus có hai giao diện. Giao diện quản trị (nhà cung cấp gọi là vEnterprise Integration Administration) hiển thị danh sách agent, biểu đồ route, số lần chạy, thời gian xử lý từng điểm cuối, dung lượng bộ nhớ, và cho phép dừng, khởi động, tạm ngưng agent hoặc route. Toàn bộ số liệu và thao tác điều khiển này đi qua giao diện Jolokia của từng agent, tức là giao diện quản trị gọi thẳng tới một địa chỉ HTTP trên máy chủ chạy agent. Giao diện thứ hai là công cụ thiết kế luồng (Productivity Tooling), một studio kéo thả trên nền web, sinh ra mã Camel dạng XML, tự cập nhật tệp khai báo thư viện (pom) theo luồng và cho phép nhập thành phần từ tệp JAR. Theo kiểm kê tại D00-03, phần quản trị có 41 chức năng và công cụ thiết kế có 29 chức năng.

**Khối Hub (trung tâm tích hợp)** cung cấp cơ chế trao đổi bản tin theo mô hình phát hành và đăng ký nhận trên nền Apache Pulsar. Giao diện quản trị cho phép khai báo dự án tích hợp, topic, bên phát (publisher), bên nhận (subscriber), quan hệ phát hành và quan hệ đăng ký nhận kèm địa chỉ nhận, số tiến trình xử lý và số lần thử lại. Bảng điều khiển hiển thị số lượng các đối tượng này cùng mức dùng bộ nhớ và bộ xử lý của máy chủ. Hồ sơ yêu cầu người vận hành khối này phải là kỹ sư có hiểu biết về Apache Pulsar. Khối Hub có 14 chức năng được kiểm kê.

**Khối API Management** quản lý tập trung các API theo mô hình ba thành phần là cổng API (gateway), dịch vụ quản trị và giao diện quản trị. Hồ sơ ghi rõ khối này dùng mã nguồn mở của Gravitee. Chức năng chính gồm bọc một API có sẵn, nhập đặc tả từ Swagger, khai báo gói sử dụng (Plan) với kiểu xác thực, hạn mức tốc độ và hạn ngạch, quản lý vòng đời của Plan, quản lý ứng dụng khai thác và việc đăng ký sử dụng. Khối này có 27 chức năng được kiểm kê.

**Khối Danh mục dùng chung (Aita)** lưu trữ và cung cấp các bảng mã dùng chung. Dữ liệu được tổ chức theo mô hình thực thể, thuộc tính, giá trị: mỗi danh mục có một tập thuộc tính do người dùng tự khai báo, mỗi bản ghi lưu giá trị theo từng thuộc tính với độ dài tối đa 2.000 ký tự. Chức năng gồm hiển thị dạng cây, thêm, sửa, xóa, nhập và xuất bằng Excel, CSV, API, và một API truy vấn tùy chọn. Khối này có 19 chức năng được kiểm kê.

**Khối Payment (thanh toán)** là lớp trung gian giữa các HTTT của tỉnh và kênh thanh toán, trong đó nhà cung cấp mặc định và duy nhất được cấu hình sẵn là PayGov. Chức năng gồm quản lý nhà cung cấp dịch vụ thanh toán (thêm, kiểm tra kết nối, kích hoạt, dừng), quản lý đối tác, nhóm dịch vụ và dịch vụ, tiếp nhận kết quả thanh toán, lưu giao dịch, tra cứu nhật ký giao dịch và một bảng điều khiển thống kê. Hồ sơ không mô tả nghiệp vụ đối soát, hoàn tiền, xử lý giao dịch treo hay cơ chế xác thực bản tin trả kết quả từ kênh thanh toán. Khối này có 23 chức năng được kiểm kê.

Bảng dưới đây tổng hợp số chức năng theo khối và theo kết luận xử lý, trích từ D00-03 §5. Bảng dùng để định lượng khối lượng phải kế thừa và để chứng minh rằng phương án đầu tư không làm mất chức năng đang dùng.

| Nhóm kiểm kê | Thuộc khối | Tổng | Giữ nguyên | Nâng cấp | Thay thế | Loại bỏ | Khác |
|---|---|---|---|---|---|---|---|
| BUS | Bus | 41 | 11 | 15 | 15 | 0 | 0 |
| TOOL | Bus (công cụ thiết kế) | 29 | 17 | 9 | 1 | 2 | 0 |
| HUB | Hub | 14 | 7 | 5 | 2 | 0 | 0 |
| APIM | API Management | 27 | 14 | 10 | 3 | 0 | 0 |
| DMDC | Danh mục dùng chung | 19 | 7 | 12 | 0 | 0 | 0 |
| PAY | Payment | 23 | 16 | 7 | 0 | 0 | 0 |
| NGSP | Kết nối quốc gia (xuyên khối) | 8 | 7 | 1 | 0 | 0 | 0 |
| IAM | Định danh (xuyên khối) | 8 | 3 | 2 | 2 | 1 | 0 |
| NFR | Phi chức năng, vận hành | 14 | 3 | 8 | 2 | 0 | 1 |
| **Tổng** | | **183** | **85** | **69** | **25** | **3** | **1** |

: Kiểm kê chức năng hệ LGSP cũ theo năm khối và phương án xử lý

Năm khối nghiệp vụ chiếm 153 trên 183 mục; 30 mục còn lại là các năng lực xuyên khối. Trong 183 mục, có 85 mục được giữ nguyên hành vi, 69 mục được nâng cấp, 25 mục được thay bằng cơ chế khác do thay đổi công nghệ, và chỉ 3 mục được đề xuất loại bỏ vì lý do an toàn thông tin (người dùng tự sửa tệp pom, nhập thành phần từ tệp JAR, đăng nhập bằng tài khoản mạng xã hội). Tỷ lệ 94 mục phải nâng cấp hoặc thay thế trên 183 mục, tương đương 51%, cho thấy hơn một nửa chức năng của hệ cũ không còn đáp ứng nếu giữ nguyên trạng.

#### 2.2.4. Công nghệ và phiên bản

Bảng sau liệt kê các công nghệ nền của hệ cũ theo đúng những gì hồ sơ ghi nhận, kèm tình trạng vòng đời tại thời điểm lập báo cáo (tháng 11/2026). Các mốc kết thúc hỗ trợ được ghi theo công bố của nhà phát hành mà đơn vị tư vấn nắm được; do chưa đối chiếu lại trực tuyến ở thời điểm biên soạn, cột này mang nhãn "chưa xác minh trực tuyến" và phải được kiểm tra trước khi phát hành bản 1.0.

| Thành phần | Phiên bản ghi trong hồ sơ | Nguồn trong hồ sơ | Tình trạng vòng đời (chưa xác minh trực tuyến) |
|---|---|---|---|
| Java | Java 8, bản 8u291 | Phân tích yêu cầu; hướng dẫn cài đặt | Phát hành tháng 4/2021. Oracle đã kết thúc hỗ trợ chính cho Java 8 từ năm 2022; các khung phần mềm hiện hành (Spring Boot 3 trở lên) yêu cầu tối thiểu Java 17 |
| Spring Boot | Spring Boot 2, Spring Boot Reactive | Thiết kế tổng thể | Dòng 2.x đã kết thúc hỗ trợ cộng đồng từ cuối năm 2023 |
| Spring Cloud | Zuul Proxy | Thiết kế tổng thể | Zuul đã ở chế độ bảo trì từ cuối năm 2018 và bị loại khỏi Spring Cloud từ bản 2020.0 |
| Giao diện | Angular 7 | Thiết kế tổng thể; phân tích yêu cầu | Phát hành tháng 10/2018, kết thúc hỗ trợ dài hạn từ tháng 4/2020, tức là trước cả thời điểm hệ cũ được triển khai |
| Hệ điều hành | Linux CentOS 6.x (6.9 trở lên) | Hướng dẫn cài đặt | Kết thúc vòng đời ngày 30/11/2020, trước thời điểm triển khai |
| Máy chủ ứng dụng | Apache Tomcat 8.5.31 (hướng dẫn cài đặt); 9.0.46 (hướng dẫn vận hành) | Hướng dẫn cài đặt; hướng dẫn vận hành | Dòng 8.5 kết thúc vòng đời ngày 31/03/2024. Bản 9.0.46 phát hành tháng 5/2021 và đã có nhiều bản vá bảo mật sau đó |
| Cơ sở dữ liệu | PostgreSQL 13 | Hướng dẫn cài đặt | Kết thúc vòng đời tháng 11/2025 |
| Lõi tích hợp | Apache Camel, không ghi phiên bản | Thiết kế chi tiết Bus | Với Java 8, phiên bản cao nhất dùng được là dòng Camel 3.14, đã kết thúc hỗ trợ từ cuối năm 2023 |
| Nhắn tin | Apache Pulsar, không ghi phiên bản | Thiết kế chi tiết Hub | Các dòng phát hành năm 2021 (2.7, 2.8) đã kết thúc hỗ trợ |
| Quản lý API | Mã nguồn mở Gravitee, không ghi phiên bản | Thiết kế tổng thể | Dòng 3.x của năm 2021 đã kết thúc hỗ trợ |
| Định danh | Keycloak, không ghi phiên bản; đường dẫn lấy token có tiền tố `/auth/realms` | Hướng dẫn lấy token | Tiền tố `/auth` là đặc trưng của bản Keycloak chạy trên WildFly (bản 16 trở về trước), đã kết thúc hỗ trợ từ năm 2022 |
| Quản lý log, số liệu | Graylog, Metricbeat, Tracer, Jolokia | Thiết kế tổng thể; thiết kế chi tiết | Không ghi phiên bản; mô hình thu số liệu qua JMX không còn là hướng phát triển của Camel |
| Đăng nhập màn quản trị Bus | SAML của midPoint | Thiết kế tổng thể | Tồn tại song song với Keycloak, tạo hai cơ chế đăng nhập |

: Công nghệ, phiên bản và tình trạng vòng đời của hệ cũ

Điểm đáng chú ý nhất của bảng là ba thành phần (Angular 7, CentOS 6, Zuul) đã hết vòng đời ngay tại thời điểm hệ cũ được đưa vào sử dụng năm 2021, và tới năm 2026 thì không còn thành phần nền nào trong danh sách còn được nhà phát hành hỗ trợ ở phiên bản ghi trong hồ sơ. Ngoài ra, hồ sơ có hai điểm không nhất quán: hướng dẫn cài đặt ghi Tomcat 8.5.31 trong khi hướng dẫn vận hành ghi Tomcat 9.0.46, và phân tích yêu cầu ghi máy chủ tối thiểu 8 GB bộ nhớ với cổng mạng 10 Gbps trong khi hướng dẫn cài đặt ghi 32 GB với cổng mạng 1 Gbps. Sự thiếu nhất quán này tự nó là một rủi ro vận hành, vì đội tiếp nhận không thể dựa vào hồ sơ để dựng lại hệ thống.

#### 2.2.5. Mô hình triển khai và vận hành

Theo hướng dẫn cài đặt và hướng dẫn vận hành, mỗi khối được đóng gói thành tệp WAR và triển khai trên một máy chủ Tomcat. Phần giao diện và phần xử lý của một khối chạy chung trên một tiến trình Tomcat ở cổng 8080, vì vậy dừng thành phần này sẽ làm dừng luôn thành phần kia. Cơ sở dữ liệu PostgreSQL được cài trên cùng máy chủ hoặc trên một máy chủ cơ sở dữ liệu; biểu mẫu hồ sơ có chỗ ghi cặp máy chủ chính và máy chủ chờ nhưng để trống. Với sáu bộ hướng dẫn cài đặt, hồ sơ hàm ý tối thiểu sáu máy chủ ứng dụng, chưa kể các máy chủ cho Apache Pulsar, cổng API, Keycloak và Graylog vốn không có hướng dẫn cài đặt. Số máy chủ thực tế cần chủ đầu tư xác nhận (Q-D0101-23).

Quy trình vận hành được mô tả hoàn toàn bằng thao tác tay. Người vận hành đăng nhập máy chủ qua SSH, chạy lệnh khởi động hoặc dừng Tomcat, và trong trường hợp không dừng được thì tìm mã tiến trình rồi buộc dừng. Mọi thay đổi cấu hình, kể cả đổi thông tin kết nối cơ sở dữ liệu hay đổi cổng, đều yêu cầu dừng và khởi động lại ứng dụng. Việc nâng cấp được thực hiện bằng cách đổi tên tệp WAR cũ có kèm ngày tháng để làm bản sao lưu, chép tệp mới vào thư mục, dừng Tomcat, triển khai lại rồi khởi động. Quy trình này không có bước kiểm thử tự động, không có cơ chế quay lui ngoài việc chép lại tệp cũ, và luôn gây gián đoạn dịch vụ trong thời gian thực hiện.

Về giám sát, các mục "hướng dẫn giám sát hệ thống", "bảng mã lỗi hệ thống", "các sự cố và cách khắc phục", "hướng dẫn tối ưu" và "hướng dẫn bảo dưỡng" trong tài liệu hướng dẫn vận hành chỉ có khung biểu mẫu, không có nội dung. Phần duy nhất được điền là danh sách kiểm tra định kỳ hằng ngày với các ngưỡng tài nguyên máy chủ (tải bộ xử lý dưới 75%, bộ nhớ dưới 90%, ổ cứng dưới 90%). Nói cách khác, hồ sơ không trang bị cho đội vận hành của tỉnh kiến thức để chẩn đoán và xử lý sự cố ở tầng ứng dụng.

Về cam kết chất lượng, tài liệu phân tích yêu cầu của các khối ghi cùng một bộ chỉ tiêu: độ sẵn sàng 90% mỗi năm; thời gian xử lý không quá 5 giây với 10 người dùng đồng thời và 1.000 bản ghi trong cơ sở dữ liệu, tỷ lệ giao dịch thành công từ 95%; tổng số người dùng hoạt động là 1 và tối đa 100 người dùng đồng thời; tệp nhật ký được sao lưu mỗi tháng một lần; hỗ trợ bảo trì trong 2 tháng sau triển khai. Mức sẵn sàng 90% mỗi năm cho phép hệ thống ngừng hoạt động tới 36,5 ngày trong một năm. Các chỉ tiêu này phù hợp với một sản phẩm thử nghiệm quy mô nhỏ, không phù hợp với một nền tảng mà mọi dịch vụ công trực tuyến của tỉnh phụ thuộc vào.

### 2.3. Đánh giá hệ cũ theo bảy tiêu chí

#### 2.3.1. Vòng đời công nghệ

Như đã phân tích ở mục 2.2.4, toàn bộ nền công nghệ của hệ cũ đã ở ngoài vòng đời hỗ trợ. Hệ quả thực tế có ba lớp. Lớp thứ nhất là an toàn: các lỗ hổng mới được công bố ở Java 8, Spring Boot 2, Tomcat, Angular 7 hay CentOS 6 sẽ không có bản vá chính thức, và tỉnh không thể chứng minh với cơ quan thẩm định an toàn thông tin rằng hệ thống đang được cập nhật bản vá định kỳ theo yêu cầu của CMP-LAW-06 và CMP-LAW-08. Lớp thứ hai là khả năng nâng cấp: do các thành phần phụ thuộc lẫn nhau theo chuỗi, không thể nâng riêng một thành phần. Muốn lên Spring Boot hiện hành phải lên Java 17 trở lên, kéo theo phải thay Zuul, thay phiên bản Camel (với thay đổi lớn về cấu trúc gói và cách khai báo), thay Angular qua nhiều phiên bản chính và thay cả mô hình thu số liệu qua JMX. Khối lượng này tương đương viết lại phần lớn mã nguồn. Lớp thứ ba là nhân lực: các kỹ sư thành thạo những phiên bản đã lỗi thời ngày càng khó tìm, và nhà cung cấp cũng không có động lực duy trì đội ngũ cho một nền tảng họ không còn phát triển.

#### 2.3.2. Khả năng mở rộng

Hệ cũ mở rộng theo chiều dọc, tức là bằng cách tăng cấu hình máy chủ. Mỗi agent của khối Bus gắn cứng với một địa chỉ máy chủ và một cổng được lưu trong cơ sở dữ liệu quản trị; muốn chạy thêm bản sao của một agent phải cài tay trên máy chủ khác và khai báo thêm. Phần giao diện và phần xử lý chạy chung một tiến trình nên không thể tăng riêng năng lực xử lý. Không có cơ chế tự động tăng giảm số bản sao theo tải. Chỉ tiêu thiết kế 10 người dùng đồng thời và 1.000 bản ghi cho thấy hệ cũ chưa từng được kiểm thử ở tải lớn.

Trong khi đó, quy mô tham chiếu cỡ M của một tỉnh sau sắp xếp theo bộ giả định nền là tới 200 HTTT kết nối, 1.000 API công bố, 10 triệu giao dịch đồng bộ mỗi ngày, đỉnh 1.000 giao dịch mỗi giây tại cổng API và 5 triệu bản ghi danh mục dùng chung. Khoảng cách giữa chỉ tiêu thiết kế của hệ cũ và quy mô này là nhiều bậc độ lớn, và không thể thu hẹp bằng việc bổ sung máy chủ vì kiến trúc không cho phép chia tải theo chiều ngang một cách có kiểm soát. Lượng giao dịch thực tế mà hệ cũ đang phục vụ cần chủ đầu tư cung cấp để xác nhận nhận định này (Q-D0101-24).

#### 2.3.3. An toàn thông tin

Việc rà soát hồ sơ phát hiện một số điểm yếu có tính hệ thống, không phải lỗi đơn lẻ.

Điểm thứ nhất là quản lý bí mật. Các tài liệu hướng dẫn cài đặt của cả sáu khối ghi mật khẩu tài khoản cơ sở dữ liệu ở dạng văn bản rõ và dùng chung một mật khẩu cho mọi khối. Phụ lục kết nối NGSP ghi khóa và mã bí mật của ứng dụng (Consumer Key, Consumer Secret) ở dạng văn bản rõ. Hệ cũ dựa vào một thư viện riêng của nhà cung cấp để mã hóa thông tin kết nối trong tệp cấu hình, không có kho bí mật tập trung, không có cơ chế xoay vòng khóa. Bất kỳ ai tiếp cận được bộ hồ sơ đều có thể đã nắm được các thông tin xác thực này, vì vậy toàn bộ khóa và mật khẩu phải được cấp lại khi cắt chuyển.

Điểm thứ hai là bảo vệ kênh truyền. Phụ lục kết nối NGSP ghi địa chỉ lấy token và địa chỉ bộ chuyển tiếp dùng giao thức HTTP không mã hóa trên địa chỉ IP công cộng, và các lệnh mẫu tắt việc kiểm tra chứng thư máy chủ. Hướng dẫn lấy token Keycloak cũng dùng địa chỉ HTTP. Giao diện quản trị khối Bus gọi tới giao diện Jolokia của các agent qua HTTP, trong đó có các lệnh tạm ngưng và khởi động luồng; nếu giao diện này không được bảo vệ ở tầng mạng thì bất kỳ máy nào trong cùng vùng mạng đều có thể dừng luồng tích hợp.

Điểm thứ ba là cơ chế xác thực và phân quyền. Hướng dẫn tích hợp dùng kiểu cấp quyền bằng tên đăng nhập và mật khẩu (grant `password`), tức là ứng dụng phía HTTT giữ mật khẩu của người dùng; kiểu cấp quyền này đã bị loại khỏi khuyến nghị thực hành hiện hành của OAuth. Màn quản trị khối Bus dùng một cơ chế đăng nhập khác (SAML của midPoint) so với các khối còn lại. Hệ cũ không có lớp chính sách phân quyền theo thuộc tính dữ liệu, nên không thể thể hiện quy tắc dạng "cơ quan A chỉ được khai thác trường X của tập dữ liệu Y cho mục đích Z".

Điểm thứ tư là kiểm soát phần mềm đưa vào hệ thống. Công cụ thiết kế luồng cho phép người dùng tự sửa tệp khai báo thư viện và nạp thành phần từ tệp JAR tải lên. Đây là đường đưa mã tùy ý vào môi trường chạy mà không qua kiểm duyệt, trái với yêu cầu kiểm soát phần mềm của hệ thống cấp độ 3.

Điểm thứ năm là hồ sơ cấp độ. Bộ hồ sơ hệ cũ không có hồ sơ đề xuất cấp độ an toàn hệ thống thông tin, không có ma trận ánh xạ biện pháp theo CMP-LAW-08. Tình trạng phê duyệt cấp độ của hệ cũ cần chủ đầu tư xác nhận (Q-D0101-25).

#### 2.3.4. Khả năng quan sát

Khả năng quan sát (observability) là khả năng trả lời câu hỏi "chuyện gì đang xảy ra với một giao dịch cụ thể" mà không phải đăng nhập vào từng máy chủ. Hệ cũ có ba nguồn dữ liệu vận hành rời nhau: số liệu của agent đọc qua Jolokia theo từng lần mở màn hình và không được lưu thành chuỗi thời gian; tệp nhật ký dạng văn bản mỗi giao dịch một dòng, các trường cách nhau bằng dấu gạch đứng, được gom về Graylog; và số liệu tài nguyên máy chủ từ Metricbeat. Hồ sơ yêu cầu các khối ghi một mã giao dịch để liên kết nhật ký giữa các khối, nhưng không có cơ chế truy vết phân tán theo chuẩn, không có sơ đồ đường đi của một giao dịch qua cổng API, luồng tích hợp và hệ thống đích.

Hệ cũ cũng không có cảnh báo chủ động. Danh sách kiểm tra định kỳ là việc người vận hành tự xem các ngưỡng tài nguyên mỗi ngày một lần. Không có khái niệm mục tiêu mức dịch vụ, không có cảnh báo khi tỷ lệ lỗi của một API tăng, không có hàng đợi bản tin lỗi để xử lý lại. Khi một HTTT báo "không gọi được dịch vụ", người vận hành phải lần lượt kiểm tra cổng API, agent, Pulsar và hệ thống đích bằng tay. Thời gian chẩn đoán vì vậy phụ thuộc hoàn toàn vào kinh nghiệm cá nhân, và hệ thống không thể cung cấp số liệu thống kê khai thác dữ liệu theo từng cơ quan để phục vụ báo cáo quản lý.

#### 2.3.5. Khả năng đáp ứng yêu cầu mới

Từ khi hệ cũ được thiết kế năm 2021, khung pháp lý và tổ chức đã thay đổi căn bản. Bảng dưới đây đối chiếu từng nhóm yêu cầu mới với năng lực của hệ cũ. Bảng dùng để chỉ ra rằng khoảng trống không nằm ở một vài chức năng thiếu mà ở cả các lớp năng lực chưa từng có.

| Yêu cầu mới | Căn cứ | Năng lực của hệ cũ | Khoảng trống |
|---|---|---|---|
| Quản trị, phân loại, chia sẻ dữ liệu theo Luật Dữ liệu | CMP-LAW-01, CMP-LAW-02 | Không có danh mục dữ liệu, không có phân loại, không có mã hóa theo mức dữ liệu | Thiếu toàn bộ lớp quản trị dữ liệu |
| Dữ liệu chủ, danh mục dùng chung, đánh giá chất lượng dữ liệu định kỳ | CMP-LAW-03 | Chỉ có danh mục dùng chung dạng bảng mã, không phiên bản, không đồng bộ quốc gia | Thiếu dữ liệu chủ, chất lượng dữ liệu; danh mục phải làm lại mô hình |
| Bảo vệ dữ liệu cá nhân | CMP-LAW-04, CMP-LAW-05 | Không có che, ẩn danh hóa, ghi nhận mục đích xử lý, nhật ký truy cập dữ liệu cá nhân | Thiếu toàn bộ |
| Kết nối NDXP và NDOP theo mô hình mới của Trung tâm dữ liệu quốc gia | CMP-LAW-10, CMP-LAW-11, CMP-LAW-12 | Kết nối NGSP qua cổng trung gian, mỗi dịch vụ một mã service-code, khóa ghi cứng | Phải xây lại lớp kết nối quốc gia, bổ sung kết nối NDOP |
| Chính quyền hai cấp, 34 tỉnh | Bối cảnh tại D00-01 §7 | Danh mục không có lịch sử, không có ngày hiệu lực; không có khái niệm hợp nhất nhiều tỉnh | Không xử lý được sáp nhập đơn vị hành chính có lịch sử |
| Một sản phẩm phục vụ nhiều tỉnh (multi-tenant) | Định hướng nền tảng dùng chung, Q2 của dàn ý | Mỗi triển khai là một bản cài riêng; không có cách ly dữ liệu theo tỉnh | Thiếu toàn bộ; không thể bổ sung mà không sửa mọi bảng dữ liệu |
| Thanh toán đầy đủ: đối soát, hoàn tiền, nhiều kênh | Yêu cầu nghiệp vụ, Q3 của dàn ý | Chỉ PayGov; không đối soát, không hoàn tiền; số tiền lưu bằng kiểu số nguyên 10 chữ số | Phải viết mới nghiệp vụ; phải đổi kiểu dữ liệu số tiền |
| Chức năng, tính năng kỹ thuật của LGSP | CMP-LAW-09 | Có trục tích hợp, quản lý API, nhắn tin; thiếu giám sát tập trung, cổng nhà phát triển, quản lý quy trình | Đáp ứng một phần |
| An toàn hệ thống thông tin cấp độ 3 | CMP-LAW-06, CMP-LAW-07, CMP-LAW-08 | Xem mục 2.3.3 | Không đủ điều kiện kỹ thuật để lập hồ sơ cấp độ 3 |

: Yêu cầu mới, căn cứ và khoảng trống năng lực của hệ cũ

Riêng về thanh toán, cơ sở dữ liệu của khối Payment lưu số tiền bằng kiểu số nguyên giới hạn ở khoảng 2,1 tỷ đồng (xem D00-01 §5, kiểu `T-MONEY`). Một giao dịch nộp thuế, phí hoặc tiền sử dụng đất vượt ngưỡng này sẽ không lưu được đúng giá trị. Kết hợp với việc không có đối soát, tỉnh hiện không có công cụ để phát hiện chênh lệch giữa số tiền người dân đã nộp và số tiền hệ thống nghiệp vụ ghi nhận.

Về multi-tenant, khoảng trống mang tính kiến trúc. Không bảng dữ liệu nào của hệ cũ có trường xác định tỉnh sở hữu, không khối nào có khái niệm cấu hình theo tỉnh, và mỗi lần triển khai cho một tỉnh là một lần cài đặt thủ công theo quy trình ở mục 2.2.5. Một tỉnh mới hình thành từ ba tỉnh cũ, nếu cả ba đều đang dùng hệ cũ, sẽ có ba bản cài không thể gộp lại bằng cấu hình.

#### 2.3.6. Phụ thuộc nhà cung cấp

Mức độ phụ thuộc nhà cung cấp của hệ cũ được đánh giá qua bốn dấu hiệu rút từ hồ sơ. Dấu hiệu thứ nhất là thành phần độc quyền: hệ cũ dùng thư viện mã hóa riêng của nhà cung cấp cho thông tin kết nối và tuân theo các tiêu chuẩn nội bộ của nhà cung cấp về thời gian phản hồi và cấu hình máy chủ ứng dụng, là những tài liệu tỉnh không có. Dấu hiệu thứ hai là tri thức vận hành: tài liệu hướng dẫn vận hành nhiều lần ghi rằng đơn vị vận hành của nhà cung cấp "đã có tài liệu chuẩn" cho hệ điều hành, cơ sở dữ liệu và thiết bị mạng thay vì trình bày nội dung, và để trống các phần xử lý sự cố. Dấu hiệu thứ ba là hồ sơ cài đặt không đủ để dựng lại hệ thống, như đã nêu ở mục 2.2.1. Dấu hiệu thứ tư là cam kết hỗ trợ chỉ 2 tháng sau triển khai theo tài liệu phân tích yêu cầu.

Hồ sơ không cho biết tỉnh có được bàn giao mã nguồn đầy đủ kèm quyền sửa đổi hay không, cũng không cho biết điều khoản và chi phí của hợp đồng hỗ trợ hiện tại (Q-D0101-26). Dù câu trả lời thế nào, bốn dấu hiệu trên cho thấy trong thực tế tỉnh không thể tự vận hành, tự sửa lỗi và tự nâng cấp hệ cũ mà không có nhà cung cấp ban đầu. Điều này làm yếu vị thế của tỉnh trong mọi lần đàm phán gia hạn và khiến nguyên tắc cạnh tranh trong lựa chọn nhà thầu khó thực hiện ở các lần nâng cấp sau.

#### 2.3.7. Chi phí vận hành

Hồ sơ không có số liệu chi phí vận hành hằng năm của hệ cũ; số liệu này cần chủ đầu tư cung cấp để đưa vào so sánh phương án ở Chương 8 (Q-D0101-27). Tuy vậy, cấu trúc chi phí có thể suy ra từ mô hình triển khai và vận hành, và có bốn yếu tố khiến chi phí trên một đơn vị giá trị ở mức cao.

Yếu tố thứ nhất là sử dụng tài nguyên kém hiệu quả: mỗi khối chiếm trọn một máy chủ 32 GB bộ nhớ bất kể tải thực tế, không chia sẻ tài nguyên giữa các khối và không co giãn theo giờ cao điểm hay thấp điểm. Yếu tố thứ hai là chi phí nhân công vận hành thủ công: mọi thao tác triển khai, đổi cấu hình, kiểm tra định kỳ đều do người thực hiện qua dòng lệnh trên từng máy chủ. Yếu tố thứ ba là chi phí gián đoạn: mỗi lần đổi cấu hình hay nâng cấp đều phải dừng dịch vụ, và mức sẵn sàng cam kết 90% mỗi năm cho phép thời gian ngừng dài. Yếu tố thứ tư là chi phí cơ hội do kết nạp chậm: một HTTT mới phải được khai báo riêng ở từng khối, luồng tích hợp phải được dựng và triển khai bằng tay, nên thời gian từ lúc có yêu cầu tới lúc dùng được dịch vụ kéo dài; thời gian trung bình thực tế cần chủ đầu tư cung cấp (Q-D0101-28).

Ngoài chi phí trực tiếp, việc duy trì một hệ thống hết vòng đời còn làm phát sinh chi phí rủi ro không nhìn thấy trong dự toán, gồm chi phí khắc phục khi xảy ra sự cố an toàn thông tin và chi phí chuyển đổi ngày càng tăng do dữ liệu và luồng tích hợp tiếp tục tích lũy trên nền cũ.

### 2.4. Bảng tổng hợp điểm nghẽn

Từ các đánh giá trên, báo cáo tổng hợp 14 điểm nghẽn. Mỗi điểm nghẽn mang một mã `ĐN-nn` dùng trong phạm vi D01-01 để Chương 3 đối chiếu với mục tiêu và các chương giải pháp đối chiếu với phân hệ. Cột "Mức độ" phản ánh mức ảnh hưởng tới khả năng tiếp tục vận hành hợp pháp và an toàn: mức Cao nghĩa là không thể tiếp tục chấp nhận, mức Trung bình nghĩa là làm giảm hiệu quả đáng kể.

| Mã | Điểm nghẽn | Bằng chứng từ hồ sơ hệ cũ | Tiêu chí | Mức độ | Phân hệ Datahub giải quyết |
|---|---|---|---|---|---|
| ĐN-01 | Toàn bộ nền công nghệ hết vòng đời hỗ trợ | Java 8, Spring Boot 2, Zuul, Angular 7, CentOS 6, Tomcat 8.5, PostgreSQL 13 (mục 2.2.4; LGC-NFR-014) | Vòng đời | Cao | Toàn bộ, theo stack tại D01-00 §2 |
| ĐN-02 | Kiến trúc máy chủ đơn lẻ, không co giãn, một điểm hỏng | Một máy chủ cho mỗi khối; agent gắn cứng địa chỉ và cổng; giao diện và xử lý chung tiến trình | Mở rộng | Cao | PH-03, PH-04, PH-05, PH-10, PH-20 |
| ĐN-03 | Cam kết chất lượng dịch vụ thấp, không có dự phòng thảm họa | Sẵn sàng 90% mỗi năm; 5 giây với 10 người dùng; phần sao lưu, phục hồi không có nội dung (LGC-NFR-001, 002, 005) | Mở rộng, vận hành | Cao | PH-13, PH-20; D03-09 |
| ĐN-04 | Bí mật ở dạng rõ, không có kho bí mật, kênh truyền không mã hóa | Mật khẩu CSDL và khóa NGSP trong tài liệu; địa chỉ HTTP; thư viện mã hóa riêng (LGC-NFR-007, LGC-NGSP-008) | ATTT | Cao | PH-12, PH-05, PH-14 |
| ĐN-05 | Xác thực, phân quyền lỗi thời và không thống nhất | Grant `password`; hai cơ chế đăng nhập; không có chính sách theo thuộc tính (LGC-IAM-006, 008) | ATTT | Cao | PH-12 |
| ĐN-06 | Cho phép nạp mã tùy ý vào môi trường chạy | Người dùng sửa tệp pom, nhập JAR (LGC-TOOL-022, 027); điều khiển agent qua Jolokia HTTP | ATTT | Cao | PH-04, PH-05 |
| ĐN-07 | Không quan sát được giao dịch đầu cuối, không cảnh báo chủ động | Số liệu qua JMX theo từng agent; nhật ký văn bản; phần giám sát, sự cố trong hướng dẫn vận hành để trống (LGC-NFR-004) | Quan sát | Cao | PH-13, PH-18 |
| ĐN-08 | Vận hành và triển khai thủ công, mỗi thay đổi đều gây gián đoạn | Chép tệp WAR, khởi động lại Tomcat, buộc dừng tiến trình | Vận hành, chi phí | Trung bình | PH-20 (GitOps), PH-04 |
| ĐN-09 | Thiếu lớp dữ liệu dùng chung: dữ liệu chủ, chất lượng dữ liệu, bảo vệ dữ liệu cá nhân | Không có khối tương ứng trong hệ cũ | Yêu cầu mới | Cao | PH-06, PH-08, PH-09 |
| ĐN-10 | Danh mục dùng chung không phiên bản, không lịch sử, không đồng bộ quốc gia | Mô hình thực thể, thuộc tính, giá trị; không có ngày hiệu lực (khối DMDC) | Yêu cầu mới | Cao | PH-07 |
| ĐN-11 | Kết nối quốc gia theo mô hình cũ, ghi cứng, chưa có NDOP | Phụ lục kết nối NGSP; mã service-code; khóa ghi trong tài liệu | Yêu cầu mới | Cao | PH-14 |
| ĐN-12 | Thanh toán thiếu đối soát, hoàn tiền; giới hạn số tiền | Chỉ PayGov; kiểu số nguyên 10 chữ số; không mô tả bảo mật bản tin trả kết quả | Yêu cầu mới | Cao | PH-19 |
| ĐN-13 | Không hỗ trợ nhiều tỉnh; ba mô hình định danh HTTT rời nhau | Không có trường tỉnh trong dữ liệu; application, publisher, partner khai báo riêng | Yêu cầu mới, mở rộng | Cao | PH-01, PH-20 |
| ĐN-14 | Phụ thuộc nhà cung cấp, hồ sơ không đủ để tự vận hành | Thư viện và tiêu chuẩn nội bộ; hướng dẫn vận hành dẫn chiếu tài liệu không được bàn giao; hỗ trợ 2 tháng (LGC-NFR-011) | Phụ thuộc, chi phí | Trung bình | Toàn bộ; D06-02, D06-03, D06-04 |

: Tổng hợp điểm nghẽn của hệ cũ, bằng chứng, mức độ và phân hệ Datahub giải quyết

Trong 14 điểm nghẽn, 12 điểm ở mức Cao. Sáu điểm (ĐN-01, ĐN-02, ĐN-05, ĐN-09, ĐN-13 và một phần ĐN-07) có nguyên nhân từ kiến trúc, tức là không thể khắc phục bằng cách bổ sung chức năng hay vá lỗi trên nền hiện có. Nhận định này là cơ sở để Chương phân tích phương án đánh giá phương án PA1 (nâng cấp hệ cũ) so với PA2 và PA3.

### 2.5. Sự cần thiết đầu tư

#### 2.5.1. Sự cần thiết về pháp lý

Lập luận pháp lý dựa trên ba nghĩa vụ mà tỉnh phải thực hiện và hệ cũ không cho phép thực hiện. Nghĩa vụ thứ nhất là quản trị và chia sẻ dữ liệu theo CMP-LAW-01 và CMP-LAW-02: tỉnh phải phân loại dữ liệu, bảo đảm chất lượng, kết nối và chia sẻ với cơ sở dữ liệu tổng hợp quốc gia và các cơ quan khác, đồng thời áp dụng biện pháp bảo vệ tương ứng với loại dữ liệu. Hệ cũ không có danh mục dữ liệu, không có khái niệm loại dữ liệu và không có biện pháp bảo vệ phân biệt theo loại. Nghĩa vụ thứ hai theo CMP-LAW-03 là chia sẻ dữ liệu qua dịch vụ được công bố, không yêu cầu người dân cung cấp lại thông tin cơ quan nhà nước đã có, quản lý dữ liệu chủ và danh mục dùng chung, đánh giá chất lượng dữ liệu định kỳ. Hệ cũ chỉ đáp ứng phần hạ tầng kết nối, không đáp ứng phần quản trị dữ liệu. Nghĩa vụ thứ ba là bảo đảm an toàn hệ thống thông tin theo cấp độ theo CMP-LAW-06, CMP-LAW-07 và CMP-LAW-08, và bảo vệ dữ liệu cá nhân theo CMP-LAW-04 và CMP-LAW-05. Một nền tảng trung chuyển dữ liệu công dân của toàn tỉnh được dự kiến xếp cấp độ 3; các điểm nghẽn ĐN-01, ĐN-04, ĐN-05 và ĐN-06 khiến hệ cũ không đủ điều kiện kỹ thuật để được phê duyệt hồ sơ ở cấp độ này.

Ngoài ra, định hướng kiến trúc ở cấp quốc gia đã thay đổi. CMP-LAW-10 và dự thảo tại CMP-LAW-11 xác định nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh phải kết nối với các nền tảng của Trung tâm dữ liệu quốc gia và tuân theo từ điển dữ liệu dùng chung. Phân tích tác động trong hồ sơ dự án (tài liệu `docs/06-impact` của kho mã) chỉ ra sáu nhóm năng lực phải bổ sung, trong đó có kết nối NDOP, ẩn danh hóa dữ liệu và bộ chỉ số thu thập tự động. Không nhóm nào trong số này có thể gắn vào hệ cũ mà không dựng thêm một nền tảng mới bên cạnh.

Về trình tự, thủ tục, việc đầu tư được thực hiện theo quy định hiện hành về quản lý đầu tư ứng dụng công nghệ thông tin sử dụng ngân sách nhà nước, hiện là [Nghị định 224/2026/NĐ-CP](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-45) quy định chi tiết Luật Chuyển đổi số số 148/2025/QH15, có hiệu lực từ 01/7/2026 và thay thế Nghị định 45/2026/NĐ-CP (CMP-LAW-14, nội dung mã cần cập nhật); theo quy định chuyển tiếp, dự án chưa có quyết định đầu tư trước 01/7/2026 như Datahub áp dụng Nghị định 224/2026/NĐ-CP; căn cứ chi tiết được trình bày ở Chương căn cứ pháp lý của báo cáo này.

#### 2.5.2. Sự cần thiết về nghiệp vụ

Về nghiệp vụ, nhu cầu đầu tư xuất phát từ bốn thay đổi trong cách chính quyền tỉnh hoạt động. Thay đổi thứ nhất là mô hình hai cấp: khi cấp huyện không còn, thủ tục hành chính được giải quyết ở cấp xã và cấp tỉnh, và cán bộ cấp xã cần tra cứu trực tuyến dữ liệu dân cư, hộ tịch, đất đai, bảo hiểm, doanh nghiệp ngay khi tiếp nhận hồ sơ. Lượng lời gọi dữ liệu vì thế tăng và phân bố tới nhiều điểm hơn, đòi hỏi nền tảng trung chuyển có độ sẵn sàng cao trong suốt giờ hành chính. Mức 90% mỗi năm của hệ cũ không bảo đảm được điều này.

Thay đổi thứ hai là yêu cầu cắt giảm giấy tờ. Muốn bỏ được yêu cầu người dân nộp bản sao giấy tờ, cơ quan tiếp nhận phải lấy được dữ liệu tương ứng qua nền tảng một cách tin cậy, và dữ liệu đó phải có chất lượng đủ để dùng thay giấy tờ. Điều này cần cả kết nối ổn định (PH-03, PH-04, PH-14) lẫn dữ liệu chủ và đo chất lượng dữ liệu (PH-06, PH-08).

Thay đổi thứ ba là hợp nhất danh mục sau sáp nhập. Danh mục đơn vị hành chính, cơ quan, đơn vị sự nghiệp của tỉnh mới phải được quản lý ở một nơi, có lịch sử thay đổi và có bảng ánh xạ từ mã cũ sang mã mới, để các HTTT chuyển đổi dần mà dữ liệu lịch sử vẫn tra cứu được. Khối Aita không có các khả năng này.

Thay đổi thứ tư là thanh toán trực tuyến trở thành một phần mặc định của dịch vụ công. Khi tỷ lệ thanh toán trực tuyến tăng, việc không có đối soát tự động chuyển từ một thiếu sót thành rủi ro tài chính: chênh lệch không được phát hiện, khiếu nại của người dân không có căn cứ đối chiếu, và bộ phận kế toán phải đối chiếu thủ công.

#### 2.5.3. Sự cần thiết về kỹ thuật

Lập luận kỹ thuật trả lời câu hỏi vì sao không tiếp tục duy trì hoặc nâng cấp từng phần. Thứ nhất, nền công nghệ hết vòng đời là rủi ro tăng dần theo thời gian chứ không đứng yên: mỗi tháng trôi qua có thêm lỗ hổng không có bản vá. Thứ hai, chuỗi phụ thuộc giữa Java, Spring Boot, Camel, Angular và mô hình giám sát qua JMX khiến việc nâng phiên bản từng phần không khả thi, như phân tích ở mục 2.3.1; khối lượng nâng cấp nền tương đương viết lại. Thứ ba, các năng lực còn thiếu ở ĐN-09 và ĐN-13 đòi hỏi thay đổi mô hình dữ liệu của mọi khối, nên việc bổ sung trên nền cũ sẽ vừa tốn công viết lại vừa giữ lại các hạn chế kiến trúc ở ĐN-02 và ĐN-07.

Thứ tư, điều kiện để làm mới đã chín muồi. Các công nghệ nguồn mở tương ứng với từng khối của hệ cũ hiện đều có phiên bản đang được hỗ trợ dài hạn và có mô hình triển khai trên Kubernetes: Camel Quarkus thay cho Camel chạy trong Tomcat, Kafka thay cho Pulsar, APISIX thay cho cổng API cũ, Keycloak bản hiện hành kết hợp OPA thay cho Keycloak bản cũ, OpenTelemetry thay cho JMX (xem ADR-002, ADR-004, ADR-005, ADR-006). Kho mã của dự án đã có phần hiện thực ban đầu cho lõi tích hợp và trình thiết kế luồng, làm giảm rủi ro kỹ thuật của phương án xây mới. Thứ năm, chiến lược thay thế dần (strangler) cho phép hệ mới đứng trước hệ cũ và chuyển từng nhóm dịch vụ, nên việc làm mới không đồng nghĩa với việc chấp nhận một lần cắt chuyển toàn bộ nhiều rủi ro.

#### 2.5.4. Sự cần thiết về kinh tế

Lập luận kinh tế gồm ba ý, với số liệu chi phí cụ thể được trình bày ở Chương 8 và phần lợi ích ở Chương 10. Ý thứ nhất là chi phí của việc trì hoãn. Hệ cũ vẫn phải được trả chi phí vận hành hằng năm trong khi giá trị sử dụng giảm dần; mọi khoản đầu tư vá víu trên nền cũ sẽ mất giá trị khi nền đó buộc phải thay. Đồng thời, mỗi năm trì hoãn có thêm HTTT kết nối, thêm luồng tích hợp và thêm dữ liệu trên nền cũ, làm chi phí di trú sau này tăng.

Ý thứ hai là hiệu quả theo quy mô. Sau sắp xếp còn 34 tỉnh, phần lớn có cùng nhu cầu và cùng nghĩa vụ pháp lý. Nếu mỗi tỉnh tự đầu tư một nền tảng riêng thì chi phí phát triển bị lặp lại 34 lần. Một sản phẩm đóng gói đa tỉnh cho phép chi phí phát triển được trả một lần; tỉnh thứ hai trở đi chỉ chịu chi phí triển khai, hạ tầng, di trú và đào tạo. Theo cơ cấu nỗ lực trong bộ giả định nền, phần thí điểm và triển khai tại một tỉnh (wave W3) chiếm khoảng 55,5 trên 455 người-tháng, tức là khoảng 12% tổng nỗ lực; phân tích chi tiết nằm ở mục 10.2.5.

Ý thứ ba là giảm chi phí tích hợp cho toàn tỉnh. Mỗi kết nối điểm tới điểm được thay bằng một kết nối qua nền tảng sẽ tiết kiệm chi phí xây dựng và duy trì ở cả hai đầu. Việc tái sử dụng danh mục dùng chung và dữ liệu chủ làm giảm chi phí mà từng HTTT phải bỏ ra để tự duy trì bảng mã. Các lợi ích này tăng theo số HTTT kết nối, và số HTTT của mỗi tỉnh đã tăng sau sáp nhập.

#### 2.5.5. Sự phù hợp với Kế hoạch chuyển đổi số của địa phương

Điều 45 của Nghị định 224/2026/NĐ-CP yêu cầu báo cáo nghiên cứu khả thi của dự án đầu tư hệ thống chuyển đổi số thuyết minh rõ sự phù hợp với Kế hoạch chuyển đổi số 5 năm hoặc hằng năm của địa phương. Datahub phù hợp với kế hoạch này ở ba điểm. Thứ nhất, nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh là thành phần hạ tầng số dùng chung mà mọi kế hoạch chuyển đổi số cấp tỉnh đều phải có, vì nó là điều kiện để các HTTT của sở, ngành và cấp xã liên thông với nhau và với các nền tảng quốc gia. Thứ hai, các mục tiêu BO-01, BO-04 và BO-05 trực tiếp phục vụ nhóm chỉ tiêu về kết nối, chia sẻ dữ liệu và dữ liệu dùng chung thường có trong kế hoạch chuyển đổi số của địa phương, còn BO-07 phục vụ chỉ tiêu thanh toán trực tuyến dịch vụ công. Thứ ba, việc thay thế hệ cũ hết vòng đời và lập hồ sơ cấp độ 3 đáp ứng nhóm nhiệm vụ bảo đảm an toàn, an ninh mạng của kế hoạch.

Tuy vậy, báo cáo chưa có văn bản Kế hoạch chuyển đổi số 5 năm và hằng năm của tỉnh thí điểm, nên chưa trích được tên nhiệm vụ, chỉ tiêu và số thứ tự cụ thể mà Datahub thực hiện. Trước khi trình thẩm định, chủ đầu tư cần cung cấp văn bản kế hoạch và xác nhận dự án đã có tên trong danh mục nhiệm vụ của kế hoạch, hoặc đề xuất bổ sung vào kế hoạch hằng năm gần nhất (Q-D0101-29). Trình tự đưa dự án vào kế hoạch và vào kế hoạch đầu tư công trung hạn được trình bày ở chương căn cứ pháp lý.

### 2.6. Hậu quả nếu không đầu tư

Nếu dự án không được đầu tư, tỉnh sẽ tiếp tục vận hành hệ cũ trong tình trạng hiện tại, và các hậu quả sau được dự báo theo thứ tự mức độ nghiêm trọng.

Hậu quả thứ nhất là rủi ro an toàn thông tin và pháp lý tăng dần. Nền tảng đang trung chuyển dữ liệu cá nhân của công dân (hộ tịch, lý lịch tư pháp, bảo hiểm xã hội) chạy trên các thành phần không còn bản vá, với thông tin xác thực đã xuất hiện ở dạng rõ trong tài liệu. Một sự cố lộ lọt dữ liệu sẽ kéo theo trách nhiệm theo CMP-LAW-04, CMP-LAW-05 và CMP-LAW-16, ảnh hưởng tới người dân và tới uy tín của chính quyền tỉnh. Tỉnh cũng không hoàn thành được việc phê duyệt hồ sơ cấp độ cho hệ thống.

Hậu quả thứ hai là không hoàn thành nghĩa vụ về dữ liệu. Không có dữ liệu chủ, chất lượng dữ liệu và phân loại dữ liệu, tỉnh không có công cụ để thực hiện các yêu cầu của CMP-LAW-01, CMP-LAW-02 và CMP-LAW-03, và sẽ gặp khó khi cơ quan trung ương đánh giá mức độ kết nối, chia sẻ dữ liệu thông qua bộ chỉ số thu thập tự động theo định hướng tại CMP-LAW-11.

Hậu quả thứ ba là gián đoạn dịch vụ công. Với mô hình máy chủ đơn lẻ và quy trình vận hành thủ công, khi lượng giao dịch tăng theo mô hình hai cấp, xác suất quá tải và thời gian khắc phục đều tăng. Mỗi lần nền tảng ngừng, cán bộ một cửa ở cấp xã không tra cứu được dữ liệu và phải quay lại yêu cầu người dân nộp giấy tờ.

Hậu quả thứ tư là phân mảnh trở lại. Khi nền tảng dùng chung không đáp ứng, các sở, ngành sẽ tự xây kết nối điểm tới điểm cho nhu cầu cấp bách của mình. Số kết nối không được quản lý tăng lên, làm tăng chi phí của toàn tỉnh và đi ngược yêu cầu chia sẻ qua dịch vụ được công bố.

Hậu quả thứ năm là thất thoát cơ hội về quy mô. Nếu từng tỉnh tự giải quyết riêng, cả nước sẽ có nhiều nền tảng khác nhau làm cùng một việc, mỗi nền tảng lại gắn với một nhà cung cấp, và khoản tiết kiệm từ việc dùng chung một sản phẩm sẽ không đạt được.

Hậu quả thứ sáu là chi phí chuyển đổi sau này cao hơn. Thời điểm buộc phải thay thế rồi sẽ tới, khi một thành phần hết vòng đời gây sự cố không khắc phục được hoặc khi một yêu cầu pháp lý có thời hạn bắt buộc. Thay thế trong tình thế bị động thường không kịp thực hiện theo lộ trình chuyển dần, phải cắt chuyển một lần với rủi ro cao hơn và chi phí cao hơn so với đầu tư chủ động theo kế hoạch tại D01-02.

### 2.7. Câu hỏi mở

> **Câu hỏi mở Q-D0101-21:** Hiện trạng hạ tầng trung tâm dữ liệu tỉnh thí điểm (năng lực tính toán và lưu trữ còn trống, phân vùng mạng, hệ thống sao lưu, địa điểm dự phòng) như thế nào? Thông tin này quyết định lựa chọn giữa phương án hạ tầng H1, H2 và H3.

> **Câu hỏi mở Q-D0101-22:** Tỉnh hiện có bao nhiêu kết nối điểm tới điểm giữa các HTTT không đi qua LGSP, và giữa những hệ thống nào?

> **Câu hỏi mở Q-D0101-23:** Phiên bản thực tế đang chạy của Apache Camel, Apache Pulsar, Gravitee, Keycloak, Graylog, hệ điều hành và Tomcat là gì; hệ cũ đang chạy trên bao nhiêu máy chủ, có cụm dự phòng hay không? Hồ sơ có mâu thuẫn về phiên bản Tomcat và cấu hình máy chủ tối thiểu.

> **Câu hỏi mở Q-D0101-24:** Số liệu vận hành 12 tháng gần nhất của hệ cũ: số HTTT đang kết nối, số API, số luồng tích hợp, số topic, lượng giao dịch mỗi ngày và giờ cao điểm, số giao dịch thanh toán mỗi tháng, số bản ghi danh mục. Trong khi chờ, báo cáo dùng quy mô cỡ M.

> **Câu hỏi mở Q-D0101-25:** Hệ cũ đã được phê duyệt hồ sơ đề xuất cấp độ an toàn hệ thống thông tin chưa, ở cấp độ nào, vào thời điểm nào?

> **Câu hỏi mở Q-D0101-26:** Tỉnh có được bàn giao mã nguồn đầy đủ của hệ cũ kèm quyền sửa đổi không? Hợp đồng hỗ trợ, bảo trì hiện tại có thời hạn và phạm vi thế nào?

> **Câu hỏi mở Q-D0101-27:** Chi phí vận hành, bảo trì hằng năm của hệ cũ (thuê hạ tầng, hỗ trợ kỹ thuật, nhân sự vận hành) trong ba năm gần nhất là bao nhiêu?

> **Câu hỏi mở Q-D0101-28:** Thời gian trung bình thực tế để kết nạp một HTTT mới và để đưa một luồng tích hợp mới vào vận hành trên hệ cũ là bao lâu; số sự cố gây gián đoạn và tổng thời gian ngừng dịch vụ trong 12 tháng gần nhất?

> **Câu hỏi mở Q-D0101-29:** Tỉnh thí điểm đã ban hành Kế hoạch chuyển đổi số 5 năm và kế hoạch năm hiện hành chưa; Datahub (hoặc nhiệm vụ nâng cấp nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh) đã có trong danh mục nhiệm vụ của kế hoạch chưa, ở mục nào?


## 3. Mục tiêu, quy mô, địa điểm và phạm vi đầu tư

> **Tóm tắt cho hội đồng thẩm định.** Dự án đầu tư một nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub) để thay thế hệ LGSP đang vận hành, bổ sung lớp dữ liệu dùng chung và đóng gói thành sản phẩm dùng được cho nhiều tỉnh. Mục tiêu cụ thể được lượng hóa bằng 9 mục tiêu nghiệp vụ (BO-01 đến BO-09) và 18 chỉ số (KPI-01 đến KPI-18), trong đó các đích chính là độ sẵn sàng tầng xử lý dữ liệu từ mức cam kết 90% mỗi năm lên ít nhất 99,9% mỗi tháng, thời gian kết nạp một HTTT từ khoảng 2 đến 4 tuần xuống không quá 5 ngày làm việc, và thời gian khởi tạo một tỉnh mới trên nền tảng không quá 1 ngày làm việc. Quy mô đầu tư gồm 20 phân hệ phát hành theo ba đợt trong 18 tháng, thiết kế cho tỉnh cỡ M (tối đa 200 HTTT, 10 triệu giao dịch đồng bộ mỗi ngày) và mở rộng được lên cỡ L mà không thay kiến trúc. Hệ thống được đặt tại trung tâm dữ liệu của tỉnh thí điểm hoặc trên nền tảng điện toán đám mây Chính phủ, có địa điểm dự phòng thứ hai. Phạm vi không bao gồm kho dữ liệu phân tích, các HTTT nghiệp vụ của sở, ngành và việc mua sắm hạ tầng phần cứng.

### 3.1. Mục tiêu tổng quát

Mục tiêu tổng quát của dự án là xây dựng một nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh hiện đại, an toàn và dùng chung được cho nhiều tỉnh, làm đầu mối duy nhất cho mọi trao đổi dữ liệu giữa các HTTT trong tỉnh và giữa tỉnh với các nền tảng, cơ sở dữ liệu quốc gia, đồng thời cung cấp lớp dữ liệu dùng chung gồm danh mục dùng chung, dữ liệu chủ, chất lượng dữ liệu và bảo vệ dữ liệu cá nhân. Nền tảng thay thế hệ LGSP hiện có theo lộ trình chuyển đổi dần, không làm gián đoạn dịch vụ công đang vận hành.

Mục tiêu này có ba vế, và mỗi vế trả lời một nhóm điểm nghẽn đã nêu ở mục 2.4. Vế thứ nhất, "đầu mối duy nhất, hiện đại, an toàn", trả lời các điểm nghẽn về vòng đời công nghệ, khả năng mở rộng, an toàn thông tin và quan sát (ĐN-01 đến ĐN-08). Vế thứ hai, "lớp dữ liệu dùng chung", trả lời các yêu cầu mới mà hệ cũ không có khả năng đáp ứng (ĐN-09 đến ĐN-12). Vế thứ ba, "dùng chung được cho nhiều tỉnh", trả lời bài toán phụ thuộc nhà cung cấp và đầu tư lặp lại giữa các tỉnh (ĐN-13, ĐN-14). Cụm từ "theo lộ trình chuyển đổi dần" là một ràng buộc chứ không phải một mong muốn: hệ cũ phải tiếp tục phục vụ trong suốt thời gian chuyển đổi, và mọi phương án được đề xuất ở các chương sau đều phải thỏa ràng buộc này.

Mục tiêu tổng quát phù hợp với định hướng quản trị, chia sẻ dữ liệu theo CMP-LAW-01, CMP-LAW-02 và CMP-LAW-03, với yêu cầu chức năng của nền tảng tích hợp cấp tỉnh tại CMP-LAW-09 và với định hướng kiến trúc tại CMP-LAW-10 và CMP-LAW-11. Theo phân loại của Nghị định 224/2026/NĐ-CP, đây là một dự án đầu tư hệ thống chuyển đổi số; sự phù hợp của mục tiêu với Kế hoạch chuyển đổi số 5 năm và hằng năm của tỉnh được thuyết minh tại mục 2.5.5. Việc chứng minh sự phù hợp chi tiết với các văn bản pháp luật thuộc chương căn cứ pháp lý của báo cáo.

### 3.2. Mục tiêu cụ thể và chỉ số đo

#### 3.2.1. Cách đặt mục tiêu

Mục tiêu cụ thể của dự án được phát biểu dưới dạng mục tiêu nghiệp vụ (business objective, mã `BO`), mỗi mục tiêu có một hoặc hai chỉ số đo (key performance indicator, mã `KPI`) với giá trị nền, giá trị đích và thời điểm đo. Cách đặt này có hai lợi ích cho công tác thẩm định và quản lý dự án. Thứ nhất, hội đồng có thể đánh giá dự án có đạt mục tiêu hay không bằng số đo, không phụ thuộc vào đánh giá chủ quan. Thứ hai, mỗi chỉ số được gắn với một cổng nghiệm thu (acceptance gate) trong kế hoạch dự án (D01-02), nên việc theo dõi tiến độ và việc nghiệm thu dùng chung một thước đo.

Các mục tiêu và chỉ số dưới đây trích nguyên mã và giá trị từ tài liệu yêu cầu nghiệp vụ. Định nghĩa chính thức, công thức tính và phương pháp đo nằm tại D02-01 §3; báo cáo này không định nghĩa lại để tránh hai nguồn sự thật. Giá trị nền có dấu sao (*) là giá trị chưa đo được trên hệ cũ do hồ sơ hệ cũ không có số liệu vận hành, và chủ đầu tư cần cung cấp số liệu thực tế trước cổng G1 (xem câu hỏi mở Q-D0101-28 ở Chương 2).

#### 3.2.2. Bảng mục tiêu và chỉ số

Bảng sau tổng hợp 9 mục tiêu nghiệp vụ và 18 chỉ số đo. Cột cuối cho biết điểm nghẽn ở Chương 2 mà mục tiêu đó xử lý, để hội đồng thấy mỗi mục tiêu đều xuất phát từ một vấn đề có bằng chứng.

| Mã BO | Mục tiêu nghiệp vụ | Mã KPI | Chỉ số đo | Giá trị nền | Giá trị đích | Thời điểm đo | Điểm nghẽn xử lý |
|---|---|---|---|---|---|---|---|
| BO-01 | Mọi trao đổi dữ liệu giữa các HTTT của tỉnh và với quốc gia đi qua một điểm có kiểm soát | KPI-01 | Tỷ lệ HTTT kết nối qua Datahub trên tổng số HTTT có trao đổi dữ liệu | Chưa đo* | ≥ 90% | 12 tháng sau vận hành | ĐN-11, ĐN-13 |
| | | KPI-02 | Số kết nối điểm tới điểm còn tồn tại ngoài nền tảng | Chưa đo* | Giảm ≥ 80% | 12 tháng sau vận hành | |
| BO-02 | Dịch vụ công trực tuyến không gián đoạn vì nền tảng tích hợp | KPI-03 | Độ sẵn sàng tầng xử lý dữ liệu (data plane) theo tháng | 90%/năm (cam kết cũ) | ≥ 99,9%/tháng | Từ nghiệm thu | ĐN-02, ĐN-03 |
| | | KPI-04 | Độ trễ thêm do nền tảng tại cổng API, phân vị 95 | Không đo | ≤ 50 ms | Từ nghiệm thu | |
| BO-03 | Rút ngắn thời gian đưa một kết nối mới vào vận hành | KPI-05 | Thời gian từ khi nộp hồ sơ kết nạp tới khi HTTT gọi được API ở môi trường thật | Ước 2–4 tuần* | ≤ 5 ngày làm việc | 6 tháng sau vận hành | ĐN-08, ĐN-13 |
| | | KPI-06 | Thời gian xây dựng một luồng tích hợp chuẩn | Ước 5–10 ngày công | ≤ 2 ngày công | 6 tháng sau vận hành | |
| BO-04 | Tuân thủ pháp luật về dữ liệu và an toàn thông tin | KPI-07 | Tỷ lệ lượt khai thác dữ liệu có nhật ký đủ thông tin cho thanh tra | Không có | 100% | Từ nghiệm thu | ĐN-01, ĐN-04, ĐN-05, ĐN-06, ĐN-09 |
| | | KPI-08 | Kết quả đánh giá an toàn thông tin cấp độ 3 | Chưa có hồ sơ* | Được phê duyệt | Trước vận hành chính thức | |
| | | KPI-09 | Số thông tin xác thực đối ngoại lưu ngoài kho bí mật | > 0 | 0 | Từ nghiệm thu | |
| BO-05 | Danh mục dùng chung thống nhất, đồng bộ với quốc gia | KPI-10 | Tỷ lệ danh mục dùng chung được quản lý tập trung và có phiên bản | Chưa đo* | 100% danh mục bắt buộc | 12 tháng sau vận hành | ĐN-10 |
| | | KPI-11 | Độ trễ đồng bộ danh mục quốc gia sau khi ban hành | Thủ công | ≤ 24 giờ | 6 tháng sau vận hành | |
| BO-06 | Một nền tảng dùng chung cho nhiều tỉnh, giảm chi phí triển khai lặp | KPI-12 | Thời gian khởi tạo một tenant tỉnh mới tới khi sẵn sàng kết nối | Nhiều tuần | ≤ 1 ngày làm việc | Từ nghiệm thu | ĐN-13, ĐN-14 |
| BO-07 | Thanh toán trực tuyến minh bạch, đối soát được | KPI-13 | Tỷ lệ giao dịch đối soát tự động khớp với kênh thanh toán | Không đối soát | ≥ 99,5% | 6 tháng sau vận hành | ĐN-12 |
| | | KPI-14 | Thời gian phát hiện giao dịch lệch | Không có | ≤ 1 ngày làm việc | 6 tháng sau vận hành | |
| BO-08 | Vận hành chủ động thay vì xử lý khi người dân phản ánh | KPI-15 | Thời gian phát hiện sự cố (MTTD) | Không đo | ≤ 5 phút | Từ nghiệm thu | ĐN-07, ĐN-08 |
| | | KPI-16 | Thời gian khôi phục dịch vụ với sự cố mức 1 (MTTR) | Không đo | ≤ 1 giờ | Từ nghiệm thu | |
| BO-09 | Người vận hành dùng một giao diện thống nhất | KPI-17 | Số giao diện quản trị riêng biệt phải dùng | 5 | 1 | Từ nghiệm thu | ĐN-13 |
| | | KPI-18 | Điểm hài lòng của người dùng nội bộ theo thang SUS | Chưa đo | ≥ 75 | Sau kiểm thử chấp nhận | |

: Mục tiêu nghiệp vụ, chỉ số KPI, giá trị nền và giá trị đích

Định nghĩa chính thức của toàn bộ BO và KPI trong bảng tại D02-01.

Ba chỉ số cần được hội đồng lưu ý vì chúng mang ý nghĩa quyết định đối với hiệu quả đầu tư. KPI-03 thể hiện bước thay đổi về chất lượng dịch vụ: mức 90% mỗi năm của hệ cũ cho phép ngừng tới 36,5 ngày, còn mức 99,9% mỗi tháng chỉ cho phép ngừng khoảng 43 phút trong một tháng, tương đương khoảng 8,8 giờ trong một năm. Chỉ tiêu này được đặc tả kỹ thuật tại NFR-00-010 của D02-02 và được kiểm chứng bằng kiểm tra tổng hợp mỗi phút. KPI-05 và KPI-06 là cơ sở định lượng cho lợi ích giảm chi phí tích hợp ở Chương 10, vì thời gian kết nạp và thời gian dựng luồng quyết định trực tiếp số ngày công mà tỉnh và các nhà thầu của sở phải bỏ ra. KPI-12 là chỉ số chứng minh tính sản phẩm của Datahub: nếu khởi tạo một tỉnh mới mất không quá một ngày làm việc thì chi phí nhân rộng cho tỉnh thứ hai trở đi chủ yếu còn là hạ tầng, di trú và đào tạo, như phân tích ở mục 10.2.5.

#### 3.2.3. Quan hệ giữa điểm nghẽn, mục tiêu và phân hệ

Sơ đồ sau thể hiện chuỗi lập luận từ điểm nghẽn ở Chương 2, qua mục tiêu nghiệp vụ, tới nhóm phân hệ chịu trách nhiệm hiện thực. Mục đích của sơ đồ là để hội đồng kiểm tra rằng không có mục tiêu nào thiếu phân hệ hiện thực và không có phân hệ nào được đầu tư mà không phục vụ một mục tiêu.

```{.mermaid caption="Chuỗi từ điểm nghẽn qua mục tiêu nghiệp vụ tới nhóm phân hệ"}
flowchart TB
    subgraph DN["Điểm nghẽn, Chương 2"]
        D1["ĐN-01 đến ĐN-06<br/>vòng đời, mở rộng, ATTT"]
        D2["ĐN-07, ĐN-08<br/>quan sát, vận hành thủ công"]
        D3["ĐN-09, ĐN-10<br/>thiếu lớp dữ liệu dùng chung"]
        D4["ĐN-11, ĐN-12<br/>kết nối quốc gia, thanh toán"]
        D5["ĐN-13, ĐN-14<br/>một tỉnh, phụ thuộc nhà cung cấp"]
    end
    subgraph MT["Mục tiêu nghiệp vụ"]
        B1["BO-01 một điểm kiểm soát"]
        B2["BO-02 không gián đoạn"]
        B3["BO-03 kết nạp nhanh"]
        B4["BO-04 tuân thủ dữ liệu, ATTT"]
        B5["BO-05 danh mục thống nhất"]
        B6["BO-06 dùng chung nhiều tỉnh"]
        B7["BO-07 thanh toán đối soát được"]
        B8["BO-08 vận hành chủ động"]
        B9["BO-09 một giao diện"]
    end
    subgraph PH["Nhóm phân hệ Datahub"]
        P1["Kết nối, tích hợp<br/>PH-01 đến PH-05, PH-10, PH-11, PH-14"]
        P2["Dữ liệu dùng chung<br/>PH-06 đến PH-09"]
        P3["Vận hành, quản trị<br/>PH-12, PH-13, PH-16, PH-18, PH-20"]
        P4["Thanh toán PH-19"]
        P5["Tự phục vụ, AI<br/>PH-15, PH-17"]
    end
    D1 --> B2
    D1 --> B4
    D2 --> B8
    D2 --> B3
    D3 --> B4
    D3 --> B5
    D4 --> B1
    D4 --> B7
    D5 --> B6
    D5 --> B9
    B1 --> P1
    B2 --> P1
    B2 --> P3
    B3 --> P1
    B3 --> P5
    B4 --> P2
    B4 --> P3
    B5 --> P2
    B6 --> P3
    B7 --> P4
    B8 --> P3
    B9 --> P3
```

Khi đối chiếu sơ đồ, đơn vị tư vấn nhận thấy hai khoảng trống giữa điểm nghẽn và bộ mục tiêu hiện có tại D02-01. Khoảng trống thứ nhất là ĐN-09 (thiếu dữ liệu chủ và chất lượng dữ liệu) hiện chỉ được đo gián tiếp qua BO-04 và BO-05, trong khi hai phân hệ PH-06 và PH-08 chưa có chỉ số riêng về tỷ lệ bản ghi được hợp nhất hay điểm chất lượng dữ liệu. Khoảng trống thứ hai là mức độ tự chủ công nghệ (ĐN-14) chưa có chỉ số đo, ví dụ tỷ lệ thành phần có mã nguồn và tài liệu được bàn giao, hay năng lực tự triển khai một bản phát hành của đội vận hành tỉnh. Báo cáo không tự đặt mã chỉ số mới mà đề xuất bổ sung ở mục 3.7 để D02-01 cân nhắc.

#### 3.2.4. Mục tiêu về tiến độ và chất lượng sản phẩm

Ngoài mục tiêu nghiệp vụ, dự án có các mục tiêu về tiến độ và chất lượng sản phẩm, được dùng làm điều kiện của các cổng nghiệm thu trong D01-02. Về tiến độ, MVP gồm 12 phân hệ được nghiệm thu tại cổng G2 ở mốc T0+10 tháng; MVP vận hành chính thức tại tỉnh thí điểm ở cổng G3, mốc T0+13 tháng; đợt 2 được nghiệm thu ở cổng G4, mốc T0+15 tháng; và toàn bộ dự án được nghiệm thu ở cổng G5, mốc T0+18 tháng, khi hệ cũ được tắt và nền tảng đã được khởi tạo cho tỉnh thứ hai. Về chất lượng, mọi chức năng của hệ cũ có kết luận giữ nguyên, nâng cấp hoặc thay thế trong D00-03 (179 trên 183 mục) đều phải có yêu cầu chức năng tương ứng đã kiểm thử đạt; hồ sơ đề xuất cấp độ 3 phải được phê duyệt trước khi vận hành chính thức; và các chỉ tiêu phi chức năng cấp hệ thống tại D02-02 (nhóm NFR-00) phải đạt trong đợt kiểm thử chấp nhận.

### 3.3. Quy mô đầu tư

#### 3.3.1. Quy mô chức năng

Datahub gồm 20 phân hệ, tổ chức thành năm miền năng lực là kết nối và chia sẻ, tích hợp, dữ liệu dùng chung, vận hành và quản trị, và thanh toán. Danh sách đầy đủ, công nghệ đặc thù của từng phân hệ và kiến trúc tổng thể được mô tả tại D03-01; ở đây chỉ trình bày cách các phân hệ được phân đợt, vì phân đợt quyết định quy mô của từng giai đoạn đầu tư và thời điểm phát sinh lợi ích.

Việc phân đợt theo nguyên tắc: đợt đầu (MVP) phải đủ để thay thế bốn khối Bus, Hub, API Management và Danh mục dùng chung của hệ cũ, kết nối được với nền tảng quốc gia và phục vụ nhiều tỉnh ngay từ đầu; các đợt sau bổ sung những năng lực mà hệ cũ không có hoặc có ở mức thấp. Nguyên tắc này bảo đảm rằng tỉnh thí điểm bắt đầu chuyển đổi được ngay sau cổng G2, không phải chờ toàn bộ 20 phân hệ.

| Đợt | Phân hệ | Số phân hệ | Thay thế khối hệ cũ hoặc năng lực mới | Cổng, mốc |
|---|---|---|---|---|
| MVP (đợt 1) | PH-01, PH-02, PH-03, PH-04, PH-05, PH-07, PH-10, PH-12, PH-13, PH-14, PH-18, PH-20 | 12 | Thay khối Bus, Hub, API Management, Danh mục dùng chung và kết nối NGSP; bổ sung giám sát xuyên suốt và quản trị tenant | G2, T0+10; vận hành chính thức G3, T0+13 |
| Đợt 2 | PH-19, PH-15, PH-09, PH-11 | 4 | Thay khối Payment; bổ sung cổng nhà phát triển, bảo vệ dữ liệu cá nhân, điều phối quy trình | G4, T0+15 |
| Đợt 3 | PH-06, PH-08, PH-16, PH-17 | 4 | Bổ sung dữ liệu chủ, chất lượng dữ liệu, báo cáo chỉ tiêu, trợ lý AI | G5, T0+18 |

: Quy mô chức năng theo ba đợt triển khai, kèm khối hệ cũ thay thế và cổng nghiệm thu

Trong MVP, yêu cầu tối thiểu về che dữ liệu cá nhân trong nhật ký và kiểm soát truy cập theo vai trò vẫn được hiện thực ở PH-03, PH-12 và PH-13, để tỉnh không phải chờ PH-09 ở đợt 2 mới đáp ứng các yêu cầu cơ bản về bảo vệ dữ liệu cá nhân. Khối Payment của hệ cũ tiếp tục chạy song song cho tới khi PH-19 vận hành ổn định 30 ngày.

Về khối lượng kế thừa, Datahub phải bảo toàn 179 chức năng của hệ cũ (85 giữ nguyên hành vi, 69 nâng cấp, 25 thay bằng cơ chế khác), loại bỏ 3 chức năng vì lý do an toàn thông tin theo chấp thuận của chủ đầu tư, và xử lý riêng 1 mục phi chức năng, theo kiểm kê tại D00-03 §5. Đây là phần "giữ nguyên giá trị đã đầu tư"; phần còn lại của quy mô chức năng là năng lực mới.

#### 3.3.2. Quy mô phục vụ

Nền tảng được thiết kế theo ba cỡ tham chiếu, để một bản sản phẩm triển khai được cho các tỉnh có quy mô khác nhau mà không phải thiết kế lại. Bảng dưới đây trích các chỉ tiêu chính từ bộ giả định nền; cấu hình hạ tầng tương ứng với từng cỡ được tính ở chương giải pháp hạ tầng và tại D03-09.

| Chỉ tiêu | Cỡ S | Cỡ M (tỉnh thí điểm, giả định) | Cỡ L |
|---|---|---|---|
| Số HTTT kết nối | ≤ 80 | ≤ 200 | ≤ 400 |
| Số API, dịch vụ công bố | ≤ 400 | ≤ 1.000 | ≤ 2.500 |
| Giao dịch đồng bộ mỗi ngày | 2 triệu | 10 triệu | 30 triệu |
| Lượt gọi mỗi giây ở đỉnh tại cổng API | 300 | 1.000 | 3.000 |
| Sự kiện mỗi ngày | 5 triệu | 25 triệu | 80 triệu |
| Bản ghi danh mục dùng chung | 2 triệu | 5 triệu | 15 triệu |
| Giao dịch thanh toán mỗi tháng | 100 nghìn | 400 nghìn | 1,2 triệu |
| Sẵn sàng tầng xử lý dữ liệu | 99,9% | 99,9% | 99,95% |
| RPO / RTO | 15 phút / 1 giờ data plane, 4 giờ control plane | 15 phút / 1 giờ data plane, 4 giờ control plane | 5 phút / 1 giờ data plane, 2 giờ control plane |

: Chỉ tiêu quy mô phục vụ theo ba cỡ S, M và L

Tỉnh thí điểm được giả định ở cỡ M. Giả định này chưa dựa trên số liệu vận hành thực của hệ cũ, vì hồ sơ hệ cũ không có số liệu giao dịch. Nếu số liệu thực tế do chủ đầu tư cung cấp cho thấy tỉnh thuộc cỡ S hoặc cỡ L, phần chi phí hạ tầng ở Chương 8 sẽ thay đổi theo bảng cấu hình tương ứng, còn phần phần mềm không thay đổi vì cùng một bản sản phẩm phục vụ cả ba cỡ. Cách thiết kế theo cỡ cũng giải quyết trực tiếp tình trạng của hệ cũ, nơi cam kết hiệu năng chỉ là 10 người dùng đồng thời với 1.000 bản ghi.

#### 3.3.3. Quy mô thời gian và nguồn lực

Giai đoạn thực hiện kéo dài 18 tháng kể từ T0, chia thành sáu wave từ W0 đến W5 với chu kỳ phát triển (sprint) hai tuần, tiếp theo là 12 tháng bảo hành từ T0+18 đến T0+30. Đội thực hiện lúc đông nhất khoảng 28 người (wave W2), tổng nỗ lực tham chiếu khoảng 455 người-tháng; con số chính xác và cơ cấu chi phí được tính tại Chương 8, kế hoạch chi tiết tại D01-02. Môi trường triển khai gồm năm môi trường DEV, TEST, STAGING, PROD và DR.

#### 3.3.4. Quy mô mở rộng sang nhiều tỉnh

Datahub được thiết kế là sản phẩm đa tenant: mỗi tỉnh là một tenant độc lập về dữ liệu và quản trị, có thể dùng chung cụm hạ tầng với tỉnh khác hoặc chạy trên cơ sở dữ liệu riêng, cụm riêng, theo ba chế độ cách ly được đặc tả tại D03-10. Trong phạm vi dự án, quy mô cam kết là một tỉnh thí điểm vận hành chính thức và một tỉnh thứ hai được khởi tạo, kết nối HTTT đầu tiên trước cổng G5. Việc triển khai cho các tỉnh tiếp theo là các dự án hoặc hợp đồng dịch vụ riêng, không thuộc tổng mức đầu tư của dự án này, nhưng hiệu quả của khả năng nhân rộng được phân tích ở Chương 10 vì đó là một trong những lý do chính để chọn mô hình sản phẩm.

### 3.4. Đối tượng hưởng lợi

Đối tượng hưởng lợi của dự án được xác định theo danh sách bên liên quan (mã `SH`) tại D02-01 §4. Bảng sau nhóm các bên liên quan theo cách họ hưởng lợi, để làm cơ sở cho phần đánh giá hiệu quả xã hội ở Chương 10.

| Nhóm hưởng lợi | Bên liên quan | Lợi ích chính |
|---|---|---|
| Hưởng lợi trực tiếp, cơ quan quản lý | SH-01 Lãnh đạo UBND tỉnh; SH-02 Sở Khoa học và Công nghệ | Có công cụ quản lý tập trung mọi kết nối, có số liệu báo cáo chỉ tiêu chuyển đổi số, đáp ứng nghĩa vụ pháp lý về dữ liệu |
| Hưởng lợi trực tiếp, đơn vị vận hành | SH-03 Trung tâm dữ liệu hoặc Trung tâm Chuyển đổi số tỉnh | Một giao diện quản trị thay cho năm, giám sát chủ động, triển khai tự động, ít thao tác thủ công |
| Hưởng lợi trực tiếp, đơn vị khai thác | SH-04 Các sở, ngành, UBND cấp xã; SH-05 Nhà thầu phát triển HTTT của các sở | Kết nạp nhanh, đặc tả chuẩn, môi trường thử, tự phục vụ; dùng lại danh mục và dữ liệu chủ thay vì tự duy trì |
| Hưởng lợi trực tiếp, chủ quản dữ liệu | SH-08 Cơ quan chủ quản từng loại dữ liệu | Kiểm soát được ai dùng dữ liệu của mình, vì mục đích gì, có nhật ký để đối chiếu |
| Bên ràng buộc, cùng hưởng lợi | SH-06 Cơ quan quản lý NDXP và các cơ sở dữ liệu quốc gia; SH-07 Cơ quan chuyên trách an toàn thông tin; SH-09 Cổng thanh toán và đơn vị cung cấp dịch vụ thanh toán | Tỉnh kết nối đúng chuẩn, có nhật ký, có hồ sơ cấp độ, đối soát khớp |
| Hưởng lợi gián tiếp | SH-10 Người dân và doanh nghiệp | Không phải nộp lại giấy tờ cơ quan nhà nước đã có, dịch vụ công ít gián đoạn, dữ liệu cá nhân được bảo vệ, thanh toán minh bạch |
| Bên cung cấp, chuyển giao | SH-11 Đơn vị cung cấp sản phẩm Datahub; SH-12 Đơn vị vận hành hệ LGSP cũ | Sản phẩm nhân rộng được; chuyển giao an toàn, không mất dữ liệu |

: Nhóm hưởng lợi, bên liên quan và lợi ích chính

Ngoài tỉnh thí điểm, các tỉnh khác cũng là đối tượng hưởng lợi tiềm năng, vì sản phẩm được thiết kế để triển khai lại với chi phí biên thấp. Lợi ích này không được tính vào hiệu quả của dự án ở mức cam kết, mà chỉ được trình bày như một kịch bản tại mục 10.2.5.

### 3.5. Địa điểm đầu tư

Địa điểm thực hiện và đặt hệ thống của dự án là tỉnh thí điểm **[ĐIỀN: tên tỉnh thí điểm]**, nơi hệ LGSP cũ đang vận hành. Hệ thống sản xuất (PROD) được đặt tại một trong hai vị trí, tùy phương án hạ tầng được chọn ở chương phân tích phương án.

Vị trí thứ nhất là trung tâm dữ liệu của tỉnh thí điểm (phương án H1). Ưu điểm của vị trí này là tỉnh trực tiếp kiểm soát hạ tầng và dữ liệu, thuận lợi khi lập hồ sơ cấp độ và khi kết nối với các HTTT đang đặt cùng trung tâm. Điều kiện để chọn vị trí này là trung tâm dữ liệu còn đủ năng lực tính toán, lưu trữ và có thể dựng cụm Kubernetes đáp ứng yêu cầu tối thiểu tại D03-09; hiện trạng năng lực còn trống chưa được khảo sát (câu hỏi mở Q-D0101-21 ở Chương 2).

Vị trí thứ hai là nền tảng điện toán đám mây Chính phủ (phương án H2), dùng hạ tầng ảo hóa hoặc dịch vụ Kubernetes được quản lý. Ưu điểm là không phải đầu tư phần cứng ban đầu, co giãn theo nhu cầu và thuận lợi cho việc nhân rộng sang tỉnh khác. Điều kiện là nhà cung cấp đám mây bảo đảm lưu trữ dữ liệu trong lãnh thổ Việt Nam, đáp ứng yêu cầu an toàn thông tin cấp độ 3 và không ràng buộc dự án vào dịch vụ độc quyền của mình.

Trong cả hai trường hợp, hệ thống có một địa điểm dự phòng (DR) ở trạng thái sẵn sàng ấm (warm standby), đặt ở một trung tâm dữ liệu thứ hai hoặc một vùng đám mây thứ hai, đủ để đạt mục tiêu RPO và RTO nêu ở mục 3.3.2. Các môi trường DEV và TEST có thể đặt tại hạ tầng của nhà thầu trong giai đoạn W0 đến W2 với điều kiện không chứa dữ liệu thật; môi trường STAGING phải đặt cùng điều kiện an toàn với PROD vì được dùng cho diễn tập di trú bằng dữ liệu đã che. Phương án thứ ba H3 (thuê dịch vụ trọn gói cho nhiều tỉnh) được đánh giá ở chương phân tích phương án; nếu được chọn, địa điểm vật lý là trung tâm dữ liệu của bên cung cấp dịch vụ và phải thỏa cùng các điều kiện nêu trên.

Địa điểm thực hiện công việc phát triển phần mềm là trụ sở của nhà thầu. Các công việc khảo sát, cài đặt, di trú, kiểm thử chấp nhận và đào tạo được thực hiện tại tỉnh thí điểm. Tỉnh thứ hai, nơi được khởi tạo tenant ở wave W5, là **[ĐIỀN: tên tỉnh thứ hai]**.

### 3.6. Phạm vi đầu tư

#### 3.6.1. Phạm vi trong dự án

Phạm vi của dự án gồm năm nhóm hạng mục. Nhóm thứ nhất là phần mềm nền tảng gồm 20 phân hệ ở mục 3.3.1, được đóng gói thành sản phẩm có phiên bản phát hành v1.0 tại cổng G5, kèm mã nguồn và bản quyền sử dụng không giới hạn số tỉnh cho bên được chuyển giao theo điều khoản hợp đồng. Nhóm thứ hai là triển khai tại tỉnh thí điểm, gồm cài đặt các môi trường, cấu hình an toàn thông tin, lập hồ sơ đề xuất cấp độ 3, chạy song song với hệ cũ và cắt chuyển theo nhóm dịch vụ. Nhóm thứ ba là di trú, gồm công cụ và thực hiện di trú cấu hình, luồng tích hợp, danh mục, giao dịch thanh toán lịch sử và thông tin kết nối từ hệ cũ, kèm việc cấp lại toàn bộ khóa và mật khẩu. Nhóm thứ tư là bộ tài liệu theo vòng đời phát triển phần mềm, gồm tài liệu yêu cầu, thiết kế, kiểm thử, hướng dẫn sử dụng, hướng dẫn vận hành và hướng dẫn cài đặt. Nhóm thứ năm là đào tạo, chuyển giao công nghệ cho đội vận hành tỉnh và khởi tạo tenant cho tỉnh thứ hai.

#### 3.6.2. Phạm vi ngoài dự án

Các nội dung sau không thuộc dự án. Việc xác định rõ phạm vi ngoài dự án giúp hội đồng đánh giá tổng mức đầu tư đúng với những gì được giao, và giúp chủ đầu tư biết các nội dung nào phải được bố trí bằng dự án khác.

| Nội dung ngoài phạm vi | Lý do | Cách xử lý |
|---|---|---|
| Kho dữ liệu phân tích dạng lakehouse, kho dữ liệu chuyên đề | Thuộc giai đoạn sau theo định hướng của chủ đầu tư; tách để giới hạn rủi ro và quy mô dự án | Kiến trúc chừa điểm mở rộng qua sự kiện thay đổi dữ liệu trên PH-10 |
| Xây dựng lại các HTTT nghiệp vụ của sở, ngành | Datahub chỉ kết nối, không thay thế hệ nghiệp vụ | Bộ điều hợp PH-05 cho các hệ chưa có API chuẩn |
| Cổng dịch vụ công và hệ thống giải quyết thủ tục hành chính | Là hệ thống riêng | Datahub cung cấp kết nối và thanh toán cho hệ này |
| Hạ tầng trung tâm dữ liệu (nhà trạm, điện, làm mát, tủ rack dùng chung) và mạng truyền số liệu chuyên dùng | Thuộc hạ tầng sẵn có của tỉnh | Datahub chỉ dùng chỗ đặt và kết nối; yêu cầu tối thiểu ở Chương 6 mục 6.8 và D03-09 |
| Chỉnh sửa phía các HTTT của sở để chuyển sang kết nối qua Datahub | Thuộc trách nhiệm của chủ quản từng HTTT | Datahub cung cấp đặc tả, môi trường thử và giữ tương thích với giao diện cũ trong thời gian chuyển đổi |
| Ba chức năng hệ cũ được loại bỏ (LGC-TOOL-022, LGC-TOOL-027, LGC-IAM-007) | Rủi ro an toàn thông tin, theo D00-03 §5.1; chủ đầu tư đã chấp thuận | Ghi vào biên bản nghiệm thu |
| Triển khai cho tỉnh thứ ba trở đi | Thuộc dự án hoặc hợp đồng dịch vụ riêng | Sản phẩm v1.0 và quy trình khởi tạo tenant sẵn sàng để dùng lại |

: Nội dung ngoài phạm vi dự án, lý do và cách xử lý

Nội dung "chỉnh sửa phía các HTTT của sở" cần được chủ đầu tư lưu ý đặc biệt. Nếu các sở không bố trí kinh phí và nhà thầu để chuyển kết nối, chỉ số KPI-01 và KPI-02 khó đạt dù nền tảng đã sẵn sàng. Báo cáo đề xuất UBND tỉnh giao nhiệm vụ này cho các sở bằng một văn bản chỉ đạo song song với quyết định đầu tư; rủi ro tương ứng được theo dõi trong sổ rủi ro tại D01-02.

### 3.7. Câu hỏi mở

> **Câu hỏi mở Q-D0101-31:** Tên tỉnh thí điểm và tỉnh thứ hai được khởi tạo tenant ở wave W5 là gì? Tỉnh thứ hai đã có văn bản đồng thuận tham gia hay chưa?

> **Câu hỏi mở Q-D0101-32:** Tỉnh thí điểm có số liệu nào về số HTTT có trao đổi dữ liệu, số kết nối điểm tới điểm, số danh mục dùng chung đang quản lý và lượng giao dịch hằng ngày để xác nhận giả định cỡ M và đo giá trị nền của KPI-01, KPI-02, KPI-10?

> **Câu hỏi mở Q-D0101-33:** Chủ đầu tư ưu tiên đặt hệ thống sản xuất tại trung tâm dữ liệu tỉnh (H1) hay trên nền tảng điện toán đám mây Chính phủ (H2), và đã có địa điểm cho site dự phòng hay chưa?

> **Câu hỏi mở Q-D0101-34:** Điều khoản về quyền sở hữu mã nguồn và quyền triển khai sản phẩm cho tỉnh khác sẽ được quy định thế nào trong hợp đồng, để bảo đảm mục tiêu BO-06 và khả năng nhân rộng?

> **Câu hỏi mở Q-D0101-35:** UBND tỉnh có ban hành văn bản giao các sở, ngành bố trí nguồn lực chỉnh sửa HTTT của mình để chuyển kết nối sang Datahub trong khoảng T0+10 đến T0+18 tháng hay không?


## 4. Phân tích, lựa chọn phương án đầu tư

> **Tóm tắt cho hội đồng thẩm định.** Báo cáo so sánh ba phương án đầu tư: nâng cấp hệ LGSP cũ (PA1), mua hoặc thuê nền tảng thương mại có sẵn rồi tùy biến (PA2, xét hai biến thể là sản phẩm LGSP trong nước và nền tảng tích hợp thương mại quốc tế), và xây mới Datahub trên nền mã nguồn mở theo mô hình sản phẩm đa tenant (PA3). Trên mười tiêu chí có trọng số, PA3 đạt 85,0/100 điểm, PA2 bản trong nước đạt 61,4, PA2 bản quốc tế đạt 46,0 và PA1 đạt 44,2; thứ hạng này giữ nguyên trong hai kịch bản trọng số thay thế ưu tiên tốc độ và ưu tiên chi phí. Báo cáo đề xuất chọn **PA3**, chấp nhận nhược điểm là thời gian đưa vào sử dụng dài hơn PA2 và rủi ro xây dựng cao hơn, đổi lại quyền làm chủ mã nguồn, khả năng nhân rộng cho nhiều tỉnh và không bị khóa nhà cung cấp. Với hạ tầng, báo cáo khuyến nghị đặt môi trường vận hành chính thức tại trung tâm dữ liệu tỉnh (H1), thuê cloud chính phủ (H2) cho môi trường phát triển, kiểm thử và làm phương án thay thế cho site dự phòng, còn dịch vụ trọn gói (H3) là hướng đi cho các tỉnh nhân rộng sau. Mô hình tenant khớp với D03-10 (mặc định dùng chung có RLS, tỉnh tự vận hành dùng cụm riêng), và chiến lược di trú là thay thế dần (strangler) thay vì chuyển đổi một lần.

### 4.1. Phương pháp phân tích

Chương này trả lời câu hỏi mà người quyết định đầu tư phải trả lời trước mọi câu hỏi kỹ thuật khác: với hiện trạng đã nêu ở Chương 2 và mục tiêu đã nêu ở Chương 3, cách nào đạt mục tiêu với tổng chi phí và rủi ro chấp nhận được. Nghị định 224/2026/NĐ-CP quy định chi tiết Luật Chuyển đổi số (văn bản thay thế Nghị định 45/2026/NĐ-CP từ 01/7/2026) yêu cầu báo cáo nghiên cứu khả thi dự án đầu tư hệ thống chuyển đổi số thuyết minh thiết kế cơ sở, trong đó có phân tích, lựa chọn phương án công nghệ (điểm a khoản 2 Điều 46); chương căn cứ pháp lý (Chương 1) trình bày đầy đủ căn cứ, chương này áp dụng yêu cầu đó vào bài toán Datahub. Chương 4 là phần lựa chọn phương án, còn Chương 5 và Chương 6 cùng nhau tạo thành thiết kế cơ sở.

Việc phân tích được chia thành bốn quyết định độc lập nhưng có thứ tự. Quyết định thứ nhất là phương án đầu tư phần mềm (PA1, PA2 hay PA3), vì nó quyết định gần như mọi thứ còn lại. Quyết định thứ hai là phương án hạ tầng (H1, H2, H3), được đánh giá riêng và áp cho phương án phần mềm đã chọn. Quyết định thứ ba là mô hình tenant, tức là cách nhiều tỉnh cùng dùng một sản phẩm. Quyết định thứ tư là chiến lược chuyển đổi khỏi hệ cũ. Tách bốn quyết định như vậy giúp hội đồng thẩm định thấy rằng, ví dụ, việc chọn xây mới không bắt buộc tỉnh phải mua máy chủ, và việc chọn hạ tầng cloud không làm thay đổi kết luận về phương án phần mềm.

Phương pháp đánh giá là phân tích đa tiêu chí có trọng số (weighted multi-criteria analysis). Mỗi phương án được chấm điểm từ 1 (kém nhất) đến 5 (tốt nhất) trên từng tiêu chí, điểm được nhân với trọng số và quy về thang 100. Điểm số không phải là phép đo khách quan tuyệt đối, mà là cách làm minh bạch lập luận: mỗi điểm đều có câu giải thích ở mục 4.4, và hội đồng có thể đổi trọng số để kiểm tra kết luận có đứng vững hay không. Mục 4.5 làm sẵn phép kiểm tra độ nhạy đó với hai bộ trọng số thay thế.

Về chi phí, chương này chỉ xếp hạng định tính chi phí vòng đời, vì tổng mức đầu tư và chi phí sở hữu năm năm (TCO) được tính ở Chương 8 trên cùng bộ giả định nền. Lý do tách như vậy là để tránh hai bộ số tiền song song trong cùng một báo cáo; Chương 8 dùng bảng cấu hình hạ tầng ở Chương 6 và khối lượng công việc ở D01-02 làm đầu vào.

### 4.2. Mô tả các phương án đầu tư

#### 4.2.1. PA1: Nâng cấp, mở rộng hệ LGSP cũ

PA1 giữ nguyên kiến trúc năm khối của hệ cũ (Bus trên Apache Camel, Hub trên Apache Pulsar, quản lý API kiểu Gravitee, danh mục dùng chung Aita và Payment trung gian PayGov), nâng phiên bản các thành phần nền đã hết vòng đời và bổ sung những chức năng còn thiếu như dữ liệu chủ, chất lượng dữ liệu, bảo vệ dữ liệu cá nhân, đối soát thanh toán và kết nối NDXP theo đặc tả mới. Về hình thức, đây là phương án có vẻ ít tốn kém nhất vì tận dụng được tài sản đã đầu tư năm 2021.

Thực chất kỹ thuật của PA1 lại khác với vẻ ngoài. Chương 2 (mục 2.2.4 và 2.3.1) đã chỉ ra rằng toàn bộ nền công nghệ của hệ cũ (Java 8, Spring Boot 2, Zuul, Angular 7, CentOS 6, Tomcat 8.5, PostgreSQL 13) đã ra ngoài vòng đời hỗ trợ, và các thành phần phụ thuộc lẫn nhau theo chuỗi. Muốn lên Spring Boot hiện hành thì phải lên Java 17 trở lên; lên Java mới thì phải thay Zuul và nâng Camel qua hai phiên bản chính có thay đổi lớn về cấu trúc gói; giao diện Angular 7 phải nâng qua nhiều phiên bản chính. Khối lượng "nâng cấp" vì vậy tương đương viết lại phần lớn mã nguồn, nhưng vẫn bị ràng buộc bởi mô hình dữ liệu và kiến trúc cũ: không có trường tỉnh trong dữ liệu, ba mô hình định danh HTTT rời nhau, giao diện và xử lý chạy chung một tiến trình, agent gắn cứng địa chỉ máy chủ (ĐN-02, ĐN-13).

PA1 còn phụ thuộc một điều kiện chưa được xác nhận: tỉnh có quyền sở hữu và có đủ mã nguồn của hệ cũ hay không, bao gồm thư viện mã hóa riêng của nhà cung cấp mà Chương 2 đã nêu (ĐN-14). Nếu không có mã nguồn đầy đủ, PA1 chỉ có thể thực hiện bởi chính nhà cung cấp cũ, tức là chuyển thành một hợp đồng chỉ định thầu trên thực tế. Điểm này được ghi thành câu hỏi mở Q-D0101-41.

**Ưu điểm.** Người dùng đã quen giao diện và quy trình; một phần cấu hình luồng, danh mục và khai báo HTTT có thể giữ lại; nếu nhà cung cấp cũ thực hiện thì thời gian khởi động ngắn vì họ đã hiểu hệ thống.

**Nhược điểm.** Chi phí nâng cấp gần bằng xây mới nhưng kết quả vẫn mang các giới hạn kiến trúc cũ; không giải quyết được yêu cầu nhiều tỉnh trên một sản phẩm; tiếp tục phụ thuộc nhà cung cấp cũ; rủi ro an toàn thông tin cao trong suốt thời gian nâng cấp vì hệ đang chạy vẫn ở nền hết hỗ trợ; khó chứng minh với cơ quan thẩm định cấp độ an toàn thông tin rằng kiến trúc đáp ứng cấp độ 3 khi không có cách ly control plane và data plane.

#### 4.2.2. PA2: Mua hoặc thuê nền tảng thương mại và tùy biến

PA2 mua bản quyền hoặc thuê dịch vụ một nền tảng tích hợp đã có trên thị trường, sau đó tùy biến và bổ sung phần còn thiếu. Báo cáo xét hai biến thể vì chúng khác nhau đáng kể về rủi ro và chi phí. Mô tả dưới đây là mô tả loại sản phẩm, không đánh giá một nhãn hiệu cụ thể nào; khi lập hồ sơ mời thầu (nếu chọn PA2), việc so sánh sản phẩm cụ thể phải thực hiện theo quy trình lựa chọn nhà thầu.

**PA2a: Sản phẩm LGSP của nhà cung cấp trong nước.** Thị trường trong nước đã có một số sản phẩm nền tảng tích hợp, chia sẻ dữ liệu cấp bộ, cấp tỉnh được xây dựng theo yêu cầu chức năng, kỹ thuật của Công văn 631/THH-THHT (CMP-LAW-09) và đã kết nối với NDXP ở nhiều địa phương. Ưu điểm lớn nhất của loại sản phẩm này là đã chạy thực tế, quen thuộc với quy trình hành chính Việt Nam, đáp ứng tốt yêu cầu kết nối quốc gia và có đội hỗ trợ trong nước. Hạn chế thường gặp là sản phẩm được thiết kế cho một bộ, một tỉnh (không phải đa tenant), lớp dữ liệu dùng chung chỉ có danh mục mà chưa có dữ liệu chủ, chất lượng dữ liệu và bảo vệ dữ liệu cá nhân ở mức Luật Dữ liệu yêu cầu, và mã nguồn thuộc nhà cung cấp nên tỉnh chỉ có quyền sử dụng. Về hình thức, nhiều sản phẩm loại này được cung cấp dưới dạng thuê dịch vụ, khi đó chi phí ban đầu thấp nhưng tỉnh gắn với nhà cung cấp trong suốt thời gian thuê.

**PA2b: Nền tảng tích hợp thương mại quốc tế.** Đây là nhóm sản phẩm tích hợp doanh nghiệp (iPaaS, API management, event streaming thương mại) của các hãng phần mềm quốc tế. Ưu điểm là bộ chức năng tích hợp, quản lý API và giám sát rất đầy đủ, có hệ sinh thái bộ kết nối lớn và độ chín sản phẩm cao. Hạn chế là chi phí bản quyền thường tính theo nhân xử lý, theo số lượt gọi hoặc theo môi trường, tăng tuyến tính khi nhân rộng nhiều tỉnh; phần nghiệp vụ đặc thù Việt Nam (kết nối NDXP, PayGov, VNeID, danh mục dùng chung theo chuẩn quốc gia, quy trình kết nạp HTTT) đều phải tùy biến; nhiều sản phẩm có phiên bản tốt nhất ở dạng dịch vụ đám mây của hãng, đặt dữ liệu ngoài lãnh thổ hoặc ngoài cloud chính phủ, không phù hợp với yêu cầu lưu trữ dữ liệu trong nước (CMP-LAW-16); đội ngũ kỹ sư thành thạo sản phẩm hiếm và đắt.

**Ưu điểm chung của PA2.** Có sản phẩm chạy được sớm; rủi ro xây dựng phần lõi thấp; có đơn vị chịu trách nhiệm sản phẩm.

**Nhược điểm chung của PA2.** Không làm chủ mã nguồn; chi phí bản quyền hoặc thuê định kỳ kéo dài suốt vòng đời; phải tùy biến nhiều cho lớp dữ liệu dùng chung và cho nghiệp vụ Việt Nam, mà phần tùy biến trên sản phẩm đóng thường khó nâng cấp theo phiên bản mới của sản phẩm; khả năng nhân rộng cho nhiều tỉnh phụ thuộc chính sách cấp phép của nhà cung cấp.

#### 4.2.3. PA3 (đề xuất): Xây mới Datahub trên nền mã nguồn mở, sản phẩm đa tenant

PA3 xây mới Datahub gồm 20 phân hệ theo kiến trúc đã thiết kế ở D03-01, trên các thành phần mã nguồn mở có giấy phép phù hợp (Mục 5.3), đóng gói thành một sản phẩm duy nhất triển khai được cho nhiều tỉnh (mỗi tỉnh là một tenant), và chuyển đổi khỏi hệ cũ theo chiến lược thay thế dần. Đây không phải là viết từ đầu mọi thứ: phần nặng nhất về kỹ thuật (cổng API, động cơ tích hợp, hệ thống sự kiện, định danh, quy trình, giám sát) là các dự án mã nguồn mở trưởng thành được nhiều tổ chức lớn dùng trong vận hành thật; phần xây mới là lớp nghiệp vụ, lớp quản trị và lớp kết nối với các nền tảng quốc gia, tức đúng phần mà PA2 cũng phải tùy biến.

PA3 kế thừa tri thức nghiệp vụ của hệ cũ một cách có hệ thống: 183 chức năng của hệ cũ đã được kiểm kê thành các mục `LGC` trong D00-03, mỗi mục có kết luận giữ nguyên, nâng cấp, thay thế hay loại bỏ, và tiêu chí bàn giao là 100% mục có kết luận. Vì vậy người dùng không mất chức năng đang dùng, chỉ được cung cấp lại trên nền mới.

**Ưu điểm.** Đáp ứng đầy đủ 20 phân hệ, gồm lớp dữ liệu dùng chung mà hệ cũ và phần lớn sản phẩm thương mại không có; tỉnh (hoặc cơ quan được giao làm chủ sản phẩm) làm chủ mã nguồn; không có chi phí bản quyền phần mềm nền; một bản mã nguồn cho mọi tỉnh nên chi phí phát triển được phân bổ khi nhân rộng; kiến trúc thiết kế từ đầu cho an toàn thông tin cấp độ 3 và sẵn sàng nâng cấp độ 4; chạy được cả trên hạ tầng tại chỗ và cloud chính phủ vì chỉ dùng chuẩn mở.

**Nhược điểm.** Thời gian đến khi đưa vào vận hành chính thức dài hơn PA2 (MVP nghiệm thu ở T0+10 tháng, vận hành chính thức MVP ở T0+13 tháng theo bộ giả định nền); rủi ro xây dựng cao hơn vì phải phát triển nhiều; đòi hỏi đội phát triển có năng lực về Kubernetes, Kafka, Camel và kiến trúc đa tenant; đội vận hành của trung tâm dữ liệu tỉnh phải được đào tạo công nghệ mới (rủi ro RSK-A01 tại D03-01).

### 4.3. Tiêu chí và trọng số đánh giá

Mười tiêu chí dưới đây được chọn từ ba nguồn: mục tiêu nghiệp vụ BO-01 đến BO-09 tại D02-01, các điểm nghẽn ĐN-01 đến ĐN-14 tại Chương 2, và các yêu cầu đối với thiết kế cơ sở tại khoản 1 Điều 46 Nghị định 224/2026/NĐ-CP (tuân thủ khung kiến trúc, tiêu chuẩn, quy định kết nối và chia sẻ dữ liệu). Trọng số phản ánh mức độ mà tiêu chí quyết định sự thành công lâu dài của nền tảng, không chỉ của dự án 18 tháng.

| Mã | Tiêu chí | Trọng số | Câu hỏi đánh giá | Nguồn |
|---|---|---|---|---|
| TC-1 | Đáp ứng chức năng | 15 | Phương án có cung cấp đủ 20 phân hệ, kể cả lớp dữ liệu dùng chung và thanh toán có đối soát? | D02-01, ĐN-09 đến ĐN-12 |
| TC-2 | Tuân thủ kiến trúc và pháp lý | 12 | Có phù hợp Khung Kiến trúc CPĐT 3.0, Luật Dữ liệu, yêu cầu LGSP và kết nối NDXP? | CMP-LAW-01, 03, 09, 10 |
| TC-3 | An toàn thông tin | 12 | Có đạt cấp độ 3 và nâng được lên cấp độ 4 mà không phải thay kiến trúc? | CMP-LAW-06 đến 08, BO-04 |
| TC-4 | Chi phí vòng đời (định tính) | 12 | Tổng chi phí 5 năm, gồm bản quyền, phát triển, hạ tầng, vận hành, khi tính cả nhân rộng | Chương 8 |
| TC-5 | Rủi ro thực hiện | 10 | Xác suất trễ hạn, vượt chi phí, không đạt chất lượng | D01-02 sổ rủi ro |
| TC-6 | Làm chủ mã nguồn, tự chủ công nghệ | 10 | Tỉnh có quyền và năng lực sửa, mở rộng, chuyển giao sản phẩm? | ĐN-14 |
| TC-7 | Nhân rộng nhiều tỉnh | 10 | Có triển khai cho tỉnh khác với chi phí biên thấp? | BO-06, KPI-12 |
| TC-8 | Thời gian đưa vào sử dụng | 7 | Bao lâu đến khi dịch vụ thật chạy trên nền mới? | Bộ giả định nền §3 |
| TC-9 | Khóa nhà cung cấp | 7 | Chi phí và độ khó khi đổi nhà cung cấp phát triển, vận hành, hạ tầng | NT-09 tại D03-01 |
| TC-10 | Nhân lực | 5 | Có đủ nhân lực trong nước để phát triển và vận hành? | RSK-A01 |
| | **Tổng** | **100** | | |

: Tiêu chí và trọng số đánh giá phương án đầu tư

Ba tiêu chí đầu chiếm 39% trọng số vì chúng là điều kiện cần: một phương án không đáp ứng chức năng, không tuân thủ hoặc không đạt cấp độ an toàn thông tin thì dù rẻ cũng không dùng được. Chi phí vòng đời nhận 12% chứ không cao hơn, vì Chương 8 sẽ cho thấy chênh lệch chi phí giữa các phương án nằm chủ yếu ở bản quyền định kỳ và ở chi phí nhân rộng, tức là đã được phản ánh một phần qua TC-6, TC-7 và TC-9. Thời gian đưa vào sử dụng có trọng số vừa phải (7%) vì hệ cũ vẫn chạy song song trong suốt quá trình chuyển đổi, nên chậm hơn vài tháng không làm gián đoạn dịch vụ công.

### 4.4. Bảng điểm và giải thích

Bảng dưới đây trình bày điểm từng phương án trên từng tiêu chí và điểm tổng có trọng số quy về thang 100 (điểm tổng = tổng của điểm nhân trọng số, chia 5). Phần giải thích ngay sau bảng nêu lý do cho các điểm có chênh lệch lớn giữa các phương án.

| Tiêu chí | Trọng số | PA1 | PA2a trong nước | PA2b quốc tế | PA3 |
|---|---|---|---|---|---|
| TC-1 Đáp ứng chức năng | 15 | 2 | 3 | 4 | 5 |
| TC-2 Tuân thủ kiến trúc, pháp lý | 12 | 2 | 4 | 2 | 5 |
| TC-3 An toàn thông tin | 12 | 2 | 3 | 3 | 4 |
| TC-4 Chi phí vòng đời | 12 | 3 | 3 | 1 | 4 |
| TC-5 Rủi ro thực hiện | 10 | 2 | 4 | 3 | 3 |
| TC-6 Làm chủ mã nguồn | 10 | 2 | 1 | 1 | 5 |
| TC-7 Nhân rộng nhiều tỉnh | 10 | 1 | 3 | 2 | 5 |
| TC-8 Thời gian đưa vào sử dụng | 7 | 4 | 5 | 3 | 2 |
| TC-9 Khóa nhà cung cấp | 7 | 2 | 1 | 1 | 5 |
| TC-10 Nhân lực | 5 | 3 | 4 | 2 | 3 |
| **Điểm tổng (thang 100)** | **100** | **44,2** | **61,4** | **46,0** | **85,0** |

: Điểm của bốn phương án PA1, PA2a, PA2b, PA3 theo từng tiêu chí có trọng số

**TC-1 Đáp ứng chức năng.** PA3 đạt 5 vì phạm vi 20 phân hệ được thiết kế đúng theo yêu cầu (D02-01, D02-02). PA2b đạt 4 vì sản phẩm quốc tế mạnh về tích hợp, quản lý API và giám sát, nhưng thiếu phần nghiệp vụ Việt Nam. PA2a đạt 3 vì sản phẩm trong nước mạnh về kết nối quốc gia nhưng thường thiếu dữ liệu chủ, chất lượng dữ liệu, bảo vệ dữ liệu cá nhân và đa tenant. PA1 đạt 2 vì hệ cũ thiếu toàn bộ lớp dữ liệu dùng chung và đối soát thanh toán (ĐN-09, ĐN-12), phần bổ sung phải xây trên nền kiến trúc cũ.

**TC-2 Tuân thủ kiến trúc và pháp lý.** PA3 đạt 5 vì kiến trúc được ánh xạ trực tiếp vào Khung Kiến trúc CPĐT 3.0 (mục 5.7) và mọi yêu cầu pháp lý có mã truy vết tại D00-03. PA2a đạt 4 vì sản phẩm đã được xây theo Công văn 631 và đã kết nối NDXP, nhưng phần đáp ứng Luật Dữ liệu và Nghị định 165/2025/NĐ-CP (CMP-LAW-01, CMP-LAW-02) còn phụ thuộc lộ trình của nhà cung cấp. PA2b đạt 2 vì phải tùy biến toàn bộ phần tuân thủ quốc gia và có nguy cơ vướng yêu cầu lưu trữ dữ liệu trong nước. PA1 đạt 2 vì kết nối quốc gia đang theo mô hình NGSP cũ, ghi cứng, chưa có NDOP (ĐN-11).

**TC-3 An toàn thông tin.** Không phương án nào đạt 5 vì cấp độ 3 chỉ được xác nhận khi hồ sơ được phê duyệt. PA3 đạt 4 vì kiến trúc có sẵn zero-trust nội bộ, tách control plane và data plane, kho bí mật, nhật ký kiểm toán chỉ-thêm và đã chừa điểm nâng cấp độ 4 (D03-01 §9). PA2a và PA2b đạt 3 vì an toàn của sản phẩm đóng phụ thuộc nhà cung cấp, tỉnh khó tự kiểm chứng mã nguồn và chuỗi cung ứng. PA1 đạt 2 vì nền hết hỗ trợ không có bản vá, bí mật ở dạng rõ và kênh truyền không mã hóa (ĐN-04 đến ĐN-06).

**TC-4 Chi phí vòng đời.** Thứ hạng định tính; số tiền ở Chương 8. PA3 đạt 4: chi phí ban đầu cao nhất trong bốn phương án vì phải phát triển nhiều (khoảng 455 người-tháng theo bộ giả định nền), nhưng không có bản quyền phần mềm nền, và từ tỉnh thứ hai trở đi chi phí biên chỉ gồm hạ tầng và triển khai. PA1 và PA2a đạt 3: PA1 có chi phí nâng cấp gần bằng xây mới nhưng không đem lại khả năng nhân rộng; PA2a có chi phí ban đầu thấp hơn nhưng phí bản quyền hoặc thuê dịch vụ lặp lại mỗi năm và mỗi tỉnh, cộng chi phí tùy biến lớp dữ liệu dùng chung. PA2b đạt 1 vì bản quyền quốc tế tính theo nhân xử lý hoặc lượt gọi, cộng chi phí tùy biến và chi phí chuyên gia, là mức cao nhất trong vòng đời năm năm.

**TC-5 Rủi ro thực hiện.** PA2a đạt 4 vì lõi sản phẩm đã chạy thực tế, rủi ro chủ yếu nằm ở phần tùy biến. PA3 đạt 3: rủi ro xây dựng cao hơn PA2a nhưng được giảm bằng ba biện pháp, gồm phát hành theo đợt với MVP 12 phân hệ, di trú thay thế dần có thể quay lui từng nhóm dịch vụ, và kiến trúc dựa trên các thành phần mã nguồn mở đã trưởng thành thay vì tự viết lõi. PA2b đạt 3 vì sản phẩm chín nhưng khối lượng tùy biến lớn và nhân lực hiếm. PA1 đạt 2 vì phải nâng cấp đồng thời nhiều thành phần phụ thuộc chuỗi trên một hệ đang chạy, và chưa rõ quyền mã nguồn.

**TC-6 Làm chủ mã nguồn.** PA3 đạt 5 vì toàn bộ mã nguồn thuộc chủ đầu tư theo hợp đồng, xây trên thành phần có giấy phép mở. PA1 đạt 2 vì quyền mã nguồn của hệ cũ chưa được xác nhận (Q-D0101-41) và có thư viện độc quyền. PA2a và PA2b đạt 1 vì mã nguồn thuộc nhà cung cấp.

**TC-7 Nhân rộng nhiều tỉnh.** PA3 đạt 5 vì đa tenant từ gốc (NT-02 tại D03-01), mục tiêu khởi tạo một tenant tỉnh mới không quá 1 ngày làm việc (KPI-12) và triển khai một cụm tỉnh độc lập không quá 3 ngày làm việc khi đã có hạ tầng (NFR-00-056). PA2a đạt 3 vì nhân rộng được bằng cách mua hoặc thuê thêm bản cho mỗi tỉnh. PA2b đạt 2 vì nhân rộng kéo theo bản quyền tăng tuyến tính. PA1 đạt 1 vì hệ cũ không có khái niệm tỉnh trong dữ liệu (ĐN-13).

**TC-8 Thời gian đưa vào sử dụng.** PA2a đạt 5 vì có thể đưa lõi vào chạy trong vài tháng. PA1 đạt 4 vì người dùng tiếp tục dùng hệ đang có trong lúc nâng cấp. PA2b đạt 3 vì sản phẩm sẵn có nhưng thời gian tùy biến dài. PA3 đạt 2 vì MVP vận hành chính thức ở T0+13 tháng và toàn bộ 20 phân hệ ở T0+18 tháng.

**TC-9 Khóa nhà cung cấp.** PA3 đạt 5 vì chỉ dùng chuẩn mở (S3, OIDC, OpenAPI, Kafka, Kubernetes) và tài liệu SDLC đầy đủ cho phép đổi nhà thầu phát triển, đổi đơn vị vận hành hoặc đổi hạ tầng. PA1, PA2a, PA2b đều bị khóa ở mức độ khác nhau.

**TC-10 Nhân lực.** PA2a đạt 4 vì nhà cung cấp trong nước có sẵn đội. PA1 và PA3 đạt 3: PA1 cần kỹ sư biết công nghệ cũ ngày càng hiếm; PA3 cần kỹ sư Kubernetes, Kafka, Camel, Spring vốn phổ biến trên thị trường nhưng đội vận hành tỉnh cần đào tạo. PA2b đạt 2 vì chuyên gia sản phẩm quốc tế hiếm và đắt.

Biểu đồ dưới đây tóm tắt logic sàng lọc phía sau bảng điểm: các phương án lần lượt được kiểm tra qua bốn câu hỏi có tính quyết định, và chỉ PA3 vượt qua cả bốn.

```{.mermaid caption="Cây sàng lọc bốn câu hỏi quyết định giữa các phương án đầu tư"}
flowchart TD
    Q1{"Đáp ứng đủ 20 phân hệ<br/>và lớp dữ liệu dùng chung?"}
    Q2{"Làm chủ mã nguồn,<br/>không khóa nhà cung cấp?"}
    Q3{"Nhân rộng nhiều tỉnh<br/>với chi phí biên thấp?"}
    Q4{"Đạt ATTT cấp độ 3,<br/>nâng được cấp độ 4?"}
    PA1["PA1 Nâng cấp hệ cũ<br/>44,2 điểm"]
    PA2A["PA2a LGSP trong nước<br/>61,4 điểm"]
    PA2B["PA2b Nền tảng quốc tế<br/>46,0 điểm"]
    PA3["PA3 Xây mới mã nguồn mở<br/>85,0 điểm - đề xuất"]
    START["Bốn phương án"] --> Q1
    Q1 -->|"Không"| PA1
    Q1 -->|"Có, sau tùy biến"| Q2
    Q2 -->|"Không"| PA2A
    Q2 -->|"Không"| PA2B
    Q2 -->|"Có"| Q3
    Q3 -->|"Có"| Q4
    Q4 -->|"Có"| PA3
```

Sơ đồ đơn giản hóa bảng điểm thành các câu hỏi có hoặc không, nên không thay thế bảng điểm. Ý nghĩa của nó là cho thấy PA2a, phương án mạnh thứ hai, bị loại chủ yếu ở câu hỏi làm chủ mã nguồn và khóa nhà cung cấp, chứ không phải ở chức năng hay rủi ro. Nếu chủ đầu tư coi việc làm chủ mã nguồn là không quan trọng, PA2a trở thành ứng viên đáng cân nhắc; mục 4.5 kiểm tra xem kết luận có đổi khi giảm trọng số các tiêu chí này hay không.

### 4.5. Kiểm tra độ nhạy và kết luận

Để kiểm tra kết luận có phụ thuộc vào cách đặt trọng số hay không, báo cáo tính lại điểm với hai bộ trọng số thay thế. Bộ thứ nhất, "ưu tiên nhanh và ít rủi ro", tăng trọng số thời gian đưa vào sử dụng lên 15, rủi ro lên 15, chi phí lên 15, và giảm làm chủ mã nguồn, nhân rộng xuống 5 mỗi tiêu chí. Bộ thứ hai, "ưu tiên chi phí", đặt chi phí vòng đời ở 25 và giảm tương ứng các tiêu chí khác. Bảng sau cho thấy kết quả.

| Bộ trọng số | PA1 | PA2a | PA2b | PA3 | Khoảng cách PA3 với phương án thứ hai |
|---|---|---|---|---|---|
| Cơ sở (mục 4.3) | 44,2 | 61,4 | 46,0 | 85,0 | 23,6 |
| Ưu tiên nhanh và ít rủi ro | 49,0 | 66,8 | 47,2 | 78,0 | 11,2 |
| Ưu tiên chi phí | 47,2 | 62,6 | 42,6 | 82,8 | 20,2 |

: Độ nhạy của xếp hạng phương án theo các bộ trọng số khác nhau

PA3 giữ vị trí thứ nhất ở cả ba bộ trọng số. Khoảng cách thu hẹp nhất ở bộ "ưu tiên nhanh và ít rủi ro" (11,2 điểm), đúng như dự đoán vì đó là hai tiêu chí PA2a mạnh nhất. Để PA2a vượt PA3, người đánh giá phải đồng thời giảm mạnh trọng số làm chủ mã nguồn, nhân rộng và khóa nhà cung cấp, tức là từ bỏ mục tiêu sản phẩm dùng chung cho nhiều tỉnh (BO-06), một mục tiêu cốt lõi của dự án.

**Kết luận.** Báo cáo đề xuất chọn **PA3: xây mới Datahub trên nền mã nguồn mở theo mô hình sản phẩm đa tenant, di trú theo chiến lược thay thế dần**. Hai nhược điểm của PA3 được xử lý trong thiết kế dự án như sau. Nhược điểm thời gian được giảm bằng cách phát hành MVP 12 phân hệ trước, thay thế ngay các khối Bus, Hub, API Management, danh mục dùng chung và kết nối quốc gia, trong khi hệ cũ vẫn phục vụ phần chưa chuyển. Nhược điểm rủi ro xây dựng được giảm bằng các cổng nghiệm thu G0 đến G5, bằng việc dùng thành phần mã nguồn mở trưởng thành cho mọi phần lõi, và bằng sổ rủi ro tại D01-02 (dẫn chiếu RSK-A01 đến RSK-A05 của D03-01).

### 4.6. Phương án hạ tầng

#### 4.6.1. Ba phương án hạ tầng

Phương án hạ tầng được đánh giá riêng vì PA3 chỉ dùng chuẩn mở (NT-09 tại D03-01) và chạy được trên mọi cụm Kubernetes đạt yêu cầu. Ba phương án là:

- **H1, Kubernetes tại chỗ (on-premises) ở trung tâm dữ liệu tỉnh.** Tỉnh đầu tư máy chủ, lưu trữ, thiết bị mạng đặt tại trung tâm dữ liệu của tỉnh; đơn vị vận hành của tỉnh quản trị từ tầng phần cứng đến tầng Kubernetes, nhà thầu cài đặt Datahub từ tầng Kubernetes trở lên.
- **H2, cloud chính phủ.** Tỉnh thuê máy ảo, lưu trữ khối, lưu trữ đối tượng và (nếu có) dịch vụ Kubernetes quản lý trên một nền tảng điện toán đám mây đáp ứng tiêu chí dành cho cơ quan nhà nước. Datahub chạy trên cụm Kubernetes chuẩn dựng trên các tài nguyên thuê đó.
- **H3, thuê dịch vụ trọn gói.** Một đơn vị cung cấp vận hành nền tảng Datahub dùng chung cho nhiều tỉnh (hồ sơ "nền tảng dùng chung" tại D03-01 §10); tỉnh thuê dịch vụ theo cam kết mức dịch vụ, không quản trị hạ tầng.

#### 4.6.2. So sánh

Bảng dưới đây so sánh ba phương án hạ tầng trên các tiêu chí quan trọng nhất với tỉnh thí điểm. Đánh giá chi phí là định tính; Chương 8 quy đổi bảng cấu hình ở Chương 6 thành số tiền cho cả H1 và H2.

| Tiêu chí | H1 tại chỗ | H2 cloud chính phủ | H3 thuê trọn gói |
|---|---|---|---|
| Kiểm soát dữ liệu, vị trí dữ liệu | Cao nhất: dữ liệu ở TTDL tỉnh | Cao: dữ liệu ở cloud trong nước đạt tiêu chí | Trung bình: dữ liệu ở hạ tầng của đơn vị cung cấp, chung với tỉnh khác (cách ly logic) |
| Hình thức chi | Chủ yếu chi đầu tư (thiết bị), kèm chi thường xuyên (điện, bảo trì, nhân sự) | Chủ yếu chi thường xuyên (thuê theo tháng) | Chi thường xuyên (phí dịch vụ) |
| Thời gian sẵn sàng | Dài: mua sắm thiết bị, lắp đặt, thường vài tháng | Nhanh: vài tuần sau khi ký hợp đồng thuê | Nhanh nhất khi nền tảng dùng chung đã tồn tại; hiện chưa tồn tại |
| Năng lực vận hành tỉnh phải có | Cao: phần cứng, ảo hóa, Kubernetes, CSDL | Trung bình: Kubernetes trở lên | Thấp: chỉ quản trị nghiệp vụ trong tenant |
| Co giãn | Theo bước mua thiết bị | Linh hoạt theo tháng | Theo hợp đồng dịch vụ |
| Dự phòng thảm họa | Cần site thứ hai của tỉnh | Dùng vùng thứ hai của nhà cung cấp cloud | Do đơn vị cung cấp đảm nhiệm |
| Hồ sơ cấp độ ATTT | Tỉnh lập cho toàn bộ hệ thống | Phân định trách nhiệm với nhà cung cấp cloud | Đơn vị cung cấp lập, tỉnh xác nhận phần của mình |
| Phù hợp với tỉnh thí điểm | Phù hợp nếu TTDL tỉnh đủ điều kiện | Phù hợp, đặc biệt cho DR và môi trường phụ | Chưa khả thi trong dự án này vì chưa có nền tảng dùng chung vận hành |

: So sánh ba phương án hạ tầng H1, H2, H3 theo tiêu chí

#### 4.6.3. Khuyến nghị

Báo cáo khuyến nghị một tổ hợp phương án thay vì một phương án thuần, vì mỗi môi trường có yêu cầu khác nhau về vị trí dữ liệu, thời điểm cần có và vòng đời.

1. **Môi trường vận hành chính thức (PROD) và tiền vận hành (STAGING) theo H1**, đặt tại trung tâm dữ liệu tỉnh, nếu trung tâm dữ liệu đáp ứng điều kiện về không gian, nguồn điện, làm mát và an toàn thông tin cấp độ 3 cho phần hạ tầng (Q-D0101-42). Lý do là dữ liệu dùng chung của tỉnh (danh mục, dữ liệu chủ, giao dịch thanh toán, nhật ký khai thác dữ liệu cá nhân) có vị trí lưu trữ rõ ràng thuộc tỉnh, và chi phí thiết bị được khấu hao trong vòng đời năm năm.
2. **Môi trường phát triển (DEV) và kiểm thử (TEST) theo H2**, thuê từ T0 trong suốt thời gian thực hiện và bảo hành. Lý do là hai môi trường này phải có ngay ở wave W0 (T0 đến T0+2), trước khi việc mua sắm thiết bị H1 hoàn tất, và chúng không chứa dữ liệu thật.
3. **Site dự phòng thảm họa (DR) theo H1 tại site thứ hai của tỉnh nếu có; nếu không thì theo H2** ở một vùng cloud chính phủ khác với vị trí PROD. Kịch bản cơ sở cho Chương 8 là DR theo H1; kịch bản thay thế là DR theo H2. Chương 6 cung cấp cấu hình cho cả hai.
4. **H3 là hướng phát triển cho giai đoạn nhân rộng**, khi có cơ quan được giao vận hành nền tảng dùng chung cho các tỉnh quy mô nhỏ. Kiến trúc đa tenant của Datahub đã hỗ trợ sẵn (D03-10, chế độ `SHARED`), nên quyết định này không phải đưa ra ngay trong dự án.

Trường hợp trung tâm dữ liệu tỉnh không đủ điều kiện, toàn bộ PROD, STAGING và DR chuyển sang H2 mà không phải thay đổi phần mềm; Chương 6 có bảng quy đổi sang tài nguyên cloud.

```{.mermaid caption="Cây quyết định chọn phương án hạ tầng H1, H2 hay H3"}
flowchart TD
    A{"TTDL tỉnh đủ điều kiện<br/>không gian, điện, ATTT cấp độ 3?"}
    B{"Tỉnh có site thứ hai<br/>cách xa site chính?"}
    P1["PROD và STAGING theo H1<br/>tại TTDL tỉnh"]
    P2["PROD và STAGING theo H2<br/>cloud chính phủ"]
    D1["DR theo H1<br/>tại site thứ hai"]
    D2["DR theo H2<br/>vùng cloud khác"]
    DV["DEV và TEST theo H2<br/>thuê từ T0"]
    H3["H3 nền tảng dùng chung<br/>cho giai đoạn nhân rộng"]
    A -->|"Có"| P1
    A -->|"Không"| P2
    P1 --> B
    B -->|"Có"| D1
    B -->|"Không"| D2
    P2 --> D2
    P1 --> DV
    P2 --> DV
    D1 -.->|"Sau dự án"| H3
    D2 -.->|"Sau dự án"| H3
```

Sơ đồ cho thấy hai câu hỏi về điều kiện của tỉnh quyết định phương án hạ tầng, còn DEV và TEST luôn thuê cloud trong mọi nhánh. Đường nét đứt tới H3 thể hiện đây là bước sau dự án, không phải nhánh quyết định hiện tại.

### 4.7. Mô hình tenant

Datahub là sản phẩm phục vụ nhiều tỉnh, và mỗi tỉnh là một tenant (D00-01, D03-10). Câu hỏi đặt ra là các tỉnh dùng chung tài nguyên đến mức nào. Ba mô hình điển hình được xét:

| Mô hình | Mô tả | Ưu điểm | Nhược điểm |
|---|---|---|---|
| Dùng chung, cách ly bằng RLS | Mọi tenant dùng chung cụm CSDL, Kafka, kho đối tượng; mỗi dòng dữ liệu có `tenant_id`, PostgreSQL Row-Level Security lọc ở tầng CSDL | Chi phí thấp nhất; một lần nâng cấp cho mọi tỉnh; RLS chặn rò rỉ kể cả khi mã ứng dụng có lỗi | Cần kỷ luật đặt biến phiên; ảnh hưởng "hàng xóm ồn ào" phải chặn bằng hạn mức |
| Schema hoặc CSDL riêng | Mỗi tenant một schema hoặc một cụm CSDL riêng; các tầng khác dùng chung | Cách ly dữ liệu mạnh hơn | Số đối tượng bùng nổ (20 phân hệ nhân 34 tỉnh); vận hành nhiều cụm CSDL |
| Cụm riêng | Mỗi tỉnh một cụm Kubernetes đầy đủ | Cách ly vật lý hoàn toàn; tỉnh tự vận hành | Chi phí hạ tầng và vận hành cao nhất cho mỗi tỉnh |

: So sánh ba mô hình tenant: mô tả, ưu điểm và nhược điểm

D03-10 và ADR-003 đã chốt mô hình kết hợp, và chương này khuyến nghị giữ nguyên quyết định đó. Mã nguồn luôn chạy ở chế độ đa tenant với RLS bắt buộc trên mọi bảng nghiệp vụ, còn hồ sơ triển khai chọn một trong ba chế độ cách ly của D03-10: `SHARED` (mặc định trên nền tảng dùng chung), `DEDICATED_DB` (cụm PostgreSQL riêng cho tỉnh có yêu cầu riêng hoặc chuẩn bị lên cấp độ 4) và `DEDICATED_CLUSTER` (cụm Kubernetes riêng cho tỉnh tự vận hành tại chỗ). Điểm quan trọng là cả ba chế độ dùng chung một bộ mã, nên tỉnh có thể chuyển chế độ khi điều kiện thay đổi mà không phải chờ một phiên bản phần mềm khác.

Áp vào phương án hạ tầng đã khuyến nghị, **tỉnh thí điểm chạy ở chế độ `DEDICATED_CLUSTER`**: cụm PROD tại trung tâm dữ liệu tỉnh chứa tenant của tỉnh thí điểm (và tenant `PLATFORM` để quản trị). RLS vẫn bật đầy đủ như ở nền tảng dùng chung; việc này có hai tác dụng. Thứ nhất, nó là lớp phòng thủ chiều sâu, vì lỗi cấu hình ở tầng ứng dụng vẫn không làm lộ dữ liệu. Thứ hai, nó bảo đảm cụm của tỉnh có thể tiếp nhận thêm tenant sau sắp xếp đơn vị hành chính (sáp nhập theo D03-10 §5.4) hoặc chuyển sang nền tảng dùng chung mà không cần di trú dữ liệu.

Tỉnh thứ hai (nhân rộng ở W5) có thể được triển khai theo một trong hai cách: một cụm riêng theo cỡ quy mô của tỉnh đó (Chương 6 có cấu hình S, M, L), hoặc một tenant `SHARED` trên cụm của tỉnh thí điểm nếu hai tỉnh thỏa thuận dùng chung và hạ tầng được mở rộng tương ứng. Lựa chọn này phụ thuộc thỏa thuận giữa hai tỉnh và được ghi thành câu hỏi mở Q-D0101-43.

```{.mermaid caption="Ba chế độ đa tenant trên cùng một bộ mã nguồn"}
flowchart TB
    CODE["Một bộ mã nguồn Datahub<br/>RLS bắt buộc mọi bảng"]
    SH["SHARED<br/>nền tảng dùng chung<br/>nhiều tỉnh cỡ nhỏ"]
    DB["DEDICATED_DB<br/>cụm PostgreSQL riêng<br/>tầng khác dùng chung"]
    CL["DEDICATED_CLUSTER<br/>cụm Kubernetes riêng<br/>tỉnh tự vận hành"]
    PILOT["Tỉnh thí điểm<br/>hạ tầng H1"]
    T2["Tỉnh thứ hai<br/>cụm riêng hoặc tenant dùng chung"]
    CODE --> SH
    CODE --> DB
    CODE --> CL
    CL --> PILOT
    CL -.-> T2
    SH -.-> T2
```

Sơ đồ nhấn mạnh rằng ba chế độ là ba hồ sơ triển khai của cùng một sản phẩm. Tỉnh thí điểm đi theo nhánh cụm riêng; tỉnh thứ hai có hai lựa chọn được thể hiện bằng nét đứt vì còn chờ quyết định.

### 4.8. Chiến lược chuyển đổi khỏi hệ cũ

#### 4.8.1. Hai chiến lược

Có hai cách chuyển đổi điển hình từ một nền tảng tích hợp đang vận hành sang nền tảng mới.

**Chuyển đổi một lần (big-bang).** Xây xong toàn bộ nền tảng mới, chuẩn bị dữ liệu và cấu hình, chọn một thời điểm (thường cuối tuần) dừng hệ cũ, chuyển dữ liệu, đổi toàn bộ địa chỉ kết nối của các HTTT sang hệ mới và khởi động. Ưu điểm là chỉ vận hành một hệ thống sau thời điểm chuyển, không phải duy trì cơ chế song song. Nhược điểm là toàn bộ rủi ro dồn vào một thời điểm: mọi HTTT phải đổi kết nối cùng lúc, mọi luồng tích hợp phải chạy đúng ngay lần đầu, và nếu có sự cố lớn thì quay lui toàn bộ rất khó vì dữ liệu phát sinh sau thời điểm chuyển đã nằm ở hệ mới.

**Thay thế dần (strangler).** Đặt một lớp định tuyến trước hệ cũ, rồi chuyển lần lượt từng nhóm dịch vụ sang nền tảng mới. Tại mỗi thời điểm, lớp định tuyến quyết định một lượt gọi đi vào hệ cũ hay hệ mới. Mỗi nhóm dịch vụ trải qua các bước chạy song song, đối soát kết quả, cắt chuyển và giám sát; nếu có sự cố, chỉ nhóm đó quay lui về hệ cũ. Khi nhóm cuối cùng đã chuyển và chạy ổn định, hệ cũ được tắt. Nhược điểm là phải vận hành hai hệ thống trong một thời gian và phải xây công cụ định tuyến, đối soát.

#### 4.8.2. Lựa chọn

Báo cáo chọn **thay thế dần** vì bốn lý do gắn với đặc điểm của LGSP. Thứ nhất, LGSP là trục trung gian của nhiều dịch vụ công trực tuyến; một sự cố ở thời điểm chuyển đổi một lần sẽ làm gián đoạn đồng thời mọi dịch vụ đi qua trục, trái với BO-02 (không gián đoạn dịch vụ công vì nền tảng tích hợp). Thứ hai, tỉnh thí điểm có tới hàng trăm HTTT kết nối (cỡ M: tới 200), thuộc nhiều chủ quản khác nhau; không thể yêu cầu tất cả đổi kết nối trong cùng một cuối tuần. Thứ ba, phạm vi phát hành theo đợt (MVP, đợt 2, đợt 3) vốn đã không cho phép chuyển một lần, vì khối Payment chỉ được thay khi PH-19 sẵn sàng ở đợt 2. Thứ tư, hệ cũ không có tài liệu đủ để dựng lại (Chương 2, ĐN-14), nên hiểu biết về hành vi thực tế của từng luồng phải được kiểm chứng bằng chạy song song và đối soát chứ không chỉ bằng đọc tài liệu.

Chi phí của lựa chọn này là thời gian vận hành song song (tối đa đến G5 theo bộ giả định nền) và khối lượng xây dựng lớp định tuyến, công cụ đối soát. Cả hai đã được tính trong kế hoạch: lớp định tuyến chính là cổng API APISIX (PH-03) sẵn có trong MVP, còn công cụ di trú và đối soát thuộc PH-18. Cơ chế kỹ thuật chi tiết của chiến lược thay thế dần được trình bày ở mục 5.9.

```{.mermaid caption="So sánh chuyển đổi một lần với thay thế dần khỏi hệ cũ"}
flowchart TB
    subgraph BB["Chuyển đổi một lần"]
        B1["Xây xong toàn bộ"] --> B2["Dừng hệ cũ<br/>một thời điểm"] --> B3["Mọi HTTT đổi kết nối"] --> B4{"Sự cố?"}
        B4 -->|"Có"| B5["Quay lui toàn bộ<br/>rủi ro mất dữ liệu"]
        B4 -->|"Không"| B6["Vận hành hệ mới"]
    end
    subgraph ST["Thay thế dần - được chọn"]
        S1["Lớp định tuyến<br/>đặt trước hệ cũ"] --> S2["Chuyển một nhóm dịch vụ"] --> S3["Song song và đối soát"] --> S4{"Đạt tiêu chí?"}
        S4 -->|"Không"| S5["Quay lui riêng nhóm đó"]
        S5 --> S2
        S4 -->|"Có"| S6["Cắt chuyển nhóm"]
        S6 -->|"Còn nhóm khác"| S2
        S6 -->|"Hết nhóm"| S7["Tắt hệ cũ trước G5"]
    end
```

Sơ đồ đặt hai chiến lược cạnh nhau để làm rõ khác biệt then chốt: ở chuyển đổi một lần, nhánh sự cố dẫn tới quay lui toàn bộ; ở thay thế dần, nhánh sự cố chỉ quay lui một nhóm dịch vụ rồi thử lại, các nhóm đã chuyển thành công không bị ảnh hưởng.

### Câu hỏi mở

Các câu hỏi dưới đây liên quan đến quyền sở hữu mã nguồn hệ cũ, điều kiện của trung tâm dữ liệu tỉnh, chế độ tenant của tỉnh thứ hai và khảo sát thị trường; câu trả lời có thể làm thay đổi kết quả so sánh phương án ở chương này.

- **Q-D0101-41.** Tỉnh có quyền sở hữu và đang lưu giữ đầy đủ mã nguồn hệ LGSP cũ (kể cả thư viện mã hóa riêng của nhà cung cấp) hay không? Câu trả lời ảnh hưởng đến tính khả thi của PA1 và đến việc dịch ngược hành vi luồng cũ khi di trú.
- **Q-D0101-42.** Trung tâm dữ liệu tỉnh hiện có đáp ứng điều kiện đặt hệ thống cấp độ 3 (không gian tủ rack, công suất điện dự phòng, làm mát, kiểm soát ra vào) cho cấu hình ở Chương 6 hay không, và tỉnh có site thứ hai đủ điều kiện làm site DR hay không?
- **Q-D0101-43.** Tỉnh thứ hai được nhân rộng ở W5 sẽ có cụm riêng hay là tenant dùng chung trên cụm của tỉnh thí điểm? Nếu dùng chung thì cần thỏa thuận giữa hai tỉnh về vận hành và chi phí.
- **Q-D0101-44.** Chủ đầu tư có muốn bổ sung một khảo sát thị trường chính thức về các sản phẩm LGSP trong nước (PA2a) để có số liệu giá tham chiếu cho Chương 8 hay không?


## 5. Giải pháp công nghệ và thiết kế cơ sở

> **Tóm tắt cho hội đồng thẩm định.** Chương 5 cùng Chương 6 tạo thành thiết kế cơ sở của dự án theo Điều 46 Nghị định 224/2026/NĐ-CP; bảng ở mục 5.1 chỉ rõ từng nội dung của khoản 2 Điều 46 được trình bày ở đâu. Datahub gồm 20 phân hệ, đóng gói thành sáu đơn vị triển khai Spring Boot, một đơn vị triển khai tích hợp Camel Quarkus và các thành phần mã nguồn mở bên thứ ba, chia thành control plane (quản trị) và data plane (đường đi của dữ liệu) để sự cố quản trị không làm gián đoạn trao đổi dữ liệu. Toàn bộ công nghệ nền là mã nguồn mở có giấy phép phù hợp, không phát sinh chi phí bản quyền, chạy được cả tại trung tâm dữ liệu tỉnh và trên cloud chính phủ. Chỉ tiêu chính cho tỉnh cỡ M là 1.000 lượt gọi mỗi giây ở đỉnh, độ trễ tăng thêm tại cổng API p95 không quá 50 ms, sẵn sàng data plane 99,9% mỗi tháng, RPO 15 phút; nền tảng kết nối NDXP, NDOP, VNeID, PayGov và hỗ trợ IPv6 song song IPv4. Chuyển đổi khỏi hệ cũ theo chiến lược thay thế dần qua cổng API, từng nhóm dịch vụ chạy song song, đối soát rồi mới cắt chuyển.

### 5.1. Phạm vi thiết kế cơ sở và cách đọc

Khoản 2 Điều 46 Nghị định 224/2026/NĐ-CP liệt kê nội dung bắt buộc của thiết kế cơ sở. Báo cáo này không lập một tập thiết kế cơ sở tách rời mà trình bày các nội dung đó trong Chương 5 (giải pháp công nghệ, phần mềm) và Chương 6 (giải pháp hạ tầng), riêng yêu cầu an ninh mạng chi tiết nằm ở Chương 7. Cách làm này giúp hội đồng thẩm định đọc thiết kế cơ sở liền mạch với phân tích phương án ở Chương 4 và tổng mức đầu tư ở Chương 8. Bảng dưới đây là chỉ mục để hội đồng kiểm tra độ đầy đủ.

| Nội dung theo khoản 2 Điều 46 | Vị trí trong báo cáo |
|---|---|
| a) Thuyết minh: mô tả yêu cầu | Mục 5.2 |
| a) Danh mục tiêu chuẩn, quy chuẩn kỹ thuật áp dụng | Mục 5.6 |
| a) Phân tích, lựa chọn phương án công nghệ | Chương 4 (phương án đầu tư), mục 5.5 (công nghệ chi tiết) |
| a) Giải pháp kết nối, liên thông | Mục 5.8 |
| a) Giải pháp IPv6 | Mục 5.9 (phần mềm), mục 6.6 (mạng) |
| a) Giải pháp bảo đảm an ninh mạng | Mục 5.10 (yêu cầu), Chương 7 (chi tiết) |
| a) Mô hình tổng thể, mô hình lô-gic, mô hình vật lý | Mục 5.3 (tổng thể), 5.4 (lô-gic), 6.2 và 6.3 (vật lý) |
| a) Tính toán quy mô thiết bị và phần mềm thương mại | Mục 6.4, 6.5; tệp `_ha-tang-sizing.csv` |
| b) Sơ đồ sơ bộ: hiện trạng hạ tầng, lắp đặt, kết nối | Mục 6.1, 6.3, 6.6 |
| c) Chỉ tiêu kỹ thuật lắp đặt, cài đặt, kiểm tra; thống kê khối lượng | Mục 6.10, 6.11 |
| d) Yêu cầu kỹ thuật phần mềm nội bộ | Mục 5.13 |
| đ) Hạng mục kết nối, chia sẻ cơ sở dữ liệu | Mục 5.8.3 |
| e) Khối lượng sơ bộ đào tạo, tập huấn | Mục 6.12 |
| g) Yêu cầu bảo đảm an ninh mạng | Mục 5.10, Chương 7 |

: Nội dung thiết kế cơ sở theo khoản 2 Điều 46 và vị trí trong báo cáo

Thiết kế cơ sở ở đây là bản tóm lược có định lượng của bộ tài liệu thiết kế đã có trong dự án: thiết kế kiến trúc tổng thể D03-01, đặc tả yêu cầu cấp hệ thống D02-02, thiết kế đa tenant D03-10 và sổ quyết định kiến trúc D00-02. Khi có khác biệt, các tài liệu đó là nguồn chi tiết; chương này không đặt quyết định mới trái với chúng. Các thông số chủ yếu, chức năng và tính năng chính được nêu đủ để xác định tổng mức đầu tư như điểm c và d khoản 1 Điều 46 yêu cầu; chi tiết thiết kế từng phân hệ thuộc bước thiết kế chi tiết (D03-02 đến D03-04).

### 5.2. Mô tả yêu cầu

#### 5.2.1. Yêu cầu nghiệp vụ

Datahub là nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới, đóng ba vai trò mà Chương 2 và D02-01 đã xác lập. Vai trò thứ nhất là trung gian bắt buộc cho mọi trao đổi dữ liệu giữa các hệ thống thông tin của tỉnh, thay thế các kết nối điểm tới điểm (BO-01). Vai trò thứ hai là cổng duy nhất kết nối ra các nền tảng và cơ sở dữ liệu quốc gia, gồm Nền tảng tích hợp, chia sẻ dữ liệu quốc gia (NDXP), Nền tảng dữ liệu mở quốc gia (NDOP), định danh điện tử VNeID và nền tảng thanh toán PayGov. Vai trò thứ ba là nơi quản trị dữ liệu dùng chung của tỉnh: danh mục dùng chung, dữ liệu chủ về công dân, tổ chức, địa chỉ, chất lượng dữ liệu và bảo vệ dữ liệu cá nhân.

Ngoài ba vai trò của một LGSP, Datahub có hai yêu cầu của một sản phẩm. Thứ nhất, một bộ mã nguồn phục vụ nhiều tỉnh, mỗi tỉnh là một tenant với dữ liệu, cấu hình và người dùng cách ly (BO-06). Thứ hai, quá trình chuyển đổi khỏi hệ LGSP cũ không được làm gián đoạn dịch vụ công trực tuyến đang chạy qua trục (BO-02).

#### 5.2.2. Yêu cầu chức năng theo nhóm phân hệ

Hai mươi phân hệ được nhóm thành sáu nhóm chức năng. Bảng dưới đây mô tả ngắn từng nhóm; danh sách đầy đủ, nhiệm vụ và ranh giới từng phân hệ ở D02-02 và D03-01 §4, yêu cầu chức năng chi tiết ở 20 tập FRS (D02-03).

| Nhóm | Phân hệ | Chức năng chính | Thay thế khối hệ cũ |
|---|---|---|---|
| Kết nối và công bố dịch vụ | PH-01 Kết nạp HTTT, PH-02 Danh mục dịch vụ, PH-03 Cổng API, PH-15 Cổng nhà phát triển | Hồ sơ HTTT thành viên, quy trình kết nạp, cấp định danh ứng dụng; đăng ký, công bố, vòng đời API; thực thi xác thực, hạn mức, ghi nhật ký; tài liệu, thử API, sandbox | API Management |
| Tích hợp và sự kiện | PH-04 Lõi tích hợp và trình thiết kế luồng, PH-05 Bộ điều hợp, PH-10 Sự kiện, PH-11 Quy trình liên thông | Thiết kế, duyệt, phát hành, chạy luồng Camel; bộ kết nối REST, SOAP, tệp, CDC; topic, schema, publisher, subscriber; quy trình BPMN có người duyệt | Bus, Productivity Tooling, Hub |
| Dữ liệu dùng chung | PH-06 Dữ liệu chủ, PH-07 Danh mục dùng chung, PH-08 Chất lượng dữ liệu, PH-09 Quyền riêng tư | Bản ghi vàng; danh mục có phiên bản, hiệu lực, đồng bộ quốc gia; quy tắc và đo chất lượng; phân loại dữ liệu, mục đích khai thác, che dữ liệu, sự đồng ý | Aita (một phần); phần còn lại là mới |
| Kết nối quốc gia và thanh toán | PH-14 Kết nối quốc gia, PH-19 Thanh toán | Adapter NDXP, NDOP, CSDL quốc gia; nhà cung cấp, giao dịch, đối soát, hoàn tiền qua PayGov và kênh khác | Phụ lục NGSP, Payment |
| Định danh, giám sát, vận hành | PH-12 Định danh và phân quyền, PH-13 Giám sát và kiểm toán, PH-18 Vận hành và xử lý lỗi | Người dùng, vai trò, chính sách, MFA; bảng điều khiển, cảnh báo, truy vết, nhật ký kiểm toán WORM; hàng đợi lỗi, xử lý lại, tham số, công cụ di trú | Keycloak, Graylog của hệ cũ |
| Quản trị sản phẩm | PH-16 Báo cáo chỉ tiêu, PH-17 Trợ lý AI, PH-20 Quản trị tenant | KPI chuyển đổi số về chia sẻ dữ liệu; tìm dịch vụ, gợi ý ánh xạ, giải thích sự cố; khởi tạo tỉnh, hạn mức, sáp nhập | Mới |

: Nhóm phân hệ, chức năng chính và khối hệ cũ được thay thế

Hệ cũ có 183 chức năng đã được kiểm kê thành các mục `LGC` tại D00-03, mỗi mục được ánh xạ tới phân hệ và yêu cầu chức năng của Datahub với kết luận giữ nguyên, nâng cấp, thay thế hoặc loại bỏ. Nhờ ánh xạ này, yêu cầu "không mất chức năng đang dùng" được kiểm chứng bằng số liệu: tiêu chí bàn giao là 100% mục có kết luận và có bằng chứng kiểm thử.

#### 5.2.3. Yêu cầu phi chức năng

Yêu cầu phi chức năng cấp hệ thống được định nghĩa chính thức ở D02-02 với mã `NFR-00-nnn`. Mục 5.11 trình bày các chỉ tiêu quan trọng nhất theo cỡ quy mô S, M, L, vì đây là đầu vào trực tiếp cho tính toán quy mô hạ tầng ở Chương 6.

### 5.3. Mô hình tổng thể

Mô hình tổng thể thể hiện Datahub trong môi trường của nó: các tác nhân bên ngoài, các lớp bên trong và các luồng chính. Sơ đồ dưới đây được vẽ theo lớp, từ trên xuống: người dùng và hệ thống bên ngoài, lớp biên, data plane, control plane, lớp dịch vụ dùng chung, lớp nền tảng.

```{.mermaid caption="Mô hình tổng thể Datahub theo lớp và các luồng chính"}
flowchart TB
    subgraph EXT["Bên ngoài tỉnh"]
        NDXP["NDXP<br/>trục quốc gia"]
        NDOP["NDOP<br/>dữ liệu mở quốc gia"]
        CSDLQG["CSDL quốc gia<br/>dân cư, doanh nghiệp, đất đai"]
        VNEID["VNeID<br/>định danh điện tử"]
        PAYGOV["PayGov và<br/>kênh thanh toán"]
    end
    subgraph TINH["Trong tỉnh"]
        HTTT["HTTT sở, ngành, xã<br/>Cổng DVC, một cửa, CSDL chuyên ngành"]
        USR["Cán bộ quản trị,<br/>kỹ sư tích hợp, nhà phát triển"]
        OLD["LGSP cũ<br/>chạy song song đến G5"]
    end
    subgraph DH["Datahub"]
        subgraph EDGE["Lớp biên"]
            WAF["APISIX biên apisix-ext<br/>WAF Coraza, TLS 1.3"]
        end
        subgraph DP["Data plane"]
            GW["Cổng API APISIX<br/>PH-03"]
            RT["dh-runtime Camel Quarkus<br/>PH-04, PH-05, PH-14"]
            KF["Kafka và Apicurio<br/>PH-10"]
        end
        subgraph CP["Control plane"]
            FE["dh-console, dh-portal<br/>giao diện, PH-15"]
            CNX["dh-connect<br/>PH-01, 02, 03"]
            INT["dh-integration<br/>PH-04, 05, 10, 14"]
            DAT["dh-data<br/>PH-06, 07, 08, 09"]
            PLT["dh-platform<br/>PH-11, 12, 13, 16, 18, 20"]
            PAY["dh-payment<br/>PH-19"]
            AST["dh-assist<br/>PH-17"]
        end
        subgraph SH["Dịch vụ dùng chung"]
            IAM["Keycloak và OPA"]
            DB["PostgreSQL CloudNativePG"]
            S3["Kho đối tượng S3"]
            SEC["OpenBao"]
            OBS["OpenTelemetry và LGTM"]
            GIT["Kho Git cấu hình<br/>và Argo CD"]
        end
        K8S["Nền tảng Kubernetes<br/>TTDL tỉnh hoặc cloud chính phủ"]
    end
    HTTT --> WAF
    USR --> WAF
    WAF --> GW
    WAF --> FE
    FE --> GW
    GW --> RT
    GW --> CNX
    GW --> INT
    GW --> DAT
    GW --> PLT
    GW --> PAY
    GW --> AST
    RT <--> KF
    RT --> HTTT
    RT --> NDXP
    RT --> NDOP
    NDXP --> CSDLQG
    IAM <-->|"OIDC"| VNEID
    PAY <--> PAYGOV
    GW -.->|"định tuyến chuyển tiếp"| OLD
    CNX --> DB
    INT --> GIT
    GIT --> RT
    DAT --> DB
    PLT --> DB
    PAY --> DB
    CP -.-> KF
    DH -.-> OBS
    SH --- K8S
```

Sơ đồ cần được đọc theo ba điểm. Thứ nhất, mọi lượt gọi từ bên ngoài, kể cả từ giao diện quản trị, đều đi qua lớp biên và cổng API APISIX, nhờ đó xác thực, hạn mức và nhật ký được áp dụng thống nhất (D03-01 §5). Thứ hai, đường đi của dữ liệu giữa hai HTTT hoặc giữa HTTT và nền tảng quốc gia chỉ gồm các thành phần data plane (cổng API, `dh-runtime`, Kafka); control plane không nằm trên đường đi này, nên khi control plane ngừng, data plane vẫn phục vụ ít nhất 24 giờ với cấu hình đã nạp (NFR-00-012, ADR-013). Thứ ba, hệ LGSP cũ xuất hiện trong mô hình như một đích định tuyến của cổng API trong giai đoạn chuyển đổi; khi một nhóm dịch vụ chưa được chuyển, cổng API chuyển tiếp lượt gọi tới hệ cũ (mục 5.14).

### 5.4. Mô hình lô-gic

#### 5.4.1. Phân tách control plane và data plane

Mô hình lô-gic của Datahub dựa trên nguyên tắc tách control plane và data plane (NT-01 tại D03-01, ADR-013). Control plane là phần con người làm việc: giao diện, CSDL quản trị, quy trình duyệt, báo cáo. Data plane là phần máy làm việc: nhận lượt gọi, kiểm tra quyền, chuyển đổi, định tuyến, phát và nhận sự kiện. Hai phần có yêu cầu rất khác nhau. Data plane cần độ trễ thấp, co giãn nhanh theo lưu lượng và sẵn sàng cao (99,9%); control plane cần tính đúng đắn của dữ liệu quản trị, chịu được độ sẵn sàng thấp hơn (99,5%, NFR-00-011) và thay đổi chức năng thường xuyên hơn. Tách hai phần cho phép tối ưu riêng từng phần, và quan trọng hơn là cô lập sự cố: một lỗi ở màn hình quản trị hay ở quy trình duyệt không thể làm dừng việc tra cứu dữ liệu dân cư của Cổng dịch vụ công.

Cấu hình đi từ control plane xuống data plane theo hai kênh có kiểm soát. Kênh thứ nhất là API quản trị của APISIX: khi một API được công bố ở PH-02, `dh-connect` khai báo route, consumer và plugin xuống APISIX, và APISIX giữ cấu hình trong bộ nhớ. Kênh thứ hai là GitOps: khi một luồng tích hợp được duyệt ở PH-04, `dh-integration` ghi tệp Camel YAML DSL (ADR-010) vào kho Git cấu hình, Argo CD (ADR-009) đồng bộ xuống `dh-runtime`. Không có kênh nào cho giao diện ra lệnh trực tiếp tới runtime, điều này khắc phục điểm nghẽn ĐN-06 của hệ cũ (cho phép nạp mã tùy ý và điều khiển agent qua HTTP).

#### 5.4.2. Đơn vị triển khai

Hai mươi phân hệ không được triển khai thành hai mươi dịch vụ riêng. D03-01 §4.2 gom chúng thành các đơn vị triển khai (deployment unit, DU) theo năm tiêu chí: cùng miền nghiệp vụ, cùng hồ sơ tải, cùng yêu cầu bảo mật, tần suất thay đổi tương đồng và số đơn vị phải phù hợp với đội vận hành của trung tâm dữ liệu tỉnh (thường 3 đến 5 người). Bên trong mỗi DU Spring Boot, mỗi phân hệ là một module Spring Modulith với ranh giới được kiểm tra tự động (ADR-001), nên có thể tách ra thành DU riêng khi cần mà không đổi hợp đồng API.

| Đơn vị triển khai | Phân hệ | Mặt | Công nghệ | Đặc điểm tải |
|---|---|---|---|---|
| `apisix` | PH-03 | Data | Apache APISIX, Coraza WAF | Tỷ lệ thuận với lượt gọi, co giãn theo CPU |
| `dh-runtime` | PH-04, PH-05, PH-14 (phần chạy) | Data | Camel Quarkus native | Co giãn theo CPU và độ trễ tiêu thụ Kafka (KEDA) |
| `kafka` | PH-10 (phần chạy) | Data | Kafka (Strimzi, KRaft), Apicurio | Tỷ lệ với số sự kiện, cần lưu trữ SSD |
| `dh-connect` | PH-01, PH-02, PH-03 (đồng bộ cấu hình), PH-15 (phần máy chủ) | Control | Spring Boot 4 | Thấp, theo người dùng quản trị |
| `dh-integration` | PH-04, PH-05, PH-10, PH-14 (phần quản trị) | Control | Spring Boot 4 | Thấp, đỉnh khi phát hành luồng |
| `dh-data` | PH-06, PH-07, PH-08, PH-09 | Control | Spring Boot 4 | Trung bình, đỉnh khi nhập danh mục, chạy lô đối sánh |
| `dh-platform` | PH-11, PH-12, PH-13, PH-16, PH-18, PH-20 | Control | Spring Boot 4, Flowable nhúng | Thấp đến trung bình |
| `dh-payment` | PH-19 | Control và Data | Spring Boot 4 | Đỉnh cuối tháng, đầu năm học; cần mạng ra kênh thanh toán |
| `dh-assist` | PH-17 | Control | Spring Boot 4, pgvector | Tùy chọn bật tắt theo tỉnh |
| `dh-console`, `dh-portal` | Giao diện mọi phân hệ, PH-15 | Control | React 19, Ant Design 6, Liquid Glass | Tệp tĩnh, tải thấp |

: Đơn vị triển khai, phân hệ, mặt điều khiển hay mặt dữ liệu, công nghệ và đặc điểm tải

Bảng cho thấy chỉ ba đơn vị (`apisix`, `dh-runtime`, `kafka`) quyết định quy mô hạ tầng theo lưu lượng; các DU control plane có tải gần như cố định theo số người dùng quản trị. Đó là lý do bảng cấu hình ở Chương 6 tách nhóm máy "worker tích hợp" và "worker biên" khỏi nhóm "worker ứng dụng".

#### 5.4.3. Đường đi của một lượt gọi

Để làm rõ mô hình lô-gic, mục này mô tả đường đi của một lượt gọi điển hình: Cổng dịch vụ công của tỉnh tra cứu thông tin công dân từ CSDL quốc gia về dân cư qua NDXP. Cổng dịch vụ công gửi yêu cầu HTTPS kèm token truy cập do realm Keycloak của tỉnh cấp. Lớp biên chấm dứt TLS và kiểm tra WAF. APISIX xác minh chữ ký token, đối chiếu tenant, kiểm tra HTTT đã đăng ký sử dụng dịch vụ, áp hạn mức, hỏi OPA quyết định cho phép dựa trên vai trò, tenant, phân loại dữ liệu và mục đích khai thác, rồi chuyển tới luồng tương ứng trong `dh-runtime`. Luồng Camel chuyển đổi yêu cầu sang định dạng của NDXP, lấy khóa ký từ OpenBao, gọi NDXP, nhận kết quả, che các trường nhạy cảm mà mục đích khai thác không cho phép xem, trả kết quả. Suốt đường đi, mã truy vết `traceparent` được truyền, và siêu dữ liệu lượt gọi (ai gọi, gọi gì, mục đích, kết quả, kích thước, thời gian) được ghi vào nhật ký khai thác phục vụ thanh tra (KPI-07). Nội dung bản tin không được lưu, trừ khi lỗi và phải đưa vào hàng đợi xử lý lại tối đa 7 ngày, có mã hóa (D03-01 §8.3).

```{.mermaid caption="Trình tự một lượt tra cứu thông tin công dân qua NDXP"}
sequenceDiagram
    participant C as Cổng dịch vụ công
    participant E as Lớp biên và WAF
    participant G as APISIX
    participant O as OPA
    participant R as dh-runtime
    participant B as OpenBao
    participant N as NDXP
    C->>E: Yêu cầu HTTPS kèm token Keycloak
    E->>G: Chấm dứt TLS, kiểm tra WAF
    G->>G: Xác minh token, tenant, đăng ký dịch vụ, hạn mức
    G->>O: Hỏi quyết định theo vai trò, tenant, mục đích
    O-->>G: Cho phép
    G->>R: Chuyển tới luồng Camel tương ứng
    R->>B: Lấy khóa ký
    R->>N: Gọi NDXP theo định dạng của NDXP
    N-->>R: Kết quả
    R->>R: Che các trường nhạy cảm không được xem
    R-->>C: Trả kết quả, ghi siêu dữ liệu lượt gọi
```

Sơ đồ cho thấy hai điểm. Thứ nhất, kiểm soát truy cập (token, tenant, hạn mức, OPA) hoàn tất ở APISIX trước khi bất kỳ luồng nào chạy, nên `dh-runtime` không phải tự kiểm tra lại. Thứ hai, khóa ký chỉ được lấy từ OpenBao tại thời điểm gọi và việc che trường nhạy cảm diễn ra trước khi kết quả rời nền tảng.

### 5.5. Phương án công nghệ

#### 5.5.1. Nguyên tắc lựa chọn

Phương án công nghệ được lựa chọn theo năm nguyên tắc. Nguyên tắc thứ nhất là chỉ dùng thành phần mã nguồn mở có giấy phép được tổ chức mã nguồn mở công nhận, hoặc giao thức chuẩn mở, để không phát sinh chi phí bản quyền và không bị khóa nhà cung cấp (NT-09 tại D03-01). Nguyên tắc thứ hai là chọn dự án mã nguồn mở trưởng thành, có cộng đồng hoặc tổ chức bảo trợ ổn định và có lựa chọn hỗ trợ thương mại nếu chủ đầu tư cần. Nguyên tắc thứ ba là chỉ dùng phiên bản còn trong vòng đời hỗ trợ tại thời điểm khóa và rà soát vòng đời trước mỗi lần nâng cấp lớn hoặc nộp hồ sơ cấp độ, nhằm không lặp lại tình trạng nền công nghệ hết hỗ trợ của hệ cũ (ĐN-01). Nguyên tắc thứ tư là chạy được như nhau trên Kubernetes tại chỗ và trên cloud chính phủ, không dùng dịch vụ đặc thù của một nhà cung cấp cloud. Nguyên tắc thứ năm là mỗi lựa chọn quan trọng có một bản ghi quyết định kiến trúc (ADR) nêu các phương án đã cân nhắc và lý do, để hội đồng thẩm định kiểm tra được tính hợp lý.

#### 5.5.2. Bảng công nghệ chốt

Bảng dưới đây liệt kê công nghệ đã chốt theo tầng, giấy phép và ADR tương ứng trong sổ D00-02. Số phiên bản cụ thể được ghim ở D04-02; ở đây chỉ ghi dòng phiên bản chính.

| Tầng | Công nghệ | Dòng phiên bản | Giấy phép | ADR |
|---|---|---|---|---|
| Giao diện | React, TypeScript, Vite, Ant Design, XYFlow; phong cách Liquid Glass | React 19, antd 6 | MIT | ADR-020 |
| Biên | Apache APISIX ở vùng biên (`apisix-ext`, dh-edge, Z1) kiêm kết thúc TLS; WAF Coraza với OWASP CRS chạy trong APISIX; không dùng Ingress NGINX hay Envoy Gateway | 3.x | Apache 2.0 | ADR-033 |
| Cổng API | Apache APISIX | 3.x | Apache 2.0 | ADR-005 |
| Backend ứng dụng | Java (Temurin), Spring Boot, Spring Modulith, Liquibase | Java 21, Boot 4, Modulith 2 | GPLv2 kèm ngoại lệ Classpath (JDK); Apache 2.0 | ADR-001 |
| Tích hợp | Apache Camel Quarkus native, Camel YAML DSL, Kamelet | Camel 4 dòng LTS | Apache 2.0 | ADR-002, ADR-010 |
| Quy trình | Flowable nhúng | 7.x | Apache 2.0 | ADR-007 |
| Sự kiện | Apache Kafka (Strimzi, KRaft), Apicurio Registry, Debezium | Kafka 4 | Apache 2.0 | ADR-004 |
| CSDL quan hệ | PostgreSQL, CloudNativePG, pgvector | PostgreSQL 18 | PostgreSQL License; Apache 2.0 | ADR-003 |
| Kho đối tượng | Garage cho tệp nghiệp vụ; Ceph RGW (Object Lock chế độ compliance) cho WORM nhật ký kiểm toán và sao lưu bất biến, tách bucket | — | AGPLv3 (Garage); LGPL (Ceph) | ADR-008, ADR-031, ADR-035 |
| Bộ nhớ đệm | Valkey | 8 | BSD-3-Clause | Chưa có ADR riêng |
| Định danh, ủy quyền | Keycloak, Open Policy Agent | Keycloak 26 | Apache 2.0 | ADR-006 |
| Bí mật | OpenBao (ưu tiên) hoặc Vault; External Secrets Operator | — | MPL 2.0 (OpenBao); BUSL 1.1 (Vault) | ADR-012 |
| Mạng nội bộ | Cilium, Istio ambient mesh | — | Apache 2.0 | ADR-013 |
| Triển khai | Kubernetes, Argo CD, Kustomize, Helm, Harbor, Trivy, KEDA | K8s ≥ 1.31 | Apache 2.0 | ADR-009 |
| Quan sát | OpenTelemetry, Prometheus hoặc Mimir, Loki, Tempo, Grafana | — | Apache 2.0; AGPLv3 (Grafana, Loki, Tempo, Mimir) | ADR-011 |
| Lưu trữ nhật ký, thống kê | OpenSearch (tìm kiếm nhật ký); ClickHouse (thống kê lưu lượng, đề xuất) | OpenSearch 2.x | Apache 2.0 | Quyết định ở SDD PH-02, PH-13 |

: Công nghệ chốt theo tầng, dòng phiên bản, giấy phép và ADR

Bảng có ba điểm hội đồng thẩm định nên lưu ý. Điểm thứ nhất là các thành phần giấy phép AGPLv3 (Garage, Grafana, Loki, Tempo, Mimir): Datahub dùng chúng nguyên bản như dịch vụ độc lập qua giao thức chuẩn, không sửa mã nguồn và không nhúng vào sản phẩm, nên nghĩa vụ công bố mã nguồn của AGPL không phát sinh; nếu sau này cần sửa mã các thành phần này thì phần sửa phải được công bố, và việc này phải được ghi thành ADR. Điểm thứ hai là Vault từ năm 2023 chuyển sang giấy phép BUSL 1.1, không phải giấy phép mã nguồn mở theo định nghĩa của tổ chức mã nguồn mở, vì vậy ADR-012 ưu tiên OpenBao là nhánh mã nguồn mở tương thích. Điểm thứ ba là Garage chưa hỗ trợ đầy đủ khóa đối tượng (object lock) theo chuẩn S3, nên ADR-008 quy định dùng Ceph RGW với Object Lock cho bằng chứng kiểm toán cần lưu bất biến, và cùng hệ Ceph RGW đó giữ bản sao lưu bất biến ở bucket riêng (ADR-035); Chương 6 tính dung lượng cho cả hai kho.

#### 5.5.3. Lý do lựa chọn các công nghệ chủ chốt

Phần này giải thích ngắn lý do của sáu lựa chọn có ảnh hưởng lớn nhất tới chi phí và rủi ro; lập luận đầy đủ ở từng ADR.

**Apache Camel cho lõi tích hợp (ADR-002, ADR-010).** Hệ cũ đã dùng Camel cho khối Bus, nên đội vận hành và các luồng hiện có dễ chuyển hơn so với một động cơ tích hợp khác. Camel có hơn 300 bộ kết nối, hỗ trợ đầy đủ các mẫu tích hợp doanh nghiệp, và bản Quarkus native khởi động trong khoảng vài chục mili giây với bộ nhớ thấp hơn nhiều so với chạy trên JVM, cho phép co giãn theo đỉnh tải giờ hành chính. Định dạng YAML DSL thay cho XML của hệ cũ giúp luồng được lưu, so sánh và duyệt trong Git như mã nguồn.

**Kafka thay Apache Pulsar (ADR-004).** Pulsar của khối Hub cũ có kiến trúc nhiều thành phần (broker, BookKeeper, ZooKeeper) khó vận hành với đội nhỏ. Kafka bản 4 chạy chế độ KRaft không cần ZooKeeper, có hệ sinh thái lớn nhất (Debezium cho bắt thay đổi dữ liệu, Apicurio cho schema, Strimzi cho vận hành trên Kubernetes) và nguồn nhân lực phổ biến hơn.

**APISIX cho cổng API (ADR-005).** APISIX giữ cấu hình trong bộ nhớ, có độ trễ tăng thêm rất thấp, hỗ trợ cập nhật cấu hình không khởi động lại và có sẵn các plugin xác thực OIDC, hạn mức, chuyển đổi, gọi OPA. Thuộc tính quan trọng nhất với Datahub là khả năng định tuyến theo trọng số và theo điều kiện, là cơ chế kỹ thuật của chiến lược thay thế dần (mục 5.14).

**APISIX kiêm lớp biên (ADR-033).** Thay vì thêm một sản phẩm biên riêng như Ingress NGINX hay Envoy Gateway, Datahub dùng hai nhóm APISIX tách biệt: `apisix-ext` đặt ở vùng biên Z1 (namespace dh-edge) kết thúc TLS, chạy WAF Coraza với bộ luật OWASP CRS và chặn lưu lượng bất thường; `apisix-int` đặt ở vùng cổng Z2 (namespace dh-gateway) thực hiện xác thực, hạn mức và định tuyến tới data plane. Cách làm này giảm một loại thành phần phải vận hành, vá lỗi và đưa vào hồ sơ cấp độ, trong khi vẫn giữ được ranh giới mạng giữa vùng biên và vùng xử lý như D03-07 và D03-09 yêu cầu.

**PostgreSQL với RLS cho đa tenant (ADR-003).** RLS chặn rò rỉ dữ liệu chéo tỉnh ở tầng CSDL, kể cả khi mã ứng dụng quên điều kiện lọc. CloudNativePG cung cấp sẵn nhân bản đồng bộ, khôi phục về thời điểm (PITR) và cụm bản sao ở site DR.

**Keycloak và OPA (ADR-006).** Keycloak hỗ trợ OIDC, SAML 2.0, MFA, liên kết danh tính với VNeID và LDAP của tỉnh, với mỗi tenant một realm. OPA tách chính sách ủy quyền ra khỏi mã, viết bằng Rego, lưu trong Git và kiểm thử tự động.

**Spring Boot 4 và Spring Modulith (ADR-001).** Backend dùng một khung phần mềm phổ biến nhất trong cộng đồng Java, với Modulith cho phép giữ số đơn vị triển khai nhỏ (phù hợp đội vận hành tỉnh) mà vẫn có ranh giới module chặt chẽ như kiến trúc vi dịch vụ.

#### 5.5.4. Phần mềm thương mại

Phương án công nghệ không có phần mềm thương mại bắt buộc. Có ba nhóm chi phí phần mềm tùy chọn mà Chương 8 tính như kịch bản riêng: hỗ trợ thương mại cho một số thành phần mã nguồn mở (bản phân phối Kubernetes có hỗ trợ, hỗ trợ PostgreSQL, Kafka, Keycloak), hệ điều hành có hỗ trợ của nhà phát hành, và nền tảng ảo hóa nếu trung tâm dữ liệu tỉnh dùng sản phẩm thương mại sẵn có. Bảng tổng hợp ở mục 6.8 liệt kê các nhóm này để làm đầu vào cho Chương 8.

### 5.6. Danh mục tiêu chuẩn, quy chuẩn kỹ thuật áp dụng

Thiết kế cơ sở phải tuân thủ tiêu chuẩn, quy chuẩn và quy định quản lý, kết nối, chia sẻ dữ liệu (điểm b khoản 1 Điều 46). Bảng dưới đây liệt kê các tiêu chuẩn áp dụng, nhóm theo mục đích. Văn bản nhà nước về danh mục tiêu chuẩn kỹ thuật ứng dụng công nghệ thông tin trong cơ quan nhà nước được dẫn theo mã CMP-LAW-13 (Thông tư 39/2017/TT-BTTTT), là văn bản cần xác minh văn bản thay thế; nếu có văn bản mới, danh mục dưới đây được rà soát lại ở bước thiết kế chi tiết.

| Nhóm | Tiêu chuẩn | Áp dụng trong Datahub |
|---|---|---|
| Kết nối, trao đổi dữ liệu | HTTP/1.1, HTTP/2; REST; OpenAPI 3.1; JSON (RFC 8259); XML 1.0; SOAP 1.1/1.2, WSDL | Mọi API công bố; SOAP qua bộ điều hợp cho hệ cũ và một số dịch vụ quốc gia |
| Sự kiện | AsyncAPI 3.0; CloudEvents 1.0; Avro, JSON Schema | Đặc tả và định dạng sự kiện Kafka, webhook |
| Định dạng lỗi | RFC 9457 Problem Details | Mọi phản hồi lỗi của API |
| Kết nối CSDL quốc gia | Yêu cầu kỹ thuật kết nối theo CMP-LAW-12 (Thông tư 13/2017/TT-BTTTT, cần xác minh); đặc tả kết nối do NDXP công bố | PH-14 |
| Yêu cầu chức năng LGSP | Công văn 631/THH-THHT (CMP-LAW-09) | Đối chiếu chức năng PH-01 đến PH-05, PH-10, PH-13, PH-14 |
| Xác thực, ủy quyền | OAuth 2.0 (RFC 6749), OpenID Connect 1.0, SAML 2.0, JWT (RFC 7519), PKCE (RFC 7636) | PH-12, cổng API, liên kết VNeID |
| Mã hóa, chữ ký | TLS 1.3 (RFC 8446), TLS 1.2 với bộ mã an toàn; X.509 v3; mTLS; HMAC-SHA256; AES-256-GCM | Kênh truyền, webhook, mã hóa trường nhạy cảm |
| Mạng | IPv4, IPv6 (RFC 8200), DNS, NTP | Mục 5.9, 6.6 |
| Bộ ký tự, thời gian | UTF-8 (Unicode, TCVN 6909:2001); ISO 8601 | Mọi dữ liệu văn bản, mốc thời gian |
| Quy trình | BPMN 2.0 | PH-11 |
| Lưu trữ đối tượng | Giao diện S3 | Kho đối tượng, sao lưu |
| Quan sát | OpenTelemetry (OTLP), W3C Trace Context, định dạng chỉ số Prometheus | PH-13 |
| An toàn ứng dụng | OWASP ASVS 5.0 mức 2; OWASP Top 10 | Kiểm thử bảo mật mọi ứng dụng web và API (NFR-00-024) |
| An toàn hệ thống theo cấp độ | CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15), CMP-LAW-06 (Nghị định 331/2026/NĐ-CP), CMP-LAW-08 (TCVN 14423:2026); CMP-LAW-07 chỉ để đối chiếu mẫu hồ sơ | Chương 7, D03-07, D03-08 |
| Khả năng truy cập | WCAG 2.2 mức AA | Giao diện quản trị và cổng nhà phát triển (NFR-00-040) |
| Đặc tả, kiểm thử | ISO/IEC/IEEE 29148; ISO/IEC/IEEE 29119-3 | Bộ tài liệu yêu cầu và kiểm thử |
| Container, triển khai | Đặc tả ảnh OCI; Kubernetes API; SBOM định dạng SPDX hoặc CycloneDX | Đóng gói, triển khai, chuỗi cung ứng |

: Tiêu chuẩn, quy chuẩn kỹ thuật áp dụng và cách áp dụng trong Datahub

Danh mục này có hai lớp. Lớp thứ nhất là tiêu chuẩn bắt buộc theo văn bản nhà nước (kết nối CSDL quốc gia, yêu cầu LGSP, an toàn hệ thống theo cấp độ); Datahub phải chứng minh tuân thủ bằng bằng chứng kiểm thử tại D00-03. Lớp thứ hai là tiêu chuẩn kỹ thuật quốc tế được chọn để bảo đảm khả năng tương tác và không khóa nhà cung cấp; chúng là ràng buộc thiết kế được kiểm tra trong cổng CI (ví dụ hợp đồng OpenAPI phải hợp lệ trước khi mã được hợp nhất).

### 5.7. Sự phù hợp với khung kiến trúc

Điểm a khoản 1 Điều 46 yêu cầu thiết kế cơ sở tuân thủ Khung kiến trúc tổng thể quốc gia số hoặc khung kiến trúc của cơ quan, tổ chức. Tại thời điểm lập báo cáo, Khung Kiến trúc Chính phủ điện tử Việt Nam phiên bản 3.0 (CMP-LAW-10) là khung đã ban hành; Khung Kiến trúc tổng thể quốc gia số (CMP-LAW-11) đang ở dạng dự thảo. Datahub được thiết kế phù hợp với khung 3.0 và có sẵn các năng lực mà dự thảo khung tổng thể quốc gia số nhấn mạnh (nền tảng dữ liệu, chỉ số đo, AI có quản trị), để khi khung mới ban hành chỉ cần đối chiếu lại chứ không phải thiết kế lại. Kiến trúc chuyển đổi số của tỉnh thí điểm (nếu đã ban hành) cũng là căn cứ đối chiếu; báo cáo ghi điểm này thành câu hỏi mở Q-D0101-45.

Bảng dưới đây ánh xạ các thành phần Datahub vào các lớp và nền tảng dùng chung của khung kiến trúc. Ánh xạ ở mức lớp vì tên gọi chi tiết các thành phần trong khung cần được Chương 1 đối chiếu nguyên văn.

| Lớp hoặc thành phần của khung | Thành phần Datahub đáp ứng | Ghi chú |
|---|---|---|
| Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh (LGSP) | Toàn bộ Datahub, trọng tâm PH-01 đến PH-05, PH-10, PH-14 | Vai trò trung gian bắt buộc, kết nối lên NDXP |
| Lớp dữ liệu và CSDL dùng chung | PH-06, PH-07, PH-08, PH-09 | Danh mục dùng chung, dữ liệu chủ, chất lượng, quyền riêng tư |
| Nền tảng định danh, xác thực | PH-12, liên kết VNeID | Một điểm đăng nhập, MFA, mỗi tỉnh một realm |
| Nền tảng thanh toán | PH-19, kết nối PayGov | Đối soát, hoàn tiền |
| Lớp an toàn thông tin | PH-12, PH-13, kiến trúc zero-trust, Chương 7 | Cấp độ 3, sẵn sàng cấp độ 4 |
| Quản trị, giám sát | PH-13, PH-16, PH-18 | Giám sát xuyên suốt, chỉ số chia sẻ dữ liệu |
| Hạ tầng (TTDL tỉnh, cloud chính phủ, mạng truyền số liệu chuyên dùng) | Chương 6 | Kubernetes chuẩn, chạy trên H1 hoặc H2 |

: Đối chiếu lớp của khung kiến trúc với thành phần Datahub đáp ứng

Hai nguyên tắc của khung kiến trúc được Datahub thực hiện bằng cơ chế kỹ thuật kiểm chứng được. Nguyên tắc chia sẻ dữ liệu qua nền tảng thay vì kết nối điểm tới điểm được thực hiện bằng việc mọi dịch vụ chỉ được khai thác qua cổng API với đăng ký sử dụng và nhật ký; KPI-01 đo tỷ lệ HTTT kết nối qua Datahub. Nguyên tắc dùng chuẩn mở, tái sử dụng được thực hiện bằng hợp đồng OpenAPI, AsyncAPI cho mọi dịch vụ và bằng mô hình sản phẩm dùng chung nhiều tỉnh.

### 5.8. Giải pháp kết nối, liên thông và chia sẻ dữ liệu

#### 5.8.1. Kết nối với các nền tảng quốc gia

Datahub kết nối với năm nhóm hệ thống bên ngoài tỉnh. Bảng dưới đây nêu phương thức kết nối, chuẩn và phân hệ phụ trách. Mọi kết nối ra ngoài đều đi qua bộ điều hợp riêng của PH-14 hoặc PH-19, để khi đặc tả phía quốc gia thay đổi chỉ phải sửa bộ điều hợp, không ảnh hưởng HTTT của tỉnh (biện pháp cho RSK-A04 tại D03-01).

| Hệ thống | Mục đích | Phương thức | Chuẩn, bảo mật | Phân hệ |
|---|---|---|---|---|
| NDXP | Khai thác CSDL quốc gia, dữ liệu bộ ngành; cung cấp dữ liệu của tỉnh lên quốc gia | REST, SOAP qua NDXP | Theo đặc tả NDXP; token ứng dụng; chữ ký số; kênh mạng truyền số liệu chuyên dùng hoặc Internet có TLS | PH-14 |
| NDOP | Công bố dữ liệu mở của tỉnh | API của NDOP, tệp theo lô | Theo đặc tả NDOP | PH-14, PH-07 |
| CSDL quốc gia (dân cư, đăng ký doanh nghiệp, đất đai, bảo hiểm và các CSDL khác) | Tra cứu, xác thực, đồng bộ | Qua NDXP; trực tiếp nếu cơ quan chủ quản yêu cầu | CMP-LAW-12 | PH-14 |
| VNeID | Định danh, xác thực người dùng là công dân hoặc cán bộ | OIDC | Liên kết danh tính trong Keycloak | PH-12 |
| PayGov và kênh thanh toán | Tạo giao dịch, nhận kết quả, đối soát, hoàn tiền | REST, webhook có chữ ký, tệp đối soát SFTP hoặc S3 | HMAC hoặc chữ ký số, chống phát lại | PH-19 |

: Kết nối của Datahub với các nền tảng quốc gia: mục đích, phương thức, chuẩn

#### 5.8.2. Kết nối với hệ thống thông tin của tỉnh

Các HTTT của sở, ngành, cấp xã kết nối với Datahub theo bốn kiểu, chọn theo khả năng của từng hệ thống. Kiểu thứ nhất là gọi và cung cấp API REST qua cổng API, áp dụng cho hệ có khả năng tích hợp hiện đại. Kiểu thứ hai là phát và nhận sự kiện qua Kafka hoặc qua webhook đẩy có chữ ký HMAC-SHA256, áp dụng khi cần thông báo thay đổi mà không phụ thuộc trực tiếp. Kiểu thứ ba là bộ điều hợp PH-05 cho hệ chưa có API chuẩn (SOAP, tệp, đọc thay đổi CSDL bằng CDC), giúp tỉnh không phải sửa ngay các hệ cũ. Kiểu thứ tư, chỉ trong giai đoạn chuyển đổi, là giữ nguyên địa chỉ và giao diện của hệ LGSP cũ cho HTTT chưa chuyển, với cổng API làm lớp tương thích (mục 5.14). Quy trình kết nạp một HTTT mới do PH-01 điều phối, mục tiêu không quá 5 ngày làm việc từ khi nộp hồ sơ tới khi gọi được API ở môi trường thật (KPI-05).

#### 5.8.3. Hạng mục kết nối, chia sẻ cơ sở dữ liệu

Điểm đ khoản 2 Điều 46 yêu cầu thiết kế cơ sở nêu hạng mục kết nối, chia sẻ của cơ sở dữ liệu theo khoản 1 Điều 21 Nghị định 194/2025/NĐ-CP. Datahub chủ yếu là nền tảng trung gian, phần lớn dữ liệu chỉ đi qua và không được lưu (D03-01 §8.3). Tuy vậy Datahub làm chủ một số cơ sở dữ liệu dùng chung, và chính các cơ sở dữ liệu này phải được thiết kế để kết nối, chia sẻ. Bảng dưới đây liệt kê các hạng mục đó. Nội dung nguyên văn khoản 1 Điều 21 Nghị định 194/2025/NĐ-CP chưa được đối chiếu khi lập chương này; bảng sẽ được điều chỉnh tên cột nếu điều khoản yêu cầu trường thông tin khác (Q-D0101-46).

| Cơ sở dữ liệu do Datahub làm chủ | Dữ liệu chính | Đối tượng được chia sẻ | Phương thức chia sẻ | Danh mục, chuẩn dùng chung |
|---|---|---|---|---|
| CSDL danh mục dùng chung của tỉnh (PH-07) | Danh mục có phiên bản và hiệu lực: đơn vị hành chính, cơ quan, danh mục chuyên ngành địa phương | Mọi HTTT của tỉnh; NDOP với danh mục công khai | API tra cứu, sự kiện khi phát hành phiên bản mới, tệp xuất | Đồng bộ với danh mục quốc gia tương ứng (KPI-10) |
| CSDL dữ liệu chủ (PH-06) | Bản ghi vàng về công dân, tổ chức, địa chỉ ở phạm vi tỉnh, liên kết với khóa CSDL quốc gia | HTTT được cấp quyền theo mục đích khai thác | API có kiểm soát mục đích, sự kiện thay đổi | Mã định danh theo CSDL quốc gia |
| CSDL danh mục dịch vụ chia sẻ (PH-02) | API và dịch vụ dữ liệu được công bố, điều kiện sử dụng | HTTT của tỉnh, nhà phát triển; hệ thống quản lý dịch vụ chia sẻ dữ liệu cấp quốc gia nếu có yêu cầu đồng bộ | Cổng nhà phát triển, API danh mục | OpenAPI 3.1 |
| CSDL giao dịch thanh toán (PH-19) | Giao dịch, đối soát, hoàn tiền | Cổng dịch vụ công, cơ quan tài chính của tỉnh | API, tệp đối soát, sự kiện | Định dạng của kênh thanh toán |
| Nhật ký khai thác dữ liệu (PH-13) | Siêu dữ liệu từng lượt khai thác: chủ thể, dữ liệu, mục đích, thời điểm | Cơ quan thanh tra, kiểm tra; chủ thể dữ liệu theo quy định bảo vệ dữ liệu cá nhân | Báo cáo, API chỉ-đọc có kiểm toán | Định dạng nhật ký thống nhất D03-04 |

: Hạng mục kết nối, chia sẻ cơ sở dữ liệu do Datahub làm chủ

Mỗi cơ sở dữ liệu trên có chủ sở hữu dữ liệu là cơ quan được tỉnh giao (dự kiến là đơn vị chủ trì quản lý dữ liệu của tỉnh), có phân loại dữ liệu ở mức trường (công khai, nội bộ, hạn chế, nhạy cảm theo D03-01 §8.2) và có chính sách khai thác gắn với mục đích (PH-09). Đây là điều kiện để việc chia sẻ đáp ứng Luật Dữ liệu (CMP-LAW-01) và quy định bảo vệ dữ liệu cá nhân (CMP-LAW-04, CMP-LAW-05).

### 5.9. Giải pháp IPv6

Datahub hỗ trợ IPv6 song song với IPv4 (dual-stack) ở mọi tầng có giao tiếp mạng, đáp ứng nội dung về IPv6 của điểm a khoản 2 Điều 46. Yêu cầu ở tầng phần mềm gồm bốn điểm. Thứ nhất, cổng API và lớp biên lắng nghe trên cả địa chỉ IPv4 và IPv6, và mọi chức năng (xác thực, hạn mức theo địa chỉ, danh sách cho phép, nhật ký) xử lý đúng địa chỉ IPv6. Thứ hai, cụm Kubernetes được cấu hình dual-stack cho pod và service; Cilium hỗ trợ IPv6 đầy đủ, kể cả chính sách mạng. Thứ ba, các trường lưu địa chỉ IP trong CSDL và trong nhật ký dùng kiểu dữ liệu chứa được IPv6 (kiểu `inet` của PostgreSQL), không dùng chuỗi có độ dài cố định cho IPv4. Thứ tư, bộ điều hợp kết nối tới HTTT và nền tảng quốc gia ưu tiên IPv6 khi phía đối tác hỗ trợ, quay về IPv4 khi không.

Yêu cầu IPv6 được đưa vào kế hoạch kiểm thử hệ thống: một bộ kịch bản kiểm thử chức năng chạy hoàn toàn qua IPv6 trên môi trường STAGING. Phần mạng (địa chỉ, định tuyến, tường lửa, đường truyền) ở mục 6.6.

### 5.10. Yêu cầu bảo đảm an ninh mạng

Thiết kế an toàn thông tin và an ninh mạng chi tiết của Datahub được trình bày ở Chương 7, dựa trên D03-07 (thiết kế an toàn thông tin) và D03-08 (hồ sơ đề xuất cấp độ). Mục này chỉ nêu các yêu cầu mà giải pháp công nghệ ở Chương 5 và hạ tầng ở Chương 6 phải thỏa, để hội đồng thấy chúng đã được tính vào thiết kế và vào quy mô.

1. Hệ thống được thiết kế đạt cấp độ 3 theo Nghị định 331/2026/NĐ-CP (CMP-LAW-06) và TCVN 14423:2026 (CMP-LAW-08), và có sẵn các điểm nâng cấp lên cấp độ 4 mà không phải thay kiến trúc: CSDL riêng theo tenant, mô-đun bảo mật phần cứng (HSM) cho khóa ký, hai trung tâm dữ liệu hoạt động song song, mạng quản trị tách riêng (D03-01 §9).
2. Mạng được phân vùng theo chức năng và mức tin cậy, với tường lửa giữa các vùng và chính sách mạng từ chối mặc định bên trong cụm; Chương 6 mục 6.6 thể hiện các vùng và Chương 7 quy định chính sách.
3. Mọi giao tiếp được mã hóa: TLS 1.3 ở biên, mTLS giữa mọi dịch vụ nội bộ qua Istio ambient (NFR-00-020); mọi dữ liệu lưu trữ được mã hóa, trường nhạy cảm được mã hóa ở tầng ứng dụng (NFR-00-021).
4. Định danh và ủy quyền tập trung, MFA bắt buộc cho vai trò quản trị, token ngắn hạn, chính sách ủy quyền theo vai trò, tenant, phân loại dữ liệu và mục đích.
5. Không có bí mật ngoài kho bí mật OpenBao (NFR-00-022, ADR-012).
6. Chuỗi cung ứng phần mềm được kiểm soát: ảnh container ký số, có SBOM, quét lỗ hổng chặn mức nghiêm trọng, chỉ dùng ảnh từ kho Harbor nội bộ (NFR-00-023).
7. Nhật ký kiểm toán chỉ-thêm, có chuỗi băm liên kết, sao vào kho WORM; lưu trực tuyến tối thiểu 12 tháng (NFR-00-027).
8. Hạ tầng phải cung cấp các năng lực an ninh mạng ngoài phạm vi phần mềm: tường lửa thế hệ mới ở biên, chống tấn công từ chối dịch vụ, giám sát an toàn thông tin tập trung của tỉnh (SOC) nhận nhật ký từ Datahub. Danh mục thiết bị ở mục 6.8 nêu các hạng mục này ở mức dung lượng; cấu hình và chính sách do Chương 7 quy định.

### 5.11. Yêu cầu phi chức năng chính theo cỡ quy mô

Bảng dưới đây trình bày chỉ tiêu phi chức năng quan trọng nhất cho ba cỡ tham chiếu S, M, L. Chỉ tiêu tải lấy từ bộ giả định nền §4; chỉ tiêu chất lượng lấy từ D02-02 với mã `NFR-00-nnn`. Đây là chỉ tiêu dùng để tính quy mô hạ tầng ở Chương 6 và để nghiệm thu ở cổng G2 (kiểm thử hiệu năng với cỡ M).

| Chỉ tiêu | Cỡ S | Cỡ M | Cỡ L | Nguồn |
|---|---|---|---|---|
| Số HTTT kết nối | ≤ 80 | ≤ 200 | ≤ 400 | Giả định nền |
| Số API, dịch vụ công bố | ≤ 400 | ≤ 1.000 | ≤ 2.500 | Giả định nền |
| Giao dịch đồng bộ mỗi ngày | 2 triệu | 10 triệu | 30 triệu | Giả định nền |
| Lượt gọi mỗi giây ở đỉnh tại cổng API | 300 | 1.000 | 3.000 | Giả định nền, NFR-00-002 |
| Sự kiện Kafka mỗi ngày | 5 triệu | 25 triệu | 80 triệu | Giả định nền |
| Bản ghi danh mục dùng chung | 2 triệu | 5 triệu | 15 triệu | Giả định nền |
| Giao dịch thanh toán mỗi tháng | 100 nghìn | 400 nghìn | 1,2 triệu | Giả định nền |
| Độ trễ tăng thêm tại cổng API | p95 ≤ 50 ms, p99 ≤ 100 ms | như S | như S | NFR-00-001 |
| Độ trễ do runtime của luồng chuẩn | p95 ≤ 30 ms | như S | như S | NFR-00-007 |
| Độ trễ đầu cuối của sự kiện | p95 ≤ 2 giây | như S | như S | NFR-00-006 |
| Sẵn sàng data plane | 99,9%/tháng | 99,9%/tháng | 99,95%/tháng | NFR-00-010, giả định nền |
| Sẵn sàng control plane | 99,5%/tháng | 99,5%/tháng | 99,5%/tháng | NFR-00-011 |
| Data plane chạy khi control plane ngừng | ≥ 24 giờ | ≥ 24 giờ | ≥ 24 giờ | NFR-00-012 |
| Một nút máy chủ hỏng | Không mất dịch vụ, tự phục hồi ≤ 5 phút | như S | như S | NFR-00-015 |
| RPO | 15 phút | 15 phút | 5 phút | NFR-00-014, giả định nền |
| RTO data plane / control plane | 1 giờ / 4 giờ | 1 giờ / 4 giờ | 1 giờ / 2 giờ | NFR-00-014, giả định nền |
| Nhật ký vận hành trực tuyến | 90 ngày | 90 ngày | 90 ngày | NFR-00-028 |
| Nhật ký kiểm toán | Trực tuyến ≥ 12 tháng, lưu trữ 24 tháng | như S | như S | NFR-00-027, giả định nền |
| Siêu dữ liệu lượt gọi truy vấn được | 12 tháng | 12 tháng | 12 tháng | NFR-00-062 |
| Mở rộng tuyến tính | Gấp đôi tài nguyên data plane cho ≥ 1,8 lần thông lượng | như S | như S | NFR-00-061 |

: Yêu cầu phi chức năng chính theo ba cỡ S, M, L

Bảng dùng RTO 1 giờ cho data plane và 4 giờ cho control plane theo D02-02 (NFR-00-014) và D03-01 §10. Thời hạn lưu nhật ký chia ba loại: nhật ký vận hành 90 ngày (NFR-00-028); nhật ký kiểm toán và siêu dữ liệu lượt gọi trực tuyến 12 tháng (NFR-00-027, NFR-00-062); bản WORM của nhật ký kiểm toán giữ 5 năm trên Ceph RGW (ADR-031). Chương 6 tính dung lượng cho cả ba loại. Ngoài ra, NFR-00-062 đặt quy mô 5 triệu bản ghi mỗi ngày mỗi tenant, thấp hơn 10 triệu giao dịch mỗi ngày của cỡ M; Chương 6 tính theo 10 triệu.

### 5.12. Đa tenant

Mô hình đa tenant đã được quyết định ở D03-10 và ADR-003; Chương 4 mục 4.7 trình bày lý do và chế độ áp dụng cho tỉnh thí điểm. Ở mức thiết kế cơ sở, cần nêu ba điểm để hội đồng thấy đa tenant được thực thi bằng hạ tầng chứ không chỉ bằng mã ứng dụng. Thứ nhất, tenant của mỗi yêu cầu chỉ được xác định từ token đã xác thực do realm Keycloak của tỉnh phát hành, không đọc từ tham số do người gọi gửi. Thứ hai, mỗi tầng có cơ chế cách ly riêng: RLS bắt buộc trong PostgreSQL, tiền tố và ACL trong Kafka, bucket riêng trong kho đối tượng, đường dẫn riêng trong OpenBao, tổ chức riêng trong Grafana, điều kiện tenant trong mọi chính sách OPA. Thứ ba, có hạn mức theo tenant cho lượt gọi, thông lượng sự kiện, dung lượng lưu trữ và số người dùng, để một tỉnh không ảnh hưởng tỉnh khác trên nền tảng dùng chung. Khởi tạo một tenant mới trên nền tảng dùng chung là quy trình tự động, mục tiêu không quá 1 giờ và không quá 1 ngày làm việc tính cả cấu hình (NFR-00-057, KPI-12); khả năng chứa ít nhất 34 tenant trên một nền tảng dùng chung là yêu cầu NFR-00-060.

### 5.13. Yêu cầu kỹ thuật đối với phần mềm nội bộ

#### 5.13.1. Phạm vi phần mềm nội bộ

Phần mềm nội bộ của dự án là toàn bộ mã nguồn do dự án xây dựng: 20 phân hệ trong sáu DU Spring Boot và DU tích hợp Camel Quarkus, hai ứng dụng giao diện, thư viện dùng chung `@datahub/ui`, bộ luồng tích hợp và bộ điều hợp mẫu, chính sách OPA, manifest triển khai Kustomize, công cụ di trú và đối soát. Các thành phần mã nguồn mở bên thứ ba ở mục 5.5.2 không phải phần mềm nội bộ; dự án chỉ cấu hình và tích hợp chúng. Phân biệt này quan trọng vì yêu cầu kỹ thuật và kiểm thử dưới đây áp dụng cho phần mềm nội bộ, và chi phí phát triển ở Chương 8 chỉ tính cho phần này.

Mô tả yêu cầu kỹ thuật dưới đây là phần tương ứng với điểm d khoản 2 Điều 46 và Điều 48 Nghị định 224/2026/NĐ-CP. Nội dung chi tiết của Điều 48 chưa được đối chiếu nguyên văn khi lập chương; các yêu cầu được trình bày theo các nhóm thông thường của đặc tả phần mềm và sẽ được sắp lại nếu điều khoản quy định cấu trúc khác (Q-D0101-47).

#### 5.13.2. Yêu cầu chức năng và quy mô

Yêu cầu chức năng được đặc tả đầy đủ ở D02-02 (cấp hệ thống) và 20 tập D02-03 (cấp phân hệ), có mã truy vết `FR-{PH}-{nnn}`; use case và user story ở D02-04, D02-05. Quy mô phần mềm dùng cho tính chi phí ở Chương 8 được ước lượng từ các tài liệu này theo phương pháp mà văn bản hướng dẫn xác định chi phí hiện hành quy định; khối lượng tham chiếu của bộ giả định nền là khoảng 455 người-tháng cho giai đoạn thực hiện.

#### 5.13.3. Yêu cầu kiến trúc và mã nguồn

Phần mềm nội bộ phải tuân thủ các ràng buộc sau, được kiểm tra tự động trong quy trình tích hợp liên tục:

- Ranh giới module Spring Modulith đạt kiểm tra tự động (NFR-00-054); phân hệ chỉ giao tiếp qua `api`, `events` hoặc REST, không đọc chéo CSDL của nhau.
- Hợp đồng trước, mã sau: mọi API có đặc tả OpenAPI 3.1, mọi sự kiện có đặc tả AsyncAPI 3.0 và schema đăng ký ở Apicurio, trước khi viết mã; giao diện chỉ gọi API qua kiểu dữ liệu sinh từ đặc tả.
- Mọi bảng nghiệp vụ có `tenant_id` và chính sách RLS trong cùng thay đổi cấu trúc; mọi API có ít nhất một ca kiểm thử rò rỉ chéo tenant (D03-10 §6).
- Không có bí mật trong mã, cấu hình, ảnh container (NFR-00-022); không có lỗ hổng phụ thuộc mức CRITICAL khi phát hành (NFR-00-023).
- Độ phủ kiểm thử đơn vị tối thiểu 80% cho mã nghiệp vụ backend, 70% cho giao diện (NFR-00-053).
- Tương thích ngược API trong cùng phiên bản chính, phiên bản cũ được duy trì tối thiểu 6 tháng (NFR-00-055).
- Giao diện đạt WCAG 2.2 mức AA, dùng thống nhất thư viện thành phần (NFR-00-040, NFR-00-045).

#### 5.13.4. Yêu cầu kiểm thử

Phần mềm nội bộ phải được kiểm thử trước nghiệm thu theo quy định về kiểm thử của văn bản hướng dẫn triển khai, giám sát, kiểm thử, nghiệm thu hiện hành (Chương 1 viện dẫn). Kế hoạch kiểm thử tổng thể ở D05-01 gồm sáu cấp: kiểm thử đơn vị, kiểm thử tích hợp (có ca rò rỉ chéo tenant bắt buộc), kiểm thử hợp đồng API, kiểm thử hệ thống, kiểm thử hiệu năng theo chỉ tiêu cỡ M ở mục 5.11 và kiểm thử bảo mật theo OWASP ASVS 5.0 mức 2. Kiểm thử chấp nhận người dùng thực hiện theo từng đợt với đại diện chủ đầu tư. Kiểm thử hiệu năng chạy trên môi trường STAGING ở khoảng một nửa quy mô PROD và được khẳng định bằng một lần kiểm thử ở quy mô đầy đủ trên PROD trước khi vận hành chính thức (mục 6.3).

#### 5.13.5. Yêu cầu tài liệu, bàn giao

Phần mềm nội bộ được bàn giao kèm mã nguồn đầy đủ, kịch bản build tái lập được, SBOM của từng ảnh phát hành, bộ tài liệu theo vòng đời phát triển (D00 đến D06) và hướng dẫn cài đặt, vận hành. Tiêu chí chuyển giao là bên nhận tự build và triển khai lại bản v1.0 từ mã nguồn bàn giao (WBS 1.27.4 tại D01-02). Phương pháp phát triển là lai giữa Scrum (sprint 2 tuần) và cổng nghiệm thu cố định G0 đến G5, mô tả ở D01-02.

### 5.14. Giải pháp di trú theo chiến lược thay thế dần

#### 5.14.1. Cơ chế kỹ thuật

Chương 4 đã chọn chiến lược thay thế dần (strangler). Mục này mô tả cơ chế kỹ thuật thực hiện. Ý tưởng cốt lõi là đặt cổng API của Datahub làm điểm vào duy nhất trước cả hệ cũ lẫn hệ mới, rồi chuyển dần quyền phục vụ của từng nhóm dịch vụ từ hệ cũ sang hệ mới bằng cấu hình định tuyến, không yêu cầu HTTT phải đổi gì ngoài lần đổi địa chỉ đầu tiên.

Cơ chế gồm năm thành phần. **Thành phần thứ nhất là lớp định tuyến**: APISIX được cấu hình route cho mọi điểm cuối của hệ cũ (API Management kiểu Gravitee, các agent Bus, Hub), lúc đầu chỉ chuyển tiếp nguyên trạng tới hệ cũ. HTTT được đổi địa chỉ một lần, từ hệ cũ sang Datahub, hoặc tỉnh đổi bản ghi DNS của tên miền hệ cũ để trỏ về Datahub, khi đó HTTT không phải đổi gì. **Thành phần thứ hai là lớp tương thích**: với dịch vụ mà giao diện của Datahub khác hệ cũ, một luồng Camel chuyển đổi yêu cầu và phản hồi để HTTT cũ tiếp tục gọi theo giao diện cũ. **Thành phần thứ ba là đồng bộ dữ liệu hai chiều trong giai đoạn chuyển tiếp**: danh mục dùng chung của Aita được đọc thay đổi bằng Debezium từ CSDL PostgreSQL của hệ cũ để giữ Datahub đồng bộ cho tới khi danh mục được cắt chuyển; sự kiện từ Pulsar của Hub được cầu nối sang Kafka để subscriber đã chuyển vẫn nhận được sự kiện do publisher chưa chuyển phát ra. **Thành phần thứ tư là chạy song song và đối soát**: trong giai đoạn bóng (shadow), APISIX sao một phần lượt gọi sang Datahub, kết quả của Datahub được so sánh với hệ cũ nhưng không trả cho người gọi; công cụ đối soát của PH-18 báo cáo tỷ lệ khớp. **Thành phần thứ năm là cắt chuyển theo trọng số và quay lui**: khi tỷ lệ khớp đạt ngưỡng, trọng số định tuyến chuyển dần (ví dụ 10%, 50%, 100%) sang Datahub; nếu chỉ số lỗi hoặc độ trễ vượt ngưỡng, trọng số được trả về hệ cũ trong vài giây bằng một thay đổi cấu hình.

```{.mermaid caption="Cơ chế chuyển đổi giữa chừng: định tuyến, luồng tương thích, đồng bộ và đối soát"}
flowchart TB
    HTTT["HTTT sở, ngành<br/>giữ nguyên giao diện cũ"]
    DNS["Tên miền hệ cũ<br/>trỏ về Datahub"]
    subgraph DH["Datahub"]
        GW["APISIX<br/>route theo nhóm dịch vụ<br/>trọng số và sao lượt gọi"]
        COMPAT["Luồng tương thích<br/>Camel chuyển đổi giao diện"]
        NEW["Phân hệ Datahub<br/>PH-02, 04, 07, 10, 14, 19"]
        REC["Đối soát PH-18<br/>so kết quả cũ và mới"]
        CDC["Debezium<br/>đọc thay đổi CSDL Aita"]
        BRIDGE["Cầu nối sự kiện<br/>Pulsar sang Kafka"]
    end
    subgraph OLD["LGSP cũ"]
        OAPI["API Management"]
        OBUS["Bus agent"]
        OHUB["Hub Pulsar"]
        OAITA["Aita danh mục"]
        OPAY["Payment"]
    end
    HTTT --> DNS --> GW
    GW -->|"nhóm chưa chuyển"| OAPI
    GW -->|"nhóm chưa chuyển"| OBUS
    GW -->|"nhóm đã chuyển"| COMPAT --> NEW
    GW -.->|"sao lượt gọi giai đoạn bóng"| REC
    OAITA --> CDC --> NEW
    OHUB --> BRIDGE --> NEW
    OPAY -.->|"tắt sau 30 ngày PH-19 ổn định"| NEW
```

Sơ đồ thể hiện trạng thái giữa chừng của quá trình chuyển đổi: một số nhóm dịch vụ đã chuyển sang Datahub qua luồng tương thích, một số vẫn được chuyển tiếp tới hệ cũ, dữ liệu danh mục và sự kiện được đồng bộ từ hệ cũ sang để hai bên nhất quán. Mũi tên nét đứt từ Payment thể hiện điều kiện tắt riêng của khối thanh toán theo bộ giả định nền.

#### 5.14.2. Vòng đời chuyển đổi của một nhóm dịch vụ

Đơn vị chuyển đổi là nhóm dịch vụ, tức là tập dịch vụ có cùng chủ quản hoặc cùng phụ thuộc dữ liệu, được chuyển cùng nhau. Danh sách nhóm và thứ tự chuyển được lập ở giai đoạn khảo sát dựa trên lưu lượng thực tế và mức độ rủi ro; nguyên tắc chung là chuyển nhóm có lưu lượng thấp và ít phụ thuộc trước để kiểm chứng quy trình, nhóm có lưu lượng cao và nhạy cảm (dân cư, dịch vụ công trực tuyến) sau, thanh toán cuối cùng ở đợt 2. Mỗi nhóm đi qua các trạng thái dưới đây, và chỉ chuyển trạng thái khi đạt tiêu chí định lượng.

```{.mermaid caption="Sơ đồ trạng thái vòng đời chuyển đổi của một nhóm dịch vụ"}
stateDiagram-v2
    [*] --> ChuanBi: Lập ánh xạ và luồng
    ChuanBi --> Bong: Kiểm thử STAGING đạt
    Bong --> CatChuyenDan: Tỷ lệ khớp đạt ngưỡng
    Bong --> ChuanBi: Sai khác cần sửa
    CatChuyenDan --> DaChuyen: Trọng số 100 phần trăm ổn định
    CatChuyenDan --> Bong: Vượt ngưỡng lỗi, quay lui
    DaChuyen --> DongHeCu: Giám sát 30 ngày không sự cố
    DongHeCu --> [*]
```

Sơ đồ trạng thái có ba nhánh quay lui rõ ràng: từ giai đoạn bóng về chuẩn bị khi đối soát phát hiện sai khác, từ cắt chuyển dần về giai đoạn bóng khi chỉ số lỗi vượt ngưỡng, và trong suốt quá trình hệ cũ vẫn chạy nên quay lui không làm mất dữ liệu. Bảng dưới đây nêu tiêu chí chuyển trạng thái đề xuất; giá trị chính thức được chốt trong kế hoạch di trú ở bước thiết kế chi tiết.

| Chuyển trạng thái | Tiêu chí đề xuất |
|---|---|
| Chuẩn bị sang Bóng | Luồng tương thích qua kiểm thử hợp đồng với giao diện cũ; ánh xạ dữ liệu được đầu mối nghiệp vụ xác nhận |
| Bóng sang Cắt chuyển dần | Tối thiểu 7 ngày làm việc ở giai đoạn bóng; tỷ lệ phản hồi khớp ≥ 99,9% sau khi loại trừ khác biệt đã được chấp nhận |
| Cắt chuyển dần sang Đã chuyển | Mỗi bậc trọng số giữ tối thiểu 2 ngày làm việc; tỷ lệ lỗi do nền tảng < 0,1%; độ trễ trong chỉ tiêu mục 5.11 |
| Đã chuyển sang Đóng hệ cũ | 30 ngày không có sự cố mức nghiêm trọng liên quan nhóm dịch vụ; HTTT đã được cấp lại thông tin xác thực mới |

: Tiêu chí chuyển trạng thái của nhóm dịch vụ trong vòng đời chuyển đổi

Thời gian gián đoạn mỗi lần cắt chuyển một nhóm được giới hạn ở mức không quá 15 phút (đề xuất của D01-02), và trên thực tế thường bằng không vì cắt chuyển chỉ là thay đổi trọng số định tuyến. Toàn bộ khóa và mật khẩu kết nối của hệ cũ được cấp lại khi chuyển, không sao chép sang Datahub, để khắc phục điểm nghẽn ĐN-04 (bí mật ở dạng rõ).

### Câu hỏi mở

Các câu hỏi dưới đây liên quan đến kiến trúc chuyển đổi số của tỉnh, nội dung các điều khoản chưa xác minh và điều kiện kỹ thuật của phương án thay thế dần; câu trả lời quyết định mức chi tiết cần bổ sung cho thiết kế cơ sở.

- **Q-D0101-45.** Tỉnh thí điểm đã ban hành kiến trúc chuyển đổi số (kiến trúc chính quyền số) cấp tỉnh hay chưa? Nếu có, cần bản hiện hành để đối chiếu ở mục 5.7.
- **Q-D0101-46.** Nội dung khoản 1 Điều 21 Nghị định 194/2025/NĐ-CP quy định những trường thông tin nào cho hạng mục kết nối, chia sẻ cơ sở dữ liệu? Bảng ở mục 5.8.3 cần được đối chiếu để bảo đảm đủ trường.
- **Q-D0101-47.** Điều 48 Nghị định 224/2026/NĐ-CP quy định nội dung mô tả yêu cầu kỹ thuật phần mềm nội bộ theo cấu trúc nào? Mục 5.13 cần được sắp xếp lại theo cấu trúc đó nếu khác.
- **Q-D0101-48.** Tỉnh có chấp nhận phương án đổi bản ghi DNS của tên miền hệ cũ để trỏ về Datahub (HTTT không phải đổi địa chỉ) không? Nếu tên miền và chứng thư số của hệ cũ do nhà cung cấp cũ quản lý, cần thủ tục bàn giao.
- **Q-D0101-49.** Đơn vị vận hành hệ cũ có đồng ý cho Datahub đọc thay đổi CSDL PostgreSQL của khối Aita (cần quyền nhân bản lô-gic) và kết nối vào Pulsar của khối Hub trong giai đoạn chuyển tiếp không?


## 6. Giải pháp hạ tầng kỹ thuật

> **Tóm tắt cho hội đồng thẩm định.** Chương này là phần hạ tầng của thiết kế cơ sở: hiện trạng, mô hình vật lý, năm môi trường, cấu hình tham chiếu cho ba cỡ tỉnh, mạng và kết nối, sao lưu và dự phòng thảm họa, danh mục thiết bị, chỉ tiêu lắp đặt, kiểm tra, khối lượng và đào tạo. Với tỉnh thí điểm cỡ M, tổng nhu cầu của cả năm môi trường là **88 node Kubernetes, 866 vCPU, 2.528 GB RAM, 29,5 TB SSD và 66 TB HDD**, trong đó PROD chiếm 360 vCPU, 1.024 GB RAM, 13,2 TB SSD, 32 TB HDD; site DR 204 vCPU, 608 GB RAM, 7,5 TB SSD, 24 TB HDD; ba môi trường phụ (STAGING, TEST, DEV) 302 vCPU, 896 GB RAM, 8,8 TB SSD, 10 TB HDD. Theo phương án hạ tầng khuyến nghị ở Chương 4, nhu cầu này quy ra 9 máy chủ vật lý hai bộ xử lý (4 cho PROD, 3 cho DR, 2 cho STAGING) cộng thuê cloud chính phủ cho DEV và TEST; nếu toàn bộ đặt trên cloud chính phủ thì dùng bảng quy đổi ở mục 6.7. Con số được tính từ tài nguyên yêu cầu của từng thành phần phần mềm ở tải đỉnh cỡ M, cộng dự phòng một nút hỏng; tệp `_ha-tang-sizing.csv` chứa đủ số liệu theo từng vai trò để Chương 8 tính chi phí.

### 6.1. Hiện trạng hạ tầng

Hệ LGSP cũ đặt tại trung tâm dữ liệu tỉnh thí điểm. Theo hồ sơ cài đặt (Chương 2 mục 2.1.2 và 2.2.5), mỗi khối chức năng được cài trên một máy chủ riêng cấu hình tối thiểu Intel Xeon E5-2670 v3, 32 GB RAM, một ổ SSD 120 GB và hai ổ SATA 1 TB, hai cổng mạng 1 Gbps, hệ điều hành CentOS 6, Tomcat và PostgreSQL 13 cài chung trên máy. Hồ sơ hàm ý tối thiểu sáu máy chủ ứng dụng, chưa kể các máy chủ cho Pulsar, cổng API, Keycloak và Graylog; số máy thực tế, vị trí tủ rack, đường truyền và năng lực còn trống của trung tâm dữ liệu chưa được khảo sát (Q-D0101-21, Q-D0101-23 tại Chương 2). Sơ đồ sơ bộ dưới đây dựng lại hiện trạng từ hồ sơ để làm căn cứ cho phương án chuyển đổi; nó sẽ được thay bằng sơ đồ khảo sát thực tế ở bước thiết kế chi tiết.

```{.mermaid caption="Hiện trạng hạ tầng hệ LGSP cũ tại trung tâm dữ liệu tỉnh"}
flowchart TB
    subgraph NGOAI["Bên ngoài"]
        NGSP["NGSP, nay là NDXP"]
        PG["PayGov"]
    end
    subgraph TTDL["TTDL tỉnh thí điểm - hiện trạng theo hồ sơ"]
        FW["Tường lửa biên<br/>chưa khảo sát"]
        S1["Máy chủ Bus<br/>Tomcat, Camel, PostgreSQL 13"]
        S2["Máy chủ Productivity Tooling"]
        S3["Máy chủ Hub<br/>Apache Pulsar"]
        S4["Máy chủ API Management"]
        S5["Máy chủ Aita danh mục"]
        S6["Máy chủ Payment"]
        S7["Máy chủ Keycloak, Graylog<br/>không có hướng dẫn cài đặt"]
    end
    HTTT["HTTT sở, ngành"]
    HTTT --> FW
    FW --> S4
    S4 --> S1
    S1 --> S3
    S1 --> S5
    S6 --> PG
    S1 -->|"HTTP theo phụ lục kết nối"| NGSP
    S2 --> S1
    S7 --> S4
```

Sơ đồ cho thấy ba đặc điểm hạ tầng mà giải pháp mới phải khắc phục: mỗi khối là một điểm hỏng đơn lẻ, không có site dự phòng, và kết nối quốc gia theo phụ lục cũ đi qua giao thức không mã hóa. Khi chuyển đổi, các máy chủ này tiếp tục chạy đến khi nhóm dịch vụ cuối cùng được cắt chuyển (tối đa đến G5), sau đó được thu hồi; báo cáo không tính tái sử dụng chúng cho Datahub vì cấu hình (bộ xử lý thế hệ 2014, 32 GB RAM, cổng 1 Gbps) không đáp ứng yêu cầu của nút Kubernetes ở mục 6.5.

### 6.2. Mô hình triển khai vật lý

Mô hình vật lý theo phương án khuyến nghị ở Chương 4 mục 4.6.3 gồm ba địa điểm: site chính tại trung tâm dữ liệu tỉnh chứa PROD và STAGING; site dự phòng chứa DR (trung tâm dữ liệu thứ hai của tỉnh, hoặc một vùng cloud chính phủ nếu tỉnh không có site thứ hai); và cloud chính phủ chứa DEV, TEST. Sơ đồ dưới đây thể hiện các địa điểm, các cụm Kubernetes và các đường kết nối chính.

```{.mermaid caption="Mô hình triển khai vật lý tại site chính, site dự phòng và cloud"}
flowchart TB
    subgraph NET["Mạng bên ngoài"]
        INET["Internet<br/>hai nhà cung cấp"]
        TSLCD["Mạng truyền số liệu chuyên dùng"]
        NDXP["NDXP, NDOP, VNeID, PayGov"]
    end
    subgraph SITE1["Site chính - TTDL tỉnh, H1"]
        FW1["Tường lửa biên HA"]
        subgraph PROD["Cụm PROD - 4 máy chủ, 30 node cỡ M"]
            P1["Vùng biên<br/>worker biên"]
            P2["Vùng ứng dụng và tích hợp"]
            P3["Vùng dữ liệu<br/>PostgreSQL, Kafka, kho đối tượng"]
            P4["Vùng quản trị và quan sát"]
        end
        subgraph STG["Cụm STAGING - 2 máy chủ, 22 node cỡ M"]
            ST1["Bản thu nhỏ PROD"]
        end
    end
    subgraph SITE2["Site dự phòng - H1 site thứ hai hoặc H2"]
        FW2["Tường lửa biên HA"]
        subgraph DR["Cụm DR warm standby - 3 máy chủ, 19 node cỡ M"]
            D1["Data plane chạy sẵn"]
            D2["Bản sao CSDL, Kafka, kho đối tượng"]
        end
        BK["Thiết bị sao lưu độc lập<br/>khóa bất biến"]
    end
    subgraph CLOUD["Cloud chính phủ - H2"]
        DEV["Cụm DEV - 5 node"]
        TEST["Cụm TEST - 12 node"]
    end
    HTTT["HTTT sở, ngành, xã"]
    INET --> FW1
    TSLCD --> FW1
    INET --> FW2
    TSLCD --> FW2
    FW1 --> P1
    FW2 --> D1
    HTTT --> TSLCD
    P1 --> NDXP
    P3 -->|"nhân bản bất đồng bộ<br/>kênh riêng PROD - DR"| D2
    P3 -->|"sao lưu hằng ngày"| BK
    TEST -.->|"không dữ liệu thật"| DEV
```

Sơ đồ có ba điểm cần lưu ý. Thứ nhất, PROD và STAGING là hai cụm Kubernetes riêng trên hai nhóm máy chủ riêng, không chia sẻ máy chủ, để thử nghiệm trên STAGING không thể ảnh hưởng PROD; hai cụm chỉ dùng chung tủ rack và thiết bị mạng với phân tách VLAN và vùng tường lửa. Thứ hai, site DR có đường vào riêng từ Internet và mạng truyền số liệu chuyên dùng, nên khi site chính mất hoàn toàn, lưu lượng chuyển sang DR bằng thay đổi DNS hoặc định tuyến mà không phụ thuộc thiết bị nào ở site chính. Thứ ba, DEV và TEST nằm ngoài trung tâm dữ liệu tỉnh và không bao giờ chứa dữ liệu thật; STAGING đặt cùng điều kiện an toàn với PROD vì được dùng diễn tập di trú bằng dữ liệu đã che (Chương 3 mục 3.5).

### 6.3. Các môi trường

Datahub dùng năm môi trường theo bộ giả định nền §4. Bảng dưới đây nêu mục đích, vị trí, quy mô so với PROD và thời điểm cần có. Thời điểm cần có là thông tin quan trọng cho Chương 8 vì nó quyết định số tháng thuê hoặc thời điểm mua sắm.

| Môi trường | Mục đích | Vị trí khuyến nghị | Quy mô so với PROD | Cần có từ | Dữ liệu |
|---|---|---|---|---|---|
| DEV | Phát triển, chạy thử của đội nhà thầu, nhánh tính năng | H2 (hoặc hạ tầng nhà thầu ở W0 đến W2) | Cố định, nhỏ (5 node) | T0 | Giả lập |
| TEST | Kiểm thử tích hợp, hợp đồng API, kiểm thử tự động mỗi sprint, giả lập NDXP và PayGov | H2 | Cố định (12 node) | T0+1 | Giả lập |
| STAGING | Kiểm thử hệ thống, hiệu năng, ATTT, UAT, diễn tập di trú và nâng cấp | H1 site chính | Khoảng 50% PROD | T0+6 (đầu W2) | Đã che |
| PROD | Vận hành chính thức | H1 site chính | 100% | T0+9 (cài đặt trước W3 ở T0+10) | Thật |
| DR | Dự phòng thảm họa, ấm (warm standby) | H1 site thứ hai hoặc H2 vùng khác | Khoảng 50–60% PROD | T0+11 (trước cắt chuyển nhóm dịch vụ lớn đầu tiên) | Bản sao thật |

: Các môi trường DEV, TEST, STAGING, PROD, DR: mục đích, vị trí, quy mô và dữ liệu

Môi trường phụ (DEV, TEST, STAGING) có cấu hình cố định đối với DEV, TEST vì tải của chúng phụ thuộc đội phát triển chứ không phụ thuộc quy mô tỉnh; STAGING thay đổi theo cỡ vì phải tái hiện cấu trúc PROD đủ để kiểm thử hiệu năng có ý nghĩa. Kiểm thử hiệu năng chạy trên STAGING ở khoảng một nửa quy mô và được ngoại suy dựa trên chỉ tiêu mở rộng tuyến tính (NFR-00-061); trước vận hành chính thức có một lần kiểm thử ở quy mô đầy đủ trên PROD khi PROD chưa nhận lưu lượng thật. Sau giai đoạn bảo hành, DEV và TEST có thể thu gọn về một cụm duy nhất phục vụ bảo trì; Chương 8 nên tính kịch bản này từ Năm 3.

### 6.4. Phương pháp tính quy mô

#### 6.4.1. Nguyên tắc

Quy mô hạ tầng được tính từ dưới lên, theo bốn bước. Bước thứ nhất là xác định tài nguyên yêu cầu (request) của từng thành phần phần mềm ở tải đỉnh của từng cỡ, dựa trên chỉ tiêu tải ở mục 5.11 và đặc tính đã biết của từng sản phẩm (ví dụ một bản sao APISIX 2 vCPU xử lý khoảng vài nghìn lượt gọi mỗi giây với cấu hình plugin điển hình; để có biên an toàn, báo cáo tính 170 lượt mỗi giây mỗi vCPU tính cả WAF và gọi OPA). Bước thứ hai là gom thành phần vào các nhóm node theo vai trò, vì mỗi nhóm có yêu cầu khác nhau về mạng, lưu trữ và vùng an ninh. Bước thứ ba là tính số node cho mỗi nhóm sao cho mức dùng khi đủ node không vượt khoảng 75–85%, và khi mất một node vẫn đủ chỗ chạy toàn bộ bản sao; số node tối thiểu của mỗi nhóm trong PROD là 3 để trải đều ba miền lỗi (failure domain). Bước thứ tư là tính dung lượng lưu trữ từ khối lượng dữ liệu theo ngày và thời gian lưu giữ.

Cách tính này cho kết quả thận trọng ở hai điểm, được chủ động chấp nhận. Một là dự trữ co giãn: nhóm worker tích hợp được cộng thêm 30% vCPU của các luồng Camel để KEDA tăng bản sao khi độ trễ tiêu thụ Kafka tăng đột biến. Hai là ánh xạ vCPU của node ảo sang luồng xử lý vật lý theo tỷ lệ 1:1 cho PROD và DR (không bán vượt), tỷ lệ 2:1 cho môi trường phụ.

#### 6.4.2. Tài nguyên yêu cầu theo thành phần, cỡ M

Bảng dưới đây là ví dụ của bước thứ nhất cho cỡ M, nhóm theo vai trò node. Số bản sao nhân với vCPU và RAM của mỗi bản sao cho tài nguyên yêu cầu của nhóm; các cỡ S và L được tính tương tự với số bản sao khác (có trong bản tính lưu kèm hồ sơ).

| Nhóm node | Thành phần, số bản sao × (vCPU, GB RAM) | Tổng yêu cầu | Cấu hình node | Số node | Mức dùng CPU / RAM |
|---|---|---|---|---|---|
| Worker biên | APISIX và Coraza WAF 6 × (2; 2) | 12 vCPU; 12 GB | 8 vCPU; 16 GB | 3 | 57% / 29% |
| Worker ứng dụng | `dh-connect` 3 × (2; 4), `dh-platform` 3 × (2; 4), `dh-data` 3 × (2; 4), `dh-integration` 2 × (2; 4), `dh-payment` 2 × (2; 4), `dh-assist` 2 × (2; 4), Keycloak 3 × (2; 4), OPA 3 × (0,5; 0,5), OpenBao 3 × (1; 2), Valkey 6 × (1; 4), Apicurio 2 × (1; 2), giao diện 4 × (1; 2) | 52,5 vCPU; 115,5 GB | 16 vCPU; 32 GB | 5 | 70% / 77% |
| Worker tích hợp | `dh-runtime` đồng bộ 9 × (2; 2), bất đồng bộ 6 × (2; 2), kết nối quốc gia 3 × (2; 2), runtime bộ điều hợp 4 × (1; 2), Kafka Connect và Debezium 3 × (2; 4), dự trữ KEDA 11 vCPU, 11 GB | 57 vCPU; 67 GB | 16 vCPU; 32 GB | 5 | 76% / 45% |
| Quan sát và quản trị | OpenSearch 3 × (4; 16), Prometheus hoặc Mimir 2 × (2; 8), Loki 3 × (2; 4), Tempo 2 × (1; 4), Grafana 3 × (0,5; 1), OTel Collector 3 × (1; 2), Argo CD 1 × (4; 8), Harbor và Trivy 1 × (4; 8), các operator 1 × (3; 6) | 39,5 vCPU; 115 GB | 16 vCPU; 64 GB | 4 | 66% / 46% |

: Tài nguyên yêu cầu theo nhóm node và thành phần, ví dụ cỡ M

Mức dùng khi đủ node được giữ ở 57–77%, nghĩa là khi một máy chủ vật lý hỏng và các node trên đó mất đi, các node còn lại vẫn chứa được toàn bộ bản sao với mức dùng khoảng 85–95%, đáp ứng yêu cầu "một nút hỏng không mất dịch vụ" (NFR-00-015). Nhóm worker biên có RAM dùng thấp vì APISIX nặng về CPU; cấu hình 8 vCPU, 16 GB là cấu hình nhỏ nhất hợp lý cho node Kubernetes trong vùng biên.

PostgreSQL, Kafka và kho đối tượng chạy trên nhóm node dữ liệu riêng (có taint để chỉ thành phần dữ liệu được đặt lên), vì chúng cần ổ SSD cục bộ hiệu năng cao và không được chia sẻ CPU với ứng dụng. Cỡ M dùng 3 node PostgreSQL 16 vCPU, 64 GB (một primary, hai standby đồng bộ), 3 broker Kafka 8 vCPU, 32 GB, và 4 node kho đối tượng.

#### 6.4.3. Dung lượng lưu trữ

Bảng dưới đây trình bày căn cứ tính dung lượng cho cỡ M. Các hệ số kích thước bản tin là giả định thiết kế, sẽ được hiệu chỉnh bằng số liệu thực tế của hệ cũ (Q-D0101-24 tại Chương 2).

| Loại dữ liệu | Căn cứ tính (cỡ M) | Dung lượng cần | Đặt tại |
|---|---|---|---|
| Kafka | 25 triệu sự kiện × 2 KB + 10 triệu bản ghi giao dịch × 1 KB = 60 GB/ngày; lưu 7 ngày; nhân bản 3 | 1,26 TB, tức 47% của 3 × 0,9 TB khả dụng | SSD node Kafka |
| PostgreSQL | Danh mục 5 triệu bản ghi nhiều phiên bản, dữ liệu chủ, giao dịch thanh toán 5 năm (400 nghìn mỗi tháng), cấu hình, quy trình, kiểm toán quản trị 12 tháng, chỉ mục | Khoảng 0,5 TB ở Năm 5, tức 50% của 1 TB mỗi node | SSD node PostgreSQL |
| Nhật ký giao dịch tìm kiếm nhanh | 10 triệu × 1,5 KB = 15 GB/ngày; 90 ngày; 1 bản sao; ngưỡng đầy 85% | Khoảng 3,5 TB | SSD node quan sát |
| Siêu dữ liệu lượt gọi truy vấn 12 tháng | 10 triệu × khoảng 60 byte sau nén × 365 ngày; 2 bản sao | Khoảng 0,45 TB | SSD node quan sát |
| Chỉ số giám sát | 90 ngày | Khoảng 0,3 TB | SSD node quan sát |
| Bản WORM nhật ký kiểm toán 5 năm (ADR-031) | 10 triệu × 0,4 KB = 4 GB/ngày × 1.825 ngày, nén khoảng 2,5 lần | 2,9 TB khả dụng | Ceph RGW, Object Lock chế độ compliance |
| Sao lưu CSDL | 4 bản toàn phần hằng tuần nén, WAL 30 ngày | Khoảng 1,4 TB khả dụng | Kho đối tượng Garage |
| Bản tin lớn lưu tạm (claim check), hàng đợi lỗi | 2% giao dịch × 500 KB × 7 ngày | 0,7 TB khả dụng | Garage |
| Nhật ký vận hành 90 ngày (NFR-00-028) | Khoảng 20 GB/ngày trước nén, nén khoảng 5 lần | 0,36 TB khả dụng | Garage (Loki) |
| Truy vết, ảnh container, tệp nghiệp vụ | Truy vết lấy mẫu 14 ngày, kho ảnh, tệp nhập danh mục và đối soát | Khoảng 0,9 TB khả dụng | Garage |

: Dung lượng lưu trữ theo loại dữ liệu và nơi đặt, cỡ M

Tổng dung lượng khả dụng cần trên kho đối tượng cỡ M là khoảng 6,3 TB; với hệ số nhân bản 3 của Garage và của Ceph RGW, dung lượng thô cần khoảng 19 TB, tức 59% của 32 TB HDD thô bố trí cho 4 node kho đối tượng PROD, phần còn lại dành cho tăng trưởng trong vòng đời năm năm. Nhóm node quan sát cỡ M có 4,8 TB SSD, mức dùng dự kiến khoảng 88% nếu chạy đồng thời kho tìm kiếm nhật ký 90 ngày và kho siêu dữ liệu 12 tháng; đây là điểm cần theo dõi, và quyết định ở SDD PH-13 về việc chọn một kho chính (OpenSearch hay ClickHouse) có thể giảm đáng kể mức này. Nếu SDD giữ cả hai, cần bổ sung khoảng 1 TB SSD cho mỗi node quan sát từ Năm 2.

#### 6.4.4. Băng thông

Băng thông đỉnh ra vào site chính cỡ M được ước tính theo ba thành phần: lượt gọi đồng bộ 1.000 mỗi giây × 8 KB (yêu cầu cộng phản hồi) là 64 Mbps; sự kiện đẩy ra ngoài khoảng 1.000 mỗi giây ở đỉnh (25 triệu mỗi ngày, hệ số đỉnh 3,5) × 2 KB là 16 Mbps; bản tin lớn và tệp 2% lượt gọi × 500 KB là 80 Mbps. Tổng khoảng 160 Mbps, nhân hệ số dự phòng 1,5 cho mã hóa và đột biến, ra khoảng 250 Mbps; đường truyền khuyến nghị ở mục 6.6.4 được làm tròn lên mức gói cước phổ biến. Cỡ S và L được tính tương tự, lần lượt khoảng 46 Mbps và 484 Mbps trước hệ số dự phòng.

### 6.5. Bảng cấu hình tham chiếu cỡ S, M, L

Mục này là đầu vào chính cho Chương 8. Mỗi dòng là một vai trò node trong một môi trường; số liệu chi tiết cùng cấu trúc nằm trong tệp `_ha-tang-sizing.csv` (cột: cỡ, môi trường, vai trò, số node, vCPU mỗi node, RAM GB mỗi node, SSD TB mỗi node, HDD TB mỗi node). Cách đọc ô: "3 × (8; 16; 0,1)" là 3 node, mỗi node 8 vCPU, 16 GB RAM, 0,1 TB SSD; HDD ghi thêm khi có.

#### 6.5.1. PROD

| Vai trò | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| Control plane Kubernetes | 3 × (4; 8; 0,1) | 3 × (8; 16; 0,1) | 3 × (8; 32; 0,1) |
| Worker biên | 3 × (4; 8; 0,1) | 3 × (8; 16; 0,1) | 6 × (8; 16; 0,1) |
| Worker ứng dụng | 4 × (16; 32; 0,1) | 5 × (16; 32; 0,1) | 7 × (16; 64; 0,1) |
| Worker tích hợp | 3 × (16; 32; 0,1) | 5 × (16; 32; 0,1) | 10 × (16; 32; 0,1) |
| Node PostgreSQL | 3 × (8; 32; 0,5) | 3 × (16; 64; 1) | 3 × (32; 128; 2) |
| Broker Kafka | 3 × (4; 16; 0,3) | 3 × (8; 32; 1) | 5 × (16; 64; 1,5) |
| Node kho đối tượng | 3 × (4; 8; 0,2; HDD 3) | 4 × (4; 16; 0,2; HDD 8) | 6 × (8; 32; 0,3; HDD 12) |
| Node quan sát và quản trị | 4 × (8; 32; 0,4) | 4 × (16; 64; 1,2) | 6 × (16; 64; 2,1) |
| **Tổng PROD** | **26 node; 216 vCPU; 568 GB; 5,9 TB SSD; 9 TB HDD** | **30 node; 360 vCPU; 1.024 GB; 13,2 TB SSD; 32 TB HDD** | **46 node; 664 vCPU; 2.240 GB; 30,5 TB SSD; 72 TB HDD** |

: Cấu hình tham chiếu môi trường PROD theo vai trò, cỡ S, M, L

Từ S lên L, thành phần tăng mạnh nhất là worker tích hợp (từ 3 lên 10 node) và worker biên (từ 3 lên 6), phản ánh đúng việc lưu lượng tăng 10 lần; các DU control plane chỉ tăng nhẹ. Node PostgreSQL ở cỡ L được tăng cấu hình theo chiều dọc (32 vCPU, 128 GB) thay vì tăng số node, vì CSDL quản trị của Datahub có tải ghi thấp và lợi ích của bản sao đọc thêm không lớn.

#### 6.5.2. DR

Site DR ở trạng thái ấm: data plane (worker biên, worker tích hợp) và các DU thiết yếu chạy sẵn với số bản sao tối thiểu, CSDL, Kafka, kho đối tượng nhận bản sao liên tục. Quy mô tính toán ở khoảng 50% (S, M) và 70% (L) tài nguyên yêu cầu của PROD cho nhóm ứng dụng, tích hợp và biên; khi chuyển sang DR, KEDA và HPA tăng bản sao trong giới hạn tài nguyên có sẵn, và các lượt gọi thuộc nhóm ưu tiên thấp bị hạn mức chặt hơn. Nhóm dữ liệu giữ nguyên cấu hình node của PROD (bớt một node PostgreSQL) để chịu được toàn bộ tải ghi.

| Vai trò | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| Control plane Kubernetes | 3 × (4; 8; 0,1) | 3 × (8; 16; 0,1) | 3 × (8; 32; 0,1) |
| Worker biên | 2 × (4; 8; 0,1) | 2 × (8; 16; 0,1) | 3 × (8; 16; 0,1) |
| Worker ứng dụng | 2 × (16; 32; 0,1) | 2 × (16; 32; 0,1) | 4 × (16; 64; 0,1) |
| Worker tích hợp | 2 × (16; 32; 0,1) | 2 × (16; 32; 0,1) | 7 × (16; 32; 0,1) |
| Node PostgreSQL | 2 × (8; 32; 0,5) | 2 × (16; 64; 1) | 2 × (32; 128; 2) |
| Broker Kafka | 3 × (4; 16; 0,3) | 3 × (8; 32; 1) | 3 × (16; 64; 1,5) |
| Node kho đối tượng | 3 × (4; 8; 0,2; HDD 3) | 3 × (4; 16; 0,2; HDD 8) | 4 × (8; 32; 0,3; HDD 12) |
| Node quan sát và quản trị | 2 × (8; 32; 0,2) | 2 × (16; 64; 0,5) | 3 × (16; 64; 1) |
| **Tổng DR** | **19 node; 140 vCPU; 368 GB; 3,8 TB SSD; 9 TB HDD** | **19 node; 204 vCPU; 608 GB; 7,5 TB SSD; 24 TB HDD** | **29 node; 416 vCPU; 1.392 GB; 14,4 TB SSD; 48 TB HDD** |

: Cấu hình tham chiếu site DR theo vai trò, cỡ S, M, L

Ở cỡ M, DR có 4 worker ứng dụng và tích hợp (64 vCPU) so với 10 ở PROD; với mức dùng thực tế của PROD khoảng 70–76% ở đỉnh, DR phục vụ được khoảng 60% lưu lượng đỉnh cỡ M mà không cần tăng tài nguyên, đủ cho lưu lượng giờ thường và cho nhóm dịch vụ thiết yếu ở giờ cao điểm. Nếu chủ đầu tư yêu cầu DR chịu 100% tải đỉnh, nhóm worker DR phải bằng PROD (thêm khoảng 96 vCPU, 192 GB cho cỡ M); báo cáo không khuyến nghị vì chi phí tăng khoảng một phần ba cho một tình huống hiếm (Q-D0101-50).

#### 6.5.3. Môi trường phụ

STAGING tái hiện đủ các vai trò của PROD ở quy mô nhỏ hơn; TEST và DEV có cấu hình cố định cho mọi cỡ, gộp dịch vụ dữ liệu vào node "dữ liệu gộp".

| Môi trường | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| STAGING | 20 node; 130 vCPU; 352 GB; 3 TB SSD; 3 TB HDD | 22 node; 182 vCPU; 480 GB; 4,8 TB SSD; 6 TB HDD | 25 node; 280 vCPU; 896 GB; 8,2 TB SSD; 12 TB HDD |
| TEST | 12 node; 84 vCPU; 280 GB; 2,8 TB SSD; 3 TB HDD | như S | như S |
| DEV | 5 node; 36 vCPU; 136 GB; 1,2 TB SSD; 1 TB HDD | như S | như S |
| **Tổng môi trường phụ** | **37 node; 250 vCPU; 768 GB; 7 TB SSD; 7 TB HDD** | **39 node; 302 vCPU; 896 GB; 8,8 TB SSD; 10 TB HDD** | **42 node; 400 vCPU; 1.312 GB; 12,2 TB SSD; 16 TB HDD** |

: Cấu hình tham chiếu các môi trường phụ theo cỡ S, M, L

Chi tiết vai trò của từng môi trường phụ có trong tệp CSV. TEST gồm 3 node control plane (4; 8), 3 worker ứng dụng (8; 32), 2 worker tích hợp (8; 16), 3 node dữ liệu gộp (8; 32; 0,5 SSD; 1 HDD) và 1 node quan sát (8; 32; 0,5); DEV gồm 1 node control plane, 3 worker và 1 node dữ liệu gộp.

#### 6.5.4. Tổng hợp

| Nhóm | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| PROD | 26 node; 216 vCPU; 568 GB; 5,9 TB SSD; 9 TB HDD | 30 node; 360 vCPU; 1.024 GB; 13,2 TB SSD; 32 TB HDD | 46 node; 664 vCPU; 2.240 GB; 30,5 TB SSD; 72 TB HDD |
| DR | 19 node; 140 vCPU; 368 GB; 3,8 TB SSD; 9 TB HDD | 19 node; 204 vCPU; 608 GB; 7,5 TB SSD; 24 TB HDD | 29 node; 416 vCPU; 1.392 GB; 14,4 TB SSD; 48 TB HDD |
| Môi trường phụ | 37 node; 250 vCPU; 768 GB; 7 TB SSD; 7 TB HDD | 39 node; 302 vCPU; 896 GB; 8,8 TB SSD; 10 TB HDD | 42 node; 400 vCPU; 1.312 GB; 12,2 TB SSD; 16 TB HDD |
| **Tổng cộng** | **82 node; 606 vCPU; 1.704 GB; 16,7 TB SSD; 25 TB HDD** | **88 node; 866 vCPU; 2.528 GB; 29,5 TB SSD; 66 TB HDD** | **117 node; 1.480 vCPU; 4.944 GB; 57,1 TB SSD; 136 TB HDD** |

: Tổng hợp node, vCPU, RAM và lưu trữ của PROD, DR và môi trường phụ theo cỡ

Từ S lên M, tổng vCPU tăng 43% trong khi lưu lượng tăng 5 lần, và từ M lên L tăng 71% cho lưu lượng gấp 3 lần. Nguyên nhân là phần cố định (control plane Kubernetes, quan sát, môi trường phụ, số bản sao tối thiểu cho sẵn sàng cao) chiếm tỷ trọng lớn ở cỡ nhỏ. Hệ quả cho chiến lược nhân rộng là các tỉnh cỡ S có chi phí hạ tầng trên mỗi giao dịch cao nhất, và chính họ được lợi nhiều nhất từ nền tảng dùng chung ở chế độ `SHARED` (Chương 4 mục 4.7).

### 6.6. Mạng, phân vùng và kết nối

#### 6.6.1. Phân vùng mạng

Mạng của mỗi site được chia thành các vùng theo chức năng và mức tin cậy, mỗi vùng là một VLAN hoặc dải mạng riêng, giữa các vùng có tường lửa với chính sách từ chối mặc định. Bên trong cụm Kubernetes, ranh giới vùng được thực thi thêm bằng nhóm node có taint, namespace và chính sách mạng Cilium, cùng mTLS của Istio ambient. Chính sách cụ thể giữa các vùng do Chương 7 quy định; sơ đồ dưới đây là sơ đồ kết nối sơ bộ.

```{.mermaid caption="Phân vùng mạng và chính sách kết nối giữa các vùng"}
flowchart TB
    subgraph Z0["Vùng ngoài"]
        I1["Internet"]
        I2["Mạng truyền số liệu chuyên dùng"]
    end
    subgraph Z1["Vùng biên DMZ"]
        FWE["Tường lửa thế hệ mới HA<br/>chống DDoS"]
        LB["Địa chỉ dịch vụ ảo<br/>IPv4 và IPv6"]
        WB["Worker biên<br/>APISIX apisix-ext, WAF Coraza"]
    end
    subgraph Z2["Vùng ứng dụng"]
        WA["Worker ứng dụng<br/>DU Spring Boot, Keycloak"]
        WI["Worker tích hợp<br/>dh-runtime"]
    end
    subgraph Z3["Vùng dữ liệu"]
        DBN["PostgreSQL"]
        KFN["Kafka"]
        OBN["Kho đối tượng"]
    end
    subgraph Z4["Vùng quản trị"]
        OBS["Quan sát, Argo CD, Harbor"]
        BAS["Máy trạm quản trị qua cổng truy cập đặc quyền"]
        BMC["Mạng quản trị phần cứng BMC"]
    end
    subgraph Z5["Vùng nhân bản"]
        REP["Kênh riêng sang site DR"]
    end
    I1 --> FWE
    I2 --> FWE
    FWE --> LB --> WB
    WB --> WA
    WB --> WI
    WI -->|"ra ngoài qua proxy có danh sách cho phép"| FWE
    WA --> DBN
    WA --> KFN
    WI --> KFN
    WA --> OBN
    DBN --> REP
    KFN --> REP
    OBN --> REP
    BAS --> OBS
    BAS --> BMC
```

Sơ đồ thể hiện bốn quy tắc kết nối chính. Thứ nhất, chỉ vùng biên nhận kết nối từ bên ngoài, và chỉ ở cổng 443. Thứ hai, vùng dữ liệu không bao giờ nhận kết nối trực tiếp từ vùng biên hay từ bên ngoài. Thứ ba, kết nối ra ngoài của `dh-runtime` (tới NDXP, HTTT, kênh thanh toán) đi qua proxy ra có danh sách đích cho phép, để một luồng bị cấu hình sai không thể gửi dữ liệu tới địa chỉ tùy ý. Thứ tư, quản trị chỉ thực hiện từ vùng quản trị qua cổng truy cập đặc quyền, mạng quản trị phần cứng (BMC) tách riêng; đây cũng là điểm nâng cấp lên cấp độ 4 (mạng quản trị riêng).

#### 6.6.2. Mạng trong site

Mỗi máy chủ vật lý ở PROD và DR có hai cổng 25 GbE nối tới hai thiết bị chuyển mạch đầu tủ (top-of-rack) khác nhau, gộp liên kết để chịu được hỏng một cổng hoặc một thiết bị chuyển mạch; lưu lượng ứng dụng, lưu lượng lưu trữ và nhân bản được tách VLAN. Cỡ S có thể dùng 10 GbE. Mỗi máy chủ có thêm một cổng 1 GbE cho mạng BMC. Cân bằng tải vào cụm dùng địa chỉ dịch vụ ảo do Kubernetes quản lý (ví dụ MetalLB hoặc tính năng tương đương của Cilium) trước các worker biên, nên không bắt buộc thiết bị cân bằng tải phần cứng; nếu trung tâm dữ liệu tỉnh đã có thiết bị cân bằng tải dùng chung thì có thể dùng thay.

#### 6.6.3. IPv6

Mạng được thiết kế dual-stack. Mỗi vùng được cấp một dải IPv4 riêng và một tiền tố IPv6 /64 riêng từ khối địa chỉ IPv6 của tỉnh; địa chỉ dịch vụ công bố (tên miền cổng API, cổng nhà phát triển) có cả bản ghi A và AAAA. Tường lửa, thiết bị chuyển mạch, cân bằng tải và cụm Kubernetes (Cilium dual-stack) phải hỗ trợ IPv6 đầy đủ, kể cả chính sách lọc tương đương IPv4; đây là yêu cầu kỹ thuật bắt buộc trong danh mục thiết bị ở mục 6.8. Phía phần mềm, yêu cầu IPv6 ở mục 5.9. Nếu tỉnh chưa được cấp khối địa chỉ IPv6 hoặc nhà cung cấp đường truyền chưa hỗ trợ, phần bên trong vẫn chạy dual-stack và việc công bố ra ngoài qua IPv6 được bật khi đường truyền sẵn sàng (Q-D0101-51).

#### 6.6.4. Kết nối diện rộng

Bảng dưới đây nêu đường truyền khuyến nghị cho từng cỡ, dựa trên ước tính ở mục 6.4.4 và yêu cầu nhân bản sang DR.

| Đường truyền | Cỡ S | Cỡ M | Cỡ L | Ghi chú |
|---|---|---|---|---|
| Internet tại site chính | 2 × 100 Mbps | 2 × 300 Mbps | 2 × 1 Gbps | Hai nhà cung cấp khác nhau; cho HTTT ngoài mạng chuyên dùng, kênh thanh toán, VNeID |
| Mạng truyền số liệu chuyên dùng tại site chính | 100 Mbps | 200 Mbps | 500 Mbps | Kết nối NDXP, CSDL quốc gia, HTTT các cơ quan trên mạng chuyên dùng |
| Internet và mạng chuyên dùng tại site DR | Như site chính | Như site chính | Như site chính | Có thể ở trạng thái chờ với cam kết nâng băng thông khi kích hoạt |
| Kênh riêng site chính tới site DR | 200 Mbps | 500 Mbps | 1 Gbps | Nhân bản CSDL, Kafka, kho đối tượng |

: Các đường truyền diện rộng theo cỡ S, M, L

Kênh riêng sang DR được tính theo hai yêu cầu. Yêu cầu thường xuyên ở cỡ M là khoảng 50 Mbps ở đỉnh (WAL PostgreSQL khoảng 20 GB mỗi ngày, Kafka 60 GB mỗi ngày qua MirrorMaker 2, đồng bộ kho đối tượng khoảng 10 GB mỗi ngày). Yêu cầu bất thường là đồng bộ lại sau khi kênh bị gián đoạn hoặc sau diễn tập: với 500 Mbps, 1 TB dữ liệu được đồng bộ lại trong khoảng 4,5 giờ, phù hợp cửa sổ khôi phục. Độ trễ kênh không ảnh hưởng hiệu năng ứng dụng vì nhân bản sang DR là bất đồng bộ.

### 6.7. Quy đổi sang máy chủ vật lý và cloud chính phủ

#### 6.7.1. Quy đổi sang máy chủ vật lý (H1)

Các node trong bảng cấu hình là máy ảo chạy trên nền ảo hóa của trung tâm dữ liệu tỉnh. Quy đổi sang máy chủ vật lý dùng cấu hình máy chủ hai bộ xử lý phổ biến: cỡ S dùng 2 × 24 nhân (96 luồng), 384 GB RAM; cỡ M dùng 2 × 32 nhân (128 luồng), 512 GB RAM; cỡ L dùng 2 × 32 nhân, 768 GB RAM. Mỗi máy chủ dành 8 luồng và 40 GB RAM cho nền ảo hóa. Số máy chủ bằng số cần cho tài nguyên cộng một máy dự phòng (N+1), tối thiểu 3 cho PROD và DR. Node kho đối tượng là máy ảo gắn ổ HDD trực tiếp của máy chủ chứa nó, mỗi node trên một máy chủ khác nhau, nên không cần máy chủ lưu trữ riêng.

| Nhóm | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| Máy chủ PROD | 4 máy; mỗi máy 4 × 1,92 TB NVMe, 2 × 2 TB HDD (3 máy) | 4 máy; mỗi máy 4 × 3,84 TB NVMe, 2 × 4 TB HDD | 7 máy; mỗi máy 4 × 3,84 TB NVMe, 3 × 4 TB HDD (6 máy) |
| Máy chủ DR | 3 máy; mỗi máy 4 × 1,92 TB NVMe, 2 × 2 TB HDD | 3 máy; mỗi máy 4 × 1,92 TB NVMe, 2 × 4 TB HDD | 5 máy; mỗi máy 4 × 1,92 TB NVMe, 3 × 4 TB HDD (4 máy) |
| Máy chủ STAGING | 2 máy; mỗi máy 4 × 1,92 TB NVMe, 2 × 2 TB HDD | 2 máy; mỗi máy 4 × 1,92 TB NVMe, 2 × 2 TB HDD | 2 máy; mỗi máy 4 × 3,84 TB NVMe, 2 × 4 TB HDD |
| DEV và TEST (nếu đặt tại chỗ thay vì thuê) | 2 máy | 2 máy | 2 máy |
| Mức dùng CPU PROD khi đủ máy | 61% | 75% | 79% |

: Quy đổi cấu hình H1 sang máy chủ vật lý theo nhóm và cỡ

Tất cả máy chủ có thêm 2 ổ SSD 480 GB gương cho hệ điều hành nền ảo hóa, 2 cổng 25 GbE (10 GbE cho S), 1 cổng BMC, nguồn kép. Ổ NVMe cấu hình RAID 10 ở mức máy chủ: ví dụ máy PROD cỡ M có 7,68 TB khả dụng, bốn máy là 30,7 TB, so với 13,2 TB SSD cần cho PROD cỡ M, tức 43% ở năm đầu; phần dư dành cho tăng trưởng dữ liệu và cho khả năng chuyển node khi một máy hỏng. Với cỡ M, mất một máy chủ PROD thì ba máy còn lại vẫn có 360 luồng khả dụng, đúng bằng tổng vCPU của PROD; do các node chỉ dùng khoảng 70–76% tài nguyên, toàn bộ bản sao vẫn được xếp lại. Ở trạng thái vận hành theo phương án khuyến nghị, tỉnh cỡ M cần 9 máy chủ (4 PROD, 3 DR, 2 STAGING), tổng 576 nhân vật lý, 4.608 GB RAM.

#### 6.7.2. Quy đổi sang cloud chính phủ (H2)

Khi đặt trên cloud chính phủ, mỗi node quy đổi thành một máy ảo cùng vCPU và RAM, SSD quy thành lưu trữ khối SSD, còn HDD của node kho đối tượng quy thành dịch vụ lưu trữ đối tượng tương thích S3 của nhà cung cấp (nếu có) với dung lượng khả dụng bằng dung lượng thô chia 3, vì nhà cung cấp đã tự nhân bản. Nếu cloud cung cấp dịch vụ Kubernetes được quản lý, có thể bỏ các node control plane khỏi danh sách thuê. Bảng dưới đây là bảng quy đổi cho cỡ M; cỡ S và L quy đổi tương tự từ tệp CSV.

| Môi trường cỡ M | Máy ảo | vCPU | RAM GB | Lưu trữ khối SSD TB | Lưu trữ đối tượng S3 TB | Lưu trữ khối HDD TB |
|---|---|---|---|---|---|---|
| PROD | 26 (bỏ 4 node kho đối tượng) | 344 | 960 | 12,4 | 11 | — |
| DR | 16 | 192 | 560 | 6,9 | 8 | — |
| STAGING | 19 | 176 | 456 | 4,5 | 2 | — |
| TEST | 12 | 84 | 280 | 2,8 | — | 3 |
| DEV | 5 | 36 | 136 | 1,2 | — | 1 |
| **Tổng H2 toàn phần** | **78** | **832** | **2.392** | **27,8** | **21** | **4** |
| Trong đó thuê theo phương án khuyến nghị (DEV, TEST) | 17 | 120 | 416 | 4 | — | 4 |

: Quy đổi các môi trường cỡ M sang máy ảo, vCPU, RAM, lưu trữ trên cloud chính phủ (H2)

Ngoài tài nguyên tính toán và lưu trữ, thuê cloud cần tính thêm địa chỉ IP công cộng (IPv4 và IPv6), băng thông Internet theo mục 6.6.4, dịch vụ cân bằng tải và tường lửa của nhà cung cấp, kết nối tới mạng truyền số liệu chuyên dùng. Nếu DR đặt ở cloud trong khi PROD tại chỗ, kênh riêng sang DR được thay bằng kết nối riêng tới cloud của nhà cung cấp với băng thông như mục 6.6.4. Kubernetes trên cloud chính phủ phải là bản chuẩn đạt kiểm tra tương thích của cộng đồng (conformance), để giữ nguyên tắc không phụ thuộc dịch vụ độc quyền (NT-09).

### 6.8. Danh mục thiết bị, dịch vụ hạ tầng cần đầu tư

Bảng dưới đây là danh mục hạ tầng cho tỉnh thí điểm cỡ M theo phương án khuyến nghị (kịch bản cơ sở: PROD, STAGING, DR theo H1; DEV, TEST thuê H2), kèm số lượng cho cỡ S và L để dùng khi nhân rộng. Kịch bản cơ sở mua sắm thiết bị trong dự án này bằng một gói thầu thiết bị riêng (Chương 9 mục 9.4), nên danh mục là đầu vào của tổng mức đầu tư ở Chương 8; nếu tỉnh chọn đầu tư thiết bị bằng một dự án hạ tầng riêng, danh mục trở thành yêu cầu kỹ thuật cho dự án đó (Q-D0101-52).

| STT | Hạng mục | Yêu cầu kỹ thuật chính | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|---|---|
| 1 | Máy chủ PROD | Như mục 6.7.1, hỗ trợ ảo hóa phần cứng, nguồn kép, bảo hành 5 năm | 4 | 4 | 7 |
| 2 | Máy chủ DR | Như mục 6.7.1 | 3 | 3 | 5 |
| 3 | Máy chủ STAGING | Như mục 6.7.1 | 2 | 2 | 2 |
| 4 | Thiết bị chuyển mạch đầu tủ | 48 cổng 25 GbE (10 GbE cho S), 4 cổng uplink 100 GbE, hỗ trợ IPv6, gộp liên kết đa thiết bị | 2 + 2 | 2 + 2 | 4 + 2 |
| 5 | Thiết bị chuyển mạch quản trị | 48 cổng 1 GbE cho BMC | 1 + 1 | 1 + 1 | 2 + 1 |
| 6 | Tường lửa biên thế hệ mới, cặp sẵn sàng cao | Thông lượng khi bật phòng chống xâm nhập ≥ 1 Gbps (S), ≥ 2 Gbps (M), ≥ 5 Gbps (L); hỗ trợ IPv6; chống DDoS; cấu hình chi tiết theo Chương 7 | 2 + 2 | 2 + 2 | 2 + 2 |
| 7 | Thiết bị sao lưu độc lập tại site DR | Lưu trữ hỗ trợ khóa bất biến hoặc thư viện băng từ; dung lượng khả dụng | 10 TB | 20 TB | 40 TB |
| 8 | Tủ rack 42U, thanh nguồn có đo lường, bộ chuyển KVM | Tại site chính và site DR | 1 + 1 | 2 + 1 | 3 + 2 |
| 9 | Đường truyền Internet | Theo mục 6.6.4, hai nhà cung cấp, mỗi site | Thuê | Thuê | Thuê |
| 10 | Mạng truyền số liệu chuyên dùng | Theo mục 6.6.4, mỗi site | Thuê | Thuê | Thuê |
| 11 | Kênh riêng site chính tới DR | Theo mục 6.6.4 | Thuê | Thuê | Thuê |
| 12 | Cloud chính phủ cho DEV, TEST | 120 vCPU, 416 GB RAM, 4 TB SSD, 4 TB HDD, từ T0 | Thuê | Thuê | Thuê |
| 13 | Chứng thư số | Chứng thư TLS cho tên miền công bố; chứng thư số chuyên dùng cho ký số giao dịch với NDXP, PayGov | Theo nhu cầu | Theo nhu cầu | Theo nhu cầu |
| 14 | Nền ảo hóa | Xem mục 6.9 | Theo số máy chủ | Theo số máy chủ | Theo số máy chủ |
| 15 | Mô-đun bảo mật phần cứng (HSM) | Chỉ khi nâng cấp độ 4 hoặc khi Chương 7 yêu cầu cho khóa ký | Tùy chọn | Tùy chọn | Tùy chọn |

: Danh mục thiết bị, dịch vụ hạ tầng cần đầu tư theo cỡ S, M, L

Trong cột số lượng, "a + b" là số thiết bị ở site chính và site DR. Ước tính công suất điện để tỉnh kiểm tra năng lực trung tâm dữ liệu (Q-D0101-42 tại Chương 4): với cỡ M, site chính có 6 máy chủ, mỗi máy khoảng 0,8–1 kW khi tải cao, cộng thiết bị mạng khoảng 0,6 kW, tổng khoảng 6–7 kW và 2 tủ rack; site DR khoảng 3,5–4 kW và 1 tủ rack.

### 6.9. Phần mềm nền

Phần mềm nền là phần mềm nằm giữa phần cứng và Datahub. Báo cáo mô tả yêu cầu theo chức năng, không chỉ định sản phẩm thương mại, để hồ sơ mời thầu bảo đảm cạnh tranh và để tỉnh dùng lại được nền đã có.

| Lớp | Yêu cầu | Phương án mã nguồn mở tham chiếu | Phương án có hỗ trợ thương mại |
|---|---|---|---|
| Nền ảo hóa | Hỗ trợ máy ảo Linux, gắn ổ trực tiếp cho máy ảo, sao lưu máy ảo, quản lý tập trung nhiều máy chủ, IPv6 | Nền ảo hóa dựa trên KVM | Sản phẩm ảo hóa tỉnh đã có, hoặc bản KVM có hỗ trợ |
| Hệ điều hành máy chủ và node | Linux bản hỗ trợ dài hạn còn ít nhất 5 năm vòng đời tại thời điểm cài đặt | Bản phân phối Linux cộng đồng hỗ trợ dài hạn | Bản phân phối Linux doanh nghiệp có hỗ trợ |
| Kubernetes | Bản đạt kiểm tra tương thích của cộng đồng, phiên bản ≥ 1.31, dual-stack, cài bằng công cụ khai báo | Kubernetes thượng nguồn cài bằng công cụ chuẩn, hoặc bản phân phối mã nguồn mở | Bản phân phối Kubernetes có hỗ trợ |
| Lưu trữ cho container | Ổ cục bộ cho CSDL, Kafka (CloudNativePG và Strimzi khuyến nghị ổ cục bộ); trình điều khiển CSI | Trình cấp phát ổ cục bộ | Không cần |
| Sao lưu | Sao lưu CSDL liên tục, sao lưu tài nguyên Kubernetes, sao chép sang thiết bị độc lập | Công cụ sao lưu tích hợp của CloudNativePG, Velero | Phần mềm sao lưu tỉnh đã có |
| Giám sát phần cứng | Thu thập trạng thái máy chủ qua BMC vào hệ thống quan sát | Bộ thu thập chỉ số phần cứng mã nguồn mở | Phần mềm quản lý của hãng máy chủ |

: Phần mềm nền: phương án mã nguồn mở và phương án có hỗ trợ thương mại

Chương 8 tính chi phí phần mềm nền theo hai kịch bản: kịch bản cơ sở toàn mã nguồn mở (bản quyền bằng 0, chỉ tính nhân công vận hành), kịch bản có hỗ trợ thương mại cho hệ điều hành, Kubernetes và nền ảo hóa. Số đơn vị tính bản quyền thường là số bộ xử lý vật lý (cỡ M: 18 bộ xử lý trên 9 máy chủ) hoặc số node (cỡ M: 71 node trên H1, chưa tính DEV, TEST).

### 6.10. Sao lưu và dự phòng thảm họa

#### 6.10.1. Mục tiêu và nguyên tắc

Mục tiêu khôi phục theo NFR-00-014 và bộ giả định nền đã cập nhật là RPO 15 phút, RTO 1 giờ cho data plane và 4 giờ cho control plane (cỡ S, M); cỡ L có RPO 5 phút. Giải pháp tuân theo nguyên tắc 3-2-1: ba bản dữ liệu, trên hai loại phương tiện, một bản ở địa điểm khác; ngoài ra có một bản bất biến để chống mã độc tống tiền. Mọi cơ chế sao lưu đều phải được kiểm chứng bằng khôi phục thật theo lịch, vì bản sao lưu chưa từng được khôi phục thì không được coi là bản sao lưu.

#### 6.10.2. Cơ chế theo thành phần

| Thành phần | Trong site chính | Sang site DR | Bản độc lập | RPO đạt được |
|---|---|---|---|---|
| PostgreSQL | Một primary, hai standby đồng bộ; mất một node không mất dữ liệu | Cụm bản sao CloudNativePG nhận WAL liên tục, bất đồng bộ | Sao lưu toàn phần hằng ngày và WAL vào kho đối tượng, sao tiếp sang thiết bị độc lập | Vài giây đến dưới 1 phút |
| Kafka | Nhân bản 3, tối thiểu 2 bản đồng bộ | MirrorMaker 2 sao topic và vị trí tiêu thụ | Không cần (sự kiện có nguồn gốc ở CSDL hoặc HTTT) | Dưới 1 phút |
| Kho đối tượng | Nhân bản 3 giữa các node | Đồng bộ bucket định kỳ 15 phút | Bản WORM của nhật ký kiểm toán | ≤ 15 phút |
| Cấu hình, luồng, chính sách | Kho Git | Kho Git sao sang DR; Argo CD ở DR đồng bộ cùng nguồn | Bản sao kho Git hằng ngày | Bằng 0 (Git là nguồn sự thật) |
| Bí mật | OpenBao HA 3 node | Bản sao hiệu năng hoặc ảnh chụp mã hóa sang DR | Ảnh chụp mã hóa hằng ngày, khóa mở do người giữ khóa quản lý | ≤ 15 phút |
| Tài nguyên Kubernetes | Khai báo trong Git | Như trên | Velero hằng ngày | Bằng 0 |

: Cơ chế sao lưu, dự phòng theo thành phần và RPO đạt được

#### 6.10.3. Quy trình chuyển sang DR

```{.mermaid caption="Trình tự chuyển dịch vụ sang site DR"}
sequenceDiagram
    participant MON as Giám sát
    participant OPS as Trực vận hành
    participant DR as Cụm DR
    participant DNS as DNS và định tuyến
    MON->>OPS: Cảnh báo mất site chính quá 10 phút
    OPS->>OPS: Xác nhận sự cố, xin quyết định kích hoạt DR
    OPS->>DR: Nâng cụm bản sao PostgreSQL thành primary
    OPS->>DR: Chuyển Kafka DR thành cụm chính
    DR->>DR: KEDA, HPA tăng bản sao data plane
    OPS->>DNS: Trỏ tên miền cổng API sang địa chỉ DR
    DNS-->>OPS: HTTT gọi vào DR
    OPS->>DR: Khởi động đủ DU control plane
    OPS->>MON: Xác nhận data plane hoạt động, ghi nhận RTO
```

Quy trình được thiết kế để data plane hoạt động trở lại trong 1 giờ: data plane ở DR đã chạy sẵn, các bước nâng CSDL và Kafka là thao tác có kịch bản tự động, và bản ghi DNS của tên miền công bố có thời gian sống ngắn (khuyến nghị 60 giây). Control plane được khởi động sau, trong giới hạn 4 giờ. Quyết định kích hoạt DR thuộc người có thẩm quyền do tỉnh chỉ định vì kích hoạt nhầm có chi phí (phải đồng bộ ngược khi quay về); thời gian chờ quyết định được giới hạn trong kịch bản ứng phó. Diễn tập chuyển sang DR và quay về thực hiện hằng quý (NFR-00-014), trong giai đoạn dự án ở W3 và W5 (WBS 1.26.5 tại D01-02).

### 6.11. Chỉ tiêu kỹ thuật lắp đặt, cài đặt, kiểm tra và thống kê khối lượng

#### 6.11.1. Chỉ tiêu kiểm tra

Bảng dưới đây nêu chỉ tiêu kỹ thuật phải đạt khi lắp đặt, cài đặt và kiểm tra hạ tầng, trước khi bàn giao từng môi trường cho việc cài Datahub. Các chỉ tiêu này đưa vào hồ sơ thiết kế chi tiết và biên bản nghiệm thu lắp đặt.

| Hạng mục | Chỉ tiêu | Phương pháp kiểm tra |
|---|---|---|
| Máy chủ | Chạy thử tải liên tục 72 giờ không lỗi phần cứng; firmware đồng bộ phiên bản | Công cụ chạy tải, nhật ký BMC |
| Ổ lưu trữ | NVMe đạt tối thiểu 80% hiệu năng đọc ghi ngẫu nhiên công bố của nhà sản xuất sau RAID | Công cụ đo hiệu năng ổ đĩa |
| Mạng trong site | Thông lượng giữa hai máy chủ ≥ 90% tốc độ cổng; rút một cáp hoặc tắt một thiết bị chuyển mạch không mất kết nối quá 1 giây | Công cụ đo thông lượng; kiểm thử ngắt |
| IPv6 | Mọi vùng có địa chỉ IPv6; dịch vụ công bố truy cập được qua IPv6 từ bên ngoài khi đường truyền hỗ trợ | Kiểm tra kết nối và phân giải AAAA |
| Đường truyền | Đạt băng thông cam kết ở mục 6.6.4; độ trễ kênh sang DR ổn định | Đo trong 24 giờ |
| Kubernetes | Đạt bộ kiểm tra tương thích của cộng đồng; dual-stack; chính sách mạng từ chối mặc định hoạt động | Công cụ kiểm tra tương thích; kiểm thử chính sách |
| Cấu hình an toàn nền | Đạt mức cơ sở cấu hình an toàn cho hệ điều hành và Kubernetes do Chương 7 quy định | Công cụ đánh giá cấu hình an toàn |
| PostgreSQL | Tắt primary, standby được nâng trong ≤ 30 giây, không mất giao dịch đã xác nhận | Kiểm thử hỗn loạn |
| Kafka | Tắt một broker, không mất sự kiện đã xác nhận, nhà sản xuất và người tiêu thụ tự phục hồi | Kiểm thử hỗn loạn |
| Một máy chủ hỏng | Tắt một máy chủ PROD, mọi bản sao được xếp lại, dịch vụ phục hồi ≤ 5 phút (NFR-00-015) | Kiểm thử hỗn loạn |
| Sao lưu và khôi phục | Khôi phục CSDL về một thời điểm chỉ định trên môi trường riêng, đối chiếu dữ liệu đúng | Diễn tập khôi phục |
| DR | Diễn tập chuyển sang DR đạt RPO ≤ 15 phút, RTO data plane ≤ 1 giờ, control plane ≤ 4 giờ | Diễn tập theo mục 6.10.3 |
| Hiệu năng | PROD đạt chỉ tiêu cỡ M ở mục 5.11 trong kiểm thử tải trước vận hành chính thức | Kiểm thử tải |

: Chỉ tiêu và phương pháp kiểm tra lắp đặt, cài đặt hạ tầng

#### 6.11.2. Thống kê khối lượng lắp đặt, cài đặt

Bảng dưới đây thống kê khối lượng chính cho tỉnh thí điểm cỡ M theo phương án khuyến nghị, làm căn cứ ước tính chi phí lắp đặt, cài đặt ở Chương 8 và khối lượng công việc ở WBS của D01-02 (phần tử 1.26).

| Hạng mục | Đơn vị | Khối lượng | Ghi chú |
|---|---|---|---|
| Lắp đặt máy chủ vào tủ rack, đấu nối | máy | 9 | 6 site chính, 3 site DR |
| Lắp đặt, cấu hình thiết bị chuyển mạch | thiết bị | 6 | 4 đầu tủ, 2 quản trị |
| Lắp đặt, cấu hình tường lửa biên | cặp | 2 | Một cặp mỗi site |
| Lắp đặt thiết bị sao lưu độc lập | thiết bị | 1 | Site DR |
| Cài đặt, cấu hình nền ảo hóa | máy chủ | 9 | |
| Tạo, cài hệ điều hành node | node | 71 | PROD 30, DR 19, STAGING 22 |
| Dựng cụm Kubernetes | cụm | 5 | PROD, DR, STAGING tại H1; DEV, TEST trên H2 (17 node) |
| Cài đặt bộ thành phần nền (CloudNativePG, Strimzi, Garage, Ceph RGW (WORM), Keycloak, OPA, OpenBao, Istio, Cilium, Argo CD, Harbor, quan sát) | cụm × bộ | 5 × khoảng 25 thành phần | Cài bằng GitOps, dùng chung khai báo |
| Cài đặt Datahub và khởi tạo tenant | cụm, tenant | 5 cụm; 2 tenant ở tỉnh thí điểm (tỉnh và `PLATFORM`) | Cộng tenant tỉnh 2 ở W5 |
| Cấu hình nhân bản PROD sang DR | luồng nhân bản | 4 | PostgreSQL, Kafka, kho đối tượng, OpenBao |
| Kiểm thử theo mục 6.11.1 | bộ kiểm tra | 13 hạng mục cho PROD; 9 cho DR; 7 cho STAGING | |
| Diễn tập DR trong dự án | lần | 2 | W3, W5 |

: Thống kê khối lượng lắp đặt, cài đặt theo hạng mục

### 6.12. Khối lượng sơ bộ đào tạo, tập huấn

Điểm e khoản 2 Điều 46 yêu cầu thiết kế cơ sở nêu khối lượng sơ bộ đào tạo, tập huấn. Bảng dưới đây nêu đối tượng, số học viên, số lớp và thời lượng cho tỉnh thí điểm cỡ M và tỉnh thứ hai. Số học viên đầu mối HTTT lấy theo quy mô cỡ M (khoảng 200 HTTT, mỗi HTTT một đầu mối). Nội dung chương trình và lộ trình chuyển giao cho đội vận hành ở D01-02 (WBS 1.27, chương nhân sự mục 6.8); đào tạo nội bộ cho đội nhà thầu không tính vào đây.

| Đối tượng | Nội dung chính | Học viên | Số lớp | Ngày mỗi lớp | Người-ngày |
|---|---|---|---|---|---|
| Đội vận hành hạ tầng và nền tảng của tỉnh | Kubernetes, GitOps, PostgreSQL, Kafka, kho đối tượng, quan sát, sao lưu, DR, xử lý sự cố theo runbook | 6 | 1 | 15 | 90 |
| Quản trị tenant, quản trị nghiệp vụ nền tảng | PH-01, 02, 12, 13, 18, 20; kết nạp HTTT, công bố dịch vụ, phân quyền, giám sát | 10 | 1 | 5 | 50 |
| Kỹ sư tích hợp của tỉnh và đơn vị phát triển HTTT | Thiết kế luồng, bộ điều hợp, sự kiện, quy trình, kiểm thử luồng | 30 | 2 | 5 | 150 |
| Cán bộ an toàn thông tin | Kiến trúc an toàn, giám sát, ứng phó sự cố của Datahub | 4 | 1 | 3 | 12 |
| Cán bộ nghiệp vụ dữ liệu | Danh mục dùng chung, dữ liệu chủ, chất lượng dữ liệu, quyền riêng tư | 40 | 2 | 2 | 80 |
| Cán bộ thanh toán, đối soát | PH-19: nhà cung cấp, giao dịch, đối soát, hoàn tiền | 15 | 1 | 2 | 30 |
| Đầu mối kỹ thuật HTTT thành viên | Quy trình kết nạp, cổng nhà phát triển, chuyển kết nối từ hệ cũ | 200 | 5 | 1 | 200 |
| Lãnh đạo, quản lý | Giới thiệu nền tảng, chỉ số, trách nhiệm các bên | 20 | 1 | 0,5 | 10 |
| Tỉnh thứ hai: quản trị tenant | Như dòng quản trị tenant, rút gọn | 8 | 1 | 3 | 24 |
| Tỉnh thứ hai: vận hành | Vận hành cụm hoặc tenant theo phương án tỉnh 2 | 4 | 1 | 5 | 20 |
| Tỉnh thứ hai: đầu mối HTTT | Kết nạp và kết nối | 40 | 1 | 1 | 40 |
| **Tổng** | | **377** | **17** | **53,5 ngày lớp** | **706** |

: Khối lượng sơ bộ đào tạo, tập huấn theo đối tượng

Đào tạo được tổ chức tại tỉnh trên môi trường thực hành riêng (một tenant thực hành trên STAGING hoặc TEST), mỗi khóa có bài kiểm tra cuối khóa với tiêu chí ít nhất 90% học viên đạt (WBS 1.27.2). Lớp cho đầu mối HTTT có thể tổ chức trực tuyến để giảm chi phí đi lại cho cấp xã.

### Câu hỏi mở

Các câu hỏi dưới đây liên quan đến mức dự phòng của site DR, địa chỉ IPv6, cách đưa thiết bị vào tổng mức đầu tư và số liệu tải thực tế; câu trả lời quyết định cách chốt cấu hình ở chương này.

- **Q-D0101-50.** Chủ đầu tư chấp nhận site DR phục vụ khoảng 60% lưu lượng đỉnh cỡ M (kịch bản cơ sở) hay yêu cầu DR chịu 100% tải đỉnh (tăng khoảng 96 vCPU, 192 GB RAM cho cỡ M)?
- **Q-D0101-51.** Tỉnh đã được cấp khối địa chỉ IPv6 và nhà cung cấp Internet, mạng truyền số liệu chuyên dùng tại trung tâm dữ liệu tỉnh đã hỗ trợ IPv6 hay chưa?
- **Q-D0101-52.** Thiết bị hạ tầng ở mục 6.8 được mua sắm trong dự án này hay trong một dự án hạ tầng riêng của tỉnh? Báo cáo lấy kịch bản cơ sở là mua sắm trong dự án bằng gói thầu riêng; nếu tách sang dự án hạ tầng riêng, tổng mức đầu tư giảm còn khoảng 28.964 triệu đồng (Chương 8 mục 8.6.3).
- **Q-D0101-53.** Trung tâm dữ liệu tỉnh đang dùng nền ảo hóa, hệ điều hành và phần mềm sao lưu nào, có tận dụng được cho Datahub không?
- **Q-D0101-54.** Số liệu kích thước bản tin trung bình, tỷ lệ bản tin lớn và lượng nhật ký thực tế của hệ cũ là bao nhiêu? Các hệ số ở mục 6.4.3 và 6.4.4 sẽ được hiệu chỉnh theo số liệu này.


## 7. Phương án bảo đảm an toàn thông tin và an ninh mạng

**Tóm tắt cho hội đồng thẩm định.** Báo cáo đề xuất xác định Datahub ở **cấp độ 3** và thiết kế sẵn các điểm nâng cấp để lên **cấp độ 4** khi nền tảng phục vụ nhiều tỉnh. Cơ sở pháp lý hiện hành là Luật An ninh mạng số 116/2025/QH15 (hiệu lực 01/7/2026), trong đó Điều 8 chia hệ thống thông tin thành 5 cấp độ theo mức tổn hại và giao Chính phủ quy định chi tiết. Nghị định 331/2026/NĐ-CP (CMP-LAW-06) quy định chi tiết việc xác định cấp độ và TCVN 14423:2026 (CMP-LAW-08) quy định yêu cầu bảo vệ theo từng cấp, nên hồ sơ đề xuất cấp độ (D03-08) được lập theo hai văn bản này; Datahub là hệ thống mới nên không lập hồ sơ theo Nghị định 85/2016/NĐ-CP. Phương án gồm 20 nhóm biện pháp bao trùm quản lý và kỹ thuật, mỗi nhóm ánh xạ tới các biện pháp có mã SEC chính thức trong D03-07, trong đó cách ly dữ liệu giữa các tỉnh được thực thi ở tầng hạ tầng chứ không chỉ ở mã ứng dụng, dữ liệu lưu hoàn toàn trong nước, nhật ký kiểm toán không sửa được và được gửi về trung tâm giám sát an toàn thông tin (SOC) của tỉnh. Kiểm thử xâm nhập độc lập là điều kiện của cổng G2 và G4; quyết định phê duyệt cấp độ là điều kiện của cổng G3.

### 7.1. Cơ sở pháp lý về cấp độ sau Luật An ninh mạng 2025

Từ ngày 01/7/2026, Luật An ninh mạng số 116/2025/QH15 có hiệu lực và chấm dứt hiệu lực của Luật An toàn thông tin mạng số 86/2015/QH13 và Luật An ninh mạng số 24/2018/QH14 ([nguồn](https://hethongphapluat.com/law-no-116-2025-qh15-dated-december-10-2025-on-cybersecurity.html)). Ba quy định của luật mới chi phối trực tiếp chương này.

Thứ nhất, **Điều 8** phân hệ thống thông tin thành 5 cấp độ theo mức tổn hại khi xảy ra sự cố. Theo bản đọc được, cấp độ 3 tương ứng với hệ thống mà sự cố có thể gây tổn hại đặc biệt nghiêm trọng tới quyền và lợi ích hợp pháp của tổ chức, cá nhân, tổn hại nghiêm trọng tới lợi ích công cộng, hoặc tổn hại tới trật tự xã hội, an ninh quốc gia; cấp độ 4 tương ứng với tổn hại đặc biệt nghiêm trọng tới lợi ích công cộng, trật tự, an toàn xã hội hoặc tổn hại nghiêm trọng tới an ninh quốc gia; cấp độ 5 dành cho hệ thống mà sự cố gây tổn hại đặc biệt nghiêm trọng tới an ninh quốc gia. Khoản 2 Điều 8 giao Chính phủ quy định tiêu chí chi tiết, thẩm quyền, trình tự và biện pháp cho từng cấp độ.

Thứ hai, **Điều 10 và Điều 11** quy định nghĩa vụ của chủ quản hệ thống. Chủ quản hệ thống cấp độ 3 và 4 (không thuộc danh mục hệ thống quan trọng về an ninh quốc gia) phải thực hiện các nhiệm vụ cốt lõi (phân loại hệ thống, quản lý rủi ro) và các biện pháp cụ thể như thẩm định, giám sát, ứng phó sự cố. Hệ thống phải được kiểm tra trước khi đưa vào vận hành, chủ quản tự kiểm tra hằng năm và báo cáo bằng văn bản cho lực lượng chuyên trách trước tháng 10 hằng năm.

Thứ ba, **điều khoản chuyển tiếp** cho phép hệ thống đã được xác định cấp độ theo luật năm 2015 giữ nguyên cấp độ, nhưng phải đáp ứng điều kiện bảo vệ theo quy định mới trong 12 tháng kể từ ngày luật có hiệu lực. Điều này liên quan đến hệ LGSP cũ của tỉnh: nếu hệ cũ đã có quyết định cấp độ, cấp độ đó không tự chuyển sang Datahub vì Datahub là hệ thống mới, phải lập hồ sơ riêng.

Về văn bản dưới luật, Nghị định 331/2026/NĐ-CP ngày 19/8/2026 (CMP-LAW-06) kế nhiệm Nghị định 85/2016/NĐ-CP và quy định chi tiết việc bảo vệ an ninh mạng đối với hệ thống thông tin theo năm cấp độ. Ba điểm của nghị định chi phối trực tiếp Datahub. Một là thẩm quyền: hồ sơ cấp độ 3 do đơn vị chuyên trách về an ninh mạng thẩm định và chủ quản hệ thống phê duyệt, còn hồ sơ cấp độ 4 do Bộ Công an thẩm định; vì vậy khi Datahub được nâng lên cấp độ 4 (mục 7.2.2), cơ quan thẩm định thay đổi. Hai là ngưỡng dữ liệu cá nhân: hệ thống xử lý dữ liệu cá nhân cơ bản của từ 100.000 chủ thể trở lên, hoặc dữ liệu nhạy cảm của từ 10.000 chủ thể trở lên, thuộc tối thiểu cấp độ 3; Datahub của một tỉnh cỡ M vượt cả hai ngưỡng. Ba là chuyển tiếp tại Điều 39: hệ thống đầu tư trước 01/7/2026 được thẩm định theo khung cũ trong 6 tháng và phải đáp ứng yêu cầu mới trong 12 tháng; Datahub là hệ thống mới nên áp dụng ngay khung mới ([tổng hợp pháp lý ở D03-07 §2](../03-thiet-ke/attt/D03-07-thiet-ke-attt.md)). Các điều khoản này mới được đối chiếu qua nguồn thứ cấp, chưa đối chiếu Công báo (Q-D0101-71).

Yêu cầu bảo vệ theo cấp độ được quy định ở TCVN 14423:2026 (CMP-LAW-08), tiêu chuẩn thay TCVN 14423:2025 và TCVN 11930:2017. Chương 3 đến chương 7 của tiêu chuẩn tương ứng cấp độ 1 đến cấp độ 5; yêu cầu cấp độ 3 gồm 18 nhóm (mục 5.1 đến 5.18) phủ cả quản lý và kỹ thuật, kèm Phụ lục A về an toàn vật lý. Thông tư 12/2022/TT-BTTTT (CMP-LAW-07) chỉ được giữ làm đối chiếu mẫu hồ sơ cho tới khi có văn bản hướng dẫn Nghị định 331/2026/NĐ-CP.

Từ đó, báo cáo chọn cách tiếp cận sau. Hồ sơ đề xuất cấp độ và thiết kế an toàn thông tin được xây dựng theo 18 nhóm yêu cầu cấp độ 3 của TCVN 14423:2026, ánh xạ chi tiết ở D03-07 và D03-08. Mỗi biện pháp được gắn với mục đích bảo vệ (bảo mật, toàn vẹn, sẵn sàng, truy vết) chứ không chỉ gắn với điều khoản, để khi có văn bản hướng dẫn mới, việc ánh xạ lại chỉ là thay cột tham chiếu. Kế hoạch dự án đặt mốc nộp hồ sơ ở T0+8, đủ thời gian để đơn vị chuyên trách thẩm định trước G3.

### 7.2. Xác định cấp độ

#### 7.2.1. Đề xuất cấp độ 3 cho tỉnh thí điểm

Datahub là trung gian bắt buộc cho trao đổi dữ liệu giữa các hệ thống thông tin của tỉnh và với nền tảng quốc gia. Ba đặc điểm khiến hệ thống ở mức cấp độ 3 thay vì cấp độ 2. Một là phạm vi phục vụ: với tỉnh cỡ M, nền tảng kết nối tới 200 hệ thống thông tin và khoảng 10 triệu giao dịch mỗi ngày, trong đó có luồng hồ sơ dịch vụ công trực tuyến; sự cố kéo dài làm ngừng dịch vụ công trên toàn tỉnh, tức tổn hại nghiêm trọng tới lợi ích công cộng. Hai là dữ liệu: nền tảng xử lý dữ liệu cá nhân của người dân ở quy mô toàn tỉnh, gồm cả dữ liệu thuộc loại nhạy cảm theo Nghị định 356/2025/NĐ-CP (số định danh, thông tin tài khoản và lịch sử giao dịch thanh toán qua PH-19); lộ lọt có thể gây tổn hại đặc biệt nghiêm trọng tới quyền của cá nhân. Ba là vị trí kết nối: nền tảng giữ chứng thư và tài khoản kết nối NDXP, NDOP, PayGov; bị chiếm quyền có thể trở thành điểm tấn công vào nền tảng quốc gia.

Datahub không xử lý thông tin bí mật nhà nước (chính sách chặn dữ liệu mật CMP-23 ở docs/01-legal), không điều khiển hạ tầng trọng yếu, nên với một tỉnh đơn lẻ, mức tổn hại chưa tới ngưỡng "tổn hại đặc biệt nghiêm trọng tới lợi ích công cộng" của cấp độ 4.

#### 7.2.2. Vì sao thiết kế sẵn cấp độ 4

Khi Datahub được vận hành như nền tảng dùng chung cho nhiều tỉnh (phương án H3, chế độ tenant `SHARED`), một sự cố của cụm dùng chung làm ngừng dịch vụ công của nhiều tỉnh cùng lúc. Khi đó mức tổn hại có thể được cơ quan thẩm định đánh giá ở cấp độ 4. Nếu kiến trúc không chuẩn bị trước, việc nâng cấp độ sẽ đòi thay đổi kiến trúc lớn đúng vào giai đoạn nhân rộng. Vì vậy dự án áp dụng nguyên tắc "cấp độ 3 triển khai, cấp độ 4 thiết kế": mọi biện pháp cấp độ 3 được triển khai và nghiệm thu; các biện pháp bổ sung cho cấp độ 4 có điểm cắm sẵn trong kiến trúc (cột "Bổ sung cấp độ 4" ở mục 7.4) và chỉ phát sinh chi phí thiết bị, vận hành khi kích hoạt. D03-01 §9 liệt kê bốn điểm nâng cấp chính: CSDL riêng theo tenant, mô-đun bảo mật phần cứng (HSM) cho khóa ký, hai trung tâm dữ liệu hoạt động song song, mạng quản trị tách riêng.

### 7.3. Phương án theo nhóm yêu cầu

Mục này trình bày phương án theo hai nhóm lớn của TCVN 14423:2026: yêu cầu quản lý và yêu cầu kỹ thuật. Mỗi tiểu mục nêu cách Datahub đáp ứng, còn biện pháp cụ thể được tóm ở bảng mục 7.4 và có mã SEC chính thức trong D03-07. Định nghĩa chính thức của từng biện pháp nằm ở D03-07.

#### 7.3.1. Yêu cầu quản lý

**Chính sách an toàn thông tin.** Chủ quản hệ thống ban hành quy chế bảo đảm an toàn thông tin riêng cho Datahub, gồm phân loại dữ liệu bốn mức (Công khai, Nội bộ, Hạn chế, Nhạy cảm theo D03-01 §8.2), quy tắc cấp quyền, quy tắc sử dụng tài khoản đặc quyền, quy trình xử lý sự cố. Quy chế được soạn trong W2 cùng hồ sơ cấp độ và ban hành trước G3. Điểm khác so với quy chế của hệ thống đơn tỉnh là quy chế phải phân định rõ trách nhiệm giữa quản trị nền tảng (tenant `PLATFORM`) và quản trị từng tỉnh, vì người quản trị nền tảng về kỹ thuật có thể chạm vào dữ liệu của mọi tỉnh.

**Tổ chức và nhân sự.** Đơn vị vận hành bố trí đầu mối an toàn thông tin cho Datahub (vị trí kỹ sư ATTT trong đội vận hành sáu người, D01-02 §6.5.2). Phía nhà thầu có kỹ sư ATTT từ W0 đến hết bảo hành. Người được cấp quyền quản trị phải ký cam kết bảo mật và được đào tạo trước khi nhận quyền.

**Quản lý thiết kế, xây dựng.** An toàn thông tin được đưa vào từng sprint, không để đến cuối dự án: mỗi phân hệ có mô hình hóa mối đe dọa (threat modeling) khi thiết kế, cổng CI S chặn mã có lỗ hổng hoặc lộ bí mật, và mỗi wave có kiểm thử bảo mật trước cổng nghiệm thu (D01-02 §9.3). Mã do AI agent sinh ra chịu cùng cổng kiểm soát như mã do người viết.

**Quản lý vận hành.** Thay đổi trên PROD chỉ đi qua GitOps (Argo CD) với yêu cầu thay đổi được phê duyệt; không có thao tác tay trên cụm ngoài quy trình khẩn cấp có ghi vết. Bản vá lỗ hổng mức nghiêm trọng được áp dụng trong thời hạn quy định tại D03-07.

**Kiểm tra, đánh giá và xử lý sự cố.** Hệ thống được kiểm tra trước khi đưa vào vận hành (điều kiện G3), tự kiểm tra hằng năm và báo cáo trước tháng 10 theo Điều 11 Luật An ninh mạng 2025. Quy trình ứng phó sự cố phân bốn mức, khớp với cam kết thời gian xử lý trong bảo hành (D01-02 §13.3), có diễn tập sự cố trước G3.

#### 7.3.2. Yêu cầu kỹ thuật

**Bảo đảm an toàn mạng.** Mạng được chia thành sáu vùng (vùng ngoài, biên DMZ, ứng dụng, dữ liệu, quản trị, nhân bản) với tường lửa từ chối mặc định giữa các vùng (Chương 6 mục 6.6.1). Bên trong cụm Kubernetes, ranh giới được thực thi thêm bằng chính sách mạng Cilium và mTLS của Istio ambient, theo nguyên tắc không tin cậy mặc định (zero-trust): hai dịch vụ cạnh nhau cũng phải xác thực lẫn nhau. Kết nối ra ngoài của runtime tích hợp đi qua proxy có danh sách đích cho phép.

**Bảo đảm an toàn máy chủ.** Node Kubernetes dùng hệ điều hành tối giản, cấu hình theo chuẩn cứng hóa (CIS Benchmark), không cho đăng nhập trực tiếp ngoài máy trạm quản trị qua cổng truy cập đặc quyền. Container chạy không đặc quyền, hệ thống tệp chỉ đọc khi có thể.

**Bảo đảm an toàn ứng dụng.** Mọi API công bố đi qua cổng APISIX với tường lửa ứng dụng web Coraza (bộ luật OWASP CRS), giới hạn tần suất theo client và theo tenant. Ứng dụng web và API đạt OWASP ASVS 5.0 mức 2 (NFR-00-024). Xác thực tập trung qua Keycloak, MFA bắt buộc cho vai trò quản trị, token ngắn hạn; ủy quyền qua OPA theo vai trò, tenant, phân loại dữ liệu và mục đích.

**Bảo đảm an toàn dữ liệu.** Dữ liệu được mã hóa khi truyền (TLS 1.3 ở biên, mTLS nội bộ) và khi lưu (toàn bộ volume, kho đối tượng, Kafka); trường mức Nhạy cảm được mã hóa ở tầng ứng dụng qua OpenBao transit (NFR-00-020, NFR-00-021). Không có bí mật trong mã nguồn, cấu hình hay ảnh container (NFR-00-022). Sao lưu hằng ngày kèm nhân bản liên tục sang site DR, RPO không quá 15 phút (NFR-00-014), và bản sao lưu được mã hóa, lưu ở chế độ không xóa được trong thời hạn giữ.

### 7.4. Bảng biện pháp chính

Bảng dưới đây liệt kê 20 nhóm biện pháp chính, đánh mã cục bộ NB-01 đến NB-20 và ghi kèm các mã SEC chính thức của D03-07, nơi định nghĩa tiêu chí kiểm chứng và ánh xạ điều khoản. Cột "Cấp độ 3" mô tả mức triển khai trong dự án; cột "Bổ sung cấp độ 4" mô tả phần được thiết kế sẵn và chỉ kích hoạt khi nâng cấp độ.

| Mã | Biện pháp | Nhóm | Cấp độ 3 (triển khai trong dự án) | Bổ sung cấp độ 4 (thiết kế sẵn) |
|---|---|---|---|---|
| NB-01 · SEC-13, SEC-14 | Phân vùng mạng, tường lửa từ chối mặc định | Mạng | Sáu vùng, tường lửa thế hệ mới HA ở biên, Cilium trong cụm | Tách vật lý mạng quản trị, thiết bị tường lửa riêng giữa vùng ứng dụng và dữ liệu |
| NB-02 · SEC-10 | Chống tấn công từ chối dịch vụ | Mạng | Lọc ở thiết bị biên, giới hạn tần suất tại APISIX | Dịch vụ chống DDoS từ nhà mạng hoặc trung tâm giám sát quốc gia |
| NB-03 · SEC-11 | Tường lửa ứng dụng web | Ứng dụng | Coraza với OWASP CRS ở chế độ chặn | Bộ luật riêng theo từng API nhạy cảm, kiểm thử luật định kỳ |
| NB-04 · SEC-12, SEC-15 | Mã hóa đường truyền, mTLS nội bộ | Dữ liệu | TLS 1.3 ở biên, mTLS Istio ambient giữa mọi dịch vụ | mTLS bắt buộc cho mọi HTTT kết nối, không chỉ HTTT nhạy cảm |
| NB-05 · SEC-20, SEC-21, SEC-23 | Định danh, xác thực tập trung, MFA | Ứng dụng | Keycloak mỗi tenant một realm; MFA cho quản trị | MFA bằng khóa phần cứng (WebAuthn) cho mọi vai trò đặc quyền |
| NB-06 · SEC-26 | Ủy quyền theo chính sách | Ứng dụng | OPA tại cổng và từng đơn vị triển khai; điều kiện tenant bắt buộc | Phê duyệt hai người cho thay đổi chính sách |
| NB-07 · SEC-28 | Quản lý truy cập đặc quyền | Máy chủ | Cổng truy cập đặc quyền, ghi phiên quản trị | Quyền đặc quyền cấp theo phiên, hết hạn tự động |
| NB-08 · SEC-33, SEC-34 | Quản lý bí mật và khóa | Dữ liệu | OpenBao, thông tin xác thực CSDL động, khóa ký trong OpenBao | HSM cho khóa ký và khóa gốc mã hóa |
| NB-09 · SEC-30, SEC-31 | Mã hóa khi lưu và mã hóa trường nhạy cảm | Dữ liệu | Mã hóa volume, kho đối tượng, Kafka; envelope encryption trường Nhạy cảm | Khóa riêng theo tenant ở HSM |
| NB-10 · SEC-80 đến SEC-88 | Cách ly đa tenant | Dữ liệu | RLS bắt buộc, ACL Kafka, realm, bucket, đường dẫn bí mật theo tenant (D03-10 §4) | Chế độ `DEDICATED_DB` hoặc `DEDICATED_CLUSTER` cho tỉnh cấp độ 4 |
| NB-11 · SEC-60, SEC-62 | Nhật ký kiểm toán không sửa được | Giám sát | Chỉ-thêm, chuỗi băm, kho WORM; trực tuyến 12 tháng (NFR-00-027) | Đẩy thời gian thực sang kho độc lập của đơn vị giám sát |
| NB-12 · SEC-63, SEC-66 | Giám sát an toàn, gửi SOC | Giám sát | Gửi nhật ký an ninh về SOC tỉnh; cảnh báo theo luật phát hiện | Giám sát 24/7 có người trực, kết nối hệ thống giám sát quốc gia |
| NB-13 · SEC-55, SEC-56, SEC-57 | Chuỗi cung ứng phần mềm | Máy chủ, ứng dụng | Ảnh ký bằng cosign, SBOM, Trivy chặn CRITICAL, chỉ dùng Harbor nội bộ | Kiểm chứng chữ ký bắt buộc ở admission, tái tạo bản dựng (reproducible build) |
| NB-14 · SEC-50, SEC-52 | Cứng hóa máy chủ và container | Máy chủ | Chuẩn CIS, container không đặc quyền, tệp chỉ đọc | Quét tuân thủ liên tục, chặn triển khai lệch chuẩn |
| NB-15 · SEC-09 | Quản lý lỗ hổng, bản vá | Vận hành | Quét định kỳ, thời hạn vá theo mức | Thời hạn vá rút ngắn, kiểm thử xâm nhập sau mỗi phiên bản chính |
| NB-16 · SEC-70, SEC-71 | Sao lưu, dự phòng thảm họa | Dữ liệu | Sao lưu hằng ngày, nhân bản sang DR, RPO 15 phút, diễn tập hằng quý | Hai trung tâm hoạt động song song |
| NB-17 · SEC-32, SEC-37 | Bảo vệ dữ liệu cá nhân | Dữ liệu | Che dữ liệu trong log và giao diện, xem đầy đủ phải nêu lý do (PH-09 ở đợt 2) | Đánh giá tác động định kỳ theo từng tenant |
| NB-18 · SEC-26 (chính sách chặn) | Chặn dữ liệu bí mật nhà nước | Dữ liệu | Nhãn phân loại mật, chính sách chặn tại OPA | Không thay đổi |
| NB-19 · SEC-08, SEC-42 | Kiểm thử an toàn | Kiểm tra | ASVS mức 2, kiểm thử xâm nhập độc lập trước G2 và G4 | Kiểm thử xâm nhập định kỳ 6 tháng, diễn tập tấn công (red team) |
| NB-20 · SEC-01, SEC-03, SEC-72 | Quy chế, đào tạo, ứng phó sự cố | Quản lý | Quy chế ATTT, đào tạo, quy trình sự cố bốn mức, diễn tập trước G3 | Đội ứng phó sự cố trực 24/7 |

: Biện pháp an toàn thông tin chính: cấp độ 3 triển khai và phần bổ sung cấp độ 4

Bảng cho thấy phần lớn chi phí bổ sung của cấp độ 4 nằm ở thiết bị (HSM, tường lửa bổ sung, site thứ hai hoạt động song song) và nhân lực giám sát 24/7, không nằm ở phần mềm. Đây là kết quả của việc chọn kiến trúc đa tenant với ba chế độ cách ly ngay từ đầu.

### 7.5. Sơ đồ phân vùng và lớp bảo vệ

Sơ đồ dưới đây ghép phân vùng mạng của Chương 6 với các lớp bảo vệ. Một lượt gọi từ hệ thống thông tin bên ngoài phải đi qua lần lượt lớp biên, lớp định danh và ủy quyền, rồi mới tới ứng dụng và dữ liệu; mọi lớp đều ghi nhật ký về lớp giám sát.

```{.mermaid caption="Phân vùng mạng và các lớp bảo vệ một lượt gọi đi qua"}
flowchart TB
    subgraph NGOAI["Vùng ngoài"]
        HT["HTTT sở ngành, xã"]
        QG["NDXP, NDOP, PayGov"]
    end
    subgraph BIEN["Vùng biên DMZ - NB-01, 02, 03"]
        FW["Tường lửa thế hệ mới, chống DDoS"]
        GW["APISIX và WAF Coraza<br/>TLS 1.3, giới hạn tần suất"]
    end
    subgraph DINHDANH["Lớp định danh và ủy quyền - NB-05, 06"]
        KC["Keycloak<br/>mỗi tỉnh một realm"]
        OPA["OPA<br/>vai trò, tenant, mục đích"]
    end
    subgraph UNGDUNG["Vùng ứng dụng - NB-04, 13, 14"]
        DU["Đơn vị triển khai Spring Boot"]
        RT["Runtime tích hợp dh-runtime"]
    end
    subgraph DULIEU["Vùng dữ liệu - NB-08, 09, 10, 16"]
        PG["PostgreSQL có RLS theo tenant"]
        KF["Kafka có ACL theo tenant"]
        OB["Kho đối tượng mã hóa"]
        BAO["OpenBao, HSM khi lên cấp 4"]
    end
    subgraph GIAMSAT["Vùng quản trị và giám sát - NB-07, 11, 12"]
        PAM["Cổng truy cập đặc quyền"]
        AUD["Nhật ký kiểm toán WORM"]
        SOC["SOC của tỉnh"]
    end
    HT --> FW
    QG --> FW
    FW --> GW
    GW -->|"xác minh token"| KC
    GW -->|"quyết định truy cập"| OPA
    GW -->|"mTLS"| DU
    GW -->|"mTLS"| RT
    DU --> PG
    DU --> KF
    RT --> KF
    DU --> OB
    DU --> BAO
    RT -->|"proxy ra có danh sách cho phép"| FW
    PAM --> UNGDUNG
    PAM --> DULIEU
    GW -.->|"nhật ký"| AUD
    DU -.->|"nhật ký"| AUD
    AUD -.->|"sự kiện an ninh"| SOC
```

Hai điểm trong sơ đồ cần lưu ý. Thứ nhất, không có mũi tên nào từ vùng ngoài hay vùng biên đi thẳng vào vùng dữ liệu; mọi truy cập dữ liệu phải qua ứng dụng đã xác thực. Thứ hai, quản trị viên chỉ chạm vào vùng ứng dụng và dữ liệu qua cổng truy cập đặc quyền, và mọi phiên đều được ghi lại, nên kể cả người có quyền cao nhất cũng để lại dấu vết.

### 7.6. An ninh đa tenant

Rủi ro đặc trưng của mô hình sản phẩm đa tenant là lộ dữ liệu của tỉnh này cho tỉnh khác (RSK-36, RSK-A03). Datahub xử lý rủi ro này bằng nguyên tắc cách ly ở tầng hạ tầng, được đặc tả đầy đủ tại D03-10 §4. Tenant của mỗi yêu cầu chỉ được xác định từ token đã xác thực, không từ tham số do client gửi. Ở CSDL, mọi bảng nghiệp vụ có cột `tenant_id` với RLS bắt buộc và vai trò kết nối không có quyền vượt RLS; đơn vị triển khai tự từ chối khởi động nếu phát hiện cấu hình sai. Ở Kafka, topic mang tiền tố tenant và ACL theo tiền tố; consumer kiểm tra tenant trong header khớp với tên topic. Kho đối tượng, kho bí mật, nhật ký kiểm toán và giao diện giám sát đều tách theo tenant.

Về khóa mã hóa, mỗi tenant có khóa mã hóa trường nhạy cảm riêng trong OpenBao, nên khóa bị lộ của một tỉnh không giải mã được dữ liệu tỉnh khác. Khi lên cấp độ 4, khóa gốc của từng tenant chuyển vào HSM. Tenant quản trị nền tảng (`PLATFORM`) chỉ truy cập dữ liệu tỉnh qua cơ chế liên tenant có lý do và kiểm toán.

Kiểm thử rò rỉ chéo tenant chạy tự động trong CI ở mọi bản dựng và là tiêu chí bắt buộc của cổng G2; kiểm thử xâm nhập độc lập có kịch bản riêng về vượt ranh giới tenant.

### 7.7. Bảo vệ dữ liệu cá nhân

Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (cùng hiệu lực 01/01/2026, nghị định thay Nghị định 13/2023/NĐ-CP) đặt ba yêu cầu có tác động trực tiếp. Một là hồ sơ đánh giá tác động xử lý dữ liệu cá nhân chuyển từ hậu kiểm sang tiền kiểm: cơ quan chuyên trách của Bộ Công an đánh giá hồ sơ trong 15 ngày và hồ sơ phải có sơ đồ luồng dữ liệu, biện pháp bảo vệ, phân định vai trò bên kiểm soát và bên xử lý ([nguồn tóm tắt](https://www.ey.com/vi_vn/technical/tax/tax-and-law-updates/nghi-dinh-so-356-2025-nd-cp-quy-dinh-chi-tiet-mot-so-dieu-va-bien-phap-thi-hanh-luat-bao-ve-du-lieu-ca-nhan)). Hai là phạm vi dữ liệu nhạy cảm được mở rộng, gồm ảnh căn cước, thông tin tài khoản định danh điện tử, tài khoản ngân hàng và lịch sử giao dịch tài chính. Ba là yêu cầu có người hoặc bộ phận phụ trách bảo vệ dữ liệu cá nhân đạt tiêu chuẩn năng lực.

Datahub đáp ứng theo cách sau. Về vai trò pháp lý, với dữ liệu đi qua (bản tin giữa các hệ thống), Datahub là bên xử lý thay cho cơ quan chủ quản dữ liệu và mặc định không lưu nội dung, chỉ lưu siêu dữ liệu (D03-01 §8.3); với dữ liệu lưu lại (dữ liệu chủ, giao dịch thanh toán), chủ đầu tư là bên kiểm soát. Phân định này được ghi trong hồ sơ đánh giá tác động. Về kỹ thuật, trường dữ liệu được gắn mức phân loại; trường mức Nhạy cảm được mã hóa ở tầng ứng dụng, không xuất hiện trong log (NFR-00-029), được che mặc định khi hiển thị, và việc xem đầy đủ phải nêu lý do và được ghi kiểm toán. Phân hệ PH-09 (đợt 2) bổ sung quản lý mục đích xử lý, sự đồng ý và nhật ký khai thác phục vụ thanh tra. Về hồ sơ, hồ sơ đánh giá tác động cho các luồng có dữ liệu nhạy cảm được lập trong W4 và được phê duyệt trước G4 (D01-02 §4.3.2); luồng thanh toán của PH-19 cần hồ sơ trước khi cắt chuyển. Báo cáo kiến nghị đơn vị vận hành chỉ định người phụ trách bảo vệ dữ liệu cá nhân cho Datahub, có thể kiêm nhiệm với kỹ sư ATTT nếu đạt tiêu chuẩn.

### 7.8. Lưu trữ dữ liệu trong nước

Luật An ninh mạng 2025 yêu cầu dữ liệu cá nhân và dữ liệu quan hệ người dùng thu thập, xử lý tại Việt Nam phải được lưu tại Việt Nam theo quy định của Chính phủ. Datahub đáp ứng ở mức thiết kế: mọi môi trường chứa dữ liệu thật (PROD, STAGING khi dùng dữ liệu đã che, DR) đặt tại Trung tâm dữ liệu tỉnh hoặc cloud chính phủ trong nước; không thành phần nào gửi dữ liệu ra dịch vụ nước ngoài (không dùng dịch vụ quản lý của nhà cung cấp cloud quốc tế, không gửi telemetry ra ngoài). Cổng AI (PH-17, đợt 3) chỉ được định tuyến tới mô hình đặt trong nước hoặc đã được chủ quản phê duyệt, và không gửi trường mức Nhạy cảm. Môi trường DEV, TEST trên cloud chỉ dùng dữ liệu giả lập.

### 7.9. Giám sát an toàn thông tin và SOC

Datahub tự giám sát vận hành qua PH-13 (OpenTelemetry, bộ LGTM, OpenSearch), nhưng giám sát an toàn thông tin được thiết kế để kết nối với SOC của tỉnh thay vì dựng SOC riêng. Lý do là SOC của tỉnh đã giám sát các hệ thống khác, có người trực và có quy trình phối hợp với lực lượng chuyên trách; dựng SOC riêng cho một nền tảng sẽ tốn kém và phân tán. Datahub gửi về SOC các nguồn sau: nhật ký WAF và cổng API, sự kiện xác thực và từ chối ủy quyền, sự kiện vượt ranh giới tenant, nhật ký phiên quản trị đặc quyền, cảnh báo từ quét lỗ hổng và kiểm tra cấu hình. Định dạng gửi theo chuẩn mở (syslog hoặc OTLP) để tương thích với nền tảng SOC hiện có. Nếu tỉnh chưa có SOC hoặc SOC chưa đủ năng lực, chủ đầu tư thuê dịch vụ giám sát an toàn thông tin của doanh nghiệp đủ điều kiện, được tính như một khoản thuê dịch vụ ở Chương 8 (Q-D0101-72).

### 7.10. Kiểm thử xâm nhập và đánh giá độc lập

Dự án có hai đợt kiểm thử xâm nhập độc lập do đơn vị độc lập về pháp nhân với nhà thầu phát triển thực hiện (D01-02 §5.3.7). Đợt thứ nhất trước G2, kiểm thử hộp xám toàn bộ 12 phân hệ MVP, có kịch bản riêng về vượt ranh giới tenant và về chiếm quyền tài khoản kết nối quốc gia; kiểm thử lại sau khắc phục, và G2 chỉ đạt khi không còn phát hiện mức nghiêm trọng hoặc cao đang mở. Đợt thứ hai trước G4, tập trung vào phân hệ thanh toán PH-19 và bảo vệ dữ liệu cá nhân PH-09. Báo cáo của đơn vị độc lập là thành phần của hồ sơ đề xuất cấp độ và là căn cứ cho việc kiểm tra trước khi đưa vào vận hành theo Điều 11 Luật An ninh mạng 2025. Sau dự án, báo cáo kiến nghị kiểm thử xâm nhập hằng năm, gắn với lần tự kiểm tra trước tháng 10.

### 7.11. Hồ sơ đề xuất cấp độ

Hồ sơ đề xuất cấp độ được lập thành tài liệu D03-08. Hồ sơ gồm thuyết minh xác định cấp độ (dựa trên mục 7.2), mô tả phạm vi và ranh giới hệ thống, sơ đồ mạng và phân vùng, phương án bảo đảm an toàn đáp ứng yêu cầu của cấp độ (bảng SEC ở D03-07 ánh xạ vào yêu cầu), quy chế an toàn thông tin, và báo cáo kiểm thử độc lập. Do văn bản quy định chi tiết chưa xác minh, D03-08 được lập theo mẫu của khung cũ nhưng có phụ lục ánh xạ sang cấu trúc yêu cầu của Luật An ninh mạng 2025, để chỉ phải đổi mẫu khi văn bản mới được ban hành. Lịch hồ sơ theo kế hoạch dự án: nộp tại T0+8 (M-09), mục tiêu có quyết định tại T0+10, muộn nhất T0+12 (M-12); quyết định phê duyệt là điều kiện vào của cổng G3. Phân hệ thanh toán và các phân hệ đợt 2 nằm trong ranh giới hệ thống đã khai báo, nên không cần hồ sơ mới nhưng phải cập nhật phương án khi đưa vào vận hành.

### 7.12. Chi phí bảo đảm an toàn thông tin

Chi phí an toàn thông tin được tính trong tổng mức đầu tư và TCO tại Chương 8, không tách thành dự án riêng. Các khoản chính gồm: thiết bị an ninh mạng ở biên (tường lửa thế hệ mới HA, chống DDoS) trong danh mục thiết bị Chương 6 mục 6.8; nhân lực kỹ sư ATTT của nhà thầu trong giai đoạn thực hiện và bảo hành (theo bộ giả định nền); đánh giá thiết kế và kiểm thử xâm nhập độc lập hai đợt; lập hồ sơ đề xuất cấp độ và hồ sơ đánh giá tác động xử lý dữ liệu cá nhân; chứng thư số cho kết nối quốc gia và ký bản tin; đào tạo an toàn thông tin cho đội vận hành. Chi phí vận hành hằng năm gồm kiểm thử xâm nhập định kỳ, giám sát SOC (nếu thuê dịch vụ) và gia hạn chứng thư. Các khoản chỉ phát sinh khi nâng lên cấp độ 4 (HSM, tường lửa bổ sung, site thứ hai hoạt động song song, giám sát 24/7) được Chương 8 trình bày như kịch bản riêng, không cộng vào tổng mức đầu tư của dự án thí điểm.

### 7.13. Câu hỏi mở

Các câu hỏi dưới đây liên quan đến văn bản hướng dẫn Nghị định 331/2026/NĐ-CP, năng lực SOC của tỉnh và cấp độ hiện hành của hệ cũ; câu trả lời quyết định cách lập hồ sơ đề xuất cấp độ.

- **Q-D0101-71.** Các điều khoản của Nghị định 331/2026/NĐ-CP về thẩm quyền thẩm định cấp độ 3, ngưỡng dữ liệu cá nhân và chuyển tiếp (Điều 39) mới được đọc qua nguồn thứ cấp. Chủ đầu tư cần đối chiếu Công báo và xác nhận đơn vị chuyên trách an ninh mạng nào của tỉnh thẩm định hồ sơ cấp độ 3 của Datahub, trong thời hạn bao lâu.
- **Q-D0101-72.** Tỉnh thí điểm đã có SOC đang vận hành chưa, và SOC có tiếp nhận nhật ký theo syslog hoặc OTLP không? Nếu chưa, chủ đầu tư chọn thuê dịch vụ giám sát hay đầu tư SOC trong dự án khác?
- **Q-D0101-73.** Văn bản hướng dẫn mẫu hồ sơ đề xuất cấp độ theo Nghị định 331/2026/NĐ-CP đã được ban hành chưa? Nếu chưa, chủ đầu tư có chấp nhận dùng mẫu của Thông tư 12/2022/TT-BTTTT với nội dung yêu cầu theo TCVN 14423:2026 như D03-08 đang làm không?
- **Q-D0101-74.** Hệ LGSP cũ của tỉnh đã có quyết định phê duyệt cấp độ chưa, ở cấp mấy? Thông tin này dùng để đối chiếu trong hồ sơ D03-08 và xác định nghĩa vụ chuyển tiếp của hệ cũ trong thời gian chạy song song.


## 8. Tổng mức đầu tư, chi phí vận hành và TCO 5 năm

> **Tóm tắt cho hội đồng thẩm định.** Với phương án đề xuất PA3 (xây mới Datahub trên nền mã nguồn mở) cho tỉnh thí điểm cỡ M, tổng mức đầu tư sơ bộ là **40.702 triệu đồng trước thuế GTGT** (khoảng 42.236 triệu đồng gồm thuế GTGT ước tính) theo phương án hạ tầng khuyến nghị H1 (PROD, STAGING, DR đặt tại trung tâm dữ liệu tỉnh, DEV và TEST thuê cloud), và **33.460 triệu đồng trước thuế** (khoảng 34.401 triệu đồng gồm thuế) nếu toàn bộ hạ tầng thuê cloud chính phủ (H2). Chi phí sở hữu năm năm kể từ T0 (TCO, gồm đầu tư, bảo hành, vận hành và hỗ trợ kỹ thuật) là **62.651 triệu đồng với H1** và **72.271 triệu đồng với H2**: H2 rẻ hơn khoảng 7,2 tỷ đồng ở bước đầu tư nhưng đắt hơn khoảng 9,6 tỷ đồng sau năm năm, nên báo cáo giữ khuyến nghị H1 của Chương 4. Chi phí phần mềm nội bộ được ước tính theo hai cách độc lập (người-tháng và điểm trường hợp sử dụng), hai kết quả chênh nhau 7,7%. Chi phí biên để đưa tỉnh thứ hai cỡ M lên nền tảng dùng chung khoảng 6.417 triệu đồng một lần và 900 triệu đồng mỗi năm, nên TCO năm năm bình quân mỗi tỉnh giảm từ 62,7 tỷ đồng (một tỉnh) xuống khoảng 36,4 tỷ đồng (hai tỉnh) và 20,7 tỷ đồng (năm tỉnh). Mọi đơn giá trong chương là **giá trị tham khảo** để thẩm định sơ bộ; chủ đầu tư thay bằng đơn giá chính thức và báo giá trước khi phê duyệt.

### 8.1. Phương pháp xác định chi phí

#### 8.1.1. Căn cứ và cơ cấu tổng mức đầu tư

Tổng mức đầu tư của dự án đầu tư hệ thống chuyển đổi số được xác định theo Điều 49 Nghị định 224/2026/NĐ-CP quy định chi tiết Luật Chuyển đổi số (khoản 5 Điều 45 của Nghị định dẫn chiếu Điều 49 cho nội dung tổng mức đầu tư trong báo cáo nghiên cứu khả thi) và Thông tư 39/2026/TT-BKHCN về lập và quản lý chi phí trong đầu tư, mua sắm, thuê dịch vụ cho chuyển đổi số sử dụng ngân sách nhà nước ([nguồn](https://dauthaumuasam.vn/thong-tu-so-39-2026-tt-bkhcn-cua-bo-khoa-hoc-va-cong-nghe-quy-dinh-lap-va-quan-ly-chi-phi-trong-hoat-dong-dau-tu-mua-sam-thue-dich-vu-cho-chuyen-doi-so-su-dung-ngan-sach-nha-nuoc/)). Thông tư 39/2026 cấu trúc tổng mức đầu tư thành năm nhóm: G = G(TB/DV) + G(QLDA) + G(TV) + G(K) + G(DP). Nhóm G(TB) là chi phí thiết bị theo nghĩa rộng, gồm mua sắm thiết bị, phần mềm nội bộ, tạo lập cơ sở dữ liệu, lắp đặt, cài đặt, đào tạo, triển khai. Nhóm G(DV) là chi phí thuê dịch vụ công nghệ số (thuê phần mềm, thuê hạ tầng số, thuê quản trị, vận hành). Nhóm G(QLDA) gồm quản lý dự án và giám sát, đánh giá đầu tư. Nhóm G(TV) là tư vấn (khảo sát, lập báo cáo, thiết kế, lựa chọn nhà thầu, giám sát). Nhóm G(K) là chi phí khác (thẩm định, bảo hiểm, kiểm thử, vận hành thử, kiểm toán). Nhóm G(DP) là dự phòng, tối đa 10% khi lập tổng mức đầu tư, tính trên tổng các khoản chi phí không gồm G(DV).

Chương này giữ đúng năm nhóm đó để hội đồng thẩm định đối chiếu được trực tiếp với biểu mẫu tổng mức đầu tư. Hai điểm chưa xác minh được ở thời điểm lập báo cáo và cần kiểm tra trước khi trình. Thứ nhất, nguyên văn Điều 49 Nghị định 224/2026 và các định mức tỷ lệ của Thông tư 39/2026 (đặc biệt định mức chi phí quản lý dự án, tư vấn) mới được đọc qua bản trích đăng trên trang tổng hợp văn bản, chưa đối chiếu Công báo; vì vậy các tỷ lệ phần trăm trong chương là giá trị tham khảo, không phải định mức trích từ Thông tư (Q-D0101-81). Thứ hai, Quyết định 671/QĐ-BTTTT ngày 26/4/2024 hướng dẫn xác định chi phí phần mềm nội bộ bằng điểm trường hợp sử dụng có căn cứ ban hành là các văn bản nay đã hết hiệu lực; chưa xác định được Bộ Khoa học và Công nghệ đã ban hành hướng dẫn thay thế hay Thông tư 39/2026 có phụ lục phương pháp tương đương hay chưa (Q-D0101-82). Do đó chương dùng phương pháp điểm trường hợp sử dụng như một phương pháp chuyên gia để đối chiếu, còn phương pháp người-tháng gắn với cấu trúc phân rã công việc (WBS) của D01-02 là cơ sở lập tổng mức đầu tư.

#### 8.1.2. Phạm vi, đơn vị và các quy ước

Đơn vị tiền là triệu đồng, làm tròn đến 1 triệu đồng; giá trước thuế GTGT trừ khi ghi khác. Thuế GTGT được ước tính riêng ở 10% cho thiết bị, thuê dịch vụ, tư vấn và chi phí khác; phần mềm nội bộ và dịch vụ phần mềm được giả định không chịu thuế GTGT theo pháp luật thuế hiện hành, điều này cần cơ quan tài chính xác nhận (Q-D0101-83). Mọi mốc thời gian ghi tương đối với T0 (ngày khởi động hợp đồng thực hiện), cửa sổ TCO là Năm 1 đến Năm 5 kể từ T0 theo giả định nền §3.3, chi phí chuẩn bị đầu tư cộng vào Năm 1. Trượt giá 4%/năm được áp cho chi phí vận hành từ Năm 3. Mô hình tính theo từng tháng từ T0 đến T0+59 rồi cộng theo năm; mọi tham số đầu vào nằm ở mục 8.1.3, nên khi chủ đầu tư điền đơn giá chính thức thì các bảng trong chương được tính lại theo cùng công thức. Bảng tính tham số dạng ô sửa được là một thành phần của hồ sơ trình thẩm định (Q-D0101-81).

Phạm vi chi phí bao trùm toàn bộ những gì dự án cần để Datahub chạy chính thức tại tỉnh thí điểm: phát triển 20 phân hệ, hạ tầng cho năm môi trường theo Chương 6, di trú khỏi hệ LGSP cũ, hồ sơ cấp độ an toàn thông tin, đào tạo, bảo hành 12 tháng, cùng các chi phí tư vấn, quản lý dự án, chi phí khác và dự phòng. Chương 3 mục 3.6.2 đang xếp mua sắm phần cứng ngoài phạm vi phần mềm; chương này vẫn tính thiết bị H1 vào tổng mức đầu tư để hội đồng thấy chi phí đầy đủ, đồng thời nêu con số tổng mức nếu thiết bị được mua bằng dự án hạ tầng riêng (mục 8.6.3, Q-D0101-52 tại Chương 6).

#### 8.1.3. Đơn giá tham khảo

Bảng sau tập hợp các đơn giá chính. Mỗi đơn giá là một ô tham số trong sheet "Tham số" của bảng tính, kèm khoảng thấp – cao dùng cho phân tích độ nhạy và cho kịch bản giá.

| Tham số | Giá trị tham khảo | Khoảng thấp – cao | Ghi chú |
|---|---|---|---|
| Đơn giá bình quân nhân công nhà thầu | 40 triệu đồng/người-tháng | 32 – 48 | [ĐIỀN] theo định mức chính thức; đã gồm chi phí chung, thu nhập chịu thuế tính trước |
| Đơn giá chuyên gia tư vấn | 35 triệu đồng/người-tháng | 28 – 42 | Lập báo cáo, giám sát, kiểm thử độc lập |
| Chi phí nhân sự vận hành của tỉnh | 25 triệu đồng/FTE-tháng | 20 – 30 | Lương, phụ cấp, bảo hiểm, đào tạo duy trì |
| Mức lương lao động bình quân theo giờ H (phương pháp điểm trường hợp sử dụng) | 110.000 đồng/giờ | 88.000 – 132.000 | [ĐIỀN]; chi phí lao động trực tiếp |
| Máy chủ hai bộ xử lý 2 × 32 nhân, 512 GB (PROD) | 800 triệu đồng/máy | 650 – 1.000 | Bảo hành 5 năm, cấu hình theo mục 6.7.1 |
| Thuê vCPU cloud chính phủ | 0,20 triệu đồng/vCPU-tháng | 0,15 – 0,25 | Không bán vượt cho PROD, DR |
| Thuê RAM cloud | 0,08 triệu đồng/GB-tháng | 0,06 – 0,10 | |
| Thuê lưu trữ khối SSD | 4 triệu đồng/TB-tháng | 3 – 5 | |
| Thuê lưu trữ đối tượng S3 | 0,8 triệu đồng/TB-tháng | 0,6 – 1,0 | Dung lượng khả dụng |
| Giá điện | 2.800 đồng/kWh | | PUE 1,6, tải trung bình 70% công suất đỉnh |

: Đơn giá tham khảo và khoảng thấp, cao dùng để lập chi phí

Đơn giá nhân công 40 triệu đồng/người-tháng là con số quan trọng nhất của chương vì gần một nửa tổng mức đầu tư phụ thuộc trực tiếp vào nó. Báo cáo đề xuất mức này vì ba lý do. Thứ nhất, theo cách tính của Quyết định 671/QĐ-BTTTT, giá trị phần mềm bằng chi phí lao động trực tiếp cộng chi phí chung 65% và thu nhập chịu thuế tính trước 6%, tức hệ số khoảng 1,75 trên chi phí lao động trực tiếp; một kỹ sư có chi phí lao động trực tiếp khoảng 23 triệu đồng/tháng (lương, phụ cấp, bảo hiểm của kỹ sư phần mềm có kinh nghiệm tại Việt Nam) cho ra khoảng 40 triệu đồng/người-tháng. Thứ hai, cơ cấu đội ngũ ở giả định nền §5 nghiêng về kỹ sư có kinh nghiệm (kiến trúc sư, kỹ sư tích hợp Camel và Quarkus native, SRE, ATTT chiếm khoảng một phần ba nỗ lực), nên mức bình quân không thể thấp như dự án nhập liệu hay phát triển ứng dụng đơn giản. Thứ ba, Chương 8 của D01-02 (quản lý rủi ro) đã dùng 40 triệu đồng/người-tháng để quy đổi giá trị kỳ vọng rủi ro; giữ cùng đơn giá giúp khoản dự phòng rủi ro ở D01-02 chuyển thẳng vào G(DP) mà không phải quy đổi lại.

### 8.2. Chi phí phần mềm nội bộ

#### 8.2.1. Cách thứ nhất: người-tháng theo WBS

Cách thứ nhất lấy khối lượng công việc từ WBS ở D01-02 chương 2 và bảng định biên ở giả định nền §5. Tổng nỗ lực nhà thầu giai đoạn thực hiện là **458,5 người-tháng**, gồm 454,5 người-tháng theo bảng định biên sáu wave và 4 người-tháng bổ sung cho Giám đốc dự án và Product Owner ở T0+13 đến T0+15 (giả định nền §5 đã cập nhật, làm tròn ≈ 459). Bảo hành 12 tháng thêm 60 người-tháng, tính riêng. Con số này khớp giả định nền với sai lệch 0,1%, dưới ngưỡng 5%, nên chương không đề xuất sửa khối lượng.

Không phải toàn bộ 458,5 người-tháng là "phần mềm nội bộ" theo nghĩa của Thông tư 39/2026. Bảng sau ánh xạ các phần tử WBS sang hạng mục chi phí, để phần phát triển phần mềm được so sánh đúng với phương pháp điểm trường hợp sử dụng ở mục 8.2.2, còn phần triển khai, di trú, đào tạo, hồ sơ an toàn thông tin được thể hiện thành các dòng riêng trong G(TB).

| Hạng mục G(TB) | Phần tử WBS (D01-02 §2.4, §2.5) | Người-tháng | Chi phí (triệu đồng, giá trị tham khảo) |
|---|---|---|---|
| Phần mềm nội bộ | 1.1–1.20 (20 phân hệ), 1.21 (quản lý dự án của nhà thầu, gồm 4 người-tháng bổ sung), 1.22, 1.23, 1.25.1, 1.25.3, 1.25.4, 1.26.1, 1.26.4, 1.28 | 399,5 | 15.980 |
| Cài đặt, triển khai trên hạ tầng | 1.26.2, 1.26.3, 1.26.5, 1.26.6 | 21 | 840 |
| Chuyển đổi, di trú dữ liệu, chạy song song | 1.24 | 24 | 960 |
| Đào tạo, chuyển giao (phần nhà thầu) | 1.27 | 8 | 320 |
| Hồ sơ đề xuất cấp độ, đánh giá tác động DLCN | 1.25.2, 1.25.5 | 6 | 240 |
| **Cộng giai đoạn thực hiện** | | **458,5** | **18.340** |
| Bảo hành 12 tháng | 1.29 | 60 | 2.400 |

: Chi phí phần mềm nội bộ theo người-tháng của các phần tử WBS

Phần quản lý dự án của nhà thầu (1.21) được xếp vào phần mềm nội bộ vì đây là chi phí của nhà thầu nằm trong giá gói thầu, khác với G(QLDA) là chi phí của chủ đầu tư. Bảo hành được tính thành dòng riêng trong G(TB) và trả theo quý trong 12 tháng bảo hành thay vì ẩn trong đơn giá, vì 60 người-tháng là khối lượng đáng kể (khoảng 13% nỗ lực thực hiện) và D01-02 chương 2 đã đề nghị tính riêng; cách làm này cũng giúp chủ đầu tư so sánh với phương án chuyển phần bảo hành sang hợp đồng hỗ trợ kỹ thuật từ chi thường xuyên (Q-D0101-84).

#### 8.2.2. Cách thứ hai: điểm trường hợp sử dụng

Cách thứ hai ước lượng giá trị phần mềm theo phương pháp điểm trường hợp sử dụng (use case point) của Quyết định 671/QĐ-BTTTT, dùng như phương pháp chuyên gia vì tình trạng hiệu lực chưa rõ (mục 8.1.1). Công thức là G = 1,4 × E × P × H, trong đó E = 10/6 × AUCP là giá trị nỗ lực thực tế, AUCP = UUCP × TCF × EF là điểm trường hợp sử dụng đã điều chỉnh, UUCP là tổng điểm tác nhân (UAW) và điểm trường hợp sử dụng (UUCW), P là thời gian lao động cho một điểm (giờ/điểm), H là mức lương lao động bình quân theo giờ. Giá trị phần mềm trước thuế bằng G cộng chi phí chung C = 65% G và thu nhập chịu thuế tính trước TL = 6% (G + C).

Vì D02-02 (SRS) hiện chỉ đặc tả các yêu cầu chức năng dùng chung FR-00, danh sách trường hợp sử dụng của từng phân hệ chưa có. Báo cáo ước lượng số trường hợp sử dụng của mỗi phân hệ từ phạm vi chức năng ở D03-01 và từ nỗ lực WBS, phân theo ba mức độ phức tạp: đơn giản (không quá 3 giao dịch, trọng số 5), trung bình (4 đến 7 giao dịch, trọng số 10) và phức tạp (trên 7 giao dịch, trọng số 15). Hệ số theo mức độ cần thiết (bắt buộc, mong muốn, tùy chọn) của Quyết định 671 được đặt bằng 1,0 cho mọi trường hợp sử dụng trong lần ước lượng này; khi có danh sách chính thức, hệ số này được điền theo phân loại MoSCoW ở FRS. Bảng sau cho kết quả.

| Phân hệ | Đơn giản | Trung bình | Phức tạp | Điểm UUCW | | Phân hệ | Đơn giản | Trung bình | Phức tạp | Điểm UUCW |
|---|---|---|---|---|---|---|---|---|---|---|
| PH-01 | 3 | 4 | 2 | 85 | | PH-11 | 2 | 3 | 2 | 70 |
| PH-02 | 3 | 4 | 3 | 100 | | PH-12 | 2 | 4 | 2 | 80 |
| PH-03 | 2 | 3 | 2 | 70 | | PH-13 | 3 | 4 | 2 | 85 |
| PH-04 | 4 | 8 | 6 | 190 | | PH-14 | 2 | 3 | 2 | 70 |
| PH-05 | 3 | 5 | 2 | 95 | | PH-15 | 3 | 3 | 1 | 60 |
| PH-06 | 2 | 4 | 2 | 80 | | PH-16 | 2 | 3 | 1 | 55 |
| PH-07 | 3 | 5 | 3 | 110 | | PH-17 | 2 | 3 | 2 | 70 |
| PH-08 | 2 | 3 | 1 | 55 | | PH-18 | 3 | 3 | 1 | 60 |
| PH-09 | 2 | 4 | 2 | 80 | | PH-19 | 3 | 6 | 4 | 135 |
| PH-10 | 2 | 3 | 2 | 70 | | PH-20 | 3 | 4 | 2 | 85 |

: Điểm trường hợp sử dụng (UUCW) theo phân hệ và độ phức tạp

Tổng cộng có 174 trường hợp sử dụng với UUCW = 1.705 điểm. Phân hệ có điểm cao nhất là PH-04 (190 điểm, do trình thiết kế luồng, chạy thử, quản lý phiên bản luồng đều là giao dịch nhiều bước) và PH-19 (135 điểm, do đối soát và hoàn tiền có nhiều nhánh nghiệp vụ). Điểm tác nhân UAW = 38, gồm 8 tác nhân người dùng qua giao diện (quản trị tenant, quản trị tích hợp, cán bộ vận hành, cán bộ sở ngành, nhà phát triển, kiểm toán viên, người phụ trách bảo vệ dữ liệu cá nhân, quản trị hệ thống; trọng số 3), 4 tác nhân hệ thống qua giao thức (NDXP, NDOP, PayGov, VNeID; trọng số 2) và 6 tác nhân hệ thống qua API đơn giản (HTTT sở ngành, nhà cung cấp thanh toán, ngân hàng, dịch vụ mô hình ngôn ngữ, cổng thư điện tử và tin nhắn, hệ LGSP cũ; trọng số 1).

Hệ số kỹ thuật TCF = 0,6 + 0,01 × 59,5 = 1,195, cao vì Datahub là hệ phân tán (giá trị 5), yêu cầu xử lý đồng thời lớn, an toàn thông tin cấp độ 3, cho bên thứ ba truy cập và phải tái sử dụng cho nhiều tỉnh (đều ở giá trị 5). Hệ số môi trường EF = 1,4 − 0,03 × 16 = 0,92, phản ánh đội có kinh nghiệm hướng đối tượng và động lực tốt nhưng yêu cầu chưa ổn định (giá trị 2) và ngôn ngữ, khung công nghệ khó (Camel Quarkus native, giá trị 3). Từ đó AUCP = 1.743 × 1,195 × 0,92 = 1.916,3 điểm và E = 3.193,8. Với P = 20 giờ/điểm (mức ứng với đội có độ ổn định kinh nghiệm cao theo cách nội suy của Quyết định 671, cần đối chiếu) và H = 110.000 đồng/giờ (giá trị tham khảo), bảng sau là kết quả.

| Thành phần | Công thức | Giá trị (triệu đồng, giá trị tham khảo) |
|---|---|---|
| Giá trị phần mềm G | 1,4 × 3.193,8 × 20 × 0,11 | 9.837 |
| Chi phí chung C | 65% × G | 6.394 |
| Thu nhập chịu thuế tính trước TL | 6% × (G + C) | 974 |
| **Giá trị phần mềm nội bộ trước thuế** | G + C + TL | **17.205** |
| Đối chiếu: cách người-tháng (399,5 người-tháng × 40) | | 15.980 |
| Chênh lệch | | +7,7% |

: Công thức và giá trị quy đổi điểm trường hợp sử dụng sang chi phí

#### 8.2.3. Đối chiếu hai cách và lựa chọn cơ sở

Hai cách cho kết quả chênh nhau 1.225 triệu đồng, tức 7,7%, nằm trong biên sai số thông thường của ước lượng ở bước nghiên cứu khả thi (khoảng ±20%). Phần chênh có hai nguyên nhân có thể giải thích. Một là phương pháp điểm trường hợp sử dụng quy ra khoảng 89.400 giờ, tương đương 508 người-tháng 176 giờ, cao hơn 399,5 người-tháng của WBS; khoảng cách này phản ánh việc hệ số 1,4 và năng suất 20 giờ/điểm của phương pháp được hiệu chỉnh cho cách làm truyền thống, trong khi WBS đã tính đến việc dùng AI agent viết mã có kiểm soát (giả định nền §5) và việc dùng lại thành phần nguồn mở trưởng thành. Hai là số trường hợp sử dụng là ước lượng sơ bộ; sai 15 đến 20 trường hợp sử dụng đã đủ đổi dấu chênh lệch.

Báo cáo chọn **cách người-tháng làm cơ sở** cho tổng mức đầu tư vì ba lý do: nó gắn trực tiếp với WBS, bảng định biên và tiến độ ở D01-02 nên kiểm soát được bằng EVM trong thực hiện; nó không phụ thuộc vào một văn bản chưa rõ hiệu lực; và nó cho con số thận trọng thấp hơn, phù hợp với nguyên tắc tổng mức đầu tư là trần chi phí. Phương pháp điểm trường hợp sử dụng được giữ trong hồ sơ làm phép kiểm tra chéo; nếu cơ quan thẩm định yêu cầu dùng phương pháp này làm cơ sở thì G(TB) phần mềm nội bộ tăng 1.225 triệu đồng và dự phòng tăng tương ứng khoảng 114 triệu đồng.

### 8.3. Chi phí hạ tầng

#### 8.3.1. Phương án H1: mua sắm thiết bị tại trung tâm dữ liệu tỉnh

Theo kịch bản cơ sở của Chương 4 mục 4.6.3 và Chương 6 mục 6.8, tỉnh thí điểm cỡ M cần 9 máy chủ vật lý (4 PROD, 3 DR, 2 STAGING), thiết bị mạng, tường lửa và thiết bị sao lưu độc lập, còn DEV và TEST thuê cloud chính phủ từ T0. Bảng dưới đây lượng giá danh mục thiết bị theo đơn giá trung vị, kèm tổng ở hai đầu khoảng giá.

| Thiết bị | Số lượng | Đơn giá trung vị | Thành tiền |
|---|---|---|---|
| Máy chủ PROD (2 × 32 nhân, 512 GB, 4 × 3,84 TB NVMe, 2 × 4 TB HDD, bảo hành 5 năm) | 4 | 800 | 3.200 |
| Máy chủ DR (4 × 1,92 TB NVMe, 2 × 4 TB HDD) | 3 | 750 | 2.250 |
| Máy chủ STAGING (4 × 1,92 TB NVMe, 2 × 2 TB HDD) | 2 | 720 | 1.440 |
| Chuyển mạch đầu tủ 48 × 25 GbE, 4 × 100 GbE | 4 | 250 | 1.000 |
| Chuyển mạch quản trị 48 × 1 GbE | 2 | 35 | 70 |
| Tường lửa thế hệ mới ≥ 2 Gbps khi bật IPS (hai cặp sẵn sàng cao) | 4 | 350 | 1.400 |
| Thiết bị sao lưu độc lập 20 TB có khóa bất biến | 1 | 500 | 500 |
| Tủ rack 42U, PDU đo lường, KVM | 3 | 80 | 240 |
| **Cộng thiết bị** | | | **10.100** |
| Lắp đặt, cấu hình, vận chuyển (3%) | | | 303 |
| **Cộng thiết bị H1** | | | **10.403** (khoảng 8.096 – 13.575) |

: Chi phí mua sắm thiết bị theo phương án H1

Nền ảo hóa, hệ điều hành và Kubernetes dùng bản mã nguồn mở theo Chương 6 mục 6.9 nên chi phí bản quyền bằng 0. Máy chủ được mua kèm bảo hành 5 năm của hãng, nên trong cửa sổ TCO không phát sinh chi phí bảo trì phần cứng; nếu chỉ mua bảo hành 3 năm thì giá máy chủ giảm khoảng 8% nhưng Năm 4 và Năm 5 phải thêm khoảng 8% giá trị thiết bị mỗi năm cho gia hạn bảo hành. Theo dõi kế toán, thiết bị được khấu hao đều 5 năm, khoảng 2.081 triệu đồng mỗi năm; TCO trong chương tính theo dòng tiền (ghi chi phí khi thanh toán) nên khấu hao chỉ để tham khảo cho báo cáo tài sản. Chi phí vận hành riêng của H1 gồm điện khoảng 282 triệu đồng/năm (khoảng 7,2 kW tải trung bình của hai site, PUE 1,6) và đường truyền khoảng 55 triệu đồng/tháng (Internet hai nhà cung cấp tại hai site, kênh riêng 500 Mbps sang DR theo Chương 6 mục 6.6.4; mạng truyền số liệu chuyên dùng giả định không thu phí). DEV và TEST thuê cloud (120 vCPU, 416 GB RAM, 4 TB SSD, 4 TB HDD) khoảng 84,7 triệu đồng/tháng.

#### 8.3.2. Phương án H2: thuê cloud chính phủ

Với H2, mọi môi trường thuê theo bảng quy đổi ở Chương 6 mục 6.7.2 (78 máy ảo, 832 vCPU, 2.392 GB RAM, 27,8 TB SSD, 21 TB lưu trữ đối tượng). Chi phí thuê theo tháng được tính từ đơn giá ở mục 8.1.3, cộng phí mạng, địa chỉ IP, tường lửa và cân bằng tải của nhà cung cấp. Bảng sau cho chi phí theo môi trường ở mức giá trung vị và hai đầu khoảng.

| Môi trường | Tài nguyên | Triệu đồng/tháng (trung vị) | Khoảng thấp – cao | Thời điểm bắt đầu thuê |
|---|---|---|---|---|
| PROD | 344 vCPU, 960 GB, 12,4 TB SSD, 11 TB S3 | 229,0 | 168,0 – 295,0 | T0+9 |
| DR | 192 vCPU, 560 GB, 6,9 TB SSD, 8 TB S3 | 142,2 | 102,9 – 186,5 | T0+9 |
| STAGING | 176 vCPU, 456 GB, 4,5 TB SSD, 2 TB S3 | 96,3 | 71,5 – 122,1 | T0+6 |
| DEV và TEST | 120 vCPU, 416 GB, 4 TB SSD, 4 TB HDD | 84,7 | 62,8 – 107,6 | T0 |
| **Cộng khi đủ môi trường** | | **552,2** | **405,2 – 711,2** | |

: Chi phí thuê cloud chính phủ theo môi trường và thời điểm bắt đầu (H2)

Một năm thuê đủ môi trường khoảng 6.626 triệu đồng, gần bằng hai phần ba giá trị toàn bộ thiết bị H1. Đây là lý do H2 có tổng mức đầu tư thấp hơn nhưng TCO năm năm cao hơn: thuê cloud phù hợp với tải biến động, trong khi tải của Datahub là tải nền ổn định chạy 24/7. Giá cloud chính phủ có thể giảm 15% đến 30% nếu ký cam kết nhiều năm; phân tích độ nhạy ở mục 8.9 cho thấy kể cả khi giá giảm 25%, TCO của H2 vẫn cao hơn H1 khoảng 4 tỷ đồng. Đường truyền ngoài phần do cloud cung cấp (kết nối mạng chuyên dùng, kênh tới các sở) khoảng 25 triệu đồng/tháng. H2 giảm đội vận hành tỉnh từ 5,5 xuống 4,5 FTE (bớt một kỹ sư hạ tầng, D01-02 §6.5.2).

Trong tổng mức đầu tư, phần thuê cloud trong 18 tháng thực hiện được ghi vào G(DV) (1.524 triệu đồng với H1 cho DEV và TEST; 6.020 triệu đồng với H2 cho mọi môi trường). Phần thuê từ T0+18 trở đi là chi phí vận hành, chi từ chi thường xuyên theo hình thức thuê dịch vụ công nghệ số nhiều năm mà Nghị định 224/2026 cho phép.

### 8.4. Phần mềm thương mại

Kịch bản cơ sở không có chi phí bản quyền phần mềm thương mại, vì toàn bộ stack (Spring Boot, Camel Quarkus, Kafka, PostgreSQL, Keycloak, OPA, OpenBao, APISIX, Istio, Argo CD, LGTM, nền ảo hóa KVM, Linux bản cộng đồng) là mã nguồn mở với giấy phép cho phép dùng trong cơ quan nhà nước, theo nguyên tắc NT-09 tại D03-01. Chi phí nhỏ có tính thương mại (chứng thư TLS và chứng thư số chuyên dùng, phần mềm phòng chống mã độc trên máy chủ theo yêu cầu cấp độ 3) được tính trong chi phí vận hành an toàn thông tin.

Chủ đầu tư có thể chọn kịch bản **hỗ trợ thương mại tùy chọn**, mua gói hỗ trợ của hãng cho các thành phần có rủi ro vận hành cao nhất: bản phân phối Kubernetes và hệ điều hành doanh nghiệp, Kafka, PostgreSQL, Keycloak. Đơn vị tính thường là bộ xử lý vật lý (18 bộ xử lý trên 9 máy chủ) hoặc số node (71 node trên H1). Giá trị tham khảo là khoảng **1.500 triệu đồng/năm** (khoảng 900 – 2.500 tùy hãng và mức cam kết), bắt đầu từ khi PROD vận hành (T0+10). Kịch bản này làm TCO năm năm tăng khoảng 6.620 triệu đồng (H1 lên 69.271, H2 lên 78.890 triệu đồng). Báo cáo không khuyến nghị đưa vào kịch bản cơ sở, vì đội hỗ trợ kỹ thuật của nhà thầu (mục 8.7) đã đảm nhận việc nâng phiên bản và vá lỗi; nhưng khuyến nghị cân nhắc riêng cho PostgreSQL và Kafka nếu đội vận hành tỉnh chưa đạt bậc chuyển giao "độc lập" tại G5 (D01-02 §6.8). Con số chính xác cần báo giá của nhà cung cấp (Q-D0101-85).

### 8.5. Quản lý dự án, tư vấn, chi phí khác và dự phòng

#### 8.5.1. Quản lý dự án

Chi phí quản lý dự án G(QLDA) gồm chi phí hoạt động của Ban quản lý dự án (khoảng 3,5 FTE suốt giai đoạn thực hiện theo giả định nền §5) và chi phí giám sát, đánh giá đầu tư. Báo cáo tính theo tỷ lệ tham khảo 3% của G(TB), ra **944 triệu đồng** với H1 và 632 triệu đồng với H2. Phép kiểm tra từ dưới lên cho kết quả tương đương: 3,5 FTE × 18 tháng × khoảng 12 triệu đồng chi phí tăng thêm mỗi người-tháng (phụ cấp, công tác phí, hội họp, văn phòng phẩm, không gồm lương ngạch bậc đã chi từ ngân sách thường xuyên) là 756 triệu đồng, cộng giám sát, đánh giá đầu tư khoảng 150 triệu đồng. Tỷ lệ chính thức lấy theo định mức của Thông tư 39/2026 khi đối chiếu (Q-D0101-81).

#### 8.5.2. Tư vấn

Chi phí tư vấn G(TV) tính theo người-tháng chuyên gia, vì khối lượng tư vấn của dự án phần mềm phụ thuộc vào độ phức tạp hơn là vào giá trị thiết bị. Gói thầu chính được giả định là gói thiết kế và cung cấp hàng hóa (EP), trong đó nhà thầu vừa lập thiết kế chi tiết vừa triển khai, như Nghị định 224/2026 cho phép với hạng mục phần mềm nội bộ; vì vậy không có dòng chi phí thiết kế chi tiết riêng (nỗ lực FRS, SDD đã nằm trong WBS của nhà thầu). Nếu cơ quan thẩm định yêu cầu tách thiết kế chi tiết thành gói riêng, cần thêm khoảng 20 người-tháng tư vấn, tức 700 triệu đồng (Q-D0101-86).

| Khoản tư vấn | Khối lượng | Thành tiền (giá trị tham khảo) | Thời điểm |
|---|---|---|---|
| Khảo sát, lập BCNCKT và thiết kế cơ sở | 18 người-tháng | 630 | T0 − 7 đến T0 − 5 |
| Lập HSMT, đánh giá HSDT hai gói (EP phần mềm, mua sắm thiết bị) | 6 người-tháng | 210 | T0 − 2 đến T0 |
| Tư vấn giám sát triển khai 18 tháng | 27 người-tháng (1,5 FTE) | 945 | T0 đến T0+18 |
| **Cộng G(TV)** | 51 người-tháng | **1.785** | |

: Chi phí tư vấn theo khoản

#### 8.5.3. Chi phí khác

Chi phí khác G(K) gồm các khoản Thông tư 39/2026 liệt kê (thẩm định, bảo hiểm, kiểm thử, vận hành thử, kiểm toán) và hai khoản đặc thù của dự án thay thế hệ đang chạy. Kiểm thử phần mềm độc lập là yêu cầu của Thông tư 41/2026/TT-BKHCN (phần mềm nội bộ phải được kiểm thử) và được tách khỏi kiểm thử của nhà thầu để bảo đảm khách quan. Kiểm thử xâm nhập và đánh giá an toàn thông tin độc lập thực hiện hai đợt, trước G2 (trước khi MVP vào PROD) và trước G4 (sau khi thêm phân hệ thanh toán và bảo vệ dữ liệu cá nhân). Khoản hỗ trợ của nhà cung cấp hệ cũ chi trả cho việc trích xuất dữ liệu, cấu hình và phối hợp cắt chuyển, gắn trực tiếp với RSK-17 (rủi ro lớn nhất trong sổ rủi ro); có ngân sách sẵn giúp đàm phán phụ lục bàn giao trước T0.

| Khoản chi phí khác | Thành tiền H1 (giá trị tham khảo) | Ghi chú |
|---|---|---|
| Thẩm định dự án, thiết kế; lệ phí | 50 | |
| Kiểm thử phần mềm độc lập trước nghiệm thu | 420 | 12 người-tháng chuyên gia |
| Kiểm thử xâm nhập, đánh giá ATTT độc lập | 400 | Hai đợt, mỗi đợt 200 |
| Hỗ trợ của nhà cung cấp hệ cũ | 500 | Trích xuất, phối hợp cắt chuyển (RSK-17) |
| Bảo hiểm thiết bị, kiểm toán độc lập, thẩm tra quyết toán, hội nghị nghiệm thu | 261 | H2: 240 (không có bảo hiểm thiết bị) |
| **Cộng G(K)** | **1.631** | H2: 1.610 |

: Chi phí khác theo khoản mục của phương án H1

Chi phí chạy song song hệ cũ (gia hạn hợp đồng vận hành hệ LGSP cũ đến G5) không cộng vào tổng mức đầu tư vì đây là chi thường xuyên tỉnh đang chi; điểm quan trọng là PA3 cho phép chấm dứt khoản này từ T0+18, trong khi PA1 phải duy trì nó suốt vòng đời. Hồ sơ đề xuất cấp độ do nhà thầu lập (đã tính trong G(TB)); việc thẩm định hồ sơ của cơ quan chuyên trách không thu phí theo hiểu biết hiện tại.

#### 8.5.4. Dự phòng

Dự phòng G(DP) được tính bằng 9,33% tổng G(TB), G(QLDA), G(TV), G(K), dưới mức trần 10% của Thông tư 39/2026, gồm hai phần. Phần dự phòng khối lượng phát sinh là 7%, tức **2.508 triệu đồng** với H1; khoản này bao trùm khoản dự phòng rủi ro mà D01-02 chương 8 đã định lượng (khoảng 28 người-tháng và 75 triệu đồng, tức 1.195 triệu đồng ở đơn giá 40 triệu đồng/người-tháng) với phần dư khoảng 1.313 triệu đồng cho rủi ro ngoài nhân công như hạ tầng PROD bàn giao chậm (RSK-24) hay giá thiết bị biến động (RSK-40). Phần dự phòng trượt giá là 4%/năm trong 7 tháng từ khi lập báo cáo (T0 − 7) đến khi ký hợp đồng, tức 2,33%, **836 triệu đồng**; sau khi ký, hợp đồng trọn gói chuyển rủi ro trượt giá sang nhà thầu. Cộng hai phần là **3.344 triệu đồng** với H1 (8,2% tổng mức đầu tư) và 2.342 triệu đồng với H2. Trong TCO, dự phòng được giả định dùng hết (cách tính thận trọng).

### 8.6. Tổng mức đầu tư

#### 8.6.1. Bảng tổng mức đầu tư

Bảng dưới đây là tổng mức đầu tư sơ bộ của PA3 cho tỉnh thí điểm cỡ M theo hai phương án hạ tầng, trình bày theo cơ cấu của Thông tư 39/2026. Cột H1 là kịch bản cơ sở khuyến nghị (PROD, STAGING, DR tại chỗ; DEV, TEST thuê cloud); cột H2 là toàn bộ thuê cloud chính phủ.

| Mã | Khoản mục | H1 (triệu đồng) | H2 (triệu đồng) |
|---|---|---|---|
| **G(TB)** | **Chi phí thiết bị (theo nghĩa của TT 39/2026)** | **31.473** | **21.070** |
| TB-1 | Phần mềm nội bộ (399,5 người-tháng) | 15.980 | 15.980 |
| TB-2 | Cài đặt, triển khai phần mềm trên hạ tầng | 840 | 840 |
| TB-3 | Chuyển đổi, di trú dữ liệu và chạy song song | 960 | 960 |
| TB-4 | Đào tạo, chuyển giao (nhà thầu 320, tổ chức lớp 150, chứng chỉ đội vận hành 180) | 650 | 650 |
| TB-5 | Hồ sơ đề xuất cấp độ, đánh giá tác động DLCN | 240 | 240 |
| TB-6 | Bảo hành 12 tháng sau G5 (60 người-tháng) | 2.400 | 2.400 |
| TB-7 | Thiết bị hạ tầng H1 gồm lắp đặt | 10.403 | 0 |
| **G(QLDA)** | **Quản lý dự án** | **944** | **632** |
| **G(TV)** | **Tư vấn** | **1.785** | **1.785** |
| **G(K)** | **Chi phí khác** | **1.631** | **1.610** |
| | Cộng trước dự phòng | 35.833 | 25.097 |
| **G(DP)** | **Dự phòng (7% khối lượng + 2,33% trượt giá)** | **3.344** | **2.342** |
| **G(DV)** | **Thuê dịch vụ công nghệ số trong 18 tháng thực hiện** | **1.524** | **6.020** |
| | **Tổng mức đầu tư trước thuế GTGT** | **40.702** | **33.460** |
| | Thuế GTGT ước tính (10% trên thiết bị, G(DV), G(TV), G(K)) | 1.534 | 942 |
| | **Tổng mức đầu tư gồm thuế GTGT (ước tính)** | **42.236** | **34.401** |

: Tổng mức đầu tư sơ bộ của PA3 theo phương án hạ tầng H1 và H2

Ở mức khoảng 40 đến 42 tỷ đồng, dự án nằm dưới ngưỡng dự án nhóm B theo hiểu biết hiện tại về Luật Đầu tư công (nhóm C dưới 60 tỷ đồng cho lĩnh vực này), nhưng ngưỡng sau sửa đổi năm 2025 và ngưỡng thiết kế một bước của Nghị định 224/2026 chưa được xác minh (tóm tắt pháp lý phần C, Q-D0101-87). Cơ cấu tổng mức đầu tư H1 được thể hiện ở biểu đồ sau.

```{.mermaid caption="Cơ cấu tổng mức đầu tư PA3 theo H1 theo nhóm chi phí"}
pie showData
    title "Cơ cấu tổng mức đầu tư PA3 x H1 (triệu đồng, trước thuế)"
    "Phần mềm nội bộ" : 15980
    "Triển khai, di trú, đào tạo, hồ sơ ATTT" : 2690
    "Bảo hành 12 tháng" : 2400
    "Thiết bị H1" : 10403
    "QLDA, tư vấn, chi phí khác" : 4360
    "Dự phòng" : 3344
    "Thuê cloud DEV, TEST" : 1524
```

Biểu đồ cho thấy nhân công nhà thầu (phần mềm, triển khai, di trú, đào tạo, hồ sơ, bảo hành) chiếm khoảng 52% tổng mức đầu tư và thiết bị chiếm khoảng 26%. Vì vậy hai biến số chi phối tổng mức là đơn giá nhân công và việc có đưa thiết bị vào dự án hay không.

#### 8.6.2. Vì sao H2 có tổng mức thấp hơn

H2 thấp hơn H1 khoảng 7.242 triệu đồng ở tổng mức đầu tư vì không phải mua 10.403 triệu đồng thiết bị; đổi lại G(DV) tăng 4.496 triệu đồng do thuê PROD, DR và STAGING từ T0+6 và T0+9. Chênh lệch này đảo chiều ngay trong Năm 3, khi tiền thuê cloud của H2 mỗi năm (khoảng 6,9 tỷ đồng) cao hơn tiền thuê DEV, TEST của H1 khoảng 5,8 tỷ đồng, trong khi điện, đường truyền và nhân sự hạ tầng tăng thêm của H1 chỉ khoảng 1 tỷ đồng mỗi năm. Hội đồng thẩm định cần thấy rõ rằng tổng mức đầu tư thấp hơn không có nghĩa là phương án rẻ hơn; tiêu chí đúng là TCO ở mục 8.8.

#### 8.6.3. Nếu thiết bị thuộc dự án hạ tầng riêng

Nếu tỉnh quyết định mua thiết bị H1 bằng một dự án hạ tầng riêng (Q-D0101-52), tổng mức đầu tư của dự án Datahub giảm còn khoảng **28.964 triệu đồng trước thuế** (bỏ 10.403 triệu đồng thiết bị, kéo theo G(QLDA) giảm 312, G(K) giảm 21 và dự phòng giảm khoảng 1.002 triệu đồng). Khi đó dự án hạ tầng phải hoàn thành bàn giao STAGING trước T0+6 và PROD, DR trước T0+10, và rủi ro RSK-24 (hạ tầng bàn giao chậm) trở thành rủi ro liên dự án, phải có cơ chế điều phối giữa hai chủ đầu tư.

### 8.7. Chi phí vận hành hằng năm

Chi phí vận hành bắt đầu khi PROD vào vận hành (T0+10) và kéo dài suốt vòng đời. Bảng sau trình bày chi phí vận hành của một năm đầy đủ sau bảo hành (Năm 4, đã gồm trượt giá 4%/năm từ Năm 3) cho hai phương án hạ tầng. Năm 4 được chọn vì là năm đầu tiên không còn khoản bảo hành và đã có đủ các hạng mục vận hành thường xuyên.

| Hạng mục vận hành | Cơ sở tính | H1, Năm 4 | H2, Năm 4 |
|---|---|---|---|
| Nhân sự vận hành tỉnh | 5,5 FTE (H1) hoặc 4,5 FTE (H2) × 25 triệu đồng/tháng | 1.785 | 1.460 |
| Hỗ trợ kỹ thuật, bảo trì phần mềm của nhà thầu | 2,5 FTE × 40 triệu đồng/tháng, từ T0+30 | 1.298 | 1.298 |
| Hạ tầng, thuê cloud | H1: DEV, TEST; H2: mọi môi trường | 1.099 | 7.167 |
| Điện, đường truyền | H1: điện 282 + đường truyền 660/năm; H2: đường truyền 300/năm | 1.018 | 324 |
| SOC thuê ngoài 24/7 | 400/năm | 433 | 433 |
| Đánh giá ATTT định kỳ, kiểm thử xâm nhập | 250/năm từ Năm 3 | 270 | 270 |
| Phần mềm phòng chống mã độc, chứng thư số, khác | 150/năm | 162 | 162 |
| Đào tạo duy trì | 60/năm từ Năm 3 | 65 | 65 |
| **Cộng** | | **6.130** | **11.179** |

: Chi phí vận hành hằng năm tại Năm 4 theo H1 và H2

Khoản hỗ trợ kỹ thuật của nhà thầu tương đương khoảng **7,5% giá trị phần mềm nội bộ mỗi năm** (1.200 triệu đồng trước trượt giá trên 15.980 triệu đồng), thấp hơn một chút so với khoảng 8% đến 15% thường dùng để lập kế hoạch bảo trì phần mềm. Báo cáo chọn cách tính theo FTE thay vì theo phần trăm vì nhu cầu bảo trì của Datahub do nhịp nâng phiên bản khoảng hai mươi thành phần nguồn mở quyết định (D01-02 §6.10), không tỷ lệ với giá trị phần mềm. Nghị định 224/2026 cho phép chỉ định chính doanh nghiệp đã phát triển phần mềm làm quản trị, vận hành, nên hợp đồng này có thể ký tiếp với nhà thầu phát triển. Khi Datahub được nhiều tỉnh dùng, khoản hỗ trợ sản phẩm được chia cho các tỉnh (mục 8.10), còn nhân sự vận hành, SOC và hạ tầng là chi phí riêng của từng tỉnh.

Tần suất đánh giá an toàn thông tin định kỳ với hệ thống cấp độ 3 được giả định là hằng năm; quy định cụ thể phụ thuộc vào văn bản hướng dẫn Luật An ninh mạng 116/2025 đang được xác minh (tóm tắt pháp lý phần E mục 5), nếu là hai năm một lần thì chi phí vận hành giảm khoảng 135 triệu đồng/năm.

### 8.8. TCO năm năm

#### 8.8.1. TCO của PA3 với H1 và H2

TCO được tính theo dòng tiền từng tháng, gồm toàn bộ tổng mức đầu tư (kể cả dự phòng) và chi phí vận hành đến hết Năm 5. Thanh toán hợp đồng nhà thầu theo cổng nghiệm thu như D01-02 chương 7; bảo hành trả theo quý trong T0+18 đến T0+30. Bảng sau cho TCO theo nhóm chi phí và theo năm.

| Nhóm chi phí | H1 Năm 1 | Năm 2 | Năm 3 | Năm 4 | Năm 5 | H1 cộng | H2 cộng |
|---|---|---|---|---|---|---|---|
| Hợp đồng EP (nhân công, đào tạo) | 11.482 | 7.188 | 0 | 0 | 0 | 18.670 | 18.670 |
| Thiết bị | 10.403 | 0 | 0 | 0 | 0 | 10.403 | 0 |
| Thuê cloud | 1.016 | 1.016 | 1.057 | 1.099 | 1.143 | 5.331 | 30.844 |
| QLDA, tư vấn, chi phí khác | 2.599 | 1.761 | 0 | 0 | 0 | 4.360 | 4.027 |
| Dự phòng | 2.382 | 962 | 0 | 0 | 0 | 3.344 | 2.342 |
| Bảo hành | 0 | 1.200 | 1.200 | 0 | 0 | 2.400 | 2.400 |
| Nhân sự vận hành tỉnh | 275 | 1.650 | 1.716 | 1.785 | 1.856 | 7.282 | 5.958 |
| SOC và ATTT | 92 | 550 | 894 | 930 | 967 | 3.434 | 3.434 |
| Điện, đường truyền | 157 | 942 | 979 | 1.018 | 1.059 | 4.155 | 1.324 |
| Hỗ trợ kỹ thuật nhà thầu | 0 | 0 | 624 | 1.298 | 1.350 | 3.272 | 3.272 |
| **Cộng H1** | **28.407** | **15.268** | **6.470** | **6.130** | **6.375** | **62.651** | |
| **Cộng H2** | 18.616 | 19.523 | 11.325 | 11.179 | 11.627 | | **72.271** |

: TCO năm năm của PA3 theo nhóm chi phí và theo năm, H1 so với H2

Sau năm năm, H1 rẻ hơn H2 khoảng **9.620 triệu đồng** (13%). Đường lũy kế của hai phương án cắt nhau trong Năm 3: đến hết Năm 2, H1 đã chi 43.675 triệu đồng còn H2 chi 38.139 triệu đồng; đến hết Năm 3, H1 là 50.145 còn H2 là 49.464 triệu đồng, gần bằng nhau; từ Năm 4, mỗi năm H2 đắt hơn khoảng 5 tỷ đồng. Biểu đồ sau so sánh chi phí từng năm.

```{.mermaid caption="Chi phí từng năm của PA3, H1 so với H2"}
xychart-beta
    title "Chi phí theo năm của PA3, H1 và H2 (triệu đồng)"
    x-axis ["Năm 1", "Năm 2", "Năm 3", "Năm 4", "Năm 5"]
    y-axis "Triệu đồng" 0 --> 30000
    bar [28407, 15268, 6470, 6130, 6375]
    line [18616, 19523, 11325, 11179, 11627]
```

Cột là H1, đường là H2. Hình dạng hai chuỗi thể hiện đúng bản chất hai phương án: H1 dồn chi phí vào Năm 1 (thiết bị), H2 trải đều và cao hơn từ Năm 3. Với nguồn vốn, điều này cũng có nghĩa là H1 cần vốn đầu tư phát triển lớn hơn nhưng chi thường xuyên hằng năm sau dự án nhỏ hơn khoảng 5 tỷ đồng, giảm mức độ của RSK-41 (không bố trí được kinh phí vận hành).

#### 8.8.2. Kịch bản giá thấp và cao

Giữ nguyên khối lượng và đơn giá nhân công, chỉ thay giá thiết bị, cloud, đường truyền và dịch vụ an toàn thông tin về hai đầu khoảng, TCO năm năm của H1 nằm trong khoảng **56.445 – 70.116 triệu đồng** (tổng mức đầu tư 37.704 – 44.694) và của H2 trong khoảng **62.372 – 83.049 triệu đồng** (tổng mức 31.865 – 35.175). Ở mọi kịch bản giá, H1 vẫn có TCO thấp hơn H2.

### 8.9. Phân tích độ nhạy

Phân tích độ nhạy thay đổi từng biến một quanh kịch bản cơ sở. Đơn giá nhân công thay đổi ±20% (áp cho nhân công nhà thầu, tư vấn và hỗ trợ kỹ thuật); khối lượng thay đổi ±15% (áp cho người-tháng thực hiện và bảo hành); giá cloud thay đổi ±25% (áp cho tài nguyên tính toán và lưu trữ thuê). Bảng sau cho tổng mức đầu tư và TCO năm năm ở mỗi trường hợp.

| Biến | Thay đổi | Tổng mức H1 | TCO H1 | Tổng mức H2 | TCO H2 |
|---|---|---|---|---|---|
| Cơ sở | | 40.702 | 62.651 | 33.460 | 72.271 |
| Đơn giá nhân công | −20% | 35.548 | 56.843 | 28.307 | 66.463 |
| Đơn giá nhân công | +20% | 45.855 | 68.459 | 38.613 | 78.078 |
| Khối lượng | −15% | 37.198 | 59.148 | 29.956 | 68.767 |
| Khối lượng | +15% | 44.205 | 66.154 | 36.963 | 75.774 |
| Giá cloud | −25% | 40.343 | 61.397 | 32.105 | 65.384 |
| Giá cloud | +25% | 41.060 | 63.905 | 34.815 | 79.157 |

: Độ nhạy của tổng mức đầu tư và TCO theo đơn giá nhân công, khối lượng và giá cloud

Đơn giá nhân công là biến nhạy nhất với tổng mức đầu tư (±5,2 tỷ đồng, khoảng ±12,7%), tiếp theo là khối lượng (±3,5 tỷ đồng). Với TCO của H2, giá cloud lại là biến nhạy nhất (±6,9 tỷ đồng), vì gần 43% TCO của H2 là tiền thuê cloud. Kết luận chọn H1 giữ nguyên trong mọi trường hợp đơn biến; chỉ khi giá cloud giảm khoảng 40% so với trung vị (tức khoảng 0,12 triệu đồng/vCPU-tháng) thì TCO hai phương án mới bằng nhau. Nếu tổng mức đầu tư vượt trần được duyệt do đơn giá hoặc khối lượng tăng, đòn bẩy điều chỉnh đầu tiên là thu hẹp các phân hệ đợt 3 (PH-06, PH-08, PH-16, PH-17 theo phân đợt của D02-01), như D01-02 chương 2 đã nêu.

### 8.10. So sánh TCO giữa các phương án đầu tư

Chương 4 xếp hạng định tính chi phí vòng đời (tiêu chí TC-4); mục này quy đổi thành số tiền. Vì chưa có báo giá thị trường cho PA1 và PA2 (Q-D0101-44), số liệu là ước lượng có lập luận, độ bất định khoảng ±20% đến ±40%. Để so sánh công bằng, cả bốn phương án dùng cùng hạ tầng H1, cùng chi phí QLDA, tư vấn, chi phí khác, nhân sự vận hành và an toàn thông tin; chỉ khác ở bốn yếu tố: khối lượng phát triển hoặc tùy biến, đơn giá nhân công, bản quyền hoặc phí thuê định kỳ, và mức hỗ trợ kỹ thuật sau bảo hành. Giả định của từng phương án như sau.

- **PA1** nâng cấp hệ LGSP cũ cần khoảng 380 người-tháng (320 – 450) vì phải dịch ngược hành vi các luồng, nâng nền Camel, Pulsar và cổng API và bổ sung lớp dữ liệu dùng chung, với đơn giá cao hơn 10% (44 triệu đồng/người-tháng) do thực tế chỉ nhà cung cấp cũ hoặc đối tác của họ làm được; phí hỗ trợ các thành phần độc quyền của hệ cũ khoảng 1.200 triệu đồng/năm (800 – 1.800); hỗ trợ kỹ thuật sau bảo hành 3 FTE.
- **PA2a** dùng sản phẩm LGSP trong nước cần khoảng 190 người-tháng tùy biến (150 – 240) cho dữ liệu chủ, chất lượng dữ liệu, bảo vệ dữ liệu cá nhân và di trú; phí bản quyền hoặc thuê khoảng 3.000 triệu đồng/năm cho tỉnh cỡ M (2.000 – 4.500).
- **PA2b** dùng nền tảng tích hợp quốc tế cần khoảng 260 người-tháng tùy biến (200 – 320) ở đơn giá chuyên gia 55 triệu đồng/người-tháng; thuê bao bản quyền theo nhân xử lý khoảng 5.500 triệu đồng/năm (3.500 – 8.000).

Bảng sau là kết quả TCO năm năm cho một tỉnh và cho hai tỉnh. Cột hai tỉnh cộng thêm chi phí đưa tỉnh thứ hai cỡ M vào vận hành: PA3 dùng chế độ dùng chung (mục 8.11), còn PA1, PA2a, PA2b phải dựng cụm riêng vì không phải sản phẩm đa tenant, cộng bản quyền cho tỉnh thứ hai.

| Phương án | TCO 5 năm, một tỉnh | Khoảng | TCO 5 năm, hai tỉnh (ước lượng) | Ghi chú |
|---|---|---|---|---|
| PA1 Nâng cấp hệ cũ | 68.481 | 61.030 – 76.734 | khoảng 99.200 | Không đa tenant; phụ thuộc nhà cung cấp cũ |
| PA2a LGSP trong nước | 61.840 | 55.339 – 72.466 | khoảng 100.200 | Phí thuê lặp lại mỗi năm, mỗi tỉnh |
| PA2b Nền tảng quốc tế | 83.536 | 68.866 – 101.238 | khoảng 132.500 | Bản quyền theo nhân xử lý |
| **PA3 Xây mới Datahub** | **62.651** | 56.445 – 70.116 | **72.812** | Chi phí biên tỉnh 2 thấp |

: TCO năm năm của bốn phương án cho một tỉnh và hai tỉnh

Kết quả cần được đọc thẳng thắn. Với một tỉnh, PA3 và PA2a có TCO gần như bằng nhau (chênh khoảng 1,3%, nhỏ hơn nhiều so với độ bất định), PA1 đắt hơn khoảng 9% và PA2b đắt hơn khoảng 33%. Lợi thế chi phí của PA3 chỉ hiện rõ khi tính nhân rộng: với hai tỉnh, PA3 rẻ hơn PA1 và PA2a khoảng 27 tỷ đồng, vì tỉnh thứ hai chỉ cần mở rộng hạ tầng và triển khai, không phải trả bản quyền và không phải dựng cụm riêng. Ngoài ra, các phương án PA2 không làm chủ mã nguồn và có rủi ro tăng giá thuê khi gia hạn, điều mà bảng TCO năm năm không phản ánh hết. Vì vậy chi phí không phải lý do duy nhất chọn PA3 khi chỉ xét tỉnh thí điểm, nhưng là lý do mạnh khi xét mục tiêu sản phẩm cho nhiều tỉnh (BO-06, KPI-12 tại D02-01). Điểm TC-4 ở Chương 4 (PA3 đạt 4, PA2a đạt 3) vẫn phù hợp với số liệu này vì tiêu chí đã tính cả nhân rộng.

### 8.11. Nhân rộng: chi phí biên của tỉnh thứ 2 đến n

Chi phí biên là chi phí tăng thêm để đưa một tỉnh mới cỡ M vào vận hành trên Datahub, khi sản phẩm đã có. Phần phát triển phần mềm không phát sinh lại; tỉnh mới chỉ chịu chi phí hạ tầng, triển khai, di trú từ hệ LGSP của tỉnh đó, đào tạo và vận hành. Bảng sau so sánh ba cách đưa tỉnh mới lên, tương ứng ba mô hình tenant ở Chương 4 mục 4.7 và D03-10.

| Thành phần (tỉnh cỡ M) | Dùng chung trên cụm sẵn có (SHARED) | Cụm riêng H1 | Cụm riêng H2 |
|---|---|---|---|
| Hạ tầng một lần | 4.017 (thêm 3 máy chủ PROD, 2 máy chủ DR) | 10.403 (đủ 9 máy chủ và thiết bị) | 0 |
| Triển khai, di trú, kết nạp HTTT, đào tạo, cập nhật hồ sơ cấp độ | 1.800 (45 người-tháng) | 2.200 (55 người-tháng) | 2.200 |
| Giám sát, kiểm thử ATTT, hỗ trợ của nhà cung cấp hệ cũ tỉnh đó | 600 | 600 | 600 |
| **Cộng một lần** | **6.417** | **13.203** | **2.800** |
| Vận hành hằng năm của tỉnh | 900 (2 FTE vận hành, SOC và đường truyền tăng thêm) | 2.992 | 7.660 |
| **Chi phí 5 năm (một lần + 4 năm vận hành)** | **10.161** | **25.648** | **34.665** |

: Chi phí biên đưa một tỉnh cỡ M mới vào vận hành theo ba chế độ hạ tầng

Chi phí biên **tỉnh thứ hai** theo chế độ dùng chung là khoảng **6.417 triệu đồng một lần và 900 triệu đồng mỗi năm**, chưa tính phần chia khoản hỗ trợ kỹ thuật sản phẩm (1.200 triệu đồng/năm chia đều cho các tỉnh dùng). Khối lượng 45 người-tháng gồm khởi tạo tenant và cấu hình (3), di trú từ hệ cũ của tỉnh đó với công cụ đã có (18), kết nạp HTTT các sở (10), đào tạo (4), quản lý (5), UAT (3) và cập nhật hồ sơ cấp độ (2); phần tử WBS 1.26.6 của dự án đã có 5 người-tháng cho tỉnh 2, nên nếu tỉnh 2 được thực hiện ngay ở W5 thì chi phí biên giảm tương ứng khoảng 200 triệu đồng. Bảng sau cho TCO năm năm bình quân mỗi tỉnh khi số tỉnh tăng, với giả định các tỉnh sau đều cỡ M và dùng chung.

| Số tỉnh | TCO 5 năm toàn bộ | Bình quân mỗi tỉnh |
|---|---|---|
| 1 | 62.651 | 62.651 |
| 2 | 72.812 | 36.406 |
| 3 | 82.973 | 27.658 |
| 5 | 103.295 | 20.659 |
| 10 | 154.100 | 15.410 |

: TCO năm năm toàn bộ và bình quân mỗi tỉnh theo số tỉnh dùng chung Datahub

Từ tỉnh thứ ba, bình quân mỗi tỉnh đã thấp hơn một nửa chi phí của một tỉnh đơn lẻ. Giới hạn thực tế của chế độ dùng chung là năng lực của cụm và yêu cầu cách ly: tỉnh cỡ L hoặc tỉnh muốn tự vận hành nên dùng cụm riêng (25,6 tỷ đồng năm năm với H1), vẫn rẻ hơn nhiều so với xây mới. Cơ chế pháp lý để tỉnh thứ hai dùng mã nguồn và hạ tầng do tỉnh thí điểm đầu tư, và cách chia chi phí giữa các tỉnh, chưa được xác lập (RSK-39, Q-D0101-43); đây là điều kiện để các con số trên thành hiện thực.

### Câu hỏi mở

Các câu hỏi dưới đây liên quan đến định mức chi phí theo Thông tư 39/2026/TT-BKHCN, thuế GTGT, ngưỡng nhóm dự án và việc bố trí hạ tầng; câu trả lời làm thay đổi các con số của chương này.

- **Q-D0101-81.** Định mức tỷ lệ chi phí quản lý dự án, tư vấn và chi phí khác theo Thông tư 39/2026/TT-BKHCN là bao nhiêu với dự án khoảng 40 tỷ đồng? Chương đang dùng tỷ lệ tham khảo 3% cho G(QLDA) và người-tháng cho G(TV).
- **Q-D0101-82.** Quyết định 671/QĐ-BTTTT còn được áp dụng sau 01/7/2026 không, hay Bộ Khoa học và Công nghệ đã ban hành phương pháp thay thế (kể cả phụ lục của Thông tư 39/2026)? Câu trả lời quyết định phương pháp nào là cơ sở pháp lý cho chi phí phần mềm nội bộ.
- **Q-D0101-83.** Dịch vụ phát triển phần mềm nội bộ của gói EP có thuộc đối tượng không chịu thuế GTGT không? Nếu chịu thuế 10%, tổng mức đầu tư gồm thuế tăng khoảng 2,1 tỷ đồng.
- **Q-D0101-84.** Chủ đầu tư muốn giữ bảo hành 12 tháng (2.400 triệu đồng) trong tổng mức đầu tư, hay chuyển một phần sang hợp đồng hỗ trợ kỹ thuật chi thường xuyên?
- **Q-D0101-85.** Chủ đầu tư có muốn lấy báo giá gói hỗ trợ thương mại cho PostgreSQL, Kafka, Kubernetes để quyết định kịch bản hỗ trợ thương mại không?
- **Q-D0101-86.** Cơ quan thẩm định có chấp nhận gói EP (nhà thầu vừa thiết kế chi tiết vừa triển khai) không, hay yêu cầu tách gói thiết kế chi tiết (thêm khoảng 700 triệu đồng)?
- **Q-D0101-87.** Ngưỡng phân nhóm dự án và ngưỡng thiết kế một bước theo Luật Đầu tư công sửa đổi và Nghị định 224/2026 là bao nhiêu, và dự án khoảng 40 tỷ đồng thuộc nhóm nào?
- **Q-D0101-88.** Giá điện, đường truyền và chỗ đặt thiết bị tại trung tâm dữ liệu tỉnh có được tính cho dự án không, hay trung tâm dữ liệu cấp miễn phí?


## 9. Tổ chức thực hiện, tiến độ và phương án khai thác

**Tóm tắt cho hội đồng thẩm định.** Chủ đầu tư (giả định Sở Khoa học và Công nghệ tỉnh thí điểm `T01`, GĐ-06) trực tiếp quản lý dự án qua một Ban quản lý dự án khoảng 3,5 FTE, thuê tư vấn giám sát độc lập 1,5 FTE trong 18 tháng thực hiện. Dự án được thực hiện qua hai gói thầu chính: gói EP thiết kế chi tiết và triển khai phần mềm nội bộ (18.670 triệu đồng thực hiện cộng 2.400 triệu đồng bảo hành) và gói mua sắm thiết bị hạ tầng H1 (10.403 triệu đồng), cùng bốn hợp đồng tư vấn, dịch vụ nhỏ. Giai đoạn thực hiện kéo dài 18 tháng, chia sáu wave W0 đến W5 khép lại bằng sáu cổng nghiệm thu G0 đến G5, đưa đủ 20 phân hệ vào vận hành theo ba đợt: MVP 12 phân hệ ở G2, đợt 2 gồm PH-19 Thanh toán ở G4, đợt 3 ở G5. Sau nghiệm thu, Trung tâm Chuyển đổi số tỉnh vận hành nền tảng với đội 6 người, nhà thầu bảo hành 12 tháng và chủ đầu tư được chọn giữa hai phương án hỗ trợ kỹ thuật dài hạn. Mã nguồn, dữ liệu và quyền quản trị thuộc về tỉnh trong mọi phương án.

Chương này đáp ứng điểm đ, h và l khoản 2 Điều 47 Luật Đầu tư công (phương án tổ chức quản lý khai thác, tiến độ, tổ chức quản lý dự án) và khoản 3 Điều 45 Nghị định 224/2026/NĐ-CP (CMP-LAW-14) về thuê dịch vụ công nghệ số. Chi tiết điều hành nằm ở D01-02: tổ chức và RACI ở D01-02 §5, tiến độ ở D01-02 §4, gói thầu và giải ngân ở D01-02 §7.

### 9.1. Hình thức tổ chức quản lý dự án

#### 9.1.1. Lựa chọn hình thức

Luật Đầu tư công cho phép ba hình thức quản lý dự án: chủ đầu tư thành lập Ban quản lý dự án, giao Ban quản lý dự án chuyên ngành hoặc khu vực của tỉnh, hoặc thuê tư vấn quản lý dự án. Báo cáo đề xuất **chủ đầu tư thành lập Ban quản lý dự án kiêm nhiệm có bộ phận chuyên trách**, vì ba lý do. Thứ nhất, Datahub là sản phẩm phần mềm phát triển lặp, nên chủ đầu tư phải có một người làm Chủ sản phẩm (Product Owner) phía tỉnh tham gia review từng sprint; vai trò này không thể giao trọn cho một ban quản lý dự án xây dựng vốn quen nghiệm thu khối lượng vật chất. Thứ hai, quyết định nghiệp vụ trong dự án (ưu tiên HTTT nào kết nạp trước, nhóm dịch vụ nào cắt chuyển trước) cần thẩm quyền của sở chủ quản CNTT. Thứ ba, đội vận hành của Trung tâm Chuyển đổi số phải tham gia từ W0 để tiếp nhận dần, điều dễ phối hợp hơn khi Ban quản lý dự án nằm cùng hệ thống sở.

Nếu tỉnh đã có Ban quản lý dự án chuyên ngành có kinh nghiệm dự án CNTT, phương án giao ban này quản lý vẫn khả thi với điều kiện bổ sung hai vị trí chuyên trách là Chủ sản phẩm và cán bộ kỹ thuật nền tảng biệt phái từ sở chủ quản. Câu hỏi này được ghi ở Q-D0101-96.

#### 9.1.2. Cơ cấu Ban quản lý dự án

Bảng dưới đây nêu định biên Ban quản lý dự án phía chủ đầu tư. Định biên này không tính vào 459 người-tháng của nhà thầu và được dự toán trong G(QLDA) ở Chương 8 mục 8.5.1.

| Vị trí | FTE | Trách nhiệm chính |
|---|---|---|
| Trưởng ban (lãnh đạo sở kiêm nhiệm) | 0,5 | Phê duyệt kế hoạch wave, ký biên bản nghiệm thu cổng, xử lý vấn đề leo thang |
| Chủ sản phẩm phía chủ đầu tư | 1 | Quản lý backlog sản phẩm, chấp nhận story, chủ trì nghiệm thu nghiệp vụ, đại diện các sở, ngành |
| Cán bộ kỹ thuật nền tảng | 1 | Theo dõi kiến trúc, ATTT, hạ tầng; đầu mối với Trung tâm Chuyển đổi số và đơn vị chuyên trách ANM |
| Cán bộ kế hoạch, tài chính, đấu thầu | 0,5 | Hồ sơ lựa chọn nhà thầu, hợp đồng, thanh toán, quyết toán |
| Văn thư, tổng hợp | 0,5 | Hồ sơ, biên bản, lưu trữ theo yêu cầu quản lý dự án |
| **Cộng** | **3,5** | |

: Cơ cấu nhân sự Ban quản lý dự án

Tư vấn giám sát triển khai (1,5 FTE trong 18 tháng, 945 triệu đồng ở G(TV)) là đơn vị độc lập với nhà thầu EP. Tư vấn giám sát kiểm tra chất lượng sản phẩm từng wave theo kế hoạch kiểm thử D05-01, xác nhận khối lượng trước mỗi cổng và lập báo cáo giám sát theo Thông tư 41/2026/TT-BKHCN (đề xuất CMP-LAW-24).

### 9.2. Trách nhiệm của các chủ thể

Dự án có mười nhóm chủ thể. Bảng dưới đây nêu trách nhiệm cấp dự án của từng nhóm; ma trận RACI theo từng sản phẩm bàn giao nằm ở D01-02 §5.4. Tên cơ quan ghi theo giả định nền, vì chủ quản CNTT là tham số theo tỉnh (mặc định Sở Khoa học và Công nghệ).

| Chủ thể | Vai trò | Trách nhiệm chính trong dự án |
|---|---|---|
| UBND tỉnh | Người quyết định đầu tư; chủ quản hệ thống thông tin | Quyết định chủ trương và phê duyệt dự án; phê duyệt hồ sơ đề xuất cấp độ 3 (NĐ 331/2026/NĐ-CP); ban hành quy chế khai thác Datahub; chỉ đạo sở, ngành kết nối |
| Sở Khoa học và Công nghệ (giả định) | Chủ đầu tư | Thành lập Ban quản lý dự án; lựa chọn nhà thầu; ký và quản lý hợp đồng; nghiệm thu cổng; quyết toán |
| Trung tâm Chuyển đổi số hoặc Trung tâm dữ liệu tỉnh | Đơn vị vận hành | Cung cấp chỗ đặt thiết bị và kết nối mạng; tham gia từ W0; tiếp nhận vận hành từ G3; trực sự cố; quản trị tenant `T01` |
| Đơn vị chuyên trách an ninh mạng của tỉnh | Thẩm định cấp độ | Thẩm định hồ sơ đề xuất cấp độ 3 (D03-08); tham gia kiểm tra ATTT trước G3 |
| Nhà thầu EP phần mềm và triển khai | Thiết kế chi tiết, phát triển, triển khai | Thực hiện toàn bộ WBS ở D01-02 §2; bảo đảm cổng CI và chất lượng theo D04-02; di trú, cắt chuyển; bảo hành 12 tháng |
| Nhà thầu thiết bị H1 | Cung cấp, lắp đặt hạ tầng | Cung cấp, lắp đặt, cấu hình nền theo Chương 6 mục 6.8; nghiệm thu lắp đặt trước T0+6 |
| Tư vấn giám sát | Giám sát độc lập | Giám sát chất lượng và khối lượng; báo cáo giám sát mỗi cổng |
| Đơn vị kiểm thử độc lập, kiểm thử xâm nhập | Đánh giá độc lập | Kiểm thử chấp nhận độc lập trước G2, G4; hai đợt kiểm thử xâm nhập |
| Sở, ngành, UBND cấp xã có HTTT | Bên kết nối và khai thác | Cử đầu mối kỹ thuật; chuyển kết nối khỏi hệ cũ theo lịch cắt chuyển; tham gia UAT |
| Nhà cung cấp hệ LGSP cũ | Phối hợp chuyển tiếp | Cung cấp cấu hình, dữ liệu, quyền truy cập trong giai đoạn chạy song song (RSK-17); duy trì hệ cũ đến khi tắt |

: Trách nhiệm của các chủ thể trong dự án

Hai trách nhiệm cần chủ đầu tư lưu ý vì nằm trên đường găng. Một là văn bản chỉ đạo của UBND tỉnh yêu cầu sở, ngành chuyển kết nối phải ban hành trước W3, nếu không lịch cắt chuyển ở D01-02 §4.5 phụ thuộc vào thiện chí của từng đơn vị. Hai là hợp đồng với nhà cung cấp hệ cũ phải có điều khoản phối hợp chuyển tiếp trước T0+8, khi nhóm di trú bắt đầu trích xuất cấu hình.

### 9.3. Tiến độ và các mốc chính

#### 9.3.1. Giai đoạn chuẩn bị đầu tư

Mọi mốc ghi tương đối theo T0, ngày khởi động hợp đồng EP, theo chỉ đạo của chủ đầu tư. Trình tự chuẩn bị đầu tư theo Nghị định 224/2026/NĐ-CP và Chương 1 mục 1.6.

| Bước | Thời gian tương đối | Sản phẩm |
|---|---|---|
| Lập, trình chủ trương đầu tư (nếu dự án thuộc diện phải có) | T0 − 7 → T0 − 6 tháng | Báo cáo đề xuất chủ trương đầu tư |
| Lập Báo cáo nghiên cứu khả thi | T0 − 7 → T0 − 5 tháng | D01-01 kèm thiết kế cơ sở |
| Thẩm định, phê duyệt dự án | T0 − 4 → T0 − 3 tháng | Quyết định phê duyệt dự án |
| Thiết kế chi tiết, dự toán; thẩm định, phê duyệt | T0 − 3 → T0 − 2 tháng | Thiết kế chi tiết hạng mục thiết bị; khung thiết kế chi tiết phần mềm (phần còn lại do nhà thầu EP lập theo wave) |
| Lựa chọn nhà thầu | T0 − 2 → T0 | Hợp đồng EP, hợp đồng thiết bị |

: Tiến độ giai đoạn chuẩn bị đầu tư và sản phẩm từng bước

Với gói EP, thiết kế chi tiết phần mềm nội bộ được nhà thầu lập theo từng wave và trình duyệt trước khi bắt đầu wave đó, như Chương 1 mục 1.7 đã phân tích. Vì vậy bước thiết kế chi tiết trước T0 chỉ cần hoàn tất cho hạng mục thiết bị và cho khung yêu cầu phần mềm (bộ tài liệu D02, D03 hiện có), không phải cho toàn bộ 20 phân hệ.

#### 9.3.2. Giai đoạn thực hiện

Giai đoạn thực hiện gồm sáu wave, mỗi wave gồm các sprint hai tuần và kết thúc bằng một cổng nghiệm thu. Bảng dưới đây ghi phân hệ đưa vào vận hành ở từng wave; đủ 20 phân hệ PH-01 đến PH-20 đều có wave và cổng.

| Wave | Thời gian | Phân hệ và nội dung | Cổng kết thúc |
|---|---|---|---|
| W0 | T0 → T0+2 | Khởi động, hạ tầng DEV/TEST, khung IAM, hợp đồng máy đọc (OpenAPI, AsyncAPI), khung CI | G0 Nền tảng sẵn sàng |
| W1 | T0+2 → T0+6 | PH-01, PH-02, PH-03, PH-04, PH-05, PH-12; PH-13 mức cơ bản | G1 Trục tích hợp |
| W2 | T0+6 → T0+10 | PH-07, PH-10, PH-14, PH-18, PH-20; PH-13 đầy đủ; kiểm thử hệ thống, ATTT, hiệu năng theo hồ sơ tỉnh vừa (GĐ-07) | G2 Nghiệm thu MVP (12 phân hệ) |
| W3 | T0+10 → T0+13 | Cài đặt PROD tại `T01`, di trú, chạy song song, cắt chuyển theo nhóm dịch vụ; hồ sơ cấp độ 3 được phê duyệt | G3 Vận hành chính thức MVP |
| W4 | T0+10 → T0+15 | Đợt 2: PH-19 Thanh toán, PH-15, PH-09, PH-11; cắt chuyển thanh toán khỏi PayGov qua hệ cũ | G4 Nghiệm thu đợt 2 |
| W5 | T0+15 → T0+18 | Đợt 3: PH-06, PH-08, PH-16, PH-17; đóng gói phát hành v1.0; nhân rộng sang tỉnh thứ hai; tắt hệ cũ | G5 Nghiệm thu hoàn thành dự án |
| Bảo hành | T0+18 → T0+30 | Sửa lỗi, nâng bản vá bảo mật, hỗ trợ tỉnh thứ hai | Kết thúc bảo hành |

: Tiến độ giai đoạn thực hiện theo wave và cổng nghiệm thu

Biểu đồ dưới đây thể hiện cùng lịch đó cho giai đoạn thực hiện và bảo hành, với W3 và W4 chạy chồng lấn bằng hai đội riêng; giai đoạn chuẩn bị đầu tư ở bảng mục 9.3.1.

```{.mermaid caption="Tiến độ thực hiện theo wave và thời gian bảo hành"}
gantt
    title Tiến độ thực hiện Datahub, đơn vị tháng tính từ T0
    dateFormat X
    axisFormat %s
    section Thực hiện
    W0 Nền tảng                      :w0, 0, 2
    W1 Trục tích hợp                 :w1, 2, 6
    W2 Mở rộng MVP                   :w2, 6, 10
    W3 Thí điểm và cắt chuyển        :w3, 10, 13
    W4 Đợt 2 gồm PH-19               :w4, 10, 15
    W5 Đợt 3, nhân rộng, tắt hệ cũ   :w5, 15, 18
    section Sau nghiệm thu
    Bảo hành 12 tháng                :bh, 18, 30
```

Đường găng đi qua W1, W2 và W3: một trễ ở trục tích hợp hay ở gói thiết bị (phải nghiệm thu lắp đặt trước T0+6) đẩy lùi trực tiếp ngày vận hành chính thức. PH-19 nằm ở W4 thay vì MVP vì nó phụ thuộc trục tích hợp và PH-12 đã ổn định, và vì cắt chuyển thanh toán là thao tác rủi ro tài chính cần làm sau khi các nhóm dịch vụ khác đã cắt chuyển xong. Dịch vụ thanh toán cũ chỉ tắt sau khi PH-19 chạy ổn định 30 ngày. Phân tích đường găng và phụ thuộc chi tiết nằm ở D01-02 §4.4.

#### 9.3.3. Điều kiện nghiệm thu từng cổng

Mỗi cổng có bộ tiêu chí vào và ra ở D01-02 §4.3 và bộ cổng phát hành RG-1 đến RG-5 ở D05-01. Ở mức báo cáo khả thi, ba nguyên tắc được cam kết. Một là cổng chỉ được ký khi các phân hệ của wave đạt tiêu chí chấp nhận cấp phân hệ trong FRS (mục 8 của từng FRS) và không còn lỗi mức nghiêm trọng. Hai là G2 và G4 có kiểm thử chấp nhận độc lập. Ba là G3 không được ký nếu hồ sơ cấp độ 3 chưa được phê duyệt, vì Datahub không được đưa vào vận hành chính thức khi chưa được phê duyệt cấp độ.

### 9.4. Kế hoạch lựa chọn nhà thầu

#### 9.4.1. Hai phương án đóng gói thầu

Cách chia gói thầu ảnh hưởng tới năng lực nhà thầu cần có, rủi ro giao diện giữa các nhà thầu và thời gian chuẩn bị. Báo cáo so sánh hai phương án.

**Phương án GT-A (đề xuất) gồm hai gói chính.** Gói thứ nhất là gói EP thiết kế chi tiết và triển khai toàn bộ phần mềm nội bộ của 20 phân hệ, gồm di trú, cắt chuyển, đào tạo và bảo hành. Gói thứ hai là gói mua sắm thiết bị H1. Ưu điểm là một nhà thầu chịu trách nhiệm trọn vẹn về kiến trúc, mã nguồn và tích hợp giữa các phân hệ, nên không có ranh giới trách nhiệm giữa hai nhà thầu phần mềm. Nhược điểm là gói EP có giá trị lớn, đòi hỏi đồng thời năng lực Camel Quarkus, Kubernetes, Kafka và kinh nghiệm di trú, nên số nhà thầu đáp ứng ít (RSK-03 ở D01-02 §8).

**Phương án GT-B gồm ba gói.** Gói phần mềm MVP (W0 đến W3), gói phần mềm đợt 2 và đợt 3 (W4, W5) và gói thiết bị. Phương án này giảm quy mô từng gói và có thể tăng cạnh tranh, nhưng gói thứ hai phải tiếp nhận mã nguồn của nhà thầu thứ nhất, phải làm việc song song với W3 trên cùng một kho mã, và gây chậm ít nhất ba tháng vì phải tổ chức lựa chọn nhà thầu lần hai trước T0+10. Với PH-19 Thanh toán, việc đổi nhà thầu giữa chừng còn làm tăng rủi ro đối soát. Báo cáo vì vậy không đề xuất GT-B, trừ khi kết quả khảo sát thị trường cho thấy không đủ nhà thầu cho gói EP.

#### 9.4.2. Kế hoạch lựa chọn nhà thầu theo phương án GT-A

Bảng dưới đây là kế hoạch lựa chọn nhà thầu sơ bộ. Giá trị là giá trị tham khảo trước thuế từ Chương 8; hình thức lựa chọn ghi theo Luật Đấu thầu số 22/2023/QH15 đã sửa đổi và cần đơn vị tư vấn đấu thầu xác nhận khi lập kế hoạch lựa chọn nhà thầu chính thức (Q-D0101-97).

| Gói thầu | Giá trị tham khảo (triệu đồng) | Hình thức lựa chọn | Phương thức | Loại hợp đồng | Thời gian lựa chọn | Thời gian thực hiện |
|---|---|---|---|---|---|---|
| EP phần mềm nội bộ và triển khai | 18.670 + 2.400 bảo hành | Đấu thầu rộng rãi trong nước, qua mạng | Một giai đoạn hai túi hồ sơ | Trọn gói, thanh toán theo cổng G0 đến G5 | T0 − 2 → T0 | T0 → T0+30 |
| Mua sắm, lắp đặt thiết bị H1 | 10.403 | Đấu thầu rộng rãi trong nước, qua mạng | Một giai đoạn một túi hồ sơ | Trọn gói | T0 − 2 → T0+1 | T0+1 → T0+6 |
| Thuê cloud cho DEV, TEST | Khoảng 1.016 mỗi năm | Theo quy định thuê dịch vụ công nghệ số | Theo quy định | Theo đơn giá, trả hằng tháng | T0 − 1 → T0 | T0 → T0+18, gia hạn theo năm |
| Tư vấn giám sát triển khai | 945 | Chỉ định thầu hoặc chào hàng (tùy hạn mức) | Theo quy định | Theo thời gian | T0 − 1 → T0 | T0 → T0+18 |
| Kiểm thử độc lập, kiểm thử xâm nhập | Theo Chương 8 mục 8.5.3 | Chỉ định thầu hoặc chào hàng | Theo quy định | Trọn gói theo đợt | T0+7 → T0+8 | Trước G2 và trước G4 |
| Hỗ trợ chuyển tiếp của nhà cung cấp hệ cũ | 500 | Chỉ định thầu (nhà cung cấp duy nhất nắm cấu hình) | Theo quy định | Theo sự kiện | T0+6 → T0+8 | T0+8 → T0+18 |

: Kế hoạch lựa chọn nhà thầu theo gói thầu của phương án GT-A

Gói thiết bị được phép lùi một tháng so với gói EP vì W0 chạy trên cloud DEV, TEST; nhưng nghiệm thu lắp đặt phải xong trước T0+6, khi STAGING cần cho kiểm thử hiệu năng của W2. Với phương án hạ tầng H2, gói thiết bị được thay bằng hợp đồng thuê cloud chính phủ cho mọi môi trường và áp dụng QĐ 8297/QĐ-BCA-A05 (CMP-LAW-20).

#### 9.4.3. Yêu cầu năng lực chính đối với nhà thầu EP

Hồ sơ mời thầu gói EP cần đặt yêu cầu năng lực đủ chặt để loại nhà thầu chỉ có kinh nghiệm phần mềm nghiệp vụ, nhưng không chặt tới mức chỉ một đơn vị đáp ứng. Báo cáo đề xuất năm nhóm yêu cầu: đã triển khai ít nhất một nền tảng tích hợp hoặc LGSP cấp tỉnh, cấp bộ; có nhân sự chủ chốt với kinh nghiệm Apache Camel, Kafka và Kubernetes; có quy trình phát triển an toàn đáp ứng D04-02 và có thể chứng minh bằng một kho mã mẫu; cam kết chuyển giao toàn bộ mã nguồn, hạ tầng như mã và tài liệu theo mục 9.5.4; và có phương án kiểm soát AI agent viết mã theo D01-02 §3.8 nếu dùng AI agent.

### 9.5. Phương án tổ chức quản lý, khai thác và sử dụng

#### 9.5.1. Mô hình vận hành

Sau G3, Trung tâm Chuyển đổi số tỉnh là đơn vị vận hành Datahub. Đội vận hành tỉnh gồm 6 người (khoảng 5,5 FTE), tham gia từ T0+10 để học cùng đội thí điểm của nhà thầu trong W3: hai kỹ sư nền tảng (Kubernetes, CSDL, Kafka), một kỹ sư tích hợp, một cán bộ ATTT, một quản trị nghiệp vụ nền tảng (kết nạp HTTT, công bố dịch vụ) và một cán bộ hỗ trợ người dùng. Đội vận hành làm việc theo runbook ở D03-09 và dùng PH-13 Giám sát, PH-18 Vận hành và xử lý bản tin lỗi làm công cụ hằng ngày.

Ngoài giờ hành chính, đội vận hành trực theo lịch xoay vòng với cảnh báo tự động từ PH-13. Sự cố mức nghiêm trọng ở data plane có mục tiêu khôi phục 1 giờ (NFR-00-014); khi vượt khả năng của đội tỉnh, sự cố được chuyển cho nhà thầu theo cam kết mức dịch vụ của hợp đồng bảo hành hoặc hỗ trợ kỹ thuật.

#### 9.5.2. Phân cấp quản trị và khai thác

Datahub là nền tảng đa tenant, nên quyền quản trị được phân thành ba tầng. Tầng thứ nhất là quản trị sản phẩm, thuộc đơn vị phát hành bản (nhà thầu trong bảo hành, sau đó theo mục 9.5.3), dùng PH-20 để phát hành phiên bản cho các tenant. Tầng thứ hai là quản trị tenant, thuộc Trung tâm Chuyển đổi số tỉnh, quản lý người dùng, hạn mức, tham số và HTTT thành viên của tỉnh mình; mỗi tỉnh là chủ quản tenant của mình. Tầng thứ ba là quản trị nghiệp vụ tại sở, ngành: kết nạp HTTT, đăng ký sử dụng API, quản lý danh mục chuyên ngành (PH-07), xem giao dịch thanh toán của đơn vị (PH-19). Ma trận quyền chi tiết ở D02-08.

UBND tỉnh cần ban hành quy chế khai thác Datahub trước G3, trong đó quy định nghĩa vụ kết nối qua nền tảng thay vì kết nối điểm–điểm, trách nhiệm của đơn vị cung cấp và khai thác dữ liệu, cách chia sẻ dữ liệu với Nền tảng chia sẻ, điều phối dữ liệu quốc gia theo Nghị định 278/2025/NĐ-CP. Dự thảo quy chế là một sản phẩm của WBS ở D01-02 §2.

#### 9.5.3. Hỗ trợ kỹ thuật sau bảo hành

Một nền tảng có khoảng hai mươi thành phần nguồn mở cần được nâng phiên bản và vá bảo mật thường xuyên, và đội vận hành tỉnh không đủ để phát triển tiếp sản phẩm. Từ T0+30, báo cáo giữ hai lựa chọn để chủ đầu tư quyết định khi kết thúc bảo hành.

**Lựa chọn thứ nhất** là hợp đồng hỗ trợ kỹ thuật hằng năm với nhà thầu đã phát triển phần mềm, khoảng 2 đến 3 FTE, theo cơ chế chỉ định doanh nghiệp đã phát triển phần mềm làm quản trị, vận hành của Nghị định 224/2026/NĐ-CP (Chương 1 mục 1.7). Lựa chọn này nhanh và giữ được hiểu biết sâu về mã nguồn.

**Lựa chọn thứ hai** là thuê dịch vụ công nghệ số vận hành, hỗ trợ nền tảng từ một đơn vị cung cấp dịch vụ cho nhiều tỉnh, áp dụng khi Datahub đã được nhân rộng. Theo khoản 3 Điều 45 Nghị định 224/2026/NĐ-CP, hợp đồng thuê phải nêu chất lượng dịch vụ, quyền sở hữu dữ liệu và phương án chuyển giao khi kết thúc. Chi phí hai lựa chọn được tính trong TCO ở Chương 8 mục 8.7 và 8.8. Cả hai lựa chọn đều không ràng buộc tỉnh vào một nhà cung cấp, vì tỉnh nắm mã nguồn và mọi thành phần là nguồn mở.

#### 9.5.4. Quyền sở hữu, chuyển giao mã nguồn và dữ liệu

Hợp đồng EP quy định chủ đầu tư sở hữu toàn bộ mã nguồn, cấu hình hạ tầng như mã, luồng tích hợp, đặc tả hợp đồng API và tài liệu do dự án tạo ra. Trong giai đoạn phát triển, mã nguồn nằm trên kho GitHub do chủ đầu tư quản lý tài khoản; khi bàn giao, toàn bộ kho được chuyển sang GitLab tự vận hành tại trung tâm dữ liệu tỉnh (ADR-037). Dữ liệu nghiệp vụ, nhật ký kiểm toán và dữ liệu thanh toán thuộc về tỉnh, nằm trong hạ tầng của tỉnh hoặc trên cloud chính phủ trong lãnh thổ Việt Nam, và không được nhà thầu sao chép ra ngoài.

Chuyển giao được thực hiện dần chứ không dồn vào cuối dự án. Từ W3, đội vận hành tỉnh có quyền đọc kho mã và chạy quy trình phát hành dưới sự kèm cặp của nhà thầu; ở G5, biên bản nghiệm thu hoàn thành gồm danh mục kho mã, phiên bản đã phát hành, khóa ký, hướng dẫn dựng lại môi trường từ đầu và kết quả một lần dựng lại thật do đội tỉnh thực hiện.

#### 9.5.5. Đào tạo và chuyển giao công nghệ

Khối lượng đào tạo sơ bộ ở Chương 6 mục 6.12 gồm 17 lớp cho 377 học viên, tương ứng 706 người-ngày, cho tỉnh thí điểm và tỉnh thứ hai. Đào tạo được xếp lịch theo wave để người học dùng được ngay: đội vận hành học trong W3 trước khi tiếp nhận; kỹ sư tích hợp của tỉnh học PH-04, PH-05 cuối W2 để tham gia chuyển luồng; cán bộ thanh toán học PH-19 trong W4, trước khi cắt chuyển thanh toán; cán bộ nghiệp vụ dữ liệu học PH-06, PH-08 trong W5. Đầu mối HTTT thành viên học theo từng nhóm cắt chuyển, mỗi nhóm một buổi trước ngày chuyển.

Chuyển giao công nghệ khác đào tạo ở chỗ đích đến là đội tỉnh tự làm được việc, không chỉ hiểu. Vì vậy mỗi nội dung chuyển giao có một bài kiểm tra thực hành: đội vận hành tự khôi phục một CSDL từ bản sao lưu, tự chuyển đổi sang site DR trong một lần diễn tập, tự phát hành một bản vá; kỹ sư tích hợp tự thiết kế và đưa một luồng mới vào vận hành.

#### 9.5.6. Kết thúc chạy song song và tắt hệ cũ

Hệ LGSP cũ chạy song song với Datahub từ W3 cho tới khi nhóm dịch vụ cuối cùng được cắt chuyển, chậm nhất ở G5. Mỗi khối của hệ cũ chỉ được tắt khi đủ ba điều kiện: không còn lượt gọi tới khối đó trong 30 ngày liên tục theo nhật ký của APISIX; dữ liệu cần lưu (lịch sử giao dịch, nhật ký phục vụ thanh tra) đã được chuyển hoặc lưu trữ theo D06-01; và chủ đầu tư ký biên bản tắt. Khối Payment tắt sau cùng, sau khi PH-19 chạy ổn định 30 ngày và đối soát ba kỳ liên tiếp khớp. Sau khi tắt, thiết bị của hệ cũ được thu hồi theo quy định quản lý tài sản công.

#### 9.5.7. Nhân rộng sang tỉnh khác

Datahub được thiết kế như một sản phẩm đóng gói đa tenant, nên nhân rộng là một hoạt động triển khai chứ không phải dự án phát triển mới. Trong W5, dự án thực hiện nhân rộng sang tỉnh thứ hai để chứng minh khả năng này, với chi phí đã tách riêng ở Chương 8 mục 8.11. Với các tỉnh sau, có hai cách: tỉnh tự đầu tư hạ tầng và nhận bản phát hành (cụm riêng), hoặc dùng chung cụm của một tỉnh hay của cloud chính phủ dưới dạng một tenant (D03-10). Trong cả hai cách, mỗi tỉnh là chủ quản hệ thống thông tin đối với tenant của mình và tự lập hồ sơ cấp độ.

### Câu hỏi mở

Các câu hỏi dưới đây liên quan đến hình thức Ban quản lý dự án, hạn mức chỉ định thầu và cách tổ chức kho mã nguồn trong giai đoạn phát triển; câu trả lời quyết định phương án tổ chức thực hiện.

- **Q-D0101-96.** Tỉnh thí điểm có Ban quản lý dự án chuyên ngành đã quản lý dự án CNTT không? Nếu có, chủ đầu tư chọn giao ban này hay thành lập Ban quản lý dự án kiêm nhiệm như đề xuất ở mục 9.1.1?
- **Q-D0101-97.** Hạn mức áp dụng chỉ định thầu và chào hàng cạnh tranh cho gói tư vấn và dịch vụ theo Luật Đấu thầu sửa đổi năm 2025 là bao nhiêu? Hình thức lựa chọn ở bảng 9.4.2 cần được đơn vị tư vấn đấu thầu xác nhận.
- **Q-D0101-98.** Chủ đầu tư có chấp nhận mở tài khoản tổ chức GitHub đứng tên chủ đầu tư cho kho mã trong giai đoạn phát triển không, hay yêu cầu dùng kho GitLab tại trung tâm dữ liệu tỉnh ngay từ W0?


## 10. Hiệu quả kinh tế - xã hội

> **Tóm tắt cho hội đồng thẩm định.** Datahub là dự án hạ tầng số dùng chung của khu vực công, không thu phí người dùng, nên hiệu quả được đánh giá bằng chi phí tránh được, thời gian tiết kiệm được và giá trị xã hội, không đánh giá bằng khả năng thu hồi vốn. Với tỉnh cỡ M và các giả định ghi rõ trong chương, nền tảng giảm khoảng 65% công sức xây dựng một kết nối mới so với kết nối điểm tới điểm, rút thời gian kết nạp một HTTT từ 2 đến 4 tuần xuống không quá 5 ngày làm việc, và giảm khoảng 88% công sức cập nhật danh mục dùng chung cho mỗi đợt thay đổi lớn như sắp xếp đơn vị hành chính. Lợi ích lớn nhất về kinh tế nằm ở mô hình sản phẩm đa tỉnh: nếu năm tỉnh dùng chung một sản phẩm thay vì mỗi tỉnh tự đầu tư một nền tảng tương đương, tổng nỗ lực phát triển và triển khai giảm khoảng 73% đến 76%, và tỷ lệ này tăng lên khoảng 91% nếu nhân rộng cho cả 34 tỉnh. Các con số trong chương là tỷ lệ và người-tháng; quy đổi ra tiền và so sánh với tổng chi phí sở hữu được trình bày tại Chương 8. Số liệu nền thực tế của tỉnh thí điểm (số hồ sơ thủ tục hành chính, số kết nối điểm tới điểm, chi phí vận hành hệ cũ) cần chủ đầu tư cung cấp để thay các giá trị giả định.

### 10.1. Phương pháp đánh giá

#### 10.1.1. Nguyên tắc

Chương này đánh giá hiệu quả theo bốn nguyên tắc. Nguyên tắc thứ nhất là so sánh với kịch bản không đầu tư đã mô tả ở mục 2.6, tức là tỉnh tiếp tục vận hành hệ LGSP cũ và các kết nối điểm tới điểm tiếp tục phát sinh. Nguyên tắc thứ hai là chỉ lượng hóa những lợi ích có cơ chế tác động rõ ràng và gắn được với một chỉ số đo tại D02-01; lợi ích không lượng hóa được thì trình bày định tính, không gán số. Nguyên tắc thứ ba là tách bạch phần lợi ích do Datahub tạo ra với phần lợi ích do các hệ thống khác cùng tạo ra: ví dụ việc giảm giấy tờ cho người dân cần cả Datahub, hệ thống giải quyết thủ tục hành chính và cơ sở dữ liệu quốc gia, nên chương không tính toàn bộ giá trị đó cho dự án. Nguyên tắc thứ tư là mọi giá trị giả định đều được ghi nhãn **[GĐ]** và có câu hỏi mở tương ứng để chủ đầu tư thay bằng số liệu thật trước khi trình thẩm định.

Lợi ích được đo bằng ngày công hoặc người-tháng thay vì tiền vì hai lý do. Một là đơn giá người-tháng là tham số do chủ đầu tư điền theo hướng dẫn định mức hiện hành và được thống nhất tại Chương 8; nếu chương này tự quy đổi ra tiền sẽ tạo ra hai bộ đơn giá. Hai là ngày công là đơn vị mà các sở, nhà thầu và đơn vị vận hành có thể tự kiểm chứng. Quy ước quy đổi: một người-tháng bằng 22 ngày công.

#### 10.1.2. Chuỗi kết quả

Sơ đồ dưới đây thể hiện chuỗi kết quả (logic model) từ đầu tư tới tác động. Mỗi mắt xích ở cột "kết quả trực tiếp" gắn với một chỉ số KPI, nên hiệu quả trong chương này được theo dõi bằng chính các chỉ số dùng để nghiệm thu dự án.

```{.mermaid caption="Chuỗi kết quả từ đầu tư tới tác động"}
flowchart TB
    subgraph DV["Đầu vào"]
        I1["Khoảng 455 người-tháng<br/>18 tháng thực hiện"]
        I2["Hạ tầng PROD và DR<br/>xem Chương 8"]
    end
    subgraph DR["Đầu ra"]
        O1["20 phân hệ, sản phẩm v1.0"]
        O2["Tỉnh thí điểm vận hành<br/>tỉnh thứ hai được khởi tạo"]
        O3["Hồ sơ cấp độ 3 được phê duyệt"]
    end
    subgraph KQ["Kết quả trực tiếp"]
        R1["Kết nạp nhanh<br/>KPI-05, KPI-06"]
        R2["Một điểm kiểm soát<br/>KPI-01, KPI-02, KPI-07"]
        R3["Danh mục thống nhất<br/>KPI-10, KPI-11"]
        R4["Không gián đoạn<br/>KPI-03, KPI-15, KPI-16"]
        R5["Đối soát tự động<br/>KPI-13, KPI-14"]
        R6["Tenant mới trong 1 ngày<br/>KPI-12"]
    end
    subgraph TD["Tác động"]
        T1["Giảm chi phí tích hợp<br/>của toàn tỉnh"]
        T2["Giảm giấy tờ, thời gian<br/>cho người dân, doanh nghiệp"]
        T3["Tuân thủ Luật Dữ liệu<br/>và bảo vệ DLCN"]
        T4["Giảm đầu tư lặp<br/>giữa các tỉnh"]
    end
    I1 --> O1
    I2 --> O2
    O1 --> R1
    O1 --> R3
    O1 --> R6
    O2 --> R2
    O2 --> R4
    O2 --> R5
    O3 --> R2
    R1 --> T1
    R2 --> T1
    R2 --> T3
    R3 --> T1
    R3 --> T2
    R4 --> T2
    R5 --> T2
    R6 --> T4
```

Sơ đồ cũng cho thấy một điều kiện quan trọng: tác động chỉ xuất hiện khi các sở thực sự chuyển kết nối sang nền tảng. Nếu nền tảng sẵn sàng nhưng các HTTT vẫn giữ kết nối điểm tới điểm, chuỗi bị đứt ở mắt xích R2. Điều kiện này được nêu lại ở mục 10.8.

#### 10.1.3. Bảng tham số giả định

Bảng sau tập hợp các tham số dùng trong mục 10.2. Các tham số lấy từ bộ giả định nền hoặc từ D02-01 được ghi nguồn; các tham số còn lại là giả định của đơn vị tư vấn dựa trên kinh nghiệm triển khai nền tảng tích hợp cấp tỉnh, được chọn ở mức thận trọng.

| Mã tham số | Tham số | Giá trị dùng | Nguồn |
|---|---|---|---|
| TS-01 | Số HTTT kết nối của tỉnh cỡ M | 200 | Bộ giả định nền §4 |
| TS-02 | Số đối tác trao đổi dữ liệu bình quân của một HTTT | 4 | [GĐ] |
| TS-03 | Công sức xây dựng một kết nối điểm tới điểm, tính cả hai đầu | 10 ngày công | [GĐ] |
| TS-04 | Công sức dựng một luồng tích hợp chuẩn trên nền tảng | 2 ngày công | KPI-06 (đích) |
| TS-05 | Công sức kết nạp lần đầu một HTTT vào nền tảng, phía HTTT | 5 ngày công | [GĐ] |
| TS-06 | Tỷ lệ kết nối mới có ít nhất một HTTT chưa kết nạp | 30% | [GĐ] |
| TS-07 | Công sức duy trì một kết nối điểm tới điểm mỗi năm | 2 ngày công | [GĐ] |
| TS-08 | Công sức duy trì một kết nối qua nền tảng mỗi năm | 0,5 ngày công | [GĐ] |
| TS-09 | Thời gian dựng một luồng trên hệ cũ | 5–10 ngày công | D02-01, nền KPI-06 |
| TS-10 | Số luồng tích hợp mới mỗi năm | 60 | [GĐ] |
| TS-11 | Số HTTT kết nạp mới mỗi năm | 20 (10% của TS-01) | [GĐ] |
| TS-12 | Số HTTT dùng danh mục đơn vị hành chính, cơ quan | 100 (50% của TS-01) | [GĐ] |
| TS-13 | Công sức một HTTT tự cập nhật và ánh xạ danh mục cho một đợt thay đổi lớn | 5 ngày công | [GĐ] |
| TS-14 | Tổng nỗ lực xây dựng sản phẩm và thí điểm | 455 người-tháng | Bộ giả định nền §5 |
| TS-15 | Nỗ lực triển khai cho một tỉnh cỡ M từ tỉnh thứ hai trở đi | 20–40 người-tháng | [GĐ], xem mục 10.2.5 |

: Tham số giả định dùng để tính hiệu quả định lượng

### 10.2. Hiệu quả định lượng

#### 10.2.1. Giảm chi phí tích hợp điểm tới điểm

Khi không có nền tảng dùng chung, mỗi cặp HTTT cần trao đổi dữ liệu phải tự xây một kết nối riêng: thống nhất định dạng, cấp thông tin xác thực, viết mã ở cả hai đầu, kiểm thử và duy trì. Với nền tảng, mỗi HTTT chỉ kết nối một lần với Datahub theo chuẩn chung, và mỗi nhu cầu trao đổi mới chỉ còn là một luồng được cấu hình trên nền tảng. Đây là cơ chế giảm chi phí cơ bản của mọi trục tích hợp, và nó càng có giá trị khi số HTTT càng lớn.

Với tỉnh cỡ M có 200 HTTT và mỗi HTTT trao đổi với bình quân 4 đối tác, tỉnh có khoảng 200 × 4 / 2 = 400 quan hệ trao đổi dữ liệu. Nếu toàn bộ được xây theo kiểu điểm tới điểm, công sức xây dựng là 400 × 10 = 4.000 ngày công, tương đương khoảng 182 người-tháng. Nếu toàn bộ đi qua nền tảng, công sức gồm kết nạp 200 HTTT một lần (200 × 5 = 1.000 ngày công) và dựng 400 luồng (400 × 2 = 800 ngày công), tổng cộng 1.800 ngày công, tương đương khoảng 82 người-tháng. Mức giảm là 55% cho toàn bộ mạng kết nối.

Trên thực tế, tỉnh không xây lại toàn bộ mạng kết nối từ đầu, nên con số có ý nghĩa hơn cho quyết định là chi phí biên của một kết nối mới. Một kết nối điểm tới điểm mới tốn 10 ngày công. Một kết nối mới qua Datahub tốn 2 ngày công nếu cả hai HTTT đã được kết nạp, và thêm 5 ngày công nếu có một HTTT chưa kết nạp; với tỷ lệ 30% kết nối mới có HTTT chưa kết nạp, chi phí bình quân là 2 + 0,3 × 5 = 3,5 ngày công, giảm 65% so với điểm tới điểm.

Lợi ích tiếp diễn hằng năm đến từ chi phí duy trì. Mỗi kết nối điểm tới điểm phải được duy trì riêng (đổi khóa, cập nhật khi một đầu thay đổi phiên bản, xử lý sự cố mà không có nhật ký tập trung), trong khi kết nối qua nền tảng được duy trì tập trung với kho bí mật, giám sát và cảnh báo chung. Nếu số kết nối điểm tới điểm hiện có là P và dự án đạt KPI-02 (giảm ít nhất 80%), công sức duy trì tiết kiệm mỗi năm là 0,8 × P × (2 − 0,5) = 1,2 × P ngày công. Ví dụ với P = 100, khoản tiết kiệm là 120 ngày công mỗi năm, khoảng 5,5 người-tháng. Giá trị P thực tế chưa có trong hồ sơ và cần chủ đầu tư thống kê (Q-D0101-22 tại Chương 2).

#### 10.2.2. Rút ngắn thời gian kết nạp HTTT và xây dựng luồng

Lợi ích này có hai thành phần: thời gian chờ của cơ quan có nhu cầu và công sức kỹ thuật của đơn vị vận hành, nhà thầu.

Về thời gian chờ, KPI-05 đặt đích rút thời gian từ khi nộp hồ sơ kết nạp tới khi HTTT gọi được API ở môi trường thật từ khoảng 2 đến 4 tuần (10 đến 20 ngày làm việc) xuống không quá 5 ngày làm việc, tức là mỗi lần kết nạp rút ngắn từ 5 đến 15 ngày làm việc. Với 20 HTTT kết nạp mới mỗi năm, tổng thời gian chờ giảm từ 100 đến 300 ngày làm việc mỗi năm. Thời gian chờ không phải là chi phí ngân sách trực tiếp, nhưng là độ trễ trước khi một dịch vụ công mới hoặc một HTTT mới phát huy tác dụng; với dịch vụ công trực tuyến, mỗi ngày chậm là một ngày người dân tiếp tục phải nộp giấy tờ. Cơ chế rút ngắn đến từ việc hồ sơ kết nạp được duyệt trên hệ thống thay cho công văn giấy (PH-01), thông tin xác thực được cấp tự động qua kho bí mật thay cho gửi qua thư điện tử, và một HTTT chỉ khai báo một lần thay cho ba lần ở ba khối API Management, Hub và Payment như trên hệ cũ.

Về công sức xây dựng luồng, KPI-06 đặt đích dựng một luồng tích hợp chuẩn trong không quá 2 ngày công, so với 5 đến 10 ngày công trên hệ cũ. Với 60 luồng mới mỗi năm, công sức tiết kiệm là từ 60 × 3 = 180 đến 60 × 8 = 480 ngày công mỗi năm, tương đương khoảng 8 đến 22 người-tháng mỗi năm. Cơ chế tiết kiệm là trình thiết kế luồng với mẫu dựng sẵn, bộ điều hợp dùng chung (PH-05) và quy trình triển khai tự động không phải dừng dịch vụ (PH-20), thay cho việc viết tệp cấu hình Camel bằng tay rồi chép tệp WAR và khởi động lại máy chủ như mô tả ở mục 2.2.5.

#### 10.2.3. Tái sử dụng danh mục dùng chung và dữ liệu chủ

Hiện nay mỗi HTTT tự duy trì bản sao danh mục của mình, nên mỗi lần danh mục thay đổi thì từng HTTT phải tự cập nhật. Đợt sắp xếp đơn vị hành chính năm 2025 là ví dụ điển hình: mọi HTTT có dùng mã đơn vị hành chính đều phải cập nhật bảng mã, xây bảng ánh xạ mã cũ sang mã mới và kiểm tra dữ liệu lịch sử.

Với 100 HTTT dùng danh mục đơn vị hành chính và cơ quan, mỗi HTTT tốn khoảng 5 ngày công cho một đợt thay đổi lớn, tổng công sức của toàn tỉnh là 500 ngày công cho mỗi đợt. Khi danh mục được quản lý tập trung có phiên bản, có ngày hiệu lực và bảng ánh xạ trên PH-07, công sức gồm khoảng 10 ngày công của cơ quan chủ quản danh mục để cập nhật và duyệt phiên bản mới, cộng 0,5 ngày công mỗi HTTT để kiểm tra việc nhận đồng bộ qua API hoặc sự kiện, tổng cộng 10 + 100 × 0,5 = 60 ngày công. Mức giảm khoảng 88% cho mỗi đợt thay đổi lớn. Với các thay đổi nhỏ và thường xuyên hơn của danh mục quốc gia, lợi ích chủ yếu là thời gian: KPI-11 đặt đích đồng bộ trong không quá 24 giờ sau khi quốc gia ban hành, thay cho việc cập nhật thủ công không xác định thời hạn.

Lợi ích lớn hơn nhưng khó lượng hóa là chất lượng dữ liệu. Khi cùng một xã mang các mã khác nhau ở các HTTT khác nhau, dữ liệu chia sẻ giữa các hệ bị sai lệch, báo cáo tổng hợp không khớp và hồ sơ thủ tục bị trả lại. Từ đợt 2, dữ liệu chủ (PH-06) và chất lượng dữ liệu (PH-08) mở rộng cơ chế này sang các thực thể công dân, tổ chức, địa chỉ: mỗi HTTT dùng chung một bản ghi đã được hợp nhất thay vì tự đối chiếu. Báo cáo không lượng hóa phần này vì D02-01 chưa có chỉ số cho dữ liệu chủ và chất lượng dữ liệu (xem ghi chú ở mục 3.8).

#### 10.2.4. Giảm giấy tờ cho người dân và doanh nghiệp

Khi cơ quan tiếp nhận hồ sơ thủ tục hành chính lấy được dữ liệu qua nền tảng (ví dụ thông tin hộ tịch, lý lịch tư pháp, bảo hiểm xã hội, đăng ký doanh nghiệp, là các nhóm dịch vụ đã có trong phụ lục kết nối NGSP của hệ cũ), người dân không phải nộp bản sao giấy tờ tương ứng. Lợi ích xã hội có thể ước tính theo công thức sau:

> Giá trị tiết kiệm mỗi năm = H × r × g × c

trong đó H là số hồ sơ thủ tục hành chính tỉnh tiếp nhận mỗi năm, r là tỷ lệ hồ sơ có ít nhất một thành phần giấy tờ được thay bằng dữ liệu khai thác qua nền tảng, g là số giấy tờ bình quân được thay trong một hồ sơ đó, và c là chi phí xã hội để có một giấy tờ (phí sao y, chứng thực, chi phí đi lại và thời gian của người dân).

Để minh họa thứ bậc độ lớn, với H = 1.000.000 hồ sơ mỗi năm, r = 20%, g = 1,5 và c = 30.000 đồng (cả bốn giá trị đều là **[GĐ]**), giá trị tiết kiệm cho xã hội là khoảng 9.000 triệu đồng mỗi năm. Con số này không được cộng vào phân tích chi phí của Chương 8, vì ba lý do: nó là lợi ích của người dân và doanh nghiệp chứ không phải khoản giảm chi ngân sách; nó do nhiều hệ thống cùng tạo ra, trong đó Datahub là điều kiện cần nhưng không đủ; và giá trị H, r của tỉnh thí điểm chưa có số liệu thực (Q-D0101-91). Chỉ số đo chính thức cho lợi ích này hiện chưa có trong D02-01 và được đề xuất bổ sung (mục 3.8).

Ngoài chi phí, người dân hưởng lợi từ việc giảm số lần đi lại và thời gian giải quyết. Với chính quyền hai cấp, cán bộ một cửa cấp xã tra cứu được dữ liệu ngay tại chỗ nếu nền tảng sẵn sàng trong giờ hành chính; vì vậy lợi ích này phụ thuộc trực tiếp vào KPI-03 ở mục 10.2.6.

#### 10.2.5. Chi phí nhân rộng biên cho tỉnh thứ hai trở đi

Đây là lợi ích kinh tế lớn nhất của dự án và là lý do chính để chọn mô hình sản phẩm đa tenant. Cơ chế rất đơn giản: phần lớn nỗ lực của dự án là xây dựng sản phẩm (phân tích, thiết kế, phát triển, kiểm thử 20 phân hệ), và phần này chỉ phải trả một lần. Tỉnh thứ hai trở đi chỉ phải chịu chi phí triển khai, gồm cài đặt hoặc khởi tạo tenant, cấu hình, di trú từ hệ cũ của tỉnh đó, lập hồ sơ cấp độ, đào tạo và hỗ trợ vận hành ban đầu, cộng với chi phí hạ tầng riêng nếu tỉnh chọn cụm riêng.

Căn cứ để ước tính nỗ lực triển khai biên là cơ cấu nỗ lực trong bộ giả định nền. Wave W3 (thí điểm tại tỉnh 1, gồm cài đặt PROD, di trú, chạy song song và cắt chuyển) chiếm 18,5 × 3 = 55,5 người-tháng, khoảng 12% của 455 người-tháng. Nỗ lực của W3 bao gồm cả phần học hỏi lần đầu và hoàn thiện quy trình di trú; với tỉnh tiếp theo, quy trình đã được đóng gói và việc khởi tạo tenant đạt đích KPI-12 (không quá 1 ngày làm việc), nên nỗ lực triển khai biên được giả định từ 20 người-tháng (tenant dùng chung, hệ cũ đơn giản) đến 40 người-tháng (cụm riêng, di trú hệ cũ phức tạp) cho một tỉnh cỡ M.

Kịch bản so sánh là mỗi tỉnh tự đầu tư một nền tảng có phạm vi tương đương. Kịch bản này được giả định tốn ít nhất 455 người-tháng cho mỗi tỉnh, tức là bằng nỗ lực của dự án này; đây là giả định thận trọng vì một tỉnh tự đầu tư riêng không có lợi thế của sản phẩm đã có sẵn. Bảng sau so sánh tổng nỗ lực theo số tỉnh tham gia.

| Số tỉnh n | Mỗi tỉnh tự đầu tư, n × 455 (người-tháng) | Dùng chung sản phẩm, 455 + (n − 1) × 20…40 (người-tháng) | Mức giảm |
|---|---|---|---|
| 1 | 455 | 455 | 0% |
| 2 | 910 | 475 – 495 | 46% – 48% |
| 5 | 2.275 | 535 – 615 | 73% – 76% |
| 10 | 4.550 | 635 – 815 | 82% – 86% |
| 34 | 15.470 | 1.115 – 1.775 | 89% – 93% |

: So sánh nỗ lực nhân rộng giữa mỗi tỉnh tự đầu tư và dùng chung sản phẩm

Bảng cho thấy lợi ích của mô hình sản phẩm xuất hiện ngay từ tỉnh thứ hai và tăng nhanh theo số tỉnh. Với phạm vi cam kết của dự án (một tỉnh thí điểm và một tỉnh thứ hai được khởi tạo), tổng nỗ lực tiết kiệm so với hai tỉnh tự đầu tư riêng là khoảng 415 đến 435 người-tháng. Lợi ích này kèm theo ba lưu ý mà hội đồng cần cân nhắc. Thứ nhất, bảng chỉ tính nỗ lực phát triển và triển khai; chi phí hạ tầng của mỗi tỉnh vẫn phát sinh riêng, trừ khi tỉnh dùng chế độ tenant dùng chung trên một cụm, và chi phí hạ tầng theo cỡ S, M, L được tính tại Chương 8. Thứ hai, sau khi phát hành v1.0, sản phẩm cần chi phí bảo trì và phát triển phiên bản mới; nếu nhiều tỉnh dùng chung thì chi phí này được chia sẻ, nhưng cần một cơ chế chia sẻ chi phí và một đơn vị làm chủ sản phẩm (Q-D0101-93). Thứ ba, lợi ích chỉ hiện thực hóa khi quyền sử dụng và quyền triển khai sản phẩm cho tỉnh khác được bảo đảm trong hợp đồng (Q-D0101-34 tại Chương 3).

Ngoài nỗ lực ban đầu, mô hình dùng chung còn tạo lợi ích tiếp diễn: một bản vá an toàn thông tin hay một thay đổi do văn bản pháp luật mới chỉ phải phát triển một lần rồi phát hành cho mọi tỉnh qua cùng một quy trình, thay vì mỗi tỉnh tự xử lý trên một nền tảng khác nhau.

#### 10.2.6. Giảm thời gian gián đoạn và chi phí đối soát

Về độ sẵn sàng, cam kết 90% mỗi năm của hệ cũ cho phép ngừng tới khoảng 876 giờ trong một năm, còn đích 99,9% mỗi tháng của KPI-03 chỉ cho phép ngừng khoảng 43 phút mỗi tháng, tương đương khoảng 8,8 giờ mỗi năm. Hệ cũ thực tế có thể vận hành tốt hơn mức cam kết, nhưng hồ sơ không có số liệu đo (Q-D0101-28 tại Chương 2). Giá trị kinh tế của thời gian gián đoạn tránh được bằng số lượt tra cứu, thanh toán bị gián đoạn nhân với chi phí xử lý lại của cán bộ và người dân; báo cáo chưa lượng hóa vì thiếu số liệu giao dịch thực. Các chỉ số MTTD không quá 5 phút (KPI-15) và MTTR với sự cố mức 1 không quá 1 giờ (KPI-16) củng cố lợi ích này về phía vận hành.

Về đối soát thanh toán, với quy mô cỡ M khoảng 400 nghìn giao dịch thanh toán mỗi tháng, đích KPI-13 (ít nhất 99,5% giao dịch đối soát tự động khớp) nghĩa là chỉ còn tối đa khoảng 2.000 giao dịch mỗi tháng cần xem xét thủ công, so với tình trạng hiện tại không có đối soát tự động. Lợi ích gồm giảm công sức kế toán, phát hiện giao dịch lệch trong không quá 1 ngày làm việc (KPI-14) và có căn cứ giải quyết khiếu nại của người dân. Công sức đối soát hiện tại của tỉnh cần chủ đầu tư cung cấp để lượng hóa (Q-D0101-92).

Về hạ tầng, cần nói rõ rằng Datahub không làm giảm số lượng máy chủ so với hệ cũ. Kiến trúc mới có cụm Kubernetes nhiều nút, có bản sao dự phòng và địa điểm DR, nên tài nguyên hạ tầng lớn hơn mô hình một máy chủ cho mỗi khối của hệ cũ. Khoản tăng này là chi phí của việc nâng mức sẵn sàng từ 90% lên 99,9% và đạt RPO 15 phút; nó được tính đầy đủ tại Chương 8 và không được trình bày như một khoản tiết kiệm.

#### 10.2.7. Tổng hợp hiệu quả định lượng

Bảng sau tổng hợp các lợi ích định lượng ở mục 10.2.1 đến 10.2.6. Cột "Đưa vào Chương 8" cho biết lợi ích nào được dùng trong so sánh chi phí, lợi ích nào chỉ là giá trị xã hội tham khảo.

| Lợi ích | Giá trị ước tính (cỡ M) | Chỉ số theo dõi | Đưa vào Chương 8 |
|---|---|---|---|
| Giảm công sức một kết nối mới | 65% (10 xuống 3,5 ngày công) | KPI-05, KPI-06 | Có, quy đổi theo đơn giá |
| Giảm công sức duy trì kết nối điểm tới điểm | 1,2 × P ngày công/năm (120 ngày công với P = 100) | KPI-02 | Có, khi có giá trị P |
| Giảm công sức dựng luồng | 180 – 480 ngày công/năm | KPI-06 | Có |
| Rút thời gian chờ kết nạp | 100 – 300 ngày làm việc/năm | KPI-05 | Không, định tính có số |
| Giảm công sức cập nhật danh mục mỗi đợt lớn | 88% (500 xuống 60 ngày công) | KPI-10, KPI-11 | Có, theo số đợt dự kiến |
| Giảm giấy tờ cho người dân | Minh họa khoảng 9.000 triệu đồng/năm | Đề xuất bổ sung tại D02-01 | Không, giá trị xã hội |
| Nhân rộng tỉnh thứ hai | Tiết kiệm 415 – 435 người-tháng so với tự đầu tư | KPI-12 | Có, ở kịch bản nhân rộng |
| Nhân rộng năm tỉnh | Giảm 73% – 76% tổng nỗ lực | KPI-12 | Có, ở kịch bản nhân rộng |
| Giảm gián đoạn dịch vụ | Từ tối đa 876 giờ/năm xuống khoảng 8,8 giờ/năm (theo cam kết) | KPI-03, KPI-15, KPI-16 | Không, định tính có số |
| Đối soát tự động | Tối đa khoảng 2.000 giao dịch/tháng cần xem thủ công | KPI-13, KPI-14 | Có, khi có số liệu nền |

: Tổng hợp hiệu quả định lượng, chỉ số theo dõi và phần đưa vào Chương 8

### 10.3. Hiệu quả định tính

Ngoài các lợi ích lượng hóa được, dự án tạo ra một số hiệu quả quan trọng nhưng không đo được bằng ngày công. Hiệu quả thứ nhất là minh bạch trong chia sẻ dữ liệu. Mọi lượt khai thác dữ liệu đi qua nền tảng đều có nhật ký ghi rõ ai khai thác, dữ liệu gì, vì mục đích gì và vào lúc nào (KPI-07), nên chủ quản dữ liệu (SH-08) kiểm soát được việc sử dụng dữ liệu của mình và cơ quan thanh tra có căn cứ kiểm tra. Trên hệ cũ, phần duyệt cho phép khai thác nằm ngoài hệ thống ở dạng công văn giấy và không truy vết được.

Hiệu quả thứ hai là giảm rủi ro an toàn thông tin và rủi ro pháp lý. Thay nền công nghệ hết vòng đời, đưa toàn bộ thông tin xác thực vào kho bí mật (KPI-09), mã hóa đường truyền và có hồ sơ cấp độ 3 được phê duyệt (KPI-08) làm giảm xác suất xảy ra sự cố lộ lọt dữ liệu cá nhân của công dân. Giá trị của một sự cố tránh được là rất lớn, gồm chi phí khắc phục, trách nhiệm pháp lý và uy tín của chính quyền, nhưng không thể ước tính tin cậy nên không được lượng hóa.

Hiệu quả thứ ba là nâng năng lực quản lý của cơ quan chủ quản. Khi có danh mục dịch vụ, danh mục HTTT kết nối và số liệu vận hành tập trung, Sở Khoa học và Công nghệ có bức tranh đầy đủ về việc dữ liệu nào đang được chia sẻ cho ai, phục vụ báo cáo chỉ tiêu chuyển đổi số và lập kế hoạch đầu tư các năm sau dựa trên số liệu thay vì ước đoán.

Hiệu quả thứ tư là cải thiện điều kiện làm việc của đội vận hành. Một giao diện quản trị thay cho năm giao diện (KPI-17), cảnh báo chủ động thay cho kiểm tra thủ công hằng ngày, và triển khai không gián đoạn thay cho thao tác dừng máy chủ làm giảm áp lực và rủi ro thao tác sai của đội vận hành tỉnh.

### 10.4. Đóng góp cho cải cách hành chính

Datahub đóng góp cho cải cách hành chính ở ba điểm. Điểm thứ nhất là hiện thực hóa nguyên tắc không yêu cầu người dân cung cấp lại thông tin mà cơ quan nhà nước đã có, theo CMP-LAW-03 và CMP-LAW-01: nền tảng là kênh kỹ thuật để cơ quan tiếp nhận lấy dữ liệu từ cơ quan đang quản lý dữ liệu đó, có kiểm soát và có nhật ký, như phân tích ở mục 10.2.4. Điểm thứ hai là hỗ trợ vận hành chính quyền hai cấp: khi cấp huyện không còn, cán bộ cấp xã cần tra cứu dữ liệu chuyên ngành trực tuyến, và nền tảng có độ sẵn sàng cao bảo đảm việc tra cứu không phụ thuộc vào việc liên hệ qua cấp trung gian. Điểm thứ ba là hỗ trợ quy trình liên thông nhiều cơ quan: từ đợt 2, phân hệ điều phối quy trình (PH-11) cho phép một hồ sơ đi qua nhiều cơ quan theo quy trình được định nghĩa và theo dõi được trạng thái, thay cho việc chuyển hồ sơ thủ công giữa các hệ thống.

Thanh toán trực tuyến có đối soát tự động (PH-19) cũng là một phần của cải cách hành chính, vì nó cho phép người dân hoàn thành trọn vẹn thủ tục trực tuyến, kể cả nghĩa vụ tài chính, với căn cứ đối chiếu rõ ràng khi có khiếu nại.

### 10.5. Đóng góp cho chuyển đổi số

Đối với chương trình chuyển đổi số của tỉnh, Datahub là thành phần hạ tầng số dùng chung mà các HTTT khác dựa vào, và sự phù hợp của dự án với Kế hoạch chuyển đổi số của địa phương đã được thuyết minh tại mục 2.5.5. Về kết nối với cấp quốc gia, phân hệ kết nối quốc gia (PH-14) bảo đảm tỉnh kết nối được với NDXP và NDOP theo định hướng kiến trúc tại CMP-LAW-10 và CMP-LAW-11, và phân hệ quản trị kiến trúc, chỉ số (PH-16) ở đợt 3 chuẩn bị cho việc thu thập chỉ số tự động mà cơ quan trung ương dùng để đánh giá mức độ kết nối, chia sẻ dữ liệu của địa phương. Về dữ liệu, lớp dữ liệu dùng chung (PH-06 đến PH-09) đặt nền móng cho các bước tiếp theo như kho dữ liệu phân tích, vốn nằm ngoài phạm vi dự án này nhưng được kiến trúc chừa sẵn điểm mở rộng. Về trí tuệ nhân tạo, cổng AI (PH-17) ở đợt 3 tạo một điểm kiểm soát chung cho việc các HTTT sử dụng mô hình AI, có ghi vết và chính sách, trước khi việc sử dụng AI lan rộng một cách phân tán.

### 10.6. Đóng góp cho tự chủ công nghệ

Datahub được xây dựng hoàn toàn trên công nghệ nguồn mở có cộng đồng lớn và đang được hỗ trợ dài hạn, không phụ thuộc dịch vụ độc quyền của một nhà cung cấp hạ tầng nào, và triển khai được trên cả trung tâm dữ liệu của tỉnh lẫn đám mây Chính phủ. Điều này giải quyết trực tiếp điểm nghẽn ĐN-14 của hệ cũ, nơi tỉnh phụ thuộc vào thư viện và tài liệu nội bộ của nhà cung cấp, và hồ sơ bàn giao không đủ để tự vận hành.

Tự chủ công nghệ được bảo đảm bằng bốn điều kiện cụ thể. Thứ nhất, mã nguồn, cấu hình triển khai và bộ tài liệu theo vòng đời phát triển được bàn giao đầy đủ. Thứ hai, quy trình triển khai được tự động hóa và mô tả dưới dạng mã (GitOps), nên một đội kỹ thuật khác có thể tiếp nhận mà không cần kiến thức ngầm của nhà thầu ban đầu. Thứ ba, đội vận hành tỉnh được đào tạo và tham gia từ wave W3, không chỉ nhận bàn giao vào cuối dự án. Thứ tư, không có chi phí bản quyền phần mềm, nên tỉnh có thể chọn đơn vị hỗ trợ kỹ thuật theo cơ chế cạnh tranh ở giai đoạn vận hành. Ở tầm rộng hơn, một sản phẩm nguồn mở dùng chung cho nhiều tỉnh góp phần hình thành năng lực trong nước về nền tảng tích hợp dữ liệu khu vực công, phù hợp với định hướng phát triển công nghiệp công nghệ số.

### 10.7. Hiệu quả về quốc phòng, an ninh và khả năng thu hồi vốn

Về an ninh, dự án góp phần bảo đảm an ninh mạng và an ninh dữ liệu thông qua việc lưu trữ toàn bộ dữ liệu trong lãnh thổ Việt Nam, đạt cấp độ 3 và có thiết kế để nâng lên cấp độ 4, kiểm soát tập trung mọi luồng dữ liệu đi ra khỏi tỉnh, và có nhật ký phục vụ điều tra khi có sự cố. Dự án không có hạng mục trực tiếp phục vụ quốc phòng.

Về khả năng thu hồi vốn, dự án cung cấp hạ tầng số dùng chung cho cơ quan nhà nước và không thu phí người dùng, nên không đặt mục tiêu thu hồi vốn. Trong giai đoạn nhân rộng, nếu cơ quan có thẩm quyền quyết định cung cấp nền tảng cho các tỉnh khác theo hình thức thuê dịch vụ (phương án H3), phần chi phí phát triển có thể được bù đắp một phần qua giá dịch vụ; khả năng này phụ thuộc vào cơ chế tài chính do cấp có thẩm quyền quyết định và không được tính vào hiệu quả của dự án.

### 10.8. Điều kiện để hiện thực hóa hiệu quả và cách theo dõi

Các hiệu quả nêu trên chỉ đạt được khi có đủ ba điều kiện. Điều kiện thứ nhất là các sở, ngành chuyển kết nối sang nền tảng; như đã nêu ở mục 3.6.2, phần chỉnh sửa phía các HTTT không thuộc dự án, nên cần văn bản chỉ đạo của UBND tỉnh (Q-D0101-35 tại Chương 3). Điều kiện thứ hai là có số liệu nền để so sánh; nếu giá trị nền của các KPI có dấu sao không được đo trước cổng G1, tỉnh sẽ không chứng minh được mức cải thiện. Điều kiện thứ ba là quyền triển khai sản phẩm cho tỉnh khác được bảo đảm và có đơn vị làm chủ sản phẩm sau dự án, để lợi ích nhân rộng ở mục 10.2.5 trở thành hiện thực.

Việc theo dõi hiệu quả dùng chính bộ KPI của D02-01, được thu thập tự động bởi PH-13 và PH-16 và báo cáo theo các mốc đo đã ghi ở mục 3.2.2: từ nghiệm thu, sau 6 tháng và sau 12 tháng vận hành. Báo cáo đề xuất chủ đầu tư tổ chức một lần đánh giá hiệu quả sau 12 tháng vận hành chính thức, so sánh giá trị thực đo với các giá trị trong chương này và cập nhật kịch bản nhân rộng.

### 10.9. Câu hỏi mở

> **Câu hỏi mở Q-D0101-91:** Số hồ sơ thủ tục hành chính tỉnh thí điểm tiếp nhận mỗi năm và tỷ lệ hồ sơ có thành phần giấy tờ có thể thay bằng dữ liệu khai thác qua nền tảng (theo danh mục thủ tục đã được rà soát cắt giảm giấy tờ) là bao nhiêu?

> **Câu hỏi mở Q-D0101-92:** Hiện nay việc đối soát giao dịch thanh toán trực tuyến dịch vụ công của tỉnh được thực hiện thế nào, bao nhiêu người tham gia, mất bao nhiêu ngày công mỗi tháng?

> **Câu hỏi mở Q-D0101-93:** Sau khi dự án kết thúc, cơ quan nào sẽ làm chủ sản phẩm Datahub, và chi phí bảo trì, phát triển phiên bản mới được chia sẻ giữa các tỉnh theo cơ chế nào?

> **Câu hỏi mở Q-D0101-94:** Chủ đầu tư có chấp nhận các tham số giả định TS-02, TS-03, TS-05 đến TS-08, TS-10 đến TS-13 và TS-15 ở mục 10.1.3, hay có số liệu từ các dự án tích hợp trước đây của tỉnh để thay thế?

> **Câu hỏi mở Q-D0101-95:** Ngoài tỉnh thứ hai, đã có tỉnh nào bày tỏ nhu cầu sử dụng sản phẩm, để làm cơ sở chọn kịch bản nhân rộng (2, 5 hay 10 tỉnh) trình bày cùng Chương 8?


## 11. Phân tích rủi ro và biện pháp quản lý

**Tóm tắt cho hội đồng thẩm định.** Dự án có mức rủi ro thực hiện trung bình và kiểm soát được, với điều kiện chủ đầu tư hoàn thành một số việc chuẩn bị trước T0. Trong 43 rủi ro được quản lý tại sổ rủi ro của Kế hoạch dự án (D01-02 §8), chương này nêu 12 rủi ro cấp dự án mà người quyết định đầu tư cần biết. Rủi ro lớn nhất không nằm ở công nghệ mà ở bàn giao từ nhà cung cấp hệ cũ (RSK-17), thủ tục phê duyệt (RSK-01, RSK-02) và sự phối hợp của các sở, ngành khi cắt chuyển (RSK-09). So với nâng cấp hệ cũ (PA1) và nền tảng thương mại (PA2), phương án xây mới trên mã nguồn mở (PA3) có rủi ro xây dựng cao hơn PA2a nhưng rủi ro khóa nhà cung cấp, nhân rộng và tuân thủ thấp hơn rõ rệt, nhất quán với điểm tiêu chí TC-5 ở Chương 4. Báo cáo đề xuất dự phòng rủi ro khoảng 28 người-tháng (khoảng 6% nỗ lực thực hiện), nằm trong chi phí dự phòng tối đa 10% tổng mức đầu tư theo Thông tư 39/2026/TT-BKHCN, và đề nghị chủ đầu tư dự trù riêng kinh phí vận hành sau bảo hành.

### 11.1. Cách tiếp cận

Chương này nhìn rủi ro từ góc độ người thẩm định: rủi ro nào có thể làm dự án không đạt mục tiêu (BO-01 đến BO-09 tại D02-01), vượt tổng mức đầu tư hoặc kéo dài thời gian thực hiện, tức những trường hợp phải điều chỉnh dự án theo Nghị định 224/2026/NĐ-CP. Các rủi ro kỹ thuật chi tiết, chủ sở hữu, dấu hiệu sớm và quy trình rà soát mỗi sprint, mỗi cổng thuộc D01-02 §8; ở đây chỉ dẫn chiếu mã RSK. Rủi ro kiến trúc RSK-A01 đến RSK-A05 tại D03-01 §12 đã được phản ánh vào các rủi ro dự án tương ứng.

Rủi ro được chấm theo xác suất (P) và tác động (I) thang 1 đến 5, điểm bằng P nhân I; từ 15 trở lên là mức cao. Các rủi ro mức cao được định lượng bằng giá trị kỳ vọng theo người-tháng để làm căn cứ cho khoản dự phòng ở mục 11.5.

### 11.2. Các rủi ro cấp dự án

Bảng dưới đây liệt kê 12 rủi ro cấp dự án, sắp theo điểm. Cột "Điểm còn lại" là điểm dự kiến khi biện pháp quản lý được thực hiện đúng hạn; khoảng cách giữa hai cột cho thấy giá trị của biện pháp.

| Mã | Rủi ro | P × I | Điểm | Biện pháp quản lý chính | Điểm còn lại |
|---|---|---|---|---|---|
| RSK-17 | Nhà cung cấp hệ cũ không hợp tác trích xuất dữ liệu, cấu hình | 4 × 5 | 20 | Rà soát hợp đồng hệ cũ, ký phụ lục bàn giao có danh mục và thời hạn trước T0; tỉnh tự nắm tài khoản quản trị hệ cũ | 12 |
| RSK-01 | Chậm thẩm định, phê duyệt dự án và thiết kế | 4 × 4 | 16 | Thẩm định sơ bộ không chính thức; bảng đối chiếu nội dung Điều 45 Nghị định 224/2026/NĐ-CP với các chương của báo cáo; mốc ghi dạng T0 cộng n tháng | 12 |
| RSK-08 | Tài liệu hệ cũ không khớp hệ thống đang chạy | 4 × 4 | 16 | Kiểm kê hệ cũ bằng dữ liệu thật trong W0, là điều kiện cổng G0 | 9 |
| RSK-09 | Sở, ngành chậm chuyển đổi kết nối và phối hợp kiểm thử | 4 × 4 | 16 | Lớp tương thích giữ nguyên địa chỉ, giao diện cũ; văn bản UBND tỉnh giao việc; cắt chuyển theo nhóm | 12 |
| RSK-22 | NDXP đổi đặc tả hoặc chậm cấp môi trường thử | 4 × 4 | 16 | Đăng ký kết nối từ W0; adapter thay được; bộ giả lập theo bản tin thật | 9 |
| RSK-24 | Hạ tầng PROD, DR bàn giao chậm | 4 × 4 | 16 | Lịch ràng buộc giữa gói hạ tầng và gói phần mềm; hạ tầng mô tả bằng mã | 9 |
| RSK-30 | Thiếu kỹ sư tích hợp Camel | 4 × 4 | 16 | Tiêu chí năng lực trong hồ sơ mời thầu; đào tạo chuyển đổi ở W0; khung route chuẩn | 9 |
| RSK-33 | Năng lực vận hành Kubernetes tại tỉnh chưa đáp ứng | 4 × 4 | 16 | Cán bộ vận hành làm cặp với đội nền tảng từ W2; hợp đồng vận hành có cam kết mức dịch vụ | 9 |
| RSK-19 | Gián đoạn dịch vụ khi chạy song song, cắt chuyển | 3 × 5 | 15 | So sánh bóng, chuyển lưu lượng từng phần, quay lui trong 15 phút | 8 |
| RSK-21 | Lệch đối soát PayGov khi cắt chuyển thanh toán | 3 × 5 | 15 | Cắt chuyển thanh toán sau cùng, đối soát kép tối thiểu 30 ngày | 8 |
| RSK-36 | Rò rỉ dữ liệu chéo tenant | 2 × 5 | 10 | Cách ly nhiều lớp theo ADR-003 và D03-10; kiểm thử cách ly là điều kiện G2 | 5 |
| RSK-41 | Không bố trí được kinh phí vận hành sau dự án | 3 × 4 | 12 | Trình bày chi phí vòng đời 5 năm; đưa vào kế hoạch tài chính trung hạn; chia sẻ chi phí giữa các tỉnh | 8 |

: Sổ rủi ro cấp dự án: mức điểm, biện pháp quản lý và điểm còn lại

Hai rủi ro cuối không có điểm cao nhất nhưng được đưa vào vì lý do thẩm định. RSK-36 có tác động không bù được (lộ dữ liệu của tỉnh này cho tỉnh khác) và là rủi ro đặc trưng của mô hình sản phẩm đa tenant mà báo cáo đề xuất, nên hội đồng cần thấy nó được xử lý thế nào. RSK-41 quyết định lợi ích đầu tư có được duy trì sau 5 năm hay không, liên quan trực tiếp tới phân tích hiệu quả ở Chương 10.

Bảy trong mười rủi ro điểm cao có nguyên nhân nằm ở phía cơ quan nhà nước hoặc bên thứ ba: nhà cung cấp hệ cũ, cơ quan thẩm định, các sở, ngành, cơ quan quản lý NDXP, gói hạ tầng, đơn vị vận hành. Điều này có nghĩa là biện pháp hiệu quả nhất là những việc chủ đầu tư làm trước T0 với chi phí thấp, gồm ký phụ lục bàn giao với nhà cung cấp hệ cũ, khởi động đăng ký kết nối NDXP, chuẩn bị văn bản giao việc cho sở, ngành và lập lịch gói hạ tầng. Báo cáo đề nghị đưa bốn việc này vào quyết định phê duyệt dự án như nhiệm vụ của chủ đầu tư.

### 11.3. So sánh mức rủi ro giữa các phương án

Bảng dưới đây so sánh mức rủi ro của ba phương án ở Chương 4 theo sáu nhóm rủi ro có ý nghĩa thẩm định. Mức được đánh giá định tính (thấp, trung bình, cao) kèm lập luận; kết quả nhất quán với điểm TC-5 (PA1: 2, PA2a: 4, PA2b: 3, PA3: 3) và bổ sung các nhóm rủi ro mà TC-5 không bao quát như khóa nhà cung cấp và nhân rộng.

| Nhóm rủi ro | PA1 Nâng cấp hệ cũ | PA2 Nền tảng thương mại | PA3 Xây mới mã nguồn mở |
|---|---|---|---|
| Xây dựng, kỹ thuật | **Cao.** Phải nâng nhiều thành phần phụ thuộc chuỗi (Camel trên Spring XML, Pulsar, APIM) trên một hệ đang chạy; quyền mã nguồn chưa rõ | **Thấp (PA2a) đến trung bình (PA2b).** Lõi đã chạy thực tế; rủi ro dồn vào phần tùy biến và phần còn thiếu như dữ liệu dùng chung, thanh toán | **Trung bình.** Khối lượng xây dựng lớn; giảm bằng MVP 12 phân hệ, thành phần nguồn mở trưởng thành, cổng CI bắt buộc (RSK-11, RSK-15, RSK-28) |
| Phụ thuộc nhà cung cấp hệ cũ | **Rất cao.** Mọi thay đổi phải đi qua nhà cung cấp hiện hữu, không có đòn bẩy cạnh tranh | **Cao.** Vẫn cần dữ liệu, cấu hình hệ cũ để di trú (RSK-17) | **Cao.** Như PA2; giảm bằng phụ lục bàn giao và trích xuất trực tiếp từ hạ tầng của tỉnh |
| Khóa nhà cung cấp mới, giấy phép | **Cao.** Tiếp tục khóa vào nhà cung cấp cũ | **Cao.** Bản quyền hoặc thuê bao gắn với một hãng; chi phí đổi nhà cung cấp lớn | **Thấp.** Mã nguồn thuộc tỉnh; thành phần qua giao diện chuẩn; rủi ro đổi giấy phép nguồn mở được quản lý (RSK-14) |
| Tuân thủ pháp lý, ATTT | **Cao.** Thiết kế cũ khó đạt cấp độ 3, thông tin xác thực lưu dạng văn bản (Chương 2) | **Trung bình.** Phụ thuộc hồ sơ của sản phẩm; nền tảng quốc tế có thể vướng lưu trữ trong nước | **Trung bình.** Thiết kế cho cấp độ 3 từ đầu, nhưng hồ sơ phải được phê duyệt đúng hạn (RSK-26) |
| Nhân rộng nhiều tỉnh | **Cao.** Mỗi tỉnh một bản cài đặt | **Trung bình.** Tùy mô hình cấp phép của hãng | **Thấp đến trung bình.** Thiết kế đa tenant; rủi ro còn lại là rò rỉ chéo tenant (RSK-36) và cơ chế pháp lý cho tỉnh thứ hai (RSK-39) |
| Nhân lực | **Trung bình.** Cần người hiểu hệ cũ | **Trung bình (PA2a) đến cao (PA2b).** Chuyên gia nền tảng quốc tế hiếm, đắt | **Trung bình.** Thiếu kỹ sư Camel (RSK-30) và vận hành Kubernetes (RSK-33), giảm bằng đào tạo và hợp đồng vận hành |

: So sánh mức rủi ro theo nhóm giữa PA1, PA2 và PA3

Lập luận tổng hợp như sau. PA2a có rủi ro xây dựng thấp nhất, và nếu chỉ xét rủi ro thực hiện trong 18 tháng thì PA2a nhỉnh hơn PA3. Tuy nhiên PA2a chuyển rủi ro từ giai đoạn xây dựng sang vòng đời: tỉnh phụ thuộc một hãng về giá, lộ trình sản phẩm và khả năng nhân rộng, và những rủi ro này kéo dài suốt 5 năm của cửa sổ TCO chứ không kết thúc ở G5. PA1 có rủi ro cao ở hầu hết các nhóm và không giải quyết được nguyên nhân gốc của các điểm nghẽn ở Chương 2. PA3 chấp nhận rủi ro xây dựng cao hơn đổi lấy rủi ro vòng đời thấp hơn, và rủi ro xây dựng là loại rủi ro mà kế hoạch dự án có công cụ kiểm soát trực tiếp (phát hành theo đợt, cổng nghiệm thu, quay lui từng nhóm dịch vụ). Vì vậy phân tích rủi ro củng cố, chứ không đảo ngược, kết luận chọn PA3 ở Chương 4.

### 11.4. Rủi ro còn lại

Sau khi thực hiện biện pháp quản lý, dự án vẫn còn ba nhóm rủi ro mà người quyết định đầu tư cần chấp nhận một cách có ý thức. Nhóm thứ nhất là rủi ro do bên ngoài quyết định: lịch và đặc tả của nền tảng quốc gia (RSK-22, RSK-05), thay đổi pháp luật về dữ liệu và dữ liệu cá nhân (RSK-04) và sắp xếp tổ chức hành chính (RSK-06). Dự án không loại bỏ được các rủi ro này mà chỉ giảm tác động bằng thiết kế cấu hình hóa và bằng khả năng giữ dịch vụ trên hệ cũ trong lúc chờ. Nhóm thứ hai là rủi ro tác động lớn nhưng xác suất đã được hạ thấp, gồm gián đoạn dịch vụ khi cắt chuyển (RSK-19), lệch đối soát thanh toán (RSK-21), lộ dữ liệu cá nhân khi di trú (RSK-27) và rò rỉ chéo tenant (RSK-36); điểm còn lại của chúng thấp nhưng tác động vẫn ở mức 4 hoặc 5. Nhóm thứ ba là rủi ro sau dự án, gồm năng lực vận hành (RSK-33) và kinh phí vận hành (RSK-41), nằm ngoài tổng mức đầu tư nhưng quyết định hiệu quả đầu tư.

### 11.5. Khoản dự phòng đề xuất

Theo định lượng tại D01-02 §8.5, giá trị kỳ vọng của tám rủi ro hàng đầu nằm trong nỗ lực của hợp đồng thực hiện là khoảng 42 người-tháng trước giảm thiểu và khoảng 17 người-tháng sau giảm thiểu, cộng khoảng 75 triệu đồng chi phí ngoài nhân công. Cộng dự trù khoảng 10 người-tháng cho 33 rủi ro còn lại, khoản dự phòng rủi ro đề xuất là **khoảng 28 người-tháng và 75 triệu đồng, tương đương khoảng 1.195 triệu đồng theo đơn giá tham khảo 40 triệu đồng/người-tháng (giá trị tham khảo)**, bằng khoảng 6% nỗ lực thực hiện 454,5 người-tháng.

Khoản này nằm trong chi phí dự phòng G(DP) của tổng mức đầu tư ở Chương 8. Theo Thông tư 39/2026/TT-BKHCN, dự phòng tối đa 10% tổng mức đầu tư và bao gồm cả trượt giá, khối lượng phát sinh, các khoản tạm tính; vì vậy dự phòng rủi ro cộng dự phòng trượt giá phải nằm trong trần này. Nếu biện pháp giảm thiểu không được thực hiện, giá trị kỳ vọng tiến gần toàn bộ trần 10%, nên việc thực hiện đúng hạn các biện pháp trước T0 và trong W0 là điều kiện để khoản dự phòng đủ dùng. Ngoài tổng mức đầu tư, báo cáo đề nghị chủ đầu tư dự trù trong chi thường xuyên của Năm 2 và Năm 3 khoảng 12 người-tháng dịch vụ vận hành bổ sung cho trường hợp RSK-33 xảy ra, và bố trí kinh phí gia hạn bảo trì hệ cũ tới hết G5 cộng 3 tháng (RSK-35).

Thời gian thực hiện 18 tháng không có khoảng dự phòng sau G5. Dự phòng thời gian được bố trí trong kế hoạch dưới dạng vùng đệm phạm vi mức C của mỗi wave, khoảng nổi cắt chuyển từ G3 tới G5 nhờ hệ cũ chạy song song, và điểm cắt chuyển thanh toán gắn với điều kiện ổn định 30 ngày (D01-02 §8.5.3).

### 11.6. Kết luận

Rủi ro của dự án ở mức trung bình, tập trung ở khâu chuẩn bị và phối hợp hơn là ở công nghệ, và đã có biện pháp, chủ sở hữu, dấu hiệu sớm, phương án dự phòng cho từng rủi ro tại D01-02 §8. Phương án PA3 được chọn có rủi ro xây dựng cao hơn PA2a nhưng rủi ro vòng đời thấp hơn mọi phương án khác. Với khoản dự phòng rủi ro khoảng 6% nỗ lực nằm trong trần dự phòng 10%, cùng bốn nhiệm vụ chuẩn bị của chủ đầu tư trước T0 (phụ lục bàn giao với nhà cung cấp hệ cũ, đăng ký kết nối NDXP, văn bản giao việc cho sở, ngành, lịch gói hạ tầng), dự án có thể thực hiện trong 18 tháng mà không phải điều chỉnh dự án.

### 11.7. Câu hỏi mở

Các câu hỏi dưới đây liên quan đến việc đưa các nhiệm vụ chuẩn bị trước T0 vào quyết định phê duyệt và đơn giá quy đổi khoản dự phòng rủi ro.

- **Q-D0101-80.** Chủ đầu tư có đồng ý đưa bốn nhiệm vụ chuẩn bị trước T0 ở mục 11.2 vào quyết định phê duyệt dự án không?
- **Q-D0101-89.** Đơn giá bình quân người-tháng chính thức để quy đổi khoản dự phòng rủi ro (đang dùng 40 triệu đồng/người-tháng làm giá trị tham khảo)?

## 12. Đánh giá tuân thủ, kết luận và kiến nghị

**Tóm tắt cho hội đồng thẩm định.** Chương này tổng hợp mức tuân thủ của dự án với các yêu cầu thẩm định tại khoản 7 Điều 66 Nghị định 224/2026/NĐ-CP (CMP-LAW-14): sự phù hợp với kế hoạch chuyển đổi số của tỉnh, với Khung kiến trúc, với quy định về kết nối, chia sẻ dữ liệu, an ninh mạng và bảo vệ dữ liệu cá nhân. Ma trận ở mục 12.2 cho thấy mọi yêu cầu đều có chương đáp ứng; bốn điểm còn phụ thuộc thông tin của tỉnh hoặc đối chiếu Công báo và được nêu thành câu hỏi mở. Dự án không có tác động môi trường đáng kể, tiêu thụ điện khoảng 7,2 kW tải trung bình cho hai site. Báo cáo kiến nghị chọn phương án PA3 với hạ tầng H1, tổng mức đầu tư sơ bộ 40.702 triệu đồng trước thuế GTGT, thực hiện 18 tháng theo sáu wave và đưa đủ 20 phân hệ vào vận hành.

### 12.1. Cách đánh giá

Mỗi yêu cầu tuân thủ được đánh giá theo ba mức. "Đáp ứng" nghĩa là thiết kế cơ sở đã có biện pháp cụ thể và có tài liệu thiết kế dẫn chiếu. "Đáp ứng có điều kiện" nghĩa là biện pháp đã có nhưng còn phụ thuộc một thông tin của tỉnh hoặc một điều khoản chưa đối chiếu nguyên văn. "Chưa đáp ứng" nghĩa là chưa có biện pháp; không yêu cầu nào ở mức này. Đánh giá dựa trên văn bản hiện hành tại thời điểm lập báo cáo, ghi ở Chương 1 mục 1.2.

### 12.2. Ma trận tuân thủ

Bảng dưới đây là ma trận tuân thủ cấp dự án. Ma trận chi tiết theo yêu cầu phần mềm nằm ở D00-03, còn ma trận theo biện pháp an ninh mạng nằm ở D03-07 và D03-08.

| Yêu cầu | Căn cứ | Cách Datahub đáp ứng | Chương, tài liệu | Mức |
|---|---|---|---|---|
| Phù hợp kế hoạch chuyển đổi số 5 năm và hằng năm của tỉnh | Khoản 1 Điều 45 NĐ 224/2026 | Datahub là hạ tầng số dùng chung; số hiệu kế hoạch của tỉnh cần điền | Chương 2 mục 2.5.5 | Có điều kiện (Q-D0101-14) |
| Tuân thủ Khung kiến trúc tổng thể quốc gia số hoặc khung kiến trúc hiện hành | Điều 37, điểm a khoản 1 Điều 46 NĐ 224/2026; CMP-LAW-10, CMP-LAW-11 | Ánh xạ bốn lớp kiến trúc, vai trò nền tảng tích hợp cấp tỉnh, tách control plane và data plane | Chương 5 mục 5.7; D03-01 | Có điều kiện (Q-D0101-15, Q-D0101-45) |
| Kết nối, chia sẻ dữ liệu qua Nền tảng chia sẻ, điều phối dữ liệu quốc gia | CMP-LAW-03 (NĐ 278/2025) | PH-14 kết nối quốc gia; địa chỉ và xác thực là cấu hình theo tenant (GĐ-02); chuẩn hóa trước 31/12/2026 | Chương 5 mục 5.8; FRS PH-14 | Đáp ứng |
| Chức năng của nền tảng tích hợp cấp tỉnh | CMP-LAW-09 | Phủ đủ chức năng LGSP và 183 mục nghiệp vụ hệ cũ `LGC` | Chương 5 mục 5.2; D00-03 | Đáp ứng |
| Quản trị, phân loại, chia sẻ dữ liệu | CMP-LAW-01, CMP-LAW-02 | Danh mục dùng chung (PH-07), dữ liệu chủ (PH-06), chất lượng dữ liệu (PH-08), nhãn phân loại dữ liệu | Chương 5; D02-07 | Đáp ứng |
| Bảo vệ dữ liệu cá nhân, hồ sơ đánh giá tác động | CMP-LAW-05, CMP-LAW-04 | PH-09; che dữ liệu, mã hóa trường Nhạy cảm, hồ sơ đánh giá tác động gửi cơ quan chuyên trách; báo vi phạm trong 72 giờ | Chương 7 mục 7.7; D03-07 | Đáp ứng |
| Bảo vệ an ninh mạng theo cấp độ 3, sẵn sàng cấp độ 4 | CMP-LAW-16, CMP-LAW-06, CMP-LAW-08 | 18 nhóm yêu cầu cấp độ 3 của TCVN 14423:2026; hồ sơ D03-08; điểm cắm cấp độ 4 | Chương 7; D03-07, D03-08; ADR-030 | Có điều kiện (Q-D0101-71) |
| Lưu trữ dữ liệu trong lãnh thổ Việt Nam | CMP-LAW-16 | Mọi môi trường đặt tại TTDL tỉnh hoặc cloud chính phủ trong nước; không dùng dịch vụ độc quyền nước ngoài | Chương 7 mục 7.8; Chương 6 | Đáp ứng |
| Nền tảng đám mây phục vụ chính phủ số (khi dùng H2) | CMP-LAW-20 | Chỉ chọn nhà cung cấp đạt tiêu chí; chỉ đề xuất cấp độ 3 có điều kiện cho hồ sơ HT-B | Chương 6 mục 6.7.2; D03-09 | Có điều kiện |
| Tiêu chuẩn kỹ thuật ứng dụng CNTT trong cơ quan nhà nước | CMP-LAW-13, STD-01 đến STD-05 | OpenAPI 3.1, AsyncAPI 3.0, OAuth 2.0, OIDC, TLS 1.3, WCAG 2.2 AA | Chương 5 mục 5.6 | Đáp ứng |
| IPv6 | Quy định về ứng dụng IPv6 trong cơ quan nhà nước | Hai ngăn xếp IPv4 và IPv6 ở biên và trong cụm | Chương 5 mục 5.9 | Đáp ứng |
| Chi phí theo định mức hiện hành | CMP-LAW-23 | Cơ cấu G(TB/DV), G(QLDA), G(TV), G(K), G(DP) theo Thông tư 39/2026 | Chương 8 | Có điều kiện (Q-D0101-81) |
| Kiểm thử, vận hành thử, nghiệm thu | CMP-LAW-24 | Sáu cổng G0 đến G5, kiểm thử độc lập trước G2 và G4 | Chương 9 mục 9.3.3; D01-02 §4, §13; D05-01 | Đáp ứng |
| Thuê dịch vụ công nghệ số: chất lượng, sở hữu dữ liệu, chuyển giao | Khoản 3 Điều 45 NĐ 224/2026 | DEV, TEST thuê cloud; lựa chọn thuê dịch vụ hỗ trợ sau bảo hành giữ quyền sở hữu dữ liệu và mã nguồn của tỉnh | Chương 4 mục 4.6; Chương 9 mục 9.5.3, 9.5.4 | Đáp ứng |

: Ma trận tuân thủ các yêu cầu thẩm định theo khoản 7 Điều 66 Nghị định 224/2026/NĐ-CP

Hai điểm "có điều kiện" có ảnh hưởng tới hồ sơ trình. Một là kế hoạch chuyển đổi số của tỉnh: nếu dự án chưa có tên trong kế hoạch, chủ đầu tư cần bổ sung trước khi trình thẩm định. Hai là Khung kiến trúc tổng thể quốc gia số: nếu khung chưa được ban hành chính thức, báo cáo dùng Khung Kiến trúc Chính phủ điện tử 3.0 làm căn cứ tạm thời và ánh xạ ở Chương 5 mục 5.7 đã được viết để đổi khung mà không đổi thiết kế.

### 12.3. Tuân thủ yêu cầu của hệ thống cũ và tính liên tục dịch vụ

Ngoài văn bản pháp luật, dự án có nghĩa vụ không làm gián đoạn các dịch vụ mà hệ LGSP cũ đang cung cấp. Mọi nghiệp vụ của năm khối Bus, Hub, API Management, Danh mục dùng chung và Payment được ánh xạ sang yêu cầu chức năng mới trong D00-03, và việc chuyển từng nhóm dịch vụ đi qua cơ chế thay thế dần ở Chương 5 mục 5.14 với thời gian gián đoạn mục tiêu không quá 15 phút mỗi lần cắt chuyển. Khối Payment được chuyển sau cùng và chỉ tắt sau 30 ngày PH-19 chạy ổn định (Chương 9 mục 9.5.6).

### 12.4. Tác động tới tổ chức và thủ tục hành chính

Dự án không tạo thủ tục hành chính mới cho người dân, doanh nghiệp. Với cơ quan nhà nước, dự án tạo một nghĩa vụ mới là kết nối qua nền tảng thay vì kết nối điểm–điểm, được quy định trong quy chế khai thác Datahub do UBND tỉnh ban hành (Chương 9 mục 9.5.2). Lợi ích cải cách hành chính, như giảm thành phần giấy tờ phải nộp nhờ khai thác dữ liệu đã có, được trình bày ở Chương 10.

### 12.5. Tác động môi trường

Như mục 1.5 đã nêu, dự án không xây dựng công trình, không thay đổi mục đích sử dụng đất và không thuộc diện đánh giá tác động môi trường. Hai tác động nhỏ được ghi nhận để hội đồng có đủ thông tin. Thứ nhất là tiêu thụ điện: với hạ tầng H1 cỡ M, site chính tiêu thụ khoảng 6 đến 7 kW khi tải cao và site DR khoảng 3,5 đến 4 kW; tải trung bình của hai site khoảng 7,2 kW, tương ứng chi phí điện khoảng 282 triệu đồng mỗi năm với hệ số PUE 1,6 (Chương 8 mục 8.7). Thiết bị đặt trong trung tâm dữ liệu sẵn có của tỉnh nên không phát sinh công trình làm mát mới. Với H2, tiêu thụ điện thuộc trách nhiệm của nhà cung cấp cloud. Thứ hai là thiết bị của hệ cũ: sau khi tắt hệ cũ ở G5, thiết bị được thu hồi theo quy định quản lý tài sản công; ổ lưu trữ chứa dữ liệu phải được xóa an toàn hoặc hủy vật lý có biên bản trước khi thanh lý (SEC-39 ở D03-07), và thiết bị điện tử thải bỏ được giao đơn vị có chức năng xử lý chất thải điện tử.

### 12.6. Quốc phòng, an ninh

Dự án có tác động tích cực tới an ninh mạng của tỉnh: thay một hệ thống có thành phần hết vòng đời hỗ trợ và bí mật lưu ở dạng rõ (Chương 2 mục 2.3) bằng một nền tảng được thiết kế theo cấp độ 3, có nhật ký kiểm toán bất biến và kết nối giám sát với cơ quan chuyên trách. Datahub không xử lý thông tin bí mật nhà nước; chính sách chặn dữ liệu mang nhãn mật được thực thi ở tầng ủy quyền (Chương 7). Dữ liệu và khóa mật mã nằm trong lãnh thổ Việt Nam, dưới quyền quản trị của tỉnh. Dự án không có hạng mục liên quan trực tiếp đến quốc phòng.

### 12.7. Kết luận và kiến nghị

Báo cáo đi đến bốn kết luận. Thứ nhất, việc đầu tư là cần thiết: hệ LGSP cũ có nhiều thành phần đã hết vòng đời hỗ trợ, không đáp ứng yêu cầu an ninh mạng và kết nối mới, trong khi tỉnh có nghĩa vụ chuẩn hóa kết nối qua Nền tảng chia sẻ, điều phối dữ liệu quốc gia (Chương 2). Thứ hai, phương án PA3 xây mới trên nền mã nguồn mở, kiến trúc sản phẩm đa tenant, có TCO năm năm xấp xỉ phương án rẻ nhất khi xét một tỉnh (chênh khoảng 1,3% so với PA2a) và thấp nhất khi xét từ hai tỉnh trở lên, và là phương án duy nhất nhân rộng được sang tỉnh khác với chi phí biên thấp (Chương 4, Chương 8 mục 8.10, 8.11). Thứ ba, thiết kế cơ sở đủ chi tiết để lập thiết kế chi tiết theo wave và đáp ứng các yêu cầu tuân thủ ở mục 12.2. Thứ tư, rủi ro chính đã được nhận diện và có biện pháp ứng phó, được quản lý trong sổ rủi ro ở D01-02 §8.

Trên cơ sở đó, báo cáo kiến nghị cấp có thẩm quyền:

1. Phê duyệt dự án theo phương án PA3, hạ tầng H1 (PROD, STAGING, DR tại trung tâm dữ liệu tỉnh; DEV, TEST thuê cloud chính phủ), tổng mức đầu tư sơ bộ **40.702 triệu đồng trước thuế GTGT** (khoảng 42.236 triệu đồng gồm thuế GTGT ước tính), thời gian thực hiện 18 tháng kể từ T0 và bảo hành 12 tháng.
2. Phê duyệt phạm vi 20 phân hệ PH-01 đến PH-20 theo ba đợt: MVP 12 phân hệ nghiệm thu ở G2, đợt 2 gồm PH-19 Thanh toán, PH-15, PH-09, PH-11 nghiệm thu ở G4, đợt 3 gồm PH-06, PH-08, PH-16, PH-17 nghiệm thu ở G5.
3. Giao chủ đầu tư thành lập Ban quản lý dự án theo Chương 9 mục 9.1 và lựa chọn nhà thầu theo phương án gói thầu GT-A ở Chương 9 mục 9.4.
4. Chỉ đạo các sở, ngành, UBND cấp xã có HTTT cử đầu mối kỹ thuật và chuyển kết nối khỏi hệ cũ theo lịch cắt chuyển, và ban hành quy chế khai thác Datahub trước G3.
5. Trả lời các câu hỏi mở ghi ở cuối mỗi chương trước khi trình thẩm định, ưu tiên Q-D0101-11 (nhóm dự án), Q-D0101-14 (kế hoạch chuyển đổi số của tỉnh), Q-D0101-52 (cách đưa thiết bị vào tổng mức đầu tư) và Q-D0101-71 (thẩm định cấp độ).

### Câu hỏi mở

Câu hỏi dưới đây liên quan đến mẫu ma trận tuân thủ mà cơ quan thẩm định yêu cầu.

- **Q-D0101-99.** Cơ quan thẩm định có yêu cầu ma trận tuân thủ theo mẫu riêng (ví dụ biểu mẫu thẩm định của Bộ Khoa học và Công nghệ) thay cho bảng ở mục 12.2 không?

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu, 12 chương theo khung báo cáo nghiên cứu khả thi, số liệu từ bộ giả định nền D01-00 |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Rà soát và bổ sung nội dung kỹ thuật, số liệu theo bộ giả định nền |
| 0.3 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Áp chuẩn trình bày kết hợp: thêm Tóm tắt cho hội đồng thẩm định (số liệu từ Chương 8 đến 10) và phần Giới thiệu tài liệu (mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu, cấu trúc); viết lại chú thích cụ thể cho 74 bảng và 18 hình; thêm đoạn mở cho các mục Câu hỏi mở; đổi các sơ đồ flowchart LR nhiều nút sang TB; thêm hai sơ đồ (trình tự thủ tục đầu tư ở mục 1.6, trình tự một lượt gọi ở mục 5.4.3); sửa dẫn chiếu kết luận ở bảng mục 1.4 (Chương 12 mục 12.7) và câu về TCO thấp nhất ở mục 12.7 cho khớp mục 8.10 |
