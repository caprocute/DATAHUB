## 6. Kế hoạch nhân sự

**Tóm tắt cho hội đồng thẩm định.** Nhà thầu bố trí đội ngũ theo bảng FTE của bộ giả định nền: 15,5 FTE ở W0, tăng lên 26,5 và 28 FTE ở W1 và W2, rồi chia thành hai đội chạy song song ở W3 (18,5 FTE, thí điểm và vận hành) và W4 (19,5 FTE, phát triển đợt 2), giảm còn 17,5 FTE ở W5 và 5 FTE trong 12 tháng bảo hành. Tổng nỗ lực giai đoạn thực hiện khoảng 455 người-tháng. Đỉnh tải thực tế là khoảng 38 FTE trong ba tháng chồng lấn W3 và W4 (T0+10 đến T0+13), không phải 28 FTE như khi đọc riêng từng cột. Phía chủ đầu tư cần bố trí khoảng 3,5 FTE cho Ban quản lý dự án, và đơn vị vận hành tỉnh cần một đội 6 người tham gia tăng dần từ W1 để đến G3 tự đảm nhận vận hành tầng 1 và tầng 2. Chuyển giao tri thức đi qua bốn bậc (quan sát, cùng làm, làm chính có hỗ trợ, độc lập) và được đo bằng các bài diễn tập vận hành chứ không bằng số giờ đào tạo.

### 6.1. Nguyên tắc lập kế hoạch nhân sự

Kế hoạch nhân sự dựa trên bốn nguyên tắc. Thứ nhất, đội ngũ được tổ chức theo lane sở hữu mã nguồn (chương 5), nên mỗi kỹ sư thuộc về một đội Scrum và một lane cụ thể trong suốt một wave; việc điều chuyển kỹ sư giữa các đội chỉ diễn ra ở ranh giới wave để không phá vỡ velocity. Thứ hai, quy mô đội thay đổi theo nội dung của từng wave chứ không giữ cố định: W0 cần ít người nhưng nhiều kinh nghiệm nền tảng, W1 và W2 cần đông kỹ sư phát triển, W3 cần kỹ sư nền tảng và dữ liệu, W4 cần kỹ sư backend cho PH-19. Thứ ba, mọi con số FTE trong chương lấy từ bộ giả định nền và tổng nỗ lực khớp với con số dùng ở chương chi phí; phần chi tiết hóa (phân đội, phân lane) chỉ chia nhỏ các con số đó, không cộng thêm. Thứ tư, nhân sự phía chủ đầu tư và phía vận hành tỉnh được lập kế hoạch ngang hàng với nhân sự nhà thầu, vì kinh nghiệm của các dự án chính phủ điện tử cho thấy tiến độ thường bị chặn bởi việc thiếu người ra quyết định và thiếu người tiếp nhận, hơn là thiếu kỹ sư.

Khái niệm FTE (full-time equivalent, tương đương toàn thời gian) dùng trong chương nghĩa là một người làm toàn thời gian cho dự án trong một tháng. Giá trị 0,5 nghĩa là một người dành một nửa thời gian, hoặc vai trò được chia giữa hai wave chạy cùng lúc.

### 6.2. Cơ cấu đội ngũ theo vai trò và theo wave

#### 6.2.1. Bảng định biên

Bảng dưới đây là định biên tham chiếu của nhà thầu, giữ nguyên từ bộ giả định nền §5. Cột W3 là đội thí điểm và vận hành tại tỉnh 1, cột W4 là đội phát triển đợt 2; hai cột này chạy cùng lúc từ T0+10 đến T0+13, và PM cùng PO dùng chung giữa hai cột nên ô của W4 ghi "(chung)".

| Vai trò | W0 | W1 | W2 | W3 | W4 | W5 | Bảo hành |
|---|---|---|---|---|---|---|---|
| Giám đốc dự án (PM) | 1 | 1 | 1 | 1 | (chung) | 1 | 0,25 |
| Product Owner / BA trưởng | 1 | 1 | 1 | 1 | (chung) | 1 | 0,25 |
| BA nghiệp vụ | 2 | 2 | 2 | 1 | 2 | 1 | 0 |
| Kiến trúc sư giải pháp | 1 | 1 | 1 | 0,5 | 0,5 | 0,5 | 0,25 |
| Scrum Master | 1 | 2 | 2 | 1 | 1 | 1 | 0 |
| Kỹ sư backend (Spring) | 2 | 5 | 5 | 2 | 5 | 3 | 1 |
| Kỹ sư tích hợp (Camel) | 1 | 4 | 3 | 2 | 1 | 1 | 1 |
| Kỹ sư frontend | 1 | 3 | 3 | 1 | 3 | 2 | 0,5 |
| UX/UI designer | 1 | 1 | 1 | 0 | 1 | 0,5 | 0 |
| Kỹ sư nền tảng / SRE | 2 | 2 | 2 | 3 | 1 | 2 | 1 |
| Kỹ sư ATTT | 1 | 1 | 1 | 1 | 0,5 | 0,5 | 0,25 |
| Kỹ sư dữ liệu / di trú | 0 | 0 | 1 | 2 | 1 | 1 | 0 |
| QA / kiểm thử (gồm tự động hóa, hiệu năng) | 1 | 3 | 4 | 2 | 3 | 2 | 0,5 |
| Biên soạn tài liệu & đào tạo | 0,5 | 0,5 | 1 | 1 | 0,5 | 1 | 0 |
| **Tổng FTE (≈)** | **15,5** | **26,5** | **28** | **18,5** | **19,5** | **17,5** | **5** |
| Số tháng của wave | 2 | 4 | 4 | 3 | 5 | 3 | 12 |
| **Người-tháng** | **31** | **106** | **112** | **55,5** | **97,5** | **52,5** | **60** |

