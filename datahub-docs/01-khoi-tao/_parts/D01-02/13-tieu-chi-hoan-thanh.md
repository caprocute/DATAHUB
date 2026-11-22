## 13. Tiêu chí hoàn thành dự án và bàn giao

**Tóm tắt cho hội đồng thẩm định.** Dự án được coi là hoàn thành tại G5 (T0+18) khi đạt đồng thời mười điều kiện của định nghĩa hoàn thành cấp dự án, trong đó có: 20 phân hệ chạy trên bản phát hành v1.0, 100% trong 183 chức năng hệ cũ có kết luận và bằng chứng trong RTM, hệ cũ tại tỉnh thí điểm đã tắt, tỉnh thứ hai đang vận hành, hồ sơ cấp độ 3 đã được phê duyệt và bên nhận tự build lại được sản phẩm từ mã nguồn bàn giao. Sản phẩm bàn giao gồm bảy nhóm: phần mềm, mã nguồn, hợp đồng máy đọc, bộ tài liệu D00 đến D06, hồ sơ an toàn thông tin, bằng chứng kiểm thử và hồ sơ quản lý dự án. Sau G5 là 12 tháng bảo hành; bảo hành chỉ kết thúc khi không còn lỗi mức nghiêm trọng hoặc cao đang mở, độ sẵn sàng data plane đạt ≥ 99,9% trong ít nhất 10 trên 12 tháng và các chỉ số "12 tháng" của D02-01 đã được đo.

### 13.1. Định nghĩa hoàn thành cấp dự án

Định nghĩa hoàn thành (Definition of Done) cấp dự án là tầng cao nhất trong ba tầng đã nêu ở chương 3 (story, sprint, wave). Nó trả lời câu hỏi mà hội đồng nghiệm thu hoàn thành phải trả lời: dự án đã giao đủ giá trị đã cam kết khi phê duyệt chưa, và chủ đầu tư có thể tự vận hành, tự phát triển tiếp sản phẩm mà không phụ thuộc vào nhà thầu không. Vì vậy định nghĩa này không chỉ đếm chức năng mà còn kiểm tra khả năng tự chủ của bên nhận. Dự án hoàn thành khi mười điều kiện sau cùng đúng; mỗi điều kiện có bằng chứng tương ứng trong hồ sơ G5.

1. **Đủ phạm vi.** Cả 20 phân hệ đã qua cổng của wave chứa nó (G1, G2, G4 hoặc G5) và chạy trên cùng bản phát hành v1.0; mọi việc tồn của các cổng "đạt có điều kiện" trước đó đã đóng.
2. **Thay thế hệ cũ.** RTM (D00-03) cho thấy 100% trong 183 mục `LGC` có kết luận; mọi mục Giữ nguyên, Nâng cấp, Thay thế có `FR` tương ứng và test case đạt; ba mục Loại bỏ có văn bản chấp thuận của chủ đầu tư, đúng tiêu chí 1 tại D02-01 §11.
3. **Hệ cũ đã tắt.** Hệ LGSP cũ tại tỉnh thí điểm đã ngừng phục vụ, dữ liệu và nhật ký đã được lưu trữ theo thời hạn quy định và đọc lại được, mọi thông tin xác thực của hệ cũ đã thu hồi (M-20).
4. **Vận hành chính thức.** MVP và đợt 2 đang vận hành tại tỉnh thí điểm; độ sẵn sàng data plane đạt ≥ 99,9% trong mỗi tháng kể từ G3 (KPI-03), không có sự cố mức 1 kéo dài quá mục tiêu MTTR 1 giờ (KPI-16).
5. **Nhân rộng.** Tỉnh thứ hai đang vận hành trên bản v1.0 không có mã riêng cho tỉnh; tenant được khởi tạo đạt KPI-12 (M-21), tương ứng tiêu chí 5 tại D02-01 §11.
6. **An toàn thông tin.** Quyết định phê duyệt cấp độ 3 còn hiệu lực; lần kiểm thử bảo mật trước G5 không còn phát hiện mức nghiêm trọng hoặc cao đang mở; SBOM và chữ ký hợp lệ cho 100% image của v1.0.
7. **Chất lượng.** Bộ tiêu chí kiểm thử chung TCC-1 đến TCC-10 (chương 4) đạt trên hồi quy toàn bộ v1.0; kiểm thử hiệu năng hồi quy không suy giảm quá 10% so với kết quả G2.
8. **Tài liệu.** Toàn bộ tài liệu D00 đến D06 ở bản 1.0 (đã duyệt), khớp với v1.0 đang chạy; HDSD và HDVH đã được người dùng và đội vận hành dùng thử.
9. **Tự chủ của bên nhận.** Đội vận hành tỉnh tự thực hiện được nâng cấp phiên bản, diễn tập DR và xử lý sự cố mẫu không cần nhà thầu; bên nhận tự build, ký và triển khai lại v1.0 từ mã nguồn bàn giao trên một môi trường sạch.
10. **Hồ sơ.** Hồ sơ nghiệm thu hoàn thành và hồ sơ phục vụ quyết toán được chủ đầu tư tiếp nhận; danh sách bàn giao ở mục 13.2 đã được hai bên ký xác nhận từng dòng.

