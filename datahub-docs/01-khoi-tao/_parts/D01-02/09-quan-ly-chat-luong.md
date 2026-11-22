## 9. Quản lý chất lượng

**Tóm tắt cho hội đồng thẩm định.** Chất lượng của Datahub được bảo đảm bằng ba lớp kiểm soát nối tiếp nhau. Lớp thứ nhất là máy: năm cổng CI (A, B, C, D, S) chạy trên mọi thay đổi mã và chặn merge khi không đạt, áp dụng như nhau cho mã do người hay do AI agent viết. Lớp thứ hai là người: mọi thay đổi được ít nhất một kỹ sư khác review, thay đổi về hợp đồng API, bảo mật và cấu trúc dữ liệu cần hai người duyệt. Lớp thứ ba là độc lập: tư vấn giám sát và đơn vị kiểm thử, đánh giá an toàn thông tin độc lập kiểm tra tại sprint review và tại sáu cổng nghiệm thu. Kế hoạch theo dõi tám chỉ số chất lượng mỗi sprint với ngưỡng định lượng, trong đó độ phủ kiểm thử đơn vị ≥ 80% mã nghiệp vụ backend, tỷ lệ lỗi lọt qua sprint ≤ 10% và thời gian sửa lỗi nghiêm trọng ≤ 2 ngày làm việc. Ba sprint liên tiếp vượt ngưỡng ở cùng một chỉ số buộc nhóm dừng nhận việc mới để khắc phục.

### 9.1. Mục tiêu và cách tiếp cận

Quản lý chất lượng trong dự án này có một mục tiêu cụ thể: đến mỗi cổng nghiệm thu, sản phẩm đạt tiêu chí ra ở chương 4 ngay lần đầu, không phải qua sprint khắc phục. Để đạt mục tiêu đó, chất lượng phải được xây vào từng thay đổi nhỏ chứ không thể kiểm ra ở cuối wave; một lỗi phát hiện ở cổng CI tốn vài phút để sửa, cùng lỗi đó phát hiện ở kiểm thử hệ thống tốn vài ngày, và phát hiện sau cắt chuyển tại tỉnh thí điểm có thể làm gián đoạn dịch vụ công.

Cách tiếp cận vì thế được tổ chức theo nguyên tắc "dịch trái" (shift-left): kiểm soát càng sớm càng tốt, càng tự động càng tốt, và chỉ dành công sức của người cho những gì máy không kiểm được (tính đúng đắn của nghiệp vụ, thiết kế, trải nghiệm người dùng). Nguyên tắc thứ hai là đo được: mọi yêu cầu chất lượng đều có ngưỡng số, có công cụ đo và có người chịu trách nhiệm theo dõi. Nguyên tắc thứ ba là tách người làm và người kiểm: người viết mã không tự duyệt mã của mình, nhóm phát triển không tự nghiệm thu sản phẩm của mình, và ở cổng có bên thứ ba độc lập.

Kế hoạch chất lượng ở chương này là phần quản lý; chiến lược kiểm thử chi tiết nằm ở Master Test Plan (D05-01), quy ước mã nguồn ở D04-01 và quy trình kỹ thuật (Git, CI/CD, review, phát hành) ở D04-02. Chương này chỉ đặt khung, ngưỡng và trách nhiệm để các tài liệu đó cụ thể hóa.

### 9.2. Tiêu chuẩn chất lượng áp dụng

Bảng dưới đây liệt kê các tiêu chuẩn mà sản phẩm và quy trình phải tuân theo, cùng nơi chúng được cụ thể hóa thành yêu cầu đo được. Bảng giúp tư vấn giám sát biết phải đối chiếu tiêu chuẩn nào với tài liệu nào.