Cộng sáu wave, tổng nỗ lực giai đoạn thực hiện là 454,5 người-tháng, làm tròn 455 người-tháng như giả định nền; bảo hành thêm 60 người-tháng. Cơ cấu này cho thấy dự án nặng về kỹ sư phát triển (backend, tích hợp, frontend chiếm khoảng 45% nỗ lực) và kiểm thử (khoảng 13%), phù hợp với một sản phẩm phần mềm đóng gói hơn là một dự án tích hợp hệ thống thuần túy.

#### 6.2.2. Biểu đồ tải nhân sự theo tháng

Vì W3 và W4 chồng lấn, tải nhân sự theo tháng khác với tải theo wave. Bảng dưới đây cộng các wave đang chạy trong từng tháng của giai đoạn thực hiện; cột cuối là thanh biểu đồ, mỗi ký tự tương ứng 2 FTE. Bảng được dùng thay cho biểu đồ Mermaid vì cú pháp biểu đồ cột của Mermaid chưa ổn định.

| Tháng | Wave đang chạy | FTE | Biểu đồ |
|---|---|---|---|
| T0+1 đến T0+2 | W0 | 15,5 | ████████ |
| T0+3 đến T0+6 | W1 | 26,5 | █████████████ |
| T0+7 đến T0+10 | W2 | 28 | ██████████████ |
| T0+11 đến T0+13 | W3 và W4 | 38 | ███████████████████ |
| T0+14 đến T0+15 | W4 | 19,5 | ██████████ |
| T0+16 đến T0+18 | W5 | 17,5 | █████████ |
| T0+19 đến T0+30 | Bảo hành | 5 | ██▌ |

Bảng tải có hai hệ quả cho việc lập kế hoạch. Một là đỉnh tải 38 FTE kéo dài ba tháng, nên nhà thầu phải có sẵn khoảng 10 người bổ sung so với W2 ngay từ T0+10, và chủ đầu tư phải bố trí đủ chỗ làm việc, tài khoản và quyền truy cập môi trường cho số người này (đội W3 làm việc chủ yếu tại tỉnh, đội W4 có thể làm tại văn phòng nhà thầu). Hai là sau T0+13, W4 không còn tính PM và PO vì cột W3 đã kết thúc; trên thực tế PM và PO vẫn làm việc toàn thời gian ở T0+14 và T0+15 để điều hành đợt 2 và chuẩn bị W5. Khoản hụt khoảng 4 người-tháng này được nêu trong ghi chú cuối chương để chương chi phí xử lý.

### 6.3. Phân bổ vào các đội Scrum theo lane

Định biên ở mục 6.2 được chia thành các đội Scrum, mỗi đội từ 4 đến 8 người để giữ được nhịp họp ngắn và trách nhiệm rõ. Các vai trò dùng chung (PM, PO, kiến trúc sư, BA, Scrum Master, biên soạn tài liệu) không thuộc riêng đội nào và được kê ở dòng "dùng chung". Bảng sau trình bày cấu hình đội ở từng wave cùng lane và phân hệ mà đội sở hữu.

