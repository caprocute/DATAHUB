## 1. Giới thiệu, mục tiêu và phạm vi dự án

**Tóm tắt cho hội đồng thẩm định.** Kế hoạch dự án này biến phương án được chọn trong Báo cáo nghiên cứu khả thi (D01-01) thành một chương trình thực hiện có thể kiểm soát được: 18 tháng thực hiện chia thành 6 wave (W0 đến W5), sprint 2 tuần, 6 cổng nghiệm thu (G0 đến G5) và 12 tháng bảo hành. Dự án xây mới 20 phân hệ của Datahub theo ba đợt (12 phân hệ MVP, 5 phân hệ đợt 2, 3 phân hệ đợt 3), di trú khỏi hệ LGSP cũ tại tỉnh thí điểm theo chiến lược chạy song song và thay thế dần (strangler), sau đó nhân rộng sang tỉnh thứ hai trước khi kết thúc giai đoạn thực hiện. Tổng nỗ lực tham chiếu của nhà thầu là khoảng 459 người-tháng; đỉnh tải thực tế khoảng 38 người toàn thời gian trong ba tháng W3 và W4 chồng lấn. Kho dữ liệu phân tích (lakehouse), các hệ thống thông tin nguồn của sở ngành và phần mua sắm hạ tầng vật lý hoặc thuê dịch vụ cloud nằm ngoài phạm vi phần mềm của dự án này. Mục tiêu dự án được đo bằng chín mục tiêu nghiệp vụ BO-01 đến BO-09 và 18 chỉ số KPI-01 đến KPI-18 định nghĩa tại D02-01; kế hoạch gắn mỗi chỉ số với cổng nghiệm thu đầu tiên có thể chứng minh nó.

### 1.1. Mục đích của kế hoạch

Kế hoạch dự án (project management plan) là văn bản điều hành giữa chủ đầu tư, nhà thầu thực hiện, tư vấn giám sát và đơn vị vận hành. Nó trả lời bốn câu hỏi mà Báo cáo nghiên cứu khả thi chỉ trả lời ở mức tổng thể: làm những việc gì (cấu trúc phân rã công việc ở chương 2), làm theo cách nào (mô hình thực hiện ở chương 3), làm xong lúc nào và ai xác nhận là xong (tiến độ, mốc và cổng nghiệm thu ở chương 4), và làm thế nào để biết sản phẩm đạt chất lượng (chương 9 và chương 13). Các chương còn lại của tài liệu xử lý tổ chức, nguồn lực, ngân sách, rủi ro, cấu hình, thay đổi và truyền thông.

Kế hoạch có ba nhóm người dùng chính. Hội đồng thẩm định và người quyết định đầu tư dùng nó để kiểm tra rằng tiến độ và nỗ lực khai trong D01-01 có cơ sở phân rã cụ thể. Ban quản lý dự án phía chủ đầu tư dùng nó làm khung để nghiệm thu từng phần và thanh toán theo mốc. Giám đốc dự án và các trưởng nhóm phía nhà thầu dùng nó làm đường cơ sở (baseline) để lập kế hoạch sprint, đo tiến độ và báo cáo sai lệch. Vì vậy kế hoạch được viết với hai tầng: tầng tóm tắt ở đầu mỗi chương cho người phê duyệt, và tầng chi tiết với con số, tiêu chí định lượng cho người điều hành.

Kế hoạch là tài liệu sống. Bản 1.0 được phê duyệt cùng thiết kế chi tiết và dự toán trước khi lựa chọn nhà thầu, trở thành đường cơ sở hợp đồng. Sau đó kế hoạch được cập nhật tại mỗi cổng nghiệm thu; mọi thay đổi về phạm vi, mốc hoặc nỗ lực vượt ngưỡng phải đi qua quy trình kiểm soát thay đổi ở chương 11 và được ghi nhận bằng một phiên bản mới của tài liệu.

### 1.2. Căn cứ lập kế hoạch

Kế hoạch này kế thừa toàn bộ căn cứ pháp lý, sự cần thiết đầu tư và phương án được chọn từ D01-01, nên không nhắc lại phần lập luận ở đó. Các căn cứ trực tiếp chi phối cách lập kế hoạch gồm bốn nhóm.