| Tiêu chuẩn | Phạm vi áp dụng | Cụ thể hóa tại |
|---|---|---|
| ISO/IEC 25010 (mô hình chất lượng sản phẩm phần mềm) | Khung phân loại yêu cầu phi chức năng: hiệu năng, độ tin cậy, bảo mật, khả năng bảo trì, khả năng sử dụng | D02-02, nhóm NFR-00 |
| ISO/IEC/IEEE 29148 (STD-01) | Cấu trúc và chất lượng đặc tả yêu cầu | D02-02, D02-03 |
| ISO/IEC/IEEE 29119-3 (STD-02) | Cấu trúc tài liệu kiểm thử | D05-01 đến D05-05 |
| OWASP ASVS 5.0 mức 2 (STD-03) | Yêu cầu kiểm chứng an toàn cho ứng dụng web và API | D02-02 NFR-00-024, D05-04 |
| WCAG 2.2 mức AA (STD-04) | Khả năng truy cập giao diện | D02-02 NFR-00-040 đến NFR-00-043 |
| OpenAPI 3.1, AsyncAPI 3.0, RFC 9457 (STD-05) | Hợp đồng API, sự kiện và định dạng lỗi | D03-04, `contracts/` |
| TCVN 11930:2017 (CMP-LAW-08) và quy định về bảo đảm an toàn hệ thống thông tin theo cấp độ | Yêu cầu ATTT cấp độ 3 | D03-07, D03-08 |
| Thông tư 41/2026/TT-BKHCN | Yêu cầu kiểm thử phần mềm nội bộ, nhật ký triển khai, giám sát | D05-01, hồ sơ cổng |

Ngoài tiêu chuẩn bên ngoài, dự án có bộ quy tắc nội bộ được máy kiểm tra: quy tắc sở hữu lane, quy tắc ranh giới module (chỉ dùng `api/` và `events/` của module khác), quy tắc mặc định từ chối truy cập cho mọi endpoint mới, quy tắc không có bí mật trong mã, quy tắc dùng design token cho giao diện. Các quy tắc này được ghi trong `AGENTS.md` và D04-01; điều quan trọng về mặt quản lý là mỗi quy tắc kiểm được bằng máy đều phải có một kiểm tra tự động trong CI, để việc tuân thủ không phụ thuộc vào trí nhớ của người review.

### 9.3. Cổng CI

Cổng CI (quality gate) là bộ kiểm tra tự động chạy trên mọi yêu cầu merge (pull request). Repo đã định nghĩa năm cổng, và kế hoạch dùng nguyên năm cổng này làm lớp kiểm soát chất lượng đầu tiên. Bảng sau mô tả nội dung, phạm vi kích hoạt và tác dụng chặn của từng cổng.

| Cổng | Nội dung kiểm tra | Kích hoạt khi | Tác dụng |
|---|---|---|---|
| **A** | Biên dịch; kiểm thử đơn vị; kiểm tra ranh giới module bằng `ApplicationModules.verify()` và ArchUnit; kiểm thử route Camel; đo độ phủ so với ngưỡng | Mọi PR có mã Java hoặc route | Chặn merge |
| **B** | Kiểm tra cú pháp hợp đồng OpenAPI, AsyncAPI; phát hiện thay đổi phá vỡ tương thích so với phiên bản đã gắn thẻ | PR chạm `contracts/` | Chặn merge với thay đổi phá vỡ chưa tăng phiên bản chính |
| **C** | Kiểm tra cú pháp và kiểu TypeScript; kiểm thử đơn vị thành phần giao diện; lint design token | PR chạm `apps/console/`, `packages/` | Chặn merge |
| **D** | Kiểm tra khả năng truy cập tự động bằng axe-core cho màn hình mới hoặc đã đổi | PR có màn hình mới hoặc sửa màn hình | Cảnh báo trên DEV và TEST; chặn từ khi đưa lên STAGING |
| **S** | Quét bí mật (gitleaks); phân tích tĩnh bảo mật (Semgrep); quét lỗ hổng image và phụ thuộc (Trivy); sinh SBOM | Mọi PR và mọi bản build image | Chặn merge khi có bí mật hoặc lỗ hổng CRITICAL; HIGH cần ngoại lệ được duyệt |