| Wave | Đội | Lane sở hữu | Phân hệ chính | Thành phần (FTE) |
|---|---|---|---|---|
| W0 | Đội Nền tảng (một đội duy nhất) | L-FOUND, L-PLAT, L-SEC, khung L-CTRL, L-CAMEL, L-FE | Khung monorepo, hợp đồng máy đọc, DEV/TEST, IAM khung | Backend 2, Camel 1, frontend 1, UX 1, SRE 2, ATTT 1, QA 1 (9) |
| W0 | Dùng chung | | | PM 1, PO 1, BA 2, kiến trúc sư 1, Scrum Master 1, tài liệu 0,5 (6,5) |
| W1 | Đội A Tích hợp | L-CAMEL, L-ADAPT | PH-03, PH-04, PH-05 | Camel 4, backend 1, QA 1 (6) |
| W1 | Đội B Điều khiển | L-CTRL, phần ứng dụng của L-SEC | PH-01, PH-02, PH-12 | Backend 4, QA 1 (5) |
| W1 | Đội C Giao diện | L-FE | Console cho PH-01, 02, 04 | Frontend 3, UX 1, QA 1 (5) |
| W1 | Nhóm Nền tảng và ATTT | L-PLAT, L-SEC, L-OBS | Hạ tầng, PH-13 cơ bản, cổng CI | SRE 2, ATTT 1 (3) |
| W1 | Dùng chung | | | PM 1, PO 1, BA 2, kiến trúc sư 1, Scrum Master 2, tài liệu 0,5 (7,5) |
| W2 | Đội A Tích hợp và quốc gia | L-CAMEL, L-ADAPT | PH-04, PH-05, PH-10, PH-14 | Camel 3, backend 1, QA 1 (5) |
| W2 | Đội B Điều khiển và Dữ liệu | L-CTRL, L-DATA, L-PROC | PH-07, PH-18, PH-20 | Backend 4, dữ liệu 1, QA 1 (6) |
| W2 | Đội C Giao diện | L-FE | Console cho PH-07, 10, 14, 18, 20 | Frontend 3, UX 1, QA 1 (5) |
| W2 | Nhóm Nền tảng và ATTT | L-PLAT, L-SEC, L-OBS, L-QA hiệu năng | PH-13 đầy đủ, STAGING, kiểm thử hiệu năng | SRE 2, ATTT 1, QA hiệu năng 1 (4) |
| W2 | Dùng chung | | | PM 1, PO 1, BA 2, kiến trúc sư 1, Scrum Master 2, tài liệu 1 (8) |
| W3 | Đội Thí điểm và Cắt chuyển | L-CAMEL, L-DATA (di trú), L-QA | Di trú, chạy song song, cắt chuyển theo nhóm dịch vụ | Camel 2, backend 2, frontend 1, dữ liệu 2, QA 2 (9) |
| W3 | Nhóm Nền tảng PROD | L-PLAT, L-SEC, L-OBS | Cài đặt PROD, DR, hồ sơ cấp độ 3 | SRE 3, ATTT 1 (4) |
| W3 | Dùng chung | | | PM 1, PO 1, BA 1, kiến trúc sư 0,5, Scrum Master 1, tài liệu 1 (5,5) |
| W4 | Đội D Thanh toán | L-CTRL hoặc L-DATA (module thanh toán), L-CAMEL | PH-19 | Backend 3, Camel 1, frontend 1, QA 1,5 (6,5) |
| W4 | Đội E Dữ liệu chủ và Quy trình | L-DATA, L-PROC | PH-06, PH-08, PH-09, PH-11 | Backend 2, dữ liệu 1, frontend 2, QA 1,5 (6,5) |
| W4 | Dùng chung riêng của W4 | | | UX 1, SRE 1, ATTT 0,5, BA 2, kiến trúc sư 0,5, Scrum Master 1, tài liệu 0,5 (6,5) |
| W5 | Đội F Đợt 3 | L-CTRL, L-FE, L-AI | PH-15, PH-16, PH-17 | Backend 2, frontend 2, UX 0,5, QA 1 (5,5) |
| W5 | Đội G Phát hành và Nhân rộng | L-PLAT, L-SEC, L-CAMEL, L-DATA | Phát hành v1.0, tenant tỉnh 2, tắt hệ cũ | Backend 1, Camel 1, SRE 2, ATTT 0,5, dữ liệu 1, QA 1 (6,5) |
| W5 | Dùng chung | | | PM 1, PO 1, BA 1, kiến trúc sư 0,5, Scrum Master 1, tài liệu 1 (5,5) |

Cách phân đội trên tuân theo ba quy tắc. Quy tắc thứ nhất là không đặt L-CAMEL và L-CTRL trong cùng một PR (theo IP-04), nên đội Tích hợp và đội Điều khiển luôn tách riêng ở W1, W2. Quy tắc thứ hai là ở W4, phân hệ thanh toán PH-19 có đội riêng vì đây là phân hệ có yêu cầu nghiệp vụ, đối soát và an toàn khác hẳn phần còn lại, và có phụ thuộc bên ngoài (PayGov) cần một đầu mối cố định; lane chứa mã PH-19 sẽ được kiến trúc sư chốt bằng ADR trong dải ADR-040 đến 049 trước khi W4 bắt đầu. Quy tắc thứ ba là kỹ sư kiểm thử được gắn vào từng đội thay vì gom thành một đội kiểm thử riêng, để kiểm thử diễn ra trong cùng sprint với phát triển; riêng kiểm thử hiệu năng ở W2 được gom vào nhóm Nền tảng vì cần môi trường STAGING và công cụ tạo tải chung. Mỗi đội có một trưởng nhóm kỹ thuật kiêm nhiệm theo mục 5.3.6.

### 6.4. Yêu cầu năng lực và chứng chỉ

Bảng dưới đây nêu yêu cầu tối thiểu cho từng vai trò của nhà thầu. Cột "Kinh nghiệm" là điều kiện bắt buộc dùng để đánh giá hồ sơ nhân sự chủ chốt; cột "Chứng chỉ ưu tiên" là điểm cộng, không phải điều kiện loại, trừ khi hồ sơ mời thầu quy định khác. Các con số ở bảng là đề xuất của kế hoạch này để đưa vào hồ sơ mời thầu.

