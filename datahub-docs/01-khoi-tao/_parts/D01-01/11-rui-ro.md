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

- **Q-D0101-80:** Chủ đầu tư có đồng ý đưa bốn nhiệm vụ chuẩn bị trước T0 ở mục 11.2 vào quyết định phê duyệt dự án không?
- **Q-D0101-81:** Đơn giá bình quân người-tháng chính thức để quy đổi khoản dự phòng rủi ro (đang dùng 40 triệu đồng/người-tháng làm giá trị tham khảo)?

### 11.8. Ghi chú cho người tổng hợp

- Nghị định 224/2026/NĐ-CP và Thông tư 39/2026/TT-BKHCN chưa có mã CMP-LAW; tỷ lệ dự phòng 10% lấy theo tóm tắt pháp lý, chưa đối chiếu Công báo.
- Chương 8 (tổng mức đầu tư) cần thống nhất khoản dự phòng rủi ro khoảng 28 người-tháng với tỷ lệ dự phòng trượt giá để tổng G(DP) không vượt 10%.