Ba quy tắc quản lý đi kèm năm cổng. Thứ nhất, không ai, kể cả trưởng nhóm, được tắt hoặc bỏ qua một cổng để merge gấp; nếu một cổng cho kết quả sai (ví dụ cảnh báo giả của Semgrep), cách xử lý là sửa cấu hình cổng qua một PR riêng có review của kỹ sư ATTT. Thứ hai, ngoại lệ lỗ hổng mức HIGH chỉ được cấp bởi kỹ sư ATTT, có thời hạn tối đa 30 ngày và được liệt kê trong báo cáo cổng nghiệm thu. Thứ ba, thời gian chạy của cổng A, B, C, S trên một PR thông thường được giữ dưới 15 phút; nếu vượt, nhóm nền tảng phải tối ưu trong sprint kế tiếp, vì cổng quá chậm sẽ khiến người ta tìm cách đi vòng.

Ngoài các cổng chạy theo PR, bộ kiểm thử dài hơn chạy theo lịch: bộ hồi quy E2E và kiểm thử chấp nhận tự động chạy mỗi đêm trên TEST; kiểm thử hiệu năng rút gọn chạy mỗi tuần trên STAGING từ W2; quét lỗ hổng toàn bộ image đang chạy trên mọi môi trường chạy mỗi ngày.

### 9.4. Review

Review mã nguồn (code review) là lớp kiểm soát do người thực hiện, tập trung vào những gì máy không kiểm được: mã có làm đúng nghiệp vụ trong tiêu chí chấp nhận không, thiết kế có hợp lý không, có rủi ro bảo mật về logic (ví dụ kiểm tra quyền sai đối tượng) không, kiểm thử có kiểm hành vi thật hay chỉ để tăng độ phủ.

Số người duyệt phụ thuộc mức rủi ro của thay đổi. Thay đổi thông thường cần một người duyệt là kỹ sư khác trong cùng lane. Bốn loại thay đổi cần hai người duyệt (nguyên tắc bốn mắt): thay đổi hợp đồng trong `contracts/` (người thứ hai là đại diện lane tiêu thụ); thay đổi liên quan xác thực, phân quyền, mã hóa, quản lý bí mật (người thứ hai là kỹ sư ATTT); script migration làm thay đổi cấu trúc dữ liệu đã có trên STAGING hoặc PROD (người thứ hai là kiến trúc sư hoặc kỹ sư dữ liệu); thay đổi cấu hình triển khai PROD (người thứ hai là kỹ sư nền tảng). Với PR do AI agent tạo, kỹ sư chịu trách nhiệm theo chương 3 không được tính là người duyệt thứ hai; tức là PR do agent tạo luôn có ít nhất một người đọc độc lập ngoài người giao việc cho agent.

Thời hạn review được đặt để review không trở thành nút thắt: PR nhỏ (dưới 400 dòng thay đổi) được review trong 1 ngày làm việc; PR lớn hơn bị yêu cầu tách, trừ mã sinh tự động. Ngoài review mã, ba loại review tài liệu được tổ chức theo lịch: review FRS và SDD của phân hệ bởi kiến trúc sư và PO chủ đầu tư trước sprint hiện thực; review kiến trúc mỗi quý theo tiêu chí tách đơn vị triển khai của repo; review bảo mật thiết kế (threat modeling) khi một phân hệ có luồng dữ liệu cá nhân hoặc kết nối ra ngoài tỉnh.

### 9.5. Kiểm thử theo tầng

Kiểm thử được tổ chức theo tầng, mỗi tầng có mục đích, môi trường và người chịu trách nhiệm riêng. Tầng dưới nhiều, nhanh, rẻ; tầng trên ít, chậm, đắt, nên chỉ kiểm những gì tầng dưới không kiểm được. Chi tiết chiến lược, môi trường, dữ liệu thử và tiêu chí của từng tầng nằm ở các tài liệu nhóm D05; bảng sau chỉ xác định tầng, tài liệu chi phối và thời điểm.