| Vai trò | Kinh nghiệm tối thiểu | Năng lực bắt buộc | Chứng chỉ ưu tiên |
|---|---|---|---|
| Giám đốc dự án | 10 năm trong ngành, 5 năm quản lý dự án phần mềm; đã quản lý ít nhất 1 dự án CNTT dùng ngân sách nhà nước có quy mô tương đương | Quản lý dự án lai Scrum và cổng nghiệm thu; thủ tục nghiệm thu, thanh toán theo quy định quản lý đầu tư CNTT | PMP hoặc PRINCE2; PMI-ACP hoặc PSM |
| Product Owner / BA trưởng | 7 năm phân tích nghiệp vụ; đã làm ít nhất 1 dự án LGSP, NGSP/NDXP hoặc dịch vụ công trực tuyến | Viết user story có tiêu chí chấp nhận đo được; truy vết FR, LGC; hiểu CMP-LAW-03 và CMP-LAW-01 | PSPO hoặc CSPO; CBAP |
| BA nghiệp vụ | 3 năm phân tích nghiệp vụ khu vực công | Mô hình hóa quy trình BPMN; đặc tả API ở mức nghiệp vụ; nghiệp vụ thanh toán cho BA của W4 | IIBA ECBA hoặc CCBA |
| Kiến trúc sư giải pháp | 12 năm, trong đó 5 năm thiết kế hệ phân tán và tích hợp; đã thiết kế ít nhất 1 nền tảng tích hợp hoặc API cấp tổ chức lớn | Kiến trúc multi-tenant, hướng sự kiện, Kubernetes, bảo mật theo cấp độ; viết ADR | TOGAF; CKA |
| Scrum Master | 3 năm làm Scrum Master | Điều phối nhiều đội, đo velocity, gỡ trở ngại liên tổ chức | PSM I hoặc CSM |
| Kỹ sư backend | 4 năm Java, 2 năm Spring Boot; trưởng nhóm kỹ thuật 7 năm | Spring Boot, Spring Modulith, PostgreSQL, Kafka, kiểm thử tự động; dùng AI agent có kiểm soát | Oracle Certified Professional Java; Spring Professional |
| Kỹ sư tích hợp | 4 năm tích hợp hệ thống, trong đó 2 năm Apache Camel | Camel YAML DSL, Kamelet, Camel Quarkus và native image; SOAP, REST, FTP, JDBC; xử lý lỗi và DLQ | Red Hat Certified Developer (Camel/Fuse) hoặc tương đương |
| Kỹ sư frontend | 3 năm React, TypeScript | Ant Design, sinh mã từ OpenAPI, WCAG 2.2 AA, kiểm thử thành phần | Không bắt buộc |
| UX/UI designer | 4 năm thiết kế ứng dụng quản trị nghiệp vụ | Design system, token, kiểm thử khả dụng, khả năng truy cập | Chứng nhận UX (NN/g hoặc tương đương) |
| Kỹ sư nền tảng / SRE | 4 năm vận hành hệ thống sản xuất, 2 năm Kubernetes | Kubernetes, GitOps với Argo CD, CloudNativePG, Strimzi, Istio, Vault/OpenBao, quan sát LGTM, sao lưu và DR | CKA bắt buộc với ít nhất 1 người; CKS |
| Kỹ sư ATTT | 5 năm ATTT ứng dụng và hạ tầng; đã tham gia lập hồ sơ cấp độ 3 trở lên | Hồ sơ cấp độ theo CMP-LAW-06, CMP-LAW-07, TCVN 11930 (CMP-LAW-08); OWASP ASVS; quản lý lỗ hổng | CISSP hoặc CISM; OSCP hoặc CEH; ISO 27001 Lead Implementer |
| Kỹ sư dữ liệu / di trú | 4 năm, đã thực hiện ít nhất 1 dự án di trú dữ liệu từ hệ đang chạy | SQL nâng cao, ETL, đối soát, xử lý tiếng Việt và mã đơn vị hành chính có lịch sử sáp nhập | Không bắt buộc |
| QA / kiểm thử | 3 năm; QA trưởng 6 năm | Kiểm thử API, E2E, hiệu năng (k6 hoặc Gatling), kiểm thử hợp đồng | ISTQB Foundation; ISTQB Advanced cho QA trưởng |
| Biên soạn tài liệu và đào tạo | 3 năm viết tài liệu kỹ thuật tiếng Việt | Viết HDSD, HDVH, giáo trình; Markdown và quy trình xuất .docx | Không bắt buộc |

Ngoài yêu cầu riêng từng vai trò, mọi kỹ sư phải hoàn thành ba khóa nội bộ trong W0 hoặc trong hai tuần đầu khi vào dự án (mục 6.7): quy tắc dùng AI agent và review mã (mục 5.5), lập trình an toàn theo OWASP ASVS, và bảo vệ dữ liệu cá nhân theo CMP-LAW-04, CMP-LAW-05. Ít nhất 30% số kỹ sư phát triển nên có kinh nghiệm dự án cơ quan nhà nước, vì đây là nhóm hiểu nhanh nhất thủ tục kết nối, văn bản và cách làm việc với sở ngành.

### 6.5. Nhân sự phía chủ đầu tư và phía vận hành tỉnh

#### 6.5.1. Ban quản lý dự án và các sở ngành

Mô hình Scrum chỉ chạy được khi phía chủ đầu tư có người ra quyết định sẵn sàng trong vòng một đến hai ngày. Bảng dưới đây là định biên đề xuất cho phía chủ đầu tư; đây là thời gian công tác của cán bộ nhà nước, không phải chi phí thuê ngoài, nhưng cần được ghi trong quyết định thành lập Ban quản lý dự án để cán bộ được giảm nhiệm vụ khác tương ứng.