Điều kiện 9 là điều kiện khó đạt nhất và cũng quan trọng nhất về dài hạn. Một sản phẩm nguồn mở chỉ thật sự thuộc về chủ đầu tư khi chủ đầu tư, hoặc một đơn vị do chủ đầu tư chọn, có thể build lại nó; nếu chỉ nhà thầu ban đầu làm được việc này thì mô hình "một bản mã nguồn cho nhiều tỉnh" trở thành phụ thuộc nhà cung cấp dưới một hình thức khác. Vì vậy kiểm tra build lại được thực hiện trực tiếp trong buổi nghiệm thu G5 hoặc trong tuần trước đó, có tư vấn giám sát chứng kiến, chứ không chỉ dựa trên tài liệu hướng dẫn.

### 13.2. Danh mục sản phẩm bàn giao

Bảng dưới đây liệt kê bảy nhóm sản phẩm bàn giao tại G5, hình thức bàn giao và tiêu chí chấp nhận. Một phần các sản phẩm đã được bàn giao từng phần ở các cổng trước; tại G5 chúng được bàn giao lại ở phiên bản cuối cùng, khớp với v1.0.

| Nhóm | Sản phẩm | Hình thức | Tiêu chí chấp nhận |
|---|---|---|---|
| Phần mềm | Bản phát hành v1.0 của 20 phân hệ: image container đã ký, Helm chart và cấu hình Kustomize, gói cài đặt cho hồ sơ on-prem và hồ sơ nền tảng dùng chung; ghi chú phát hành | Kho image và kho cấu hình do chủ đầu tư quản lý | Cài mới thành công trên môi trường sạch theo D06-02; SBOM và chữ ký hợp lệ cho mọi image |
| Mã nguồn | Toàn bộ kho mã (monorepo) gồm lịch sử commit, nhánh phát hành, thẻ phiên bản; script build, pipeline CI; quy tắc kiểm tra (ArchUnit, OPA, lint) | Bản sao kho Git chuyển sang hệ thống do chủ đầu tư quản lý | Build lại cho ra image có cùng hành vi và qua cùng bộ kiểm thử; không có bí mật trong lịch sử (quét gitleaks toàn lịch sử); danh mục giấy phép nguồn mở tương thích |
| Hợp đồng máy đọc | Tệp OpenAPI 3.1, AsyncAPI 3.0, JSON Schema của mô hình dữ liệu chung, chính sách OPA, bộ kiểm thử hợp đồng | Thư mục `contracts/` trong kho mã, có thẻ phiên bản | Khớp 100% với hành vi của v1.0 (kiểm thử hợp đồng xanh); hợp đồng công bố cho HTTT có mặt trên cổng nhà phát triển PH-15 |
| Tài liệu SDLC | D00-01 đến D00-03; D01-01, D01-02; D02-01 đến D02-08; D03-01 đến D03-10; D04-01, D04-02; D05-01 đến D05-05; D06-01 đến D06-05 | Markdown trong kho tài liệu và bản .docx sinh tự động theo mẫu hồ sơ | Bản 1.0, có bảng ghi nhận thay đổi; không còn câu hỏi mở chặn vận hành |
| Hồ sơ ATTT | D03-07, D03-08 và quyết định phê duyệt cấp độ 3; báo cáo kiểm thử xâm nhập và đánh giá ASVS các lần trước G2, G4, G5; danh mục biện pháp `SEC` và bằng chứng kiểm chứng; hồ sơ đánh giá tác động xử lý dữ liệu cá nhân | Bộ hồ sơ có chữ ký, kèm bản điện tử | Đầy đủ theo yêu cầu của hồ sơ cấp độ; mọi phát hiện đã đóng hoặc có ngoại lệ được duyệt |
| Bằng chứng kiểm thử | Test case D05-02 của 20 phân hệ và kết quả chạy trên v1.0; báo cáo hiệu năng D05-03; biên bản UAT các đợt; báo cáo đối soát di trú và cắt chuyển; biên bản diễn tập DR và sự cố; RTM xuất .xlsx | Bản điện tử, kết quả CI lưu trữ | RTM 100% như điều kiện 2 ở mục 13.1; mọi kết quả truy được về lần chạy CI cụ thể |
| Hồ sơ quản lý dự án | Biên bản 39 sprint review; biên bản các cổng G0 đến G5; sổ rủi ro, sổ thay đổi, báo cáo tháng; nhật ký sử dụng AI agent; biên bản đào tạo và chuyển giao | Bản điện tử có chữ ký | Đủ theo danh mục hồ sơ cổng ở chương 4 |