| Tầng | Mục đích | Tài liệu chi phối | Môi trường | Thời điểm |
|---|---|---|---|---|
| Kiểm thử đơn vị và lát cắt (unit, slice) | Hành vi của một lớp, một module, một route | D04-01, D05-01 | Máy kỹ sư, CI | Mọi PR (cổng A, C) |
| Kiểm thử hợp đồng (contract) | Bên cung cấp và bên tiêu thụ API, sự kiện khớp với hợp đồng đã gắn thẻ | D03-04, D05-01 | CI | Mọi PR chạm hợp đồng hoặc mã tiêu thụ |
| Kiểm thử tích hợp và E2E | Luồng nghiệp vụ xuyên nhiều phân hệ và thành phần nguồn mở | D05-01, D05-02 | TEST | Mỗi đêm; đầy đủ ở tuần ổn định cuối wave |
| Kiểm thử chức năng theo test case | Mỗi `FR` có `TC` dương tính và âm tính theo quy tắc truy vết D00-01 §3.2 | D05-02 (20 tập) | TEST | Trong sprint hiện thực `FR`; hồi quy cuối wave |
| Kiểm thử hiệu năng | Thông lượng, độ trễ, độ bền, khả năng mở rộng theo cỡ M | D05-03 | STAGING | Rút gọn hằng tuần từ W2; đầy đủ trước G2, G4, G5 |
| Kiểm thử bảo mật | ASVS mức 2, kiểm thử xâm nhập, cách ly tenant | D05-04 | STAGING | Liên tục qua cổng S; đầy đủ trước G2, G4, G5 |
| Kiểm thử khả năng truy cập | WCAG 2.2 mức AA, tự động và thủ công với trình đọc màn hình | D05-01, D03-06 | TEST, STAGING | Cổng D; thủ công trước mỗi UAT |
| Kiểm thử chấp nhận người dùng (UAT) | Người dùng đại diện xác nhận sản phẩm đáp ứng nghiệp vụ | D05-05 | STAGING | Trước G2, G4, G5 |
| Kiểm thử chuyển đổi và đối soát | Kết quả của Datahub trùng với hệ cũ khi chạy song song | D06-01 | STAGING, PROD | Mỗi nhóm cắt chuyển ở W3, W4 |
| Kiểm thử phục hồi | Sao lưu, phục hồi, chuyển sang DR, hỗn loạn có kiểm soát | D03-09, D05-01 | STAGING, PROD, DR | Trước G3; lặp lại trước G5 |

Hai tầng có đặc thù riêng của sản phẩm multi-tenant cần nhấn mạnh. Kiểm thử bảo mật phải gồm kịch bản cách ly tenant: người dùng và HTTT của tenant A không đọc, ghi hay thấy được dữ liệu, sự kiện, nhật ký của tenant B qua bất kỳ API, màn hình hay topic nào; kịch bản này chạy tự động mỗi đêm từ khi PH-20 có mã, vì rò rỉ chéo tenant (RSK-36) là rủi ro có tác động lớn nhất với mô hình sản phẩm. Kiểm thử hiệu năng phải đo cả tình huống "hàng xóm ồn ào", trong đó một tenant tạo tải đỉnh mà các tenant khác không bị suy giảm vượt ngưỡng.

### 9.6. Chỉ số chất lượng theo sprint

Tám chỉ số dưới đây được đo tự động hoặc bán tự động mỗi sprint, ghi vào báo cáo sprint và trình bày tại sprint review. Mục đích của chúng là phát hiện xu hướng xấu sớm, trước khi xu hướng đó trở thành lỗi không đạt ở cổng. Bảng ghi định nghĩa, ngưỡng và nguồn dữ liệu.