| Vị trí | Số người | Thời gian dành cho dự án | Giai đoạn | Nhiệm vụ chính |
|---|---|---|---|---|
| Giám đốc Ban quản lý dự án (lãnh đạo Sở kiêm nhiệm) | 1 | 20% | T0 − 2 đến G5 | Chủ trì họp tiến độ tháng, CCB, ký hồ sơ trình chủ đầu tư |
| Chủ sản phẩm phía chủ đầu tư | 1 | 100% ở W1 đến W4; 50% ở W0, W5 | T0 đến G5 | Quyết định ưu tiên backlog, sprint review, chủ trì UAT |
| Cán bộ kỹ thuật theo dõi | 1 | 100% | T0 đến G5 | Theo dõi kỹ thuật, cổng CI, kiểm tra tài liệu, kiểm tra quy tắc AI agent |
| Cán bộ kế hoạch, hợp đồng, tài chính | 1 | 30% | T0 − 2 đến quyết toán | Hồ sơ thanh toán, giải ngân, báo cáo giám sát đầu tư |
| Thư ký dự án | 1 | 20% | T0 đến G5 | Biên bản, sổ quyết định, lưu trữ văn bản |
| Đầu mối nghiệp vụ của mỗi sở ngành trong nhóm cắt chuyển | 1 mỗi sở | 10% ở W1, W2; 20% ở tháng cắt chuyển của sở | W1 đến G3 hoặc G4 | Xác nhận đặc tả, ánh xạ dữ liệu, UAT, xác nhận cắt chuyển |
| Đầu mối kỹ thuật của mỗi sở ngành | 1 mỗi sở | 10% đến 30% tùy tháng | W2 đến cắt chuyển | Điều chỉnh HTTT của sở, kiểm thử kết nối |

Cộng lại, Ban quản lý dự án cần khoảng 3,5 FTE ở các wave cao điểm. Vị trí quan trọng nhất là Chủ sản phẩm phía chủ đầu tư: nếu người này kiêm nhiệm quá nhiều việc khác, sprint review sẽ không có người chấp nhận, backlog không được sắp xếp và đội nhà thầu sẽ tự quyết thay, dẫn đến rủi ro sản phẩm lệch nhu cầu và tranh chấp ở cổng nghiệm thu.

#### 6.5.2. Đội vận hành tỉnh

Đơn vị vận hành cần một đội nòng cốt sáu người để tiếp nhận Datahub. Bảng sau nêu vị trí, số người và mức tham gia tăng dần theo wave; mức tham gia này chính là lộ trình chuyển giao ở mục 6.8.

| Vị trí | Số người | W0, W1 | W2 | W3 | W4, W5 | Sau G5 |
|---|---|---|---|---|---|---|
| Trưởng nhóm vận hành Datahub | 1 | 20% | 50% | 100% | 100% | 100% |
| Kỹ sư hạ tầng, Kubernetes | 2 | 20% | 50% | 100% | 100% | 100% |
| Kỹ sư vận hành ứng dụng và tích hợp | 1 | 10% | 50% | 100% | 100% | 100% |
| Kỹ sư ATTT (có thể dùng chung với hệ khác của Trung tâm) | 1 | 10% | 30% | 50% | 50% | 50% |
| Cán bộ hỗ trợ người dùng (service desk tầng 1) | 1 | 0% | 20% | 100% | 100% | 100% |
| **Tổng FTE** | **6** | **0,8** | **2,5** | **5,5** | **5,5** | **5,5** |

Nếu đơn vị vận hành chưa có kỹ sư Kubernetes, cần tuyển hoặc điều động trước T0+2 để kịp tham gia từ W1; thời gian đào tạo một kỹ sư vận hành truyền thống lên mức tự vận hành cụm Kubernetes theo GitOps ước khoảng sáu tháng, đúng bằng khoảng cách từ W1 đến cài đặt PROD ở W3. Nếu tỉnh chọn phương án hạ tầng H2 (cloud chính phủ), số kỹ sư hạ tầng có thể giảm xuống 1 vì lớp hạ tầng do nhà cung cấp cloud vận hành; nếu chọn H3 (thuê dịch vụ trọn gói), đội vận hành tỉnh chỉ cần trưởng nhóm, kỹ sư vận hành ứng dụng và cán bộ hỗ trợ.

### 6.6. Kế hoạch tuyển dụng và bố trí

Kế hoạch bố trí nhân sự nhà thầu đi theo bốn mốc. Ở giai đoạn lựa chọn nhà thầu (T0 − 2 đến T0), nhà thầu nêu tên nhân sự chủ chốt trong hồ sơ dự thầu, gồm PM, PO, kiến trúc sư giải pháp, kỹ sư ATTT, một kỹ sư SRE có CKA và một trưởng nhóm tích hợp có kinh nghiệm Camel; đây là các vị trí mà việc thay người sau khi trúng thầu phải được chủ đầu tư chấp thuận. Tại T0, toàn bộ 15,5 FTE của W0 phải có mặt, vì W0 chỉ có bốn sprint và mọi trễ hạn ở W0 kéo theo toàn bộ lịch. Từ T0+1, nhà thầu bố trí thêm 11 FTE để có mặt đầy đủ ngày đầu W1 (T0+2), trong đó tháng đầu tiên mỗi người mới đi qua hai tuần làm quen (mục 6.7) và được ghép cặp với một thành viên W0. Từ T0+8, nhà thầu bố trí đội W4 (khoảng 10 người mới cộng với người chuyển từ đội W2) để kịp làm quen nghiệp vụ thanh toán và môi trường trước khi W4 bắt đầu ở T0+10; việc này rất quan trọng vì đỉnh tải 38 FTE rơi đúng vào giai đoạn chủ đầu tư bận nhất với cắt chuyển.