Quyền sở hữu là một phần không tách rời của bàn giao. Mã nguồn tùy biến do dự án phát triển, tài liệu và dữ liệu hình thành trong dự án thuộc về chủ đầu tư; các thành phần nguồn mở giữ giấy phép gốc của chúng. Hợp đồng thực hiện phải ghi rõ chủ đầu tư có quyền dùng, sửa và cấp phép lại sản phẩm cho các tỉnh khác, vì đó là điều kiện để mô hình nhân rộng sang tỉnh thứ ba trở đi có thể diễn ra mà không phải mua lại quyền từ nhà thầu. Điểm này được ghi thành câu hỏi mở vì cần đối chiếu với quy định hiện hành về quyền tài sản đối với phần mềm hình thành từ ngân sách.

### 13.3. Bảo hành và điều kiện kết thúc bảo hành

Bảo hành kéo dài 12 tháng kể từ G5 (T0+18 đến T0+30), với đội ngũ khoảng 5 FTE theo giả định nền (gói 1.29, 60 người-tháng). Trong thời gian này nhà thầu sửa mọi lỗi của phần mềm đã bàn giao, phát hành bản vá bảo mật cho các thành phần nằm trong v1.0, hỗ trợ đội vận hành xử lý sự cố và nâng cấp bản vá của thành phần nguồn mở trong cùng phiên bản chính. Bảo hành không bao gồm tính năng mới, triển khai cho tỉnh mới và vận hành thường xuyên thay đơn vị vận hành.

Cam kết thời gian xử lý trong bảo hành được đặt theo mức sự cố, khớp với các chỉ số vận hành của D02-01. Bảng sau là mức đề xuất để đưa vào hợp đồng; thời gian tính từ khi đơn vị vận hành báo qua kênh hỗ trợ.