| Mã | Chỉ số | Định nghĩa | Ngưỡng | Nguồn đo |
|---|---|---|---|---|
| QM-01 | Độ phủ kiểm thử đơn vị | Tỷ lệ dòng mã được kiểm thử đơn vị thực thi, đo trên nhánh chính cuối sprint | ≥ 80% mã nghiệp vụ backend; ≥ 70% mã giao diện (NFR-00-053); mã mới trong sprint không làm giảm độ phủ | Báo cáo độ phủ của cổng A, C |
| QM-02 | Mật độ lỗi | Số lỗi được xác nhận phát hiện trong sprint trên 10 điểm story hoàn thành | ≤ 1,5 lỗi trên 10 điểm; không quá 0,3 lỗi mức nghiêm trọng hoặc cao trên 10 điểm | Hệ thống quản lý công việc |
| QM-03 | Tỷ lệ lỗi lọt qua sprint | Số lỗi của story đã "hoàn thành" bị phát hiện sau sprint đó (ở hồi quy, UAT, STAGING) chia cho tổng lỗi của các story đó | ≤ 10% | Hệ thống quản lý công việc, nhãn sprint gốc |
| QM-04 | Tỷ lệ lỗi lọt ra PROD | Số lỗi phát hiện trên PROD chia cho tổng lỗi của cùng bản phát hành | ≤ 2%; 0 lỗi mức nghiêm trọng | Hệ thống quản lý sự cố, từ W3 |
| QM-05 | Thời gian sửa lỗi | Thời gian từ khi lỗi được xác nhận đến khi bản sửa được merge, theo mức | Nghiêm trọng ≤ 2 ngày làm việc; cao ≤ 5 ngày làm việc; trung bình ≤ 1 sprint | Hệ thống quản lý công việc |
| QM-06 | Tỷ lệ kiểm thử chập chờn | Tỷ lệ kiểm thử tự động cho kết quả khác nhau khi chạy lại trên cùng mã | ≤ 2%; kiểm thử chập chờn bị cách ly và sửa trong 1 sprint | Lịch sử chạy CI |
| QM-07 | Tỷ lệ PR bị trả lại | Tỷ lệ PR phải sửa lại sau review lần đầu, tách theo PR do người và do AI agent tạo | Theo dõi xu hướng; báo động khi tỷ lệ của PR do agent cao hơn PR do người quá 1,5 lần trong 2 sprint | Hệ thống quản lý mã nguồn |
| QM-08 | Độ phủ truy vết | Tỷ lệ `FR` mức M đã hoàn thành có đủ `TC` dương tính và âm tính đã chạy đạt trong RTM | 100% cho `FR` đã đánh dấu hoàn thành | D00-03, báo cáo kiểm thử |

Ngưỡng được dùng như tín hiệu điều khiển chứ không phải để chấm điểm cá nhân. Khi một chỉ số vượt ngưỡng một sprint, retro của nhóm phải có hành động khắc phục. Khi cùng một chỉ số vượt ngưỡng ba sprint liên tiếp, nhóm đó dừng nhận story mới trong sprint kế tiếp và dành toàn bộ sức chứa để khắc phục nguyên nhân gốc, Giám đốc dự án báo cáo việc này trong báo cáo tháng. Quy tắc dừng này có chi phí ngắn hạn, nhưng nó ngăn nợ kỹ thuật dồn tới tuần ổn định cuối wave, nơi không còn thời gian để xử lý.

Chỉ số QM-07 có vai trò riêng trong việc kiểm soát AI agent. Nó cho biết agent có đang sinh mã đạt chất lượng tương đương người hay không, và là dấu hiệu sớm của RSK-28 trong sổ rủi ro. Nếu ngưỡng báo động bị vượt, trưởng lane phải rà soát lại chỉ dẫn và quy tắc cung cấp cho agent theo quy tắc số 7 ở chương 3, và có thể thu hẹp loại việc giao cho agent trong lane đó.

### 9.7. Kiểm toán chất lượng tại cổng

Trước mỗi cổng nghiệm thu, một cuộc kiểm toán chất lượng (quality audit) được tổ chức trong tuần ổn định cuối wave. Kiểm toán khác kiểm thử ở chỗ nó không tìm lỗi trong sản phẩm mà kiểm tra xem quy trình chất lượng có thật sự được tuân thủ và bằng chứng có đáng tin không. Người chủ trì là trưởng nhóm QA của nhà thầu, có tư vấn giám sát tham dự; với G2, G4 và G5, đơn vị kiểm thử, đánh giá ATTT độc lập tham dự phần bảo mật.

Nội dung kiểm toán gồm năm việc. Thứ nhất, lấy mẫu ngẫu nhiên tối thiểu 10% số PR đã merge trong wave (không ít hơn 30 PR) và kiểm tra mỗi PR có đủ mã truy vết, đủ số người duyệt theo mức rủi ro, cổng CI xanh tại thời điểm merge, không có ngoại lệ chưa được duyệt. Thứ hai, lấy mẫu 10% số `FR` mức M của wave và truy ngược từ `FR` qua story, PR, test case tới kết quả chạy, để xác nhận RTM phản ánh đúng thực tế. Thứ ba, đối chiếu chỉ số chất lượng sprint của cả wave với ngưỡng và kiểm tra các hành động khắc phục đã đóng. Thứ tư, kiểm tra danh sách ngoại lệ lỗ hổng HIGH còn hiệu lực. Thứ năm, xác nhận tài liệu SDLC của wave đã ở bản 1.0 và khớp với sản phẩm đang chạy.