Việc giảm người diễn ra ở ba thời điểm: cuối W3 (T0+13), đội Thí điểm và Cắt chuyển giảm từ 18,5 xuống khoảng 6 FTE chuyển sang đội G của W5; cuối W4 (T0+15), đội D và E giảm còn đội F; cuối W5 (G5), đội giảm còn 5 FTE bảo hành. Người rời dự án phải hoàn thành bàn giao lane (tài liệu README của lane, danh sách việc dở, quyền truy cập được thu hồi) trước ngày rời, và trưởng nhóm kỹ thuật xác nhận bàn giao.

### 6.7. Đào tạo nội bộ cho đội nhà thầu

Đội nhà thầu được đào tạo nội bộ trong W0 và mỗi khi có người mới, theo năm học phần. Học phần **Nền tảng công nghệ** (khoảng 24 giờ) gồm Spring Boot 4 và Spring Modulith với kiểm tra ranh giới module, Camel Quarkus và native image, PostgreSQL với Row Level Security cho cách ly tenant, Kafka và Apicurio, Keycloak và OPA, GitOps với Argo CD. Học phần **Nghiệp vụ** (khoảng 12 giờ) giới thiệu vai trò LGSP theo CMP-LAW-03 và CMP-LAW-09, NDXP và NDOP, PayGov, và các khối của hệ cũ (Bus, Hub, API Management, Aita, Payment) qua tài liệu hệ cũ và qua buổi trình bày của đơn vị vận hành. Học phần **An toàn và dữ liệu** (khoảng 8 giờ) gồm lập trình an toàn theo OWASP ASVS, yêu cầu cấp độ 3, bảo vệ dữ liệu cá nhân và quy tắc không dùng dữ liệu thật. Học phần **Cách làm việc** (khoảng 6 giờ) gồm quy ước repo, lane, Definition of Done, cổng CI và quy trình review. Học phần **AI agent có kiểm soát** (khoảng 4 giờ) gồm các quy tắc của mục 5.5, cách viết chỉ dẫn theo WP và các lỗi thường gặp khi review mã do agent sinh.

Sau mỗi wave, mỗi đội dành một buổi retrospective mở rộng để rút kinh nghiệm kỹ thuật và cập nhật học phần tương ứng. Tài liệu đào tạo nội bộ được lưu trong wiki của dự án và trở thành một phần của gói chuyển giao cho đơn vị vận hành.

### 6.8. Chuyển giao tri thức cho đội vận hành tỉnh

#### 6.8.1. Vì sao cần chuyển giao theo lộ trình

Tài liệu hướng dẫn vận hành của hệ cũ (bộ HDVH năm 2021 của từng khối Bus, Tooling, Hub, API Management, Aita, Payment) được tổ chức theo từng khối và theo thao tác trên máy chủ: khởi động, tắt ứng dụng Tomcat, sửa trực tiếp bảng tham số cấu hình của ứng dụng, CSDL và máy chủ, theo dõi log trên từng máy. Datahub vận hành theo cách khác hẳn: hạ tầng và cấu hình được khai báo trong Git và áp lên cụm Kubernetes qua Argo CD, không ai sửa cấu hình trực tiếp trên máy; giám sát tập trung qua OpenTelemetry và LGTM; sự cố được xử lý theo runbook gắn với cảnh báo. Khoảng cách kỹ năng này chính là rủi ro kiến trúc RSK-A01 của D03-01 (đội vận hành chưa quen Kubernetes, Kafka) và không thể lấp bằng một khóa đào tạo cuối dự án, nên chuyển giao được trải đều trong 18 tháng và đo bằng năng lực thực tế.

#### 6.8.2. Bốn bậc chuyển giao

Lộ trình chuyển giao gồm bốn bậc, mỗi bậc có điều kiện vào và điều kiện ra cụ thể, được tóm tắt trong bảng sau.

| Bậc | Thời gian | Đội vận hành làm gì | Nhà thầu làm gì | Điều kiện hoàn thành bậc |
|---|---|---|---|---|
| 1. Quan sát | W0 đến W1 | Có tài khoản chỉ đọc vào DEV, TEST; dự sprint review; học học phần Nền tảng công nghệ cùng đội nhà thầu | Mời dự, giải thích kiến trúc, chia sẻ wiki | Đội vận hành mô tả lại được kiến trúc triển khai và luồng phát hành |
| 2. Cùng làm | W2 | Cùng nhóm Nền tảng dựng STAGING; cùng làm diễn tập sao lưu, khôi phục; trực cùng khi kiểm thử hiệu năng | Làm chính, hướng dẫn từng bước | Đội vận hành tự khôi phục được một CSDL từ bản sao lưu trên STAGING dưới sự quan sát |
| 3. Làm chính có hỗ trợ | W3 đến G3 | Cài đặt PROD theo runbook; phê duyệt phát hành lên PROD; trực sự cố tầng 1, tầng 2 theo lịch xoay vòng chung | Hỗ trợ tầng 3, xử lý lỗi mã nguồn, có mặt tại chỗ ở tháng cắt chuyển | Đội vận hành tự thực hiện năm bài diễn tập (mục 6.8.3) không cần nhà thầu can thiệp |
| 4. Độc lập | Sau G3 đến hết bảo hành | Tự vận hành tầng 1, tầng 2; tự kết nạp HTTT mới; quản trị tenant | Bảo hành tầng 3 theo SLA hợp đồng | Biên bản xác nhận đủ năng lực tiếp nhận ký trước G5 |