Nhóm thứ nhất là khung pháp lý về đầu tư hệ thống chuyển đổi số sử dụng ngân sách nhà nước. Văn bản áp dụng là Nghị định 224/2026/NĐ-CP ngày 24/6/2026 quy định chi tiết Luật Chuyển đổi số số 148/2025/QH15, có hiệu lực từ 01/7/2026; Điều 90 của nghị định này bãi bỏ Nghị định 45/2026/NĐ-CP (văn bản trước đó đã thay Nghị định 73/2019/NĐ-CP), và Điều 91 quy định dự án chưa được quyết định đầu tư trước 01/7/2026 phải áp dụng nghị định mới. Datahub vì vậy được lập, thẩm định và triển khai như một dự án đầu tư hệ thống chuyển đổi số theo Nghị định 224/2026/NĐ-CP, cùng Thông tư 39/2026/TT-BKHCN về chi phí và Thông tư 41/2026/TT-BKHCN về khảo sát, triển khai, giám sát, kiểm thử và nghiệm thu ([nguồn tham khảo](https://hethongphapluat.com/nghi-dinh-224-2026-nd-cp-huong-dan-luat-chuyen-doi-so/dieu-90), chưa đối chiếu Công báo). Các văn bản này quyết định trình tự chuẩn bị đầu tư theo thiết kế hai bước (Báo cáo nghiên cứu khả thi kèm thiết kế cơ sở, sau đó thiết kế chi tiết và dự toán), yêu cầu kiểm thử phần mềm nội bộ, yêu cầu vận hành thử trước nghiệm thu, thủ tục nghiệm thu, bàn giao và các trường hợp điều chỉnh dự án phải trình cấp có thẩm quyền. Chương 4 áp các bước đó vào lịch tham chiếu; những điều khoản chưa đọc được nguyên văn (đặc biệt điều về nghiệm thu, bàn giao và về phát triển linh hoạt) được ghi thành câu hỏi mở ở cuối chương này.

Nhóm thứ hai là các yêu cầu chuyên ngành mà sản phẩm phải đáp ứng và vì thế tạo ra công việc trong WBS: Luật Dữ liệu (CMP-LAW-01) và Nghị định 165/2025/NĐ-CP (CMP-LAW-02) về quản trị và chia sẻ dữ liệu; Nghị định 47/2020/NĐ-CP (CMP-LAW-03) và Công văn 631/THH-THHT (CMP-LAW-09) về chức năng LGSP; khung pháp lý bảo vệ dữ liệu cá nhân (CMP-LAW-04, CMP-LAW-05); Nghị định 85/2016/NĐ-CP, Thông tư 12/2022/TT-BTTTT và TCVN 11930:2017 (CMP-LAW-06 đến CMP-LAW-08) về bảo đảm an toàn hệ thống thông tin theo cấp độ; Khung Kiến trúc Chính phủ điện tử phiên bản 3.0 (CMP-LAW-10).

Nhóm thứ ba là bộ giả định nền dùng chung của D01-01 và D01-02 (tệp `_gia-dinh-nen.md`), là nguồn duy nhất cho mốc, wave, đội ngũ, quy mô tham chiếu và phương án hạ tầng. Mọi con số trong tài liệu này trích từ đó; nơi nào cần một con số khác, kế hoạch ghi đề xuất ở mục "Ghi chú cho người tổng hợp" chứ không tự đặt.

Nhóm thứ tư là các quyết định kỹ thuật đã có của sản phẩm: bộ quyết định kiến trúc (D00-02), mô hình đơn vị triển khai lai, quy tắc sở hữu mã theo lane và cổng CI bắt buộc của repo. Các quyết định này không thuộc phạm vi điều chỉnh của kế hoạch, nhưng kế hoạch phải tôn trọng chúng khi phân rã công việc và lập lịch.

### 1.3. Mục tiêu dự án đo được

Mục tiêu của dự án là chín mục tiêu nghiệp vụ BO-01 đến BO-09 và 18 chỉ số KPI-01 đến KPI-18 đã được định nghĩa chính thức tại D02-01 §3, kèm giá trị nền, giá trị đích và thời điểm đo. Kế hoạch không đặt lại mục tiêu mà làm một việc khác: gắn mỗi mục tiêu với cổng nghiệm thu đầu tiên mà tại đó có thể có bằng chứng, để mỗi cổng không chỉ đếm số chức năng đã làm mà còn chứng minh một kết quả có ý nghĩa với chủ đầu tư. Bảng sau tóm tắt mối gắn kết đó; tên mục tiêu được rút gọn, giá trị đích lấy nguyên từ D02-01.

| Mục tiêu (D02-01) | Chỉ số và giá trị đích | Cổng có bằng chứng đầu tiên | Bằng chứng tại cổng |
|---|---|---|---|
| BO-01 Mọi trao đổi dữ liệu đi qua một điểm có kiểm soát | KPI-01 ≥ 90% HTTT kết nối qua Datahub; KPI-02 giảm ≥ 80% kết nối điểm–điểm (sau 12 tháng) | G3 (đo lần đầu), đo lại cuối bảo hành | Báo cáo cắt chuyển từng nhóm dịch vụ; sổ HTTT đã kết nạp trên PH-01 |
| BO-02 Dịch vụ công không gián đoạn vì nền tảng tích hợp | KPI-03 sẵn sàng data plane ≥ 99,9%/tháng; KPI-04 độ trễ thêm tại gateway p95 ≤ 50 ms | G2 (kiểm thử tải), G3 (vận hành thật) | Báo cáo kiểm thử hiệu năng D05-03; báo cáo sẵn sàng 30 ngày đầu PROD |
| BO-03 Rút ngắn thời gian đưa kết nối mới vào vận hành | KPI-05 ≤ 5 ngày làm việc; KPI-06 ≤ 2 ngày công cho một luồng chuẩn | G1 (KPI-06 trên TEST), G3 (KPI-05 trên PROD) | Nhật ký thời gian của các HTTT kết nạp trong W3 |
| BO-04 Tuân thủ pháp luật về dữ liệu và ATTT | KPI-07 = 100% lượt khai thác có nhật ký đủ; KPI-08 hồ sơ cấp độ 3 được phê duyệt; KPI-09 = 0 thông tin xác thực ngoài kho bí mật | G2 (KPI-07, KPI-09), G3 (KPI-08) | Báo cáo quét bí mật; quyết định phê duyệt cấp độ |
| BO-05 Danh mục dùng chung thống nhất, đồng bộ quốc gia | KPI-10 = 100% danh mục bắt buộc; KPI-11 đồng bộ ≤ 24 giờ | G2 (chức năng), G3 (dữ liệu tỉnh 1) | Báo cáo di trú danh mục; nhật ký đồng bộ |
| BO-06 Một nền tảng cho nhiều tỉnh | KPI-12 khởi tạo tenant ≤ 1 ngày làm việc | G2 (trên STAGING), G5 (tỉnh 2) | Biên bản khởi tạo tenant tỉnh 2 |
| BO-07 Thanh toán minh bạch, đối soát được | KPI-13 ≥ 99,5% giao dịch khớp tự động; KPI-14 phát hiện lệch ≤ 1 ngày làm việc | G4 | Báo cáo 30 ngày chạy ổn định của PH-19 |
| BO-08 Vận hành chủ động | KPI-15 MTTD ≤ 5 phút; KPI-16 MTTR sự cố mức 1 ≤ 1 giờ | G3 | Biên bản diễn tập sự cố; báo cáo cảnh báo PH-13 |
| BO-09 Một giao diện quản trị thống nhất | KPI-17 = 1 giao diện; KPI-18 điểm SUS ≥ 75 | G2 (KPI-17), UAT các đợt (KPI-18) | Biên bản UAT có khảo sát SUS |

Bảng cho thấy hai đặc điểm. Thứ nhất, phần lớn chỉ số có bằng chứng đầu tiên tại G2 hoặc G3, tức là trước khi kết thúc 13 tháng đầu, nên hội đồng có căn cứ định lượng ngay ở nghiệm thu MVP chứ không phải chờ đến G5. Thứ hai, những chỉ số có thời điểm đo "12 tháng" trong D02-01 (KPI-01, KPI-02, KPI-10) không thể đo xong trong giai đoạn thực hiện; kế hoạch đo chúng lần đầu tại G3 và đo lại ở cuối thời gian bảo hành (chương 13). Các chỉ số có dấu "chưa đo" trong D02-01 cần giá trị nền được đo trước G1 theo câu hỏi mở Q04 của D02-01.

### 1.4. Phạm vi dự án

#### 1.4.1. Trong phạm vi

Phạm vi được xác định theo sản phẩm bàn giao và theo hoạt động. Về sản phẩm, dự án xây dựng 20 phân hệ của Datahub, chia làm ba đợt. Đợt 1 (MVP) gồm 12 phân hệ là PH-01, PH-02, PH-03, PH-04, PH-05, PH-07, PH-10, PH-12, PH-13, PH-14, PH-18 và PH-20, đủ để thay thế các khối Bus, Hub, API Management, Danh mục dùng chung và kết nối quốc gia của hệ cũ. Đợt 2 gồm 5 phân hệ PH-06, PH-08, PH-09, PH-11 và PH-19, trong đó PH-19 thay khối Payment của hệ cũ, còn bốn phân hệ còn lại bổ sung lớp dữ liệu dùng chung (dữ liệu chủ, chất lượng dữ liệu, bảo vệ dữ liệu cá nhân) và điều phối quy trình. Đợt 3 gồm 3 phân hệ PH-15, PH-16 và PH-17, là cổng nhà phát triển, quản trị kiến trúc và KPI, cổng AI. Toàn bộ 20 phân hệ được đóng gói thành bản phát hành v1.0 multi-tenant duy nhất.

Về hoạt động, phạm vi gồm sáu khối việc ngoài phát triển phân hệ. Khối thứ nhất là bộ tài liệu SDLC D00 đến D06 theo dàn ý của bộ tài liệu. Khối thứ hai là nền tảng kỹ thuật dùng chung: monorepo, cổng CI, hợp đồng máy đọc (OpenAPI, AsyncAPI, chính sách OPA), thư viện dùng chung và bộ giao diện. Khối thứ ba là di trú khỏi hệ LGSP cũ tại tỉnh thí điểm theo chiến lược strangler: dựng lớp định tuyến trước hệ cũ, chuyển từng nhóm dịch vụ sang Datahub, chạy song song, đối soát, rồi tắt hệ cũ trước G5. Khối thứ tư là an toàn thông tin, gồm thiết kế, kiểm thử bảo mật và lập hồ sơ đề xuất cấp độ 3 trình phê duyệt. Khối thứ năm là cài đặt, cấu hình phần mềm nền (Kubernetes trở lên) trên bốn môi trường DEV, TEST, STAGING, PROD và site DR của tỉnh thí điểm, cộng môi trường PROD của tỉnh thứ hai. Khối thứ sáu là đào tạo, chuyển giao và nghiệm thu, bàn giao.

Nhân rộng sang tỉnh thứ hai nằm trong phạm vi ở mức "dựng tenant và đưa vào vận hành tối thiểu", nghĩa là cài đặt bản v1.0, cấu hình tenant, kết nạp các HTTT đầu tiên do tỉnh 2 chọn, đào tạo quản trị viên tỉnh 2. Di trú hệ cũ của tỉnh 2 (nếu tỉnh 2 cũng đang chạy một LGSP cũ) không nằm trong phạm vi, vì chưa biết tỉnh 2 dùng nền tảng nào; điểm này được ghi thành câu hỏi mở.

#### 1.4.2. Ngoài phạm vi

Ranh giới phạm vi được vẽ rõ để tránh tranh chấp khi nghiệm thu. Bảng sau liệt kê những hạng mục người đọc có thể nghĩ là thuộc dự án nhưng thực tế không thuộc, kèm lý do và nơi xử lý.

| Hạng mục ngoài phạm vi | Lý do | Xử lý ở đâu |
|---|---|---|
| Kho dữ liệu phân tích, lakehouse, báo cáo phân tích đa nguồn | Datahub là LGSP thế hệ mới có lớp dữ liệu dùng chung, không phải nền tảng phân tích | Dự án riêng ở giai đoạn sau; kiến trúc để sẵn điểm xuất dữ liệu qua sự kiện |
| Mua sắm thiết bị phần cứng tại TTDL tỉnh (phương án H1) hoặc thuê dịch vụ cloud chính phủ (phương án H2) | Thuộc gói mua sắm hoặc thuê dịch vụ riêng theo phương án hạ tầng được chọn ở D01-01 | Dự án chỉ đặt yêu cầu cấu hình (D03-09) và cài đặt từ tầng Kubernetes trở lên |
| Sửa đổi các HTTT nguồn và đích của sở ngành, cấp xã | Các HTTT này thuộc chủ quản khác | Dự án cung cấp adapter, hợp đồng API và hỗ trợ kỹ thuật kết nối |
| Nâng cấp NDXP, NDOP hoặc các CSDL quốc gia | Thuộc trách nhiệm cấp trung ương | Dự án chỉ xây PH-14 kết nối theo đặc tả hiện hành của các nền tảng đó |
| Phí giao dịch thanh toán, phí dịch vụ của trung gian thanh toán, thuê bao SMS | Chi phí vận hành, không phải chi phí đầu tư | Dự toán vận hành của đơn vị vận hành |
| Triển khai cho tỉnh thứ ba trở đi | Mỗi tỉnh là một quyết định đầu tư hoặc thuê dịch vụ riêng | Hợp đồng triển khai riêng dùng bản v1.0 |
| Vận hành thường xuyên sau thời gian bảo hành | Thuộc chi thường xuyên | Hợp đồng vận hành, hỗ trợ kỹ thuật hằng năm |
| Số hóa, làm sạch dữ liệu nghiệp vụ chuyên ngành của sở ngành | Không thuộc chức năng nền tảng | Dự án cung cấp công cụ chất lượng dữ liệu (PH-08) để sở ngành tự làm |
| Mô hình AI nền tảng và hạ tầng GPU | PH-17 là cổng quản trị truy cập AI, không phải nơi huấn luyện hay vận hành mô hình | Dịch vụ AI do tỉnh hoặc cấp trên cung cấp, kết nối qua PH-17 |

Hai hạng mục cần chủ đầu tư xác nhận sớm vì ảnh hưởng trực tiếp đến tiến độ. Hạng mục hạ tầng ngoài phạm vi có nghĩa là W0 và W3 phụ thuộc vào một gói thầu khác giao thiết bị hoặc dịch vụ đúng hạn; chương 4 coi đây là phụ thuộc bên ngoài trên đường găng. Hạng mục HTTT nguồn ngoài phạm vi có nghĩa là mỗi nhóm dịch vụ chỉ cắt chuyển được khi chủ quản HTTT liên quan phối hợp đổi điểm kết nối, nên kế hoạch cắt chuyển ở chương 4 xếp các nhóm dịch vụ cần ít thay đổi phía HTTT lên trước.

### 1.5. Giả định

Kế hoạch dựa trên các giả định sau. Mỗi giả định có hệ quả cụ thể nếu sai, và được theo dõi như rủi ro trong sổ rủi ro của tài liệu này.

1. Mọi mốc được tính tương đối từ T0, là ngày khởi động hợp đồng thực hiện; theo chỉ đạo của chủ đầu tư, tài liệu không gắn ngày lịch cụ thể. Nếu các bước chuẩn bị đầu tư kéo dài, T0 dịch theo, nhưng thời lượng tương đối giữa các wave giữ nguyên.
2. Tỉnh thí điểm có quy mô cỡ M: tối đa 200 HTTT kết nối, 1.000 API, 10 triệu giao dịch đồng bộ mỗi ngày, đỉnh 1.000 TPS tại cổng API. Tiêu chí kiểm thử hiệu năng ở các cổng lấy theo cỡ này.
3. Chủ đầu tư là Sở Khoa học và Công nghệ tỉnh thí điểm, người quyết định đầu tư là UBND tỉnh, đơn vị vận hành là Trung tâm Chuyển đổi số hoặc Trung tâm dữ liệu tỉnh. Các vai trò này cần được điền chính thức.
4. Hạ tầng DEV và TEST sẵn sàng trong 4 tuần đầu của W0; hạ tầng STAGING, PROD và DR của tỉnh thí điểm sẵn sàng chậm nhất tại T0+8 tháng, tức là hai tháng trước khi W3 bắt đầu.
5. Đội ngũ thực hiện theo bảng tham chiếu trong giả định nền, đỉnh tải thực tế khoảng 38 người toàn thời gian khi W3 và W4 chồng lấn, dùng AI agent viết mã có kiểm soát theo quy tắc ở chương 3.
6. Nhà cung cấp hệ LGSP cũ hợp tác trong việc cung cấp cấu trúc dữ liệu, xuất dữ liệu cấu hình và hỗ trợ trong thời gian chạy song song; hệ cũ còn được duy trì đến G5.
7. Đại diện chủ đầu tư tham gia sprint review 2 tuần một lần và có quyền quyết định ưu tiên trong phạm vi đã chốt.
8. Đặc tả kết nối NDXP, NDOP và trung gian thanh toán PayGov không thay đổi phá vỡ tương thích trong thời gian thực hiện.

### 1.6. Ràng buộc

Khác với giả định, ràng buộc là những điều kiện kế hoạch không được phép thay đổi. Ràng buộc về thời gian là giai đoạn thực hiện 18 tháng, kết thúc bằng G5 tại T0+18 tháng, vì kế hoạch vốn đầu tư được bố trí cho hai năm ngân sách liên tiếp kể từ T0 (Năm 1 và Năm 2 trong cửa sổ TCO). Ràng buộc về thủ tục là mọi sản phẩm chỉ được đưa vào vận hành chính thức sau khi nghiệm thu theo Nghị định 224/2026/NĐ-CP và sau khi hồ sơ đề xuất cấp độ 3 được phê duyệt. Ràng buộc kỹ thuật là sản phẩm dùng phần mềm nguồn mở, không phụ thuộc dịch vụ độc quyền của một nhà cung cấp cloud, dữ liệu lưu trong nước, thiết kế sẵn để nâng lên cấp độ 4. Ràng buộc về vận hành là hệ cũ không được tắt khi chưa có đối soát chứng minh rằng mọi dịch vụ của nó đã có tương đương trên Datahub, và dịch vụ thanh toán cũ chỉ được tắt sau khi PH-19 chạy ổn định 30 ngày liên tục.

### 1.7. Câu hỏi mở

- **Q-D0102-01:** Nghị định 224/2026/NĐ-CP (Điều 57 về nghiệm thu, bàn giao) và Thông tư 41/2026/TT-BKHCN quy định các bước nghiệm thu và thành phần hồ sơ cụ thể ra sao, và có cho phép nghiệm thu từng phần theo hạng mục hoặc theo đợt phát hành không? Kế hoạch đang giả định cho phép nghiệm thu từng phần theo wave; cần đối chiếu nguyên văn trước khi phát hành bản 1.0.
- **Q-D0102-02:** Dự án có thuộc diện phải lập, trình chủ trương đầu tư theo quy định hiện hành không? Điều này quyết định bước đầu tiên trong lịch chuẩn bị đầu tư (T0 − 7 đến T0 − 6 tháng).
- **Q-D0102-03:** Hạ tầng phần cứng (H1) hoặc dịch vụ cloud (H2) được mua sắm trong cùng dự án dưới dạng một gói thầu riêng, hay là một dự án khác? Câu trả lời quyết định ai chịu trách nhiệm khi hạ tầng giao chậm.
- **Q-D0102-04:** Tỉnh thứ hai là tỉnh nào, đã có LGSP đang chạy chưa, và việc triển khai cho tỉnh 2 được cấp vốn từ dự án này hay từ một thỏa thuận riêng giữa hai tỉnh?

### 1.8. Ghi chú cho người tổng hợp

- Nghị định 224/2026/NĐ-CP, Luật Chuyển đổi số 148/2025/QH15, Thông tư 39/2026/TT-BKHCN và Thông tư 41/2026/TT-BKHCN chưa có mã trong D00-01 §7. CMP-LAW-14 hiện ghi Nghị định 45/2026/NĐ-CP, văn bản đã hết hiệu lực từ 01/7/2026; đề xuất cập nhật CMP-LAW-14 thành Nghị định 224/2026/NĐ-CP và cấp mã mới cho ba văn bản còn lại.
- **Mâu thuẫn phân đợt.** D02-01 §8.3 xếp đợt 2 gồm PH-19, PH-15, PH-09, PH-11 và đợt 3 gồm PH-06, PH-08, PH-16, PH-17; `_gia-dinh-nen.md` §2 xếp đợt 2 gồm PH-19, PH-06, PH-08, PH-09, PH-11 và đợt 3 gồm PH-15, PH-16, PH-17. Kế hoạch này theo giả định nền (nguồn sự thật cho wave). Cần chọn một phương án và sửa tài liệu kia; nếu theo D02-01 thì W4 có thêm PH-15 (10 người-tháng) và bớt PH-06, PH-08 (25 người-tháng), W5 ngược lại, và WBS chương 2 phải đổi cột wave.
- **Mâu thuẫn thời hạn nhật ký.** D02-02 NFR-00-027 yêu cầu nhật ký kiểm toán trực tuyến tối thiểu 12 tháng; giả định nền §4 ghi lưu nhật ký nóng 90 ngày. Hai con số có thể cùng đúng nếu 90 ngày là log vận hành (NFR-00-028), nhưng giả định nền nên ghi rõ.
- Giả định số 4 (hạ tầng PROD sẵn sàng chậm nhất T0+8 tháng) chưa có trong `_gia-dinh-nen.md`. Đề xuất bổ sung vào §3 của tệp giả định nền vì nó là phụ thuộc trên đường găng.