Kết quả kiểm toán là một báo cáo nằm trong hồ sơ cổng, gồm danh sách phát hiện chia ba mức: không phù hợp nghiêm trọng (làm mất giá trị bằng chứng, ví dụ test case được đánh dấu đạt nhưng không có kết quả chạy), không phù hợp nhỏ và khuyến nghị. Một phát hiện không phù hợp nghiêm trọng chưa khắc phục là đủ để hội đồng kết luận cổng "không đạt" dù các tiêu chí kiểm thử đều xanh, vì khi đó chính các con số kiểm thử không còn đáng tin.

### 9.8. Giám sát độc lập

Dự án có hai bên kiểm soát độc lập với nhà thầu, với vai trò được phân định trong ma trận RACI ở chương 5. Tư vấn giám sát theo dõi khối lượng, chất lượng và tiến độ suốt 18 tháng: tham dự sprint review, có quyền truy cập chỉ đọc vào hệ thống quản lý công việc, kho mã, kết quả CI và môi trường TEST, STAGING; lập báo cáo giám sát tháng; tham dự kiểm toán chất lượng và mọi phiên nghiệm thu; xác nhận khối lượng hoàn thành làm cơ sở thanh toán. Đơn vị kiểm thử, đánh giá ATTT độc lập thực hiện kiểm thử xâm nhập và đánh giá theo ASVS trước G2, G4 và G5, cùng phần kiểm tra kỹ thuật phục vụ hồ sơ đề xuất cấp độ 3.

Để giám sát độc lập có thực chất, kế hoạch đặt ba điều kiện. Thứ nhất, bên giám sát lấy dữ liệu trực tiếp từ hệ thống (kho mã, CI, hệ thống quản lý công việc) chứ không chỉ từ báo cáo do nhà thầu soạn. Thứ hai, bên giám sát có quyền tự chọn mẫu khi kiểm toán, không chỉ xem mẫu do nhà thầu chọn. Thứ ba, các phát hiện của bên giám sát được ghi vào sổ theo dõi riêng, nhà thầu phải phản hồi trong 5 ngày làm việc, và phát hiện chưa đóng được nêu trong báo cáo cổng. Chi phí cho hai bên này nằm ở chương ngân sách dưới khoản chi phí tư vấn và chi phí khác, không nằm trong 459 người-tháng của nhà thầu.

### 9.9. Câu hỏi mở

- **Q-D0102-13:** Thông tư 41/2026/TT-BKHCN (Điều 10 về kiểm thử phần mềm nội bộ) có yêu cầu kiểm thử phải do đơn vị độc lập với nhà thầu phát triển thực hiện, hay nhà thầu tự kiểm thử dưới sự giám sát là đủ? Câu trả lời quyết định phạm vi gói kiểm thử độc lập và có thể làm giảm hoặc tăng nỗ lực QA của nhà thầu.
- **Q-D0102-14:** Tư vấn giám sát có được cấp quyền truy cập chỉ đọc vào kho mã và hệ thống CI của nhà thầu ngay từ W0 không, hay chỉ nhận báo cáo? Kế hoạch đang giả định có quyền truy cập trực tiếp.

### 9.10. Ghi chú cho người tổng hợp

- Mã chỉ số `QM-nn` là mã nội bộ của chương này, chưa có trong bảng mã D00-01 §3.1. Đề xuất bổ sung nếu D05-01 cũng dùng các chỉ số này; nếu không, có thể giữ là mã cục bộ của D01-02.
- Ngưỡng độ phủ lấy từ D02-02 NFR-00-053; ngưỡng lỗ hổng từ NFR-00-022, NFR-00-023. Nếu D05-01 đặt ngưỡng khác, cần thống nhất về một chỗ.