#### 6.8.3. Năm bài diễn tập bắt buộc

Điều kiện hoàn thành bậc 3 được đo bằng năm bài diễn tập trên STAGING hoặc PROD trong cửa sổ bảo trì, mỗi bài có kịch bản, thời gian chuẩn và biên bản: (1) phát hành một phiên bản mới qua GitOps và quay lui phiên bản; (2) khôi phục CSDL PostgreSQL về một thời điểm trước đó, đạt mục tiêu RPO và RTO do D02-02 và D03-09 quy định (giả định nền ghi 15 phút và 4 giờ cho cỡ M); (3) chuyển sang site DR và quay về; (4) xử lý một luồng tích hợp lỗi đầy DLQ, tìm nguyên nhân qua trace và phát lại bản tin trong thời gian không vượt mục tiêu MTTR của KPI-16 (1 giờ với sự cố mức 1); (5) thay chứng thư và xoay vòng bí mật của một HTTT thành viên. Đội vận hành phải tự hoàn thành cả năm bài trong thời gian chuẩn; nhà thầu chỉ quan sát và ghi nhận.

#### 6.8.4. Gói tài liệu chuyển giao

Gói chuyển giao gồm tài liệu hướng dẫn vận hành của Datahub (tham chiếu tài liệu vận hành của nhóm 06), bộ runbook gắn với từng cảnh báo, sơ đồ triển khai thực tế của tỉnh, danh mục cấu hình theo tenant, mã nguồn hạ tầng trong Git và tài liệu đào tạo nội bộ. Gói này không lặp lại cấu trúc HDVH theo khối của hệ cũ mà tổ chức theo dịch vụ và theo sự cố, để người trực không phải biết trước sự cố thuộc khối nào.

### 6.9. Nhân sự dự phòng

Rủi ro nhân sự lớn nhất của dự án là phụ thuộc vào một vài người nắm kiến thức then chốt, đặc biệt ở Camel Quarkus native, mô hình multi-tenant và nghiệp vụ thanh toán. Dự án áp dụng năm biện pháp. Thứ nhất, mỗi lane phải có ít nhất hai người đã từng merge mã vào lane đó (hệ số xe buýt, bus factor, tối thiểu là 2); Scrum Master theo dõi chỉ số này hằng sprint. Thứ hai, mỗi vị trí chủ chốt có một người thay thế được chỉ định: Scrum Master cao cấp nhất thay PM, một trưởng nhóm kỹ thuật thay kiến trúc sư, một BA nghiệp vụ thay PO. Thứ ba, hợp đồng quy định khi nhà thầu thay nhân sự chủ chốt thì người thay thế phải có năng lực tương đương theo mục 6.4, được chủ đầu tư chấp thuận và có ít nhất 10 ngày làm việc chồng lấn với người cũ. Thứ tư, nhà thầu cam kết có nguồn nhân sự dự phòng nội bộ tương đương khoảng 10% định biên để bù khi có người nghỉ dài ngày; khoản này không tính vào 455 người-tháng và không phát sinh chi phí cho chủ đầu tư. Thứ năm, kiến thức được ghi lại liên tục qua ADR, README từng lane và wiki, để người thay thế đọc được thay vì phải hỏi người đã rời.

AI agent không được xem là nhân sự dự phòng. Agent có thể giúp người mới đọc mã nhanh hơn, nhưng không thay được người chịu trách nhiệm về lane.

### 6.10. Giảm tải sau G5, bảo hành và vận hành 5 năm

Sau G5, đội nhà thầu giảm từ 17,5 xuống 5 FTE cho 12 tháng bảo hành (T0+18 đến T0+30). Đội bảo hành giữ đủ các năng lực cần để sửa lỗi ở mọi tầng: 1 kỹ sư backend, 1 kỹ sư tích hợp Camel, 0,5 frontend, 1 SRE, 0,5 QA, cộng phần thời gian của PM, PO, kiến trúc sư và kỹ sư ATTT (mỗi vị trí 0,25). Đội bảo hành không phát triển tính năng mới; mọi yêu cầu mới đi qua quy trình thay đổi và có thể trở thành hợp đồng riêng.

Bảng dưới đây tổng hợp nhân sự cho cửa sổ TCO 5 năm tính từ T0. Phần nhà thầu trong giai đoạn thực hiện và bảo hành lấy từ giả định nền; phần hỗ trợ kỹ thuật sau bảo hành và phần đội vận hành tỉnh là đề xuất của chương này, cần chương chi phí xác nhận.

| Giai đoạn | Thời gian | Nhà thầu (FTE bình quân) | Đội vận hành tỉnh (FTE) | Ghi chú |
|---|---|---|---|---|
| Thực hiện | T0 đến T0+18 | khoảng 25 (455 người-tháng / 18 tháng) | 0,8 đến 5,5 tăng dần | Theo mục 6.2 và 6.5.2 |
| Bảo hành | T0+18 đến T0+30 | 5 | 5,5 | Nhà thầu hỗ trợ tầng 3 |
| Vận hành, hỗ trợ kỹ thuật theo hợp đồng năm | T0+30 đến T0+60 | 2 đến 3 (đề xuất) | 5,5 | Nhà thầu: nâng cấp phiên bản thành phần nguồn mở, vá ATTT, hỗ trợ tầng 3 |