| Mức | Ví dụ | Phản hồi | Khôi phục dịch vụ | Sửa dứt điểm |
|---|---|---|---|---|
| 1 Nghiêm trọng | Data plane ngừng, rò rỉ dữ liệu chéo tenant, sai lệch tiền thanh toán | ≤ 15 phút, 24/7 | ≤ 1 giờ (KPI-16) | ≤ 3 ngày làm việc |
| 2 Cao | Một phân hệ control plane ngừng, một nhóm luồng tích hợp lỗi | ≤ 1 giờ trong giờ hành chính mở rộng | ≤ 4 giờ | ≤ 5 ngày làm việc |
| 3 Trung bình | Chức năng lỗi có cách làm thay thế | ≤ 1 ngày làm việc | Không áp dụng | Trong bản vá kế tiếp, tối đa 30 ngày |
| 4 Thấp | Lỗi hiển thị, tài liệu | ≤ 2 ngày làm việc | Không áp dụng | Trong bản vá kế tiếp |

Bảo hành chỉ được kết thúc và bảo lãnh bảo hành chỉ được giải tỏa khi đạt đồng thời năm điều kiện sau. Thứ nhất, không còn lỗi mức 1 hoặc mức 2 đang mở, và lỗi mức 3 còn mở không quá 5 lỗi, mỗi lỗi có phương án được chủ đầu tư chấp nhận. Thứ hai, độ sẵn sàng data plane đạt ≥ 99,9% trong ít nhất 10 trên 12 tháng bảo hành, và không tháng nào dưới 99,5%; nếu không đạt, thời gian bảo hành được kéo dài thêm số tháng không đạt. Thứ ba, các chỉ số có thời điểm đo "12 tháng" của D02-01 (KPI-01, KPI-02, KPI-10) đã được đo và báo cáo tại M-23, dù đạt hay không đạt, để chủ đầu tư có số liệu đánh giá hiệu quả đầu tư. Thứ tư, nhà thầu đã bàn giao bản vá cuối cùng kèm mã nguồn, tài liệu cập nhật và SBOM, và đội vận hành đã tự áp dụng bản vá đó. Thứ năm, ít nhất một lần diễn tập DR trong thời gian bảo hành do đội vận hành tự thực hiện đạt RPO 15 phút, RTO 1 giờ data plane và 4 giờ control plane (NFR-00-014).

Khi bảo hành kết thúc, việc hỗ trợ kỹ thuật chuyển sang hợp đồng vận hành, hỗ trợ hằng năm theo chi thường xuyên, với nhân sự tham chiếu 2 đến 3 FTE từ T0+30 như giả định nền. Nghị định 224/2026/NĐ-CP cho phép chỉ định chính doanh nghiệp đã phát triển phần mềm làm quản trị, vận hành (theo tóm tắt pháp lý, chưa đối chiếu Công báo); kế hoạch không giả định chủ đầu tư sẽ dùng cơ chế này, nhưng điều kiện 9 ở mục 13.1 bảo đảm chủ đầu tư có lựa chọn khác.

### 13.4. Câu hỏi mở

- **Q-D0102-15:** Quy định hiện hành về quyền tài sản đối với phần mềm hình thành từ ngân sách nhà nước có cho phép chủ đầu tư cấp phép lại mã nguồn Datahub cho tỉnh khác (hoặc công bố như phần mềm dùng chung) không, và hợp đồng thực hiện cần điều khoản nào để bảo đảm điều đó?
- **Q-D0102-16:** Thời hạn bảo hành 12 tháng và tỷ lệ bảo lãnh bảo hành có phù hợp với quy định áp dụng cho gói thầu EP có hạng mục phần mềm nội bộ theo Nghị định 224/2026/NĐ-CP và Luật Đấu thầu không?

### 13.5. Ghi chú cho người tổng hợp

- Cơ chế kéo dài bảo hành khi độ sẵn sàng không đạt (mục 13.3) là đề xuất; chương ngân sách và dự thảo hợp đồng cần xác nhận có đưa vào hay không.
- Tiêu chí kết thúc bảo hành dùng RTO 1 giờ data plane theo giả định nền đã cập nhật và NFR-00-014.