Mức 2 đến 3 FTE hỗ trợ kỹ thuật sau bảo hành được đề xuất dựa trên nhu cầu tối thiểu để theo kịp vòng đời phiên bản của khoảng hai mươi thành phần nguồn mở trong stack (mỗi năm cần nâng ít nhất một phiên bản chính của Spring Boot, Camel Quarkus, Kubernetes, Keycloak, PostgreSQL) và để vá lỗ hổng trong thời hạn mà cấp độ 3 yêu cầu. CMP-LAW-14 (Nghị định 224/2026/NĐ-CP) có cơ chế cho phép chỉ định doanh nghiệp đã phát triển phần mềm làm đơn vị quản trị, vận hành (theo bản tóm tắt pháp lý, cần đối chiếu điều khoản), nên hợp đồng hỗ trợ kỹ thuật sau bảo hành có thể giao tiếp cho nhà thầu phát triển mà không phải đấu thầu lại; điều này giúp giữ được người đã hiểu mã nguồn. Nếu Datahub được nhiều tỉnh dùng chung theo mô hình sản phẩm, chi phí hỗ trợ này có thể chia cho các tỉnh; đây là lý do chương chi phí nên tách khoản hỗ trợ sản phẩm (dùng chung) khỏi khoản vận hành tại tỉnh (riêng từng tỉnh).

### Câu hỏi mở

- **Q-D0102-56.** Đơn vị vận hành tỉnh thí điểm hiện có bao nhiêu kỹ sư có kinh nghiệm Kubernetes, và có thể điều động đủ 6 người theo mục 6.5.2 từ W1 không, hay cần tuyển mới?
- **Q-D0102-57.** Chủ đầu tư có bố trí được một cán bộ làm Chủ sản phẩm phía chủ đầu tư toàn thời gian ở W1 đến W4 không? Nếu không, chủ đầu tư có chấp nhận thuê chuyên gia tư vấn đóng vai trò này dưới sự ủy quyền của Ban quản lý dự án không?
- **Q-D0102-58.** Hồ sơ mời thầu có được phép đặt chứng chỉ (ví dụ CKA cho SRE, chứng chỉ ATTT cho kỹ sư ATTT) làm điều kiện bắt buộc với nhân sự chủ chốt không, hay chỉ được dùng làm tiêu chí chấm điểm?
- **Q-D0102-59.** Tỉnh thí điểm chọn phương án hạ tầng nào (H1, H2 hay H3)? Lựa chọn này làm thay đổi số kỹ sư hạ tầng của đội vận hành tỉnh từ 2 xuống 1 hoặc 0.

### Ghi chú cho người tổng hợp

- **Hụt PM và PO ở T0+14, T0+15.** Theo giả định nền §5, cột W4 ghi PM và PO là "(chung)" với W3, nhưng W3 kết thúc ở T0+13 còn W4 kéo dài tới T0+15. Cách tính 455 người-tháng vì vậy không có PM và PO trong hai tháng cuối W4, hụt khoảng 4 người-tháng. Đề xuất sửa giả định nền: hoặc thêm 2 FTE PM, PO vào W4 cho hai tháng cuối (tổng thành khoảng 459 người-tháng), hoặc ghi rõ phần này nằm trong dự phòng.
- **Đỉnh tải 38 FTE.** Giả định nền chỉ nêu tổng theo cột nên dễ hiểu nhầm đỉnh tải là 28 FTE. Đề xuất thêm một dòng vào §5 của giả định nền: "Tải đồng thời cao nhất khoảng 38 FTE ở T0+10 đến T0+13".
- **Nhân sự vận hành tỉnh và hỗ trợ kỹ thuật sau bảo hành chưa có trong giả định nền.** Chương này đề xuất 6 người (5,5 FTE) phía vận hành tỉnh, khoảng 3,5 FTE phía Ban quản lý dự án và 2 đến 3 FTE hỗ trợ kỹ thuật của nhà thầu từ T0+30. Chương chi phí và TCO của D01-01 cần các con số này; đề nghị đưa vào §5 hoặc một mục mới của giả định nền để hai tài liệu dùng thống nhất.
- **Lane của PH-19.** Bảng lane của AGENTS.md chưa có lane cho phân hệ thanh toán. Chương này giả định mã PH-19 nằm trong L-CTRL hoặc L-DATA và để kiến trúc sư chốt bằng ADR trong dải ADR-040 đến 049; nếu muốn lane riêng (ví dụ L-PAY) thì cần bổ sung vào AGENTS.md và D00-01.
- **RTO lệch giữa các tài liệu.** Giả định nền §4 ghi RTO 4 giờ cho cỡ M, trong khi D03-01 §DR ghi RTO ≤ 1 giờ cho data plane. Mục 6.8.3 tránh nêu con số và dẫn chiếu D02-02, D03-09; người tổng hợp cần chốt một con số.
- Các thời lượng đào tạo (mục 6.7), năm bài diễn tập (mục 6.8.3) và yêu cầu năm kinh nghiệm (mục 6.4) là đề xuất của chương, không có trong giả định nền.
