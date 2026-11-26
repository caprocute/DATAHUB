---
ma_tai_lieu: D03-07
ten: Thiết kế an toàn thông tin
phien_ban: 0.2
ngay: 2026-11-26
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, Kiến trúc sư, Trưởng nhóm kỹ thuật, Đội phát triển, Vận hành, Bộ phận chuyên trách an ninh mạng của chủ quản
mo_ta: Thiết kế an toàn thông tin của Datahub gồm đối tượng bảo vệ, mô hình mối đe dọa STRIDE, danh mục biện pháp SEC-nn, bảo vệ dữ liệu cá nhân, ứng phó sự cố và ma trận tuân thủ cấp độ 3, làm căn cứ thẩm định, thiết kế hạ tầng, lập trình và kiểm thử bảo mật.
tai_lieu_lien_quan: D03-01 SAD; D02-02 SRS; D03-08 Hồ sơ đề xuất cấp độ; D03-09 Hạ tầng, triển khai, DR; D03-10 Thiết kế đa tenant; D04-01 Quy chuẩn lập trình; D05-01 Kế hoạch kiểm thử tổng thể
---

# D03-07 · Thiết kế an toàn thông tin

## Tóm tắt cho hội đồng thẩm định

**Mục tiêu.** Tài liệu là thiết kế an toàn thông tin (ATTT) đầy đủ của Datahub ở cấp độ 3 theo Nghị định 331/2026/NĐ-CP, đồng thời chừa sẵn điểm nâng lên cấp độ 4 mà không phải làm lại kiến trúc. Tài liệu trả lời bốn câu hỏi: bảo vệ cái gì, ai tấn công và bằng cách nào, dùng biện pháp nào để chống, và chứng minh đáp ứng yêu cầu bằng cách nào.

**Phạm vi.** Toàn bộ thành phần của SAD (D03-01): hai ứng dụng giao diện, sáu đơn vị triển khai Spring Boot, `dh-runtime` Camel Quarkus, cổng API, Kafka, PostgreSQL, kho đối tượng, Keycloak, OPA, OpenBao, GitOps và bộ quan sát; áp dụng cho cả hồ sơ tỉnh độc lập và hồ sơ nền tảng dùng chung. An toàn của các HTTT thành viên, NDXP, PayGov và CSDL quốc gia nằm ngoài phạm vi, chỉ xử lý ranh giới với các hệ đó.

**Căn cứ pháp lý.** CMP-LAW-16 (Luật An ninh mạng 116/2025/QH15); CMP-LAW-17 (Nghị định 331/2026/NĐ-CP); STD-06 (TCVN 14423:2026, chương 5 cho cấp độ 3); CMP-LAW-05 và CMP-LAW-18 (Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15, Nghị định 356/2025/NĐ-CP); CMP-LAW-19 (Nghị định 278/2025/NĐ-CP); CMP-LAW-20 (Quyết định 8297/QĐ-BCA-A05 cho hồ sơ nền tảng dùng chung). Văn bản cũ (Nghị định 85/2016, Thông tư 12/2022, TCVN 11930:2017, Nghị định 13/2023) chỉ dùng để đối chiếu kế thừa.

**Những điểm hội đồng cần lưu ý.** (1) Khung pháp lý đã thay đổi hoàn toàn từ 2025 đến 2026; tài liệu lập theo văn bản mới và ghi rõ điểm chưa đối chiếu được toàn văn ở mục 14.1. (2) Tám vùng tin cậy Z0 đến Z7: không có đường từ Internet vào ứng dụng mà không qua biên và cổng API, không có đường ra ngoài trừ egress gateway có danh sách đích, truy cập của con người vào hạ tầng chỉ qua vùng quản trị Z7. (3) Mô hình mối đe dọa STRIDE ghi 62 mối đe dọa, ba mối ở mức nghiêm trọng (THR-09, THR-15, THR-46) đều có biện pháp hạ rủi ro tồn dư xuống mức trung bình hoặc thấp hơn. (4) Mọi biện pháp có mã `SEC-nn`, tham số đo được và cách kiểm chứng; ma trận mục 11 cho phép lần từ từng điều khoản đến biện pháp. (5) Thông báo vi phạm dữ liệu cá nhân trong 72 giờ kể từ khi phát hiện được đưa vào quy trình ứng phó sự cố (mục 8), còn báo cáo sự cố an ninh mạng phụ thuộc văn bản hướng dẫn chưa ban hành (Q309). (6) Một số tham số được siết chặt hơn SRS và SAD (phiên 15 phút, mật khẩu 14 ký tự, nhật ký lưu 12 tháng và WORM 5 năm); các điểm cần sửa ở tài liệu khác nằm ở mục 14.3.

**Con số chính.**

| Chỉ số | Giá trị |
|---|---|
| Vùng tin cậy | 8 (Z0…Z7) |
| Tác nhân đe dọa | 9 (TA-01…TA-09) |
| Mối đe dọa trong mô hình STRIDE | 62 (THR-01…62): 3 nghiêm trọng, 51 cao, 8 trung bình theo rủi ro gốc |
| Biện pháp ATTT | 92 (SEC-01…SEC-93, theo mười dải) |
| Use case phát hiện | 25 (UC-SEC-01…), tám playbook ứng phó PB-01…08 |
| Mốc báo cáo chính | 72 giờ thông báo vi phạm dữ liệu cá nhân; 10 ngày làm việc rút kinh nghiệm |
| Thời hạn lưu nhật ký | Kiểm toán: 12 tháng trực tuyến, WORM 5 năm; vận hành 90 ngày; an ninh 12 tháng |
| Ma trận tuân thủ | 4 (TCVN 14423:2026, TCVN 11930:2017 và TT 12/2022, OWASP ASVS 5.0, NFR-00-020…029) |

: Con số chính của thiết kế ATTT

## 1. Mục đích, phạm vi và người đọc

### 1.1. Mục đích

Tài liệu này là thiết kế an toàn thông tin (ATTT) đầy đủ của Datahub. Nó trả lời bốn câu hỏi theo thứ tự: Datahub phải bảo vệ cái gì (tài sản, dữ liệu, ranh giới tin cậy); ai có thể tấn công và tấn công bằng cách nào (mô hình mối đe dọa STRIDE); Datahub dùng biện pháp gì để chống lại (danh mục biện pháp `SEC-nn` hiện thực cụ thể trên ngăn xếp công nghệ đã chốt); và làm sao chứng minh các biện pháp đó đáp ứng yêu cầu cấp độ 3 theo khung pháp lý hiện hành, đồng thời không phải làm lại khi nâng lên cấp độ 4.

Danh mục `SEC-nn` được định nghĩa duy nhất tại đây (D00-01 §3.1). Hồ sơ đề xuất cấp độ (D03-08), thiết kế hạ tầng và DR (D03-09), quy chuẩn lập trình (D04-01, D04-02) và kế hoạch kiểm thử tổng thể (D05-01) chỉ tham chiếu mã, không định nghĩa lại. Khi một tài liệu khác cần một biện pháp chưa có, người viết đề xuất bổ sung vào tài liệu này trong dải số tương ứng.

### 1.2. Phạm vi

Phạm vi bao gồm toàn bộ thành phần mô tả ở SAD (D03-01) mục 4 và 5: hai ứng dụng giao diện (`dh-console`, `dh-portal`), sáu DU Spring Boot (`dh-connect`, `dh-integration`, `dh-data`, `dh-platform`, `dh-payment`, `dh-assist`), DU Camel Quarkus `dh-runtime`, APISIX, Kafka và Apicurio, PostgreSQL trên CloudNativePG, Garage, Valkey, Keycloak, OPA, OpenBao, Argo CD và kho Git cấu hình, bộ quan sát OpenTelemetry/Mimir/Loki/Tempo/Grafana, Harbor và đường ống CI/CD. Phạm vi áp dụng cho cả hai hồ sơ triển khai: **tỉnh độc lập** (cụm Kubernetes tại TTDL tỉnh) và **nền tảng dùng chung** (cụm trên cloud Chính phủ phục vụ nhiều tỉnh).

Ngoài phạm vi là an toàn của bản thân các HTTT thành viên, NDXP, PayGov và các CSDL quốc gia; tài liệu chỉ xử lý ranh giới giữa Datahub và các hệ đó (giả định chúng có thể bị xâm phạm). An toàn vật lý của TTDL được nêu ở mức yêu cầu đối với bên cung cấp hạ tầng (mục 12) và chi tiết ở D03-09.

### 1.3. Người đọc và cách đọc

Hội đồng thẩm định và bộ phận chuyên trách an ninh mạng của chủ quản đọc mục 2 (căn cứ), 3 (đối tượng bảo vệ), 11 (ma trận tuân thủ) và 12 (trách nhiệm). Kiến trúc sư và trưởng nhóm kỹ thuật đọc mục 4 (mô hình mối đe dọa) và 5 (biện pháp). Đội phát triển đọc mục 5.5 (ứng dụng và API), 6 (dữ liệu cá nhân) và 9 (đa tenant). Đội vận hành đọc mục 5.2, 5.6, 7 và 8.

### 1.4. Quan hệ với các tài liệu khác

Bảng dưới đây cho biết tài liệu này nhận đầu vào từ đâu và cung cấp gì cho tài liệu nào, để người đọc biết chỗ nào là nguồn sự thật cho từng nội dung.

| Tài liệu | Quan hệ |
|---|---|
| D03-01 SAD §8.2, §9 | SAD tóm lược bảy lớp bảo vệ và bốn mức phân loại dữ liệu; tài liệu này chi tiết hóa và có quyền điều chỉnh tham số (ví dụ thời hạn token) — điều chỉnh được ghi ở mục 14 để luồng lõi cập nhật SAD. |
| D02-02 SRS §6.3 | NFR-00-020 … 029 là yêu cầu tối thiểu; tài liệu này hiện thực và, ở một số điểm, đề xuất siết chặt hơn (mật khẩu, thời hạn lưu nhật ký). |
| D03-10 Thiết kế đa tenant | Nguồn sự thật về cơ chế cách ly theo tầng; mục 9 ở đây chỉ bổ sung góc nhìn an ninh và các biện pháp `SEC-80…89`. |
| D03-08 Hồ sơ đề xuất cấp độ | Dùng danh mục `SEC-nn` và ma trận mục 11 làm "phương án bảo vệ" trong hồ sơ trình phê duyệt. |
| D03-09 Hạ tầng, triển khai, DR | Hiện thực các biện pháp hạ tầng (`SEC-10…19`, `SEC-50…59`, `SEC-70…79`) ở mức sơ đồ mạng, cấu hình cụm, sao lưu. |
| D04-01, D04-02 | Biến `SEC-40…49` thành quy tắc lập trình và cổng CI. |
| D05-01 | Mỗi `SEC-nn` có cách kiểm chứng; D05-01 lập ca kiểm thử bảo mật, kiểm thử rò rỉ chéo tenant, kiểm thử xâm nhập. |
| ADR-030, ADR-031, ADR-032 | Ba quyết định kiến trúc ATTT do tài liệu này đề xuất. |

: Quan hệ với các tài liệu khác

### 1.5. Thuật ngữ và chữ viết tắt

Bảng dưới đây giải thích các thuật ngữ và chữ viết tắt riêng của tài liệu ATTT; thuật ngữ chung của Datahub xem D00-01 (bảng thuật ngữ và quy ước mã).

| Thuật ngữ, viết tắt | Giải thích |
|---|---|
| ATTT, ANM | An toàn thông tin; an ninh mạng. Bộ phận chuyên trách ANM là đơn vị do chủ quản bố trí theo NĐ 331/2026 |
| DLCN | Dữ liệu cá nhân, theo Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 |
| STRIDE | Phương pháp phân loại mối đe dọa theo sáu nhóm: giả mạo, sửa đổi, chối bỏ, lộ lọt, từ chối dịch vụ, leo thang đặc quyền (mục 4.1) |
| DFD | Sơ đồ luồng dữ liệu (Data Flow Diagram), dùng làm nền cho mô hình mối đe dọa (mục 4.2) |
| Ranh giới tin cậy, vùng Z0…Z7 | Nơi dữ liệu đi từ vùng tin cậy này sang vùng khác; tám vùng mạng của Datahub (mục 3.3) |
| `THR-nn`, `TA-nn`, `SEC-nn`, `UC-SEC-nn`, `PB-nn` | Mã mối đe dọa, tác nhân đe dọa, biện pháp ATTT, use case phát hiện, playbook ứng phó sự cố |
| Rủi ro gốc, rủi ro tồn dư | Mức rủi ro K × T trước và sau khi áp dụng biện pháp `SEC-nn` (mục 4.1) |
| WAF, DDoS, SIEM, SOC | Tường lửa ứng dụng web; tấn công từ chối dịch vụ phân tán; hệ thống quản lý sự kiện an ninh; trung tâm giám sát an ninh |
| MFA, WebAuthn, mTLS | Xác thực nhiều yếu tố; xác thực bằng khóa phần cứng hoặc passkey; TLS hai chiều có chứng thư ở cả hai đầu |
| RLS | Bảo mật mức dòng của PostgreSQL (Row Level Security), cách ly dữ liệu theo tenant |
| KEK, envelope encryption | Khóa mã hóa khóa; mô hình mã hóa hai tầng, khóa dữ liệu được bọc bằng khóa của tenant trong OpenBao |
| WORM | Lưu một lần, đọc nhiều lần, không sửa, không xóa; dùng cho nhật ký kiểm toán dài hạn |
| SBOM, SLSA | Bảng kê thành phần phần mềm; khung mức an toàn chuỗi cung ứng phần mềm |
| Break-glass | Truy cập khẩn cấp có ghi phiên, chỉ dùng ngoại lệ |
| RTO, RPO | Thời gian khôi phục tối đa; lượng dữ liệu mất tối đa chấp nhận được |
| A05 | Cục An ninh mạng và phòng, chống tội phạm sử dụng công nghệ cao, nơi nhận thông báo vi phạm DLCN |

: Thuật ngữ và chữ viết tắt của thiết kế ATTT

### 1.6. Tài liệu tham chiếu

Bảng dưới đây liệt kê các văn bản và tài liệu nội bộ mà tài liệu này dựa vào, cùng vai trò của từng loại. Danh sách đầy đủ có số điều và trạng thái đối chiếu ở mục 2.2 và 2.3.

| Mã | Tên | Vai trò với tài liệu này |
|---|---|---|
| CMP-LAW-16 | Luật An ninh mạng 116/2025/QH15 | Căn cứ chính: nghĩa vụ chủ quản, ứng phó sự cố |
| CMP-LAW-17 | Nghị định 331/2026/NĐ-CP | Căn cứ chính: cấp độ, hồ sơ, bộ phận chuyên trách |
| STD-06 | TCVN 14423:2026 | Căn cứ chính: ngưỡng tham số, ma trận mục 11a |
| CMP-LAW-05, CMP-LAW-18 | Luật BVDLCN 91/2025/QH15; Nghị định 356/2025/NĐ-CP | Căn cứ cho mục 6 và mốc 72 giờ ở mục 8 |
| CMP-LAW-19 | Nghị định 278/2025/NĐ-CP | Căn cứ kết nối NDXP |
| STD-03, STD-07…12 | OWASP ASVS 5.0 và API Top 10, CIS Kubernetes, SLSA, RFC OAuth, ISO 27001/27002, NIST 800-63B | Thước đo kỹ thuật cho biện pháp (mục 2.3) |
| D00-01 | Quy ước mã và thuật ngữ | Định nghĩa mã `SEC`, `THR`, thuật ngữ chung |
| D02-02 | SRS | Yêu cầu NFR-00-020…029, câu hỏi Q08 |
| D03-01 | SAD | Thành phần, bảy lớp bảo vệ, phân loại dữ liệu |
| D03-08, D03-09, D03-10 | Hồ sơ đề xuất cấp độ; Hạ tầng, triển khai, DR; Thiết kế đa tenant | Nơi dùng và hiện thực biện pháp (mục 1.4) |
| D04-01, D04-02, D05-01 | Quy chuẩn lập trình; Kế hoạch kiểm thử tổng thể | Biến `SEC-nn` thành quy tắc và ca kiểm thử |
| D06-03 | Tài liệu vận hành (dự kiến, Đợt 5) | Playbook đầy đủ (mục 8.5) |

: Tài liệu tham chiếu của thiết kế ATTT

### 1.7. Cấu trúc tài liệu

Tài liệu đi từ căn cứ, đến đối tượng bảo vệ, mối đe dọa, biện pháp, rồi các chuyên đề và cuối cùng là bằng chứng tuân thủ. Bảng dưới đây cho biết nội dung từng chương và người đọc chính.

| Chương | Nội dung | Người đọc chính |
|---|---|---|
| 1 | Mục đích, phạm vi, người đọc, thuật ngữ, tài liệu tham chiếu | Mọi người đọc |
| 2 | Căn cứ pháp lý và tiêu chuẩn kỹ thuật | Hội đồng thẩm định, bộ phận chuyên trách ANM |
| 3 | Kiểm kê tài sản, phân loại dữ liệu, ranh giới tin cậy Z0…Z7 | Hội đồng thẩm định, kiến trúc sư |
| 4 | Mô hình mối đe dọa STRIDE: DFD, tác nhân, 62 mối đe dọa | Kiến trúc sư, trưởng nhóm kỹ thuật |
| 5 | Danh mục biện pháp `SEC-01…93` và bảng ngưỡng tham số | Kiến trúc sư, đội phát triển, vận hành |
| 6 | Bảo vệ dữ liệu cá nhân | Đội phát triển, bộ phận chuyên trách ANM |
| 7 | Nhật ký kiểm toán, giám sát, use case phát hiện | Vận hành, kiểm toán viên |
| 8 | Ứng phó sự cố, RACI, mốc báo cáo, playbook | Vận hành, bộ phận chuyên trách ANM, lãnh đạo chủ quản |
| 9 | Cách ly đa tenant dưới góc độ an ninh | Đội phát triển, kiến trúc sư |
| 10 | Lộ trình nâng lên cấp độ 4 | Hội đồng thẩm định, chủ quản |
| 11 | Ma trận tuân thủ (bốn ma trận) | Hội đồng thẩm định |
| 12 | Trách nhiệm chia sẻ giữa các bên | Chủ quản, nhà cung cấp hạ tầng |
| 13 | Truy vết yêu cầu, quyết định | Kiến trúc sư, kiểm thử viên |
| 14 | Câu hỏi mở, mã mới, điểm cần sửa ở tài liệu khác | Người điều phối tài liệu |

: Cấu trúc tài liệu và người đọc chính của từng chương

## 2. Căn cứ pháp lý và tiêu chuẩn

### 2.1. Bối cảnh thay đổi khung pháp lý

Khung pháp lý về an toàn hệ thống thông tin thay đổi lớn trong giai đoạn 2025–2026. Luật An ninh mạng số 116/2025/QH15 (hiệu lực 01/7/2026) hợp nhất Luật An ninh mạng 2018 và Luật An toàn thông tin mạng 2015, giao Bộ Công an làm đầu mối. Nghị định 331/2026/NĐ-CP về bảo vệ an ninh mạng đối với hệ thống thông tin kế nhiệm Nghị định 85/2016/NĐ-CP và giữ khung phân loại năm cấp độ. TCVN 14423:2026 "An ninh mạng – Hệ thống thông tin – Yêu cầu cơ bản" thay thế cả TCVN 14423:2025 và TCVN 11930:2017. Trong lĩnh vực dữ liệu cá nhân, Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP (cùng hiệu lực 01/01/2026) thay thế Nghị định 13/2023/NĐ-CP.

Chủ đầu tư yêu cầu các biện pháp kiểm soát "theo Thông tư 12/2022/TT-BTTTT và TCVN 11930:2017". Hai văn bản này thuộc khung cũ của Nghị định 85/2016. Datahub sẽ vận hành sau 01/7/2026, nên căn cứ chính phải là văn bản hiện hành; tuy nhiên tài liệu vẫn giữ ánh xạ đối chiếu với hai văn bản cũ vì ba lý do: hội đồng thẩm định và đội ngũ của tỉnh còn quen cấu trúc yêu cầu của TCVN 11930; Nghị định 331/2026 có điều khoản chuyển tiếp (Điều 39) cho hệ đang đầu tư trước 01/7/2026, trong đó việc thẩm định có thể vẫn theo khung cũ trong 6 tháng; và chưa thấy văn bản hướng dẫn của Bộ Công an thay thế toàn bộ Thông tư 12/2022. Nhờ vậy, dù hồ sơ được thẩm định theo khung nào, phương án bảo vệ vẫn đối chiếu được.

> **Q300 (đã chốt 25/11/2026):** Datahub là hệ mới, hồ sơ cấp độ lập theo NĐ 331/2026; phần LGSP cũ còn chạy được xử lý bằng phụ lục rủi ro chuyển tiếp. *Câu hỏi gốc:* Datahub được xác định là "hệ thống đang đầu tư trước 01/7/2026" (áp dụng chuyển tiếp Điều 39 NĐ 331/2026) hay hệ thống mới? Câu trả lời quyết định hồ sơ D03-08 lập theo khung nào; thiết kế này đáp ứng cả hai.

### 2.2. Văn bản pháp lý

Bảng dưới đây phân văn bản thành hai nhóm: văn bản hiện hành dùng làm căn cứ chính, và văn bản kế thừa dùng để đối chiếu. Cột "Chi phối thiết kế" cho biết văn bản đó ảnh hưởng tới mục nào. Các số điều chỉ được nêu khi đã tra; điểm chưa đối chiếu toàn văn được ghi rõ. Mã `CMP-LAW-nn` mới đề xuất được liệt kê ở mục 14 để luồng lõi bổ sung D00-01 §7.

| Mã đề xuất | Văn bản | Trạng thái dùng | Chi phối thiết kế | Ghi chú kiểm tra |
|---|---|---|---|---|
| CMP-LAW-16 (cập nhật) | Luật An ninh mạng số 116/2025/QH15, hiệu lực 01/7/2026 | Căn cứ chính | Toàn bộ; nghĩa vụ chủ quản, ứng phó sự cố, lưu trữ dữ liệu trong nước | Đã tra nguồn Bộ Công an; chưa đối chiếu Công báo |
| CMP-LAW-17 (mới) | Nghị định 331/2026/NĐ-CP về bảo vệ an ninh mạng đối với HTTT | Căn cứ chính | Cấp độ (mục 3), hồ sơ (D03-08), dùng chung hạ tầng cloud cho cấp 3–4 (Điều 30, mục 12), bộ phận chuyên trách (Điều 31, mục 12) | Điều 8, 25, 30, 31, 39 đã tra; thành phần hồ sơ chi tiết và tiêu chí cấp 4 chưa xác minh |
| STD-06 (mới) | TCVN 14423:2026 An ninh mạng – HTTT – Yêu cầu cơ bản | Căn cứ chính | Ngưỡng tham số (mục 5), ma trận (mục 11a); chương 5 cho cấp độ 3, chương 6 cho cấp độ 4 | Tên chính xác từng nhóm 5.1–5.18 cần đối chiếu |
| CMP-LAW-05 (cập nhật) | Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15, hiệu lực 01/01/2026 | Căn cứ chính | Mục 6 | Số hiệu đã tra |
| CMP-LAW-18 (mới) | Nghị định 356/2025/NĐ-CP quy định chi tiết Luật BVDLCN, hiệu lực 01/01/2026 | Căn cứ chính | Mục 6; thay NĐ 13/2023 | Điều khoản cụ thể về mẫu hồ sơ chưa đối chiếu |
| CMP-LAW-19 (mới) | Nghị định 278/2025/NĐ-CP về kết nối, chia sẻ dữ liệu bắt buộc, thay NĐ 47/2020 | Căn cứ chính | Kết nối NDXP (PH-14), THR-30…32 | — |
| CMP-LAW-01 | Luật Dữ liệu số 60/2024/QH15 | Căn cứ chính | Phân loại dữ liệu (mục 3.3) | — |
| CMP-LAW-20 (mới) | Quyết định 8297/QĐ-BCA-A05 (2025) Bộ tiêu chí an ninh mạng cho nền tảng điện toán đám mây phục vụ CPĐT | Căn cứ cho hồ sơ nền tảng dùng chung | Mục 12 | Chưa xác minh nội dung chi tiết |
| CMP-LAW-06 | Nghị định 85/2016/NĐ-CP | Kế thừa, chỉ khi áp dụng chuyển tiếp | Đối chiếu | Đã được NĐ 331/2026 kế nhiệm |
| CMP-LAW-07 | Thông tư 12/2022/TT-BTTTT | Kế thừa, đối chiếu | Ma trận mục 11b | Chưa thấy văn bản thay thế (Q301) |
| CMP-LAW-08 | TCVN 11930:2017 | Kế thừa, đối chiếu | Ma trận mục 11b | Đã bị TCVN 14423:2026 thay thế |
| CMP-LAW-04 | Nghị định 13/2023/NĐ-CP | Hết hiệu lực từ 01/01/2026 | Chỉ để giải thích ánh xạ | Thay bởi Luật 91/2025 và NĐ 356/2025 |

: Văn bản pháp lý làm căn cứ và trạng thái sử dụng

> **Câu hỏi mở Q301:** Bộ Công an đã ban hành (hoặc dự kiến ban hành) thông tư hướng dẫn NĐ 331/2026 thay Thông tư 12/2022/TT-BTTTT chưa? Nếu có, ma trận 11b phải chuyển sang văn bản mới.

Lý do căn cứ chính là bộ ba Luật 116/2025, NĐ 331/2026 và TCVN 14423:2026 rất đơn giản: đây là các văn bản có hiệu lực tại thời điểm Datahub được thẩm định và vận hành; TCVN 11930:2017 đã bị thay thế theo lời nói đầu của TCVN 14423:2026; còn Thông tư 12/2022 hướng dẫn một nghị định đã được kế nhiệm. Việc tiếp tục dùng văn bản cũ làm căn cứ chính sẽ khiến hồ sơ bị trả lại khi thẩm định theo khung mới.

Tiêu chí liên quan tới dữ liệu cá nhân trong NĐ 331/2026 (từ 100.000 chủ thể dữ liệu cá nhân cơ bản hoặc từ 10.000 chủ thể dữ liệu nhạy cảm trở lên thì tối thiểu cấp độ 3) gần như chắc chắn áp dụng cho Datahub, vì PH-06 (dữ liệu chủ công dân), PH-19 (giao dịch thanh toán) và PH-14 (khai thác CSDL quốc gia về dân cư) đều xử lý dữ liệu của số lượng lớn công dân. Điều 8 yêu cầu lấy cấp cao nhất khi đáp ứng nhiều tiêu chí và cấm chia nhỏ hệ thống để hạ cấp; vì vậy Datahub được xác định cấp độ cho **toàn bộ nền tảng**, không tách PH-19 hay PH-17 thành hệ cấp thấp hơn. Lập luận đầy đủ thuộc D03-08.

### 2.3. Tiêu chuẩn kỹ thuật

Các tiêu chuẩn kỹ thuật dưới đây không có tính bắt buộc pháp lý nhưng được dùng làm thước đo cụ thể cho biện pháp, vì TCVN 14423:2026 nêu yêu cầu ở mức "phải có" mà không chỉ định cách làm.

| Mã | Tiêu chuẩn | Dùng cho |
|---|---|---|
| STD-03 (cập nhật) | OWASP ASVS 5.0, mức 2 (thay ASVS 4.x ở D00-01) | Ứng dụng web và API (NFR-00-024), mục 5.5, ma trận 11c |
| STD-07 (mới) | OWASP API Security Top 10 2023; OWASP Top 10 2021 | Mô hình mối đe dọa API, kiểm thử |
| STD-08 (mới) | CIS Kubernetes Benchmark; NSA/CISA Kubernetes Hardening Guidance | `SEC-50…59` |
| STD-09 (mới) | SLSA (Supply-chain Levels for Software Artifacts), mục tiêu mức 3 cho ảnh do Datahub xây | `SEC-55…57` |
| STD-10 (mới) | RFC 9700 (OAuth 2.0 Security Best Current Practice), RFC 8705 (OAuth mTLS), RFC 7523 (JWT client authentication), RFC 9449 (DPoP, tham khảo), RFC 7636 (PKCE) | `SEC-20…29` |
| STD-11 (mới) | ISO/IEC 27001:2022 và 27002:2022 (tham khảo cấu trúc kiểm soát) | Tổ chức kiểm soát `SEC-01…09` |
| STD-12 (mới) | NIST SP 800-63B (định danh số, xác thực) – tham khảo cho chính sách mật khẩu | `SEC-22` |

: Tiêu chuẩn kỹ thuật dùng làm thước đo biện pháp

## 3. Đối tượng bảo vệ

### 3.1. Kiểm kê tài sản

Không thể bảo vệ cái chưa biết là mình có. Bảng dưới đây kiểm kê tài sản thông tin của Datahub theo nhóm, kèm mức phân loại cao nhất của dữ liệu mà tài sản chứa, chủ sở hữu kỹ thuật và mức quan trọng đối với tính sẵn sàng. Kiểm kê này là đầu vào cho mô hình mối đe dọa (mục 4) và được tự động hóa: danh sách workload, ảnh container và phiên bản được sinh từ kho Git cấu hình và từ Harbor (SBOM) mỗi ngày, nên tần suất kiểm kê thực tế là liên tục, chặt hơn yêu cầu tối thiểu 1 lần/năm của TCVN 14423:2026 (`SEC-04`).

| Mã tài sản | Tài sản | Ví dụ cụ thể | Mức dữ liệu cao nhất | Chủ sở hữu kỹ thuật | Quan trọng với sẵn sàng |
|---|---|---|---|---|---|
| AS-01 | DU control plane | `dh-connect`, `dh-integration`, `dh-data`, `dh-platform` | Nhạy cảm (`dh-data`) | Trưởng nhóm phát triển | Trung bình (99,5%) |
| AS-02 | DU thanh toán | `dh-payment` | Nhạy cảm (thông tin tài khoản, giao dịch) | Nhóm PH-19 | Cao |
| AS-03 | DU AI | `dh-assist` | Hạn chế (tối đa; không được nhận dữ liệu Nhạy cảm) | Nhóm PH-17 | Thấp |
| AS-04 | Data plane | APISIX, `dh-runtime`, Kafka | Nhạy cảm (dữ liệu đi qua) | Nhóm nền tảng | Rất cao (99,9%) |
| AS-05 | Giao diện | `dh-console`, `dh-portal` (tệp tĩnh và BFF) | Hạn chế | Nhóm giao diện | Trung bình |
| AS-06 | CSDL nghiệp vụ | Cụm CloudNativePG, schema `ph{nn}_*` | Nhạy cảm | Nhóm nền tảng | Cao |
| AS-07 | Kho đối tượng | Bucket `dh-{tenant}-*` trên Garage | Nhạy cảm (tệp nhập, tệp đối soát) | Nhóm nền tảng | Trung bình |
| AS-08 | Kho WORM | Bucket nhật ký kiểm toán khóa đối tượng (Object Lock) | Hạn chế (đã che) | Vận hành ATTT | Thấp (ghi bất đồng bộ) |
| AS-09 | Bộ nhớ đệm | Valkey | Hạn chế (phiên BFF, kết quả tra cứu) | Nhóm nền tảng | Trung bình |
| AS-10 | Định danh | Keycloak (realm theo tenant, CSDL của Keycloak) | Hạn chế (băm mật khẩu, bí mật TOTP) | Vận hành ATTT | Rất cao |
| AS-11 | Kho bí mật và khóa | OpenBao (KV, transit, PKI), khóa mở niêm phong | Tối mật kỹ thuật | Vận hành ATTT | Rất cao |
| AS-12 | Chính sách | Gói chính sách OPA (Rego) trong Git, bundle server | Nội bộ | Kiến trúc sư ATTT | Cao |
| AS-13 | Cấu hình triển khai | Kho Git cấu hình, Argo CD | Nội bộ (không chứa bí mật) | Nhóm nền tảng | Cao |
| AS-14 | Chuỗi cung ứng | Kho mã nguồn, runner CI, Harbor, khóa ký cosign | Nội bộ; khóa ký là tối mật kỹ thuật | Nhóm DevSecOps | Trung bình |
| AS-15 | Quan sát | Mimir, Loki, Tempo, Grafana | Hạn chế (log đã che) | Vận hành | Trung bình |
| AS-16 | Nhật ký kiểm toán | Bảng `ph13_audit.audit_event`, neo băm | Hạn chế | Vận hành ATTT | Trung bình |
| AS-17 | Sao lưu | Bản sao CNPG (Barman), Velero, bản sao WORM ngoài site | Nhạy cảm | Vận hành | Cao (khi DR) |
| AS-18 | Hạ tầng cụm | Nút K8s, etcd, control plane K8s, Cilium, Istio | Tối mật kỹ thuật (etcd chứa Secret) | Bên cung cấp hạ tầng | Rất cao |
| AS-19 | Thông tin xác thực ra ngoài | Client NDXP, khóa ký PayGov, tài khoản CSDL nguồn | Tối mật kỹ thuật | Chủ quản từng kết nối | Cao |
| AS-20 | Kho phân tích lưu lượng | ClickHouse (`dh-olap`, Z5): siêu dữ liệu lượt gọi API giữ 12 tháng theo D03-09 | Hạn chế (định danh HTTT, địa chỉ nguồn; không chứa nội dung bản tin) | Vận hành | Trung bình |

: Kiểm kê tài sản cần bảo vệ

"Tối mật kỹ thuật" ở đây không phải mức phân loại dữ liệu nghiệp vụ mà là nhãn cho vật liệu khóa và bí mật mà nếu lộ sẽ làm vô hiệu hóa mọi biện pháp khác; chúng được xử lý theo `SEC-33…36` và không bao giờ xuất hiện ngoài OpenBao hoặc bộ nhớ tiến trình.

### 3.2. Phân loại dữ liệu và cách xử lý theo mức

SAD §8.2 định nghĩa bốn mức phân loại. Phần dưới đây chi tiết hóa mỗi mức thành quy tắc thực thi được ở từng điểm xử lý. Mức phân loại được gắn ở **mức trường** trong đặc tả dữ liệu (D02-06/D02-07) bằng thuộc tính `x-dh-classification` trong OpenAPI/JSON Schema và bằng chú thích `@Classified(level=…)` trên thực thể Java; PH-09 là nơi quản lý danh mục phân loại và mục đích khai thác. Một bản ghi có trường ở nhiều mức thì được xử lý theo mức cao nhất ở những khâu không tách được trường (ví dụ sao lưu, bản tin trong DLQ).

Bảng sau là quy tắc chuẩn; mọi ngoại lệ phải ghi trong SDD phân hệ và được kiến trúc sư ATTT duyệt.

| Khâu xử lý | Công khai | Nội bộ | Hạn chế | Nhạy cảm |
|---|---|---|---|---|
| Lưu trữ | Mã hóa volume (mặc định toàn hệ) | Như Công khai | Mã hóa volume; bảng có RLS | Mã hóa trường ở tầng ứng dụng bằng envelope encryption qua OpenBao transit (ADR-032); thêm cột băm có khóa (HMAC) nếu cần tìm kiếm chính xác |
| Truyền | TLS | TLS, mTLS nội bộ | TLS 1.3/mTLS; HTTT bên ngoài khuyến nghị mTLS | Bắt buộc mTLS hoặc private_key_jwt cho HTTT khai thác (`SEC-24`) |
| Log vận hành | Đầy đủ | Đầy đủ | Che một phần (ví dụ `0912***678`, `ng***@example.gov.vn`) | Không ghi giá trị; chỉ ghi tên trường và dấu `[REDACTED]` |
| Nhật ký kiểm toán | Đầy đủ | Đầy đủ | Che một phần trong giá trị trước/sau | Không ghi giá trị; ghi băm có khóa để tra "ai đã truy cập đối tượng X" |
| Trace | Thuộc tính span không chứa thân bản tin ở mọi mức | ← | ← | ← |
| Hiển thị giao diện | Đầy đủ | Theo quyền | Theo quyền, che một phần | Che mặc định; nút "Xem đầy đủ" yêu cầu `PERM-09-unmask` (D02-08), lý do, sinh bản ghi kiểm toán, hiển thị tối đa 60 giây |
| Xuất tệp | Đầy đủ | Theo quyền | Theo quyền | Che, trừ khi có quyền và nêu lý do (FR-00-034); tệp xuất có thủy vân tên người xuất và mã truy vết |
| Bộ nhớ đệm | Được | Được | Được, TTL ≤ 15 phút, khóa có tiền tố tenant | Không lưu giá trị rõ trong Valkey |
| Môi trường DEV/TEST | Được dùng dữ liệu thật | Được | Chỉ dữ liệu giả hoặc giả danh hóa | Cấm dữ liệu thật; chỉ dữ liệu sinh |
| Gửi cho PH-17 (AI) | Được | Được | Chỉ khi tenant bật và mô hình chạy nội bộ | Cấm |
| Thư điện tử, SMS | Được | Liên kết | Chỉ liên kết (FR-00-062) | Chỉ liên kết |
| Sao lưu | Mã hóa bản sao lưu (mặc định toàn hệ) | ← | ← | ← và trường vẫn ở dạng mã hóa trong bản sao lưu |
| Thời hạn lưu | Theo nghiệp vụ | Theo nghiệp vụ | Theo nghiệp vụ, có lịch xóa | Có thời hạn tường minh trong sổ xử lý PH-09; xóa hoặc giả danh hóa khi hết hạn |

: Bốn mức phân loại dữ liệu và cách xử lý theo mức

Dữ liệu **đi qua** (nội dung bản tin giữa HTTT) không được Datahub phân loại theo trường vì Datahub không hiểu hết nghiệp vụ của mọi bản tin; thay vào đó, mỗi API và mỗi topic được gán **mức phân loại của hợp đồng** bằng mức cao nhất của các trường trong schema đã đăng ký. Mức này quyết định yêu cầu xác thực bên khai thác (`SEC-24`), việc có ghi thân bản tin vào DLQ hay không (DLQ của hợp đồng mức Nhạy cảm được mã hóa bằng khóa riêng theo tenant và tự xóa sau tối đa 7 ngày, theo SAD §8.3), và việc có cần chấp thuận của chủ quản dữ liệu qua PH-09 khi đăng ký sử dụng hay không.

### 3.3. Ranh giới tin cậy và vùng mạng

Ranh giới tin cậy (trust boundary) là nơi dữ liệu đi từ vùng có mức tin cậy này sang vùng có mức tin cậy khác; mọi ranh giới phải có kiểm soát xác thực, ủy quyền và kiểm tra đầu vào. Datahub có tám vùng, đánh mã `Z0`…`Z7`. Vùng được hiện thực bằng tổ hợp: phân đoạn mạng vật lý hoặc VLAN ở tầng hạ tầng (D03-09), namespace Kubernetes, network policy Cilium từ chối mặc định và chính sách ủy quyền Istio.

| Vùng | Tên | Thành phần | Mức tin cậy | Kiểm soát vào |
|---|---|---|---|---|
| Z0 | Internet và mạng của bên ngoài | Người dùng, HTTT thành viên, nhà phát triển, PayGov, NDXP | Không tin | Chống DDoS, WAF, TLS |
| Z1 | Biên (DMZ) | `apisix-ext` kèm WAF Coraza (ADR-033), bộ cân bằng tải | Thấp | Chỉ 443/TCP vào; chỉ chuyển tới Z2 |
| Z2 | Cổng API | APISIX, BFF của `dh-console`/`dh-portal` | Trung bình | Xác thực token/mTLS, OPA, rate limit |
| Z3 | Ứng dụng control plane | 6 DU Spring Boot | Trung bình–cao | mTLS mesh, chính sách ủy quyền Istio theo service account |
| Z4 | Data plane runtime | `dh-runtime`, namespace `dh-rt-*` | Trung bình | mTLS; ra ngoài chỉ qua egress gateway với danh sách đích |
| Z5 | Dữ liệu | PostgreSQL, Kafka, Garage, Valkey | Cao | Chỉ nhận từ service account được liệt kê; TLS; RLS/ACL |
| Z6 | Bảo mật lõi | Keycloak (phần quản trị), OpenBao, OPA bundle server, kho WORM | Rất cao | Chỉ từ các service account liệt kê; truy cập người qua Z7 |
| Z7 | Quản trị | Bastion/PAM, Argo CD, Grafana quản trị, API server K8s | Rất cao | VPN quản trị + MFA + thiết bị được cấp phép; ở cấp độ 4 tách mạng out-of-band (`SEC-93`) |

: Tám vùng tin cậy Z0…Z7, thành phần, mức tin cậy và kiểm soát khi vào vùng

Vùng Z6 tách khỏi Z5 dù cùng là "dịch vụ dùng chung" vì sự cố ở Z6 (lộ khóa gốc OpenBao, chiếm quyền quản trị Keycloak) làm sụp toàn bộ mô hình tin cậy, trong khi sự cố ở Z5 giới hạn trong dữ liệu. Giao diện quản trị của Keycloak (`/admin`) không được công bố qua Z1; người dùng cuối chỉ thấy đường dẫn đăng nhập của realm.

```{.mermaid caption="Sơ đồ tám vùng tin cậy Z0…Z7 và đường đi của dữ liệu giữa các vùng"}
flowchart TB
  subgraph Z0[Z0 Internet / mạng ngoài]
    U[Người dùng]
    H[HTTT thành viên]
    PG0[PayGov]
    ND[NDXP]
  end
  subgraph Z1[Z1 Biên]
    EG[APISIX biên + WAF]
  end
  subgraph Z2[Z2 Cổng API]
    AP[APISIX]
    BFF[BFF console/portal]
  end
  subgraph Z3[Z3 Control plane]
    DU[6 DU Spring Boot]
  end
  subgraph Z4[Z4 Data plane]
    RT[dh-runtime]
    EGW[Egress gateway]
  end
  subgraph Z5[Z5 Dữ liệu]
    DB[(PostgreSQL)]
    KF[(Kafka)]
    S3[(Garage)]
    VK[(Valkey)]
  end
  subgraph Z6[Z6 Bảo mật lõi]
    KC[Keycloak]
    BAO[OpenBao]
    OPA[OPA bundle]
    WORM[(WORM)]
  end
  subgraph Z7[Z7 Quản trị]
    PAM[Bastion / PAM]
    ARGO[Argo CD]
  end
  U & H & PG0 -->|443 TLS| EG
  EG --> AP & BFF
  BFF --> AP
  AP --> DU & RT
  DU --> DB & KF & S3 & VK
  RT --> KF
  DU & RT --> BAO
  AP & DU --> KC
  DU & RT -->|egress có danh sách| EGW --> ND & PG0
  DU -.->|nhật ký| WORM
  PAM --> ARGO --> DU & RT
  PAM -.->|phiên ghi lại| DB
```

Sơ đồ cho thấy không có đường nào từ Z0 đi thẳng vào Z3 trở xuống mà không qua Z1 và Z2; không có đường ra Internet nào ngoài egress gateway; và truy cập của con người vào hạ tầng chỉ đi qua Z7. Mũi tên từ PAM tới CSDL là nét đứt vì đó là ngoại lệ break-glass có ghi phiên (`SEC-28`), không phải đường vận hành thường xuyên. Ở hồ sơ nền tảng dùng chung, Z1 và Z7 thường do bên cung cấp cloud vận hành một phần; trách nhiệm được phân ở mục 12.

## 4. Mô hình mối đe dọa

### 4.1. Phương pháp

Mô hình mối đe dọa dùng phương pháp STRIDE trên sơ đồ luồng dữ liệu (DFD) mức 1. STRIDE phân loại mối đe dọa thành sáu nhóm, mỗi nhóm vi phạm một thuộc tính an toàn: **S**poofing – giả mạo (vi phạm tính xác thực), **T**ampering – sửa đổi trái phép (toàn vẹn), **R**epudiation – chối bỏ (không chối bỏ được), **I**nformation disclosure – lộ lọt thông tin (bí mật), **D**enial of service – từ chối dịch vụ (sẵn sàng), **E**levation of privilege – leo thang đặc quyền (ủy quyền). Mỗi phần tử của DFD (tác nhân ngoài, tiến trình, kho dữ liệu, luồng dữ liệu) và đặc biệt mỗi điểm cắt ranh giới tin cậy được duyệt qua cả sáu nhóm.

Mỗi mối đe dọa được đánh mã `THR-nn` (loại mã mới, đề xuất bổ sung D00-01, xem mục 14) và được đánh giá bằng ma trận 5×5. **Khả năng** (K) xảy ra cho điểm 1 (hiếm: cần năng lực cấp quốc gia và nhiều điều kiện) đến 5 (gần như chắc chắn: công cụ tự động trên Internet đang khai thác). **Tác động** (T) cho điểm 1 (không đáng kể) đến 5 (nghiêm trọng: lộ dữ liệu cá nhân hàng loạt, gián đoạn dịch vụ công toàn tỉnh trên 4 giờ, thiệt hại tài chính, rò rỉ chéo tenant). **Mức rủi ro** R = K × T được xếp loại như bảng sau.

| Điểm R | Mức | Yêu cầu xử lý |
|---|---|---|
| 1–4 | Thấp (TH) | Chấp nhận, theo dõi trong đánh giá rủi ro hằng năm |
| 5–9 | Trung bình (TB) | Có biện pháp trước khi vận hành chính thức |
| 10–16 | Cao (C) | Có biện pháp trước MVP; rủi ro tồn dư phải ≤ TB |
| 20–25 | Nghiêm trọng (NT) | Chặn phát hành cho tới khi rủi ro tồn dư ≤ TB; chủ quản ký chấp nhận nếu không đạt |

: Thang xếp loại mức rủi ro theo điểm R và yêu cầu xử lý

Bảng ma trận dưới đây cho thấy mức của từng ô (hàng là khả năng, cột là tác động), để người đọc tra nhanh.

| K \ T | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| **5** | TB 5 | C 10 | C 15 | NT 20 | NT 25 |
| **4** | TH 4 | TB 8 | C 12 | C 16 | NT 20 |
| **3** | TH 3 | TB 6 | TB 9 | C 12 | C 15 |
| **2** | TH 2 | TH 4 | TB 6 | TB 8 | C 10 |
| **1** | TH 1 | TH 2 | TH 3 | TH 4 | TB 5 |

: Ma trận rủi ro 5×5 theo khả năng (K) và tác động (T)

Cột "Mức" trong bảng mối đe dọa là **rủi ro gốc** (trước biện pháp); cột "Tồn dư" là rủi ro sau khi áp dụng các biện pháp `SEC-nn` được liệt kê, ước lượng bằng cách giảm khả năng (biện pháp phòng ngừa) hoặc tác động (biện pháp hạn chế, phát hiện, phục hồi). Mô hình được rà soát lại khi thêm phân hệ, thêm loại kết nối ngoài, hoặc tối thiểu mỗi 6 tháng (`SEC-06`).

### 4.2. Sơ đồ luồng dữ liệu mức 1

Sơ đồ dưới đây là nền của toàn bộ mô hình mối đe dọa: nó đặt các tiến trình, kho dữ liệu, tác nhân ngoài và luồng dữ liệu của Datahub lên năm ranh giới tin cậy. Năm ranh giới này là cách nhìn theo luồng dữ liệu của tám vùng Z0…Z7 ở mục 3.3 (ranh giới 1 và 2 ứng với Z0 đến Z2, ranh giới 3 và 4 ứng với Z3 đến Z6, ranh giới 5 ứng với chuỗi cung ứng và Z7).

```{.mermaid caption="Sơ đồ luồng dữ liệu mức 1 với năm ranh giới tin cậy"}
flowchart TB
  classDef ext fill:#fff,stroke:#999,stroke-dasharray: 4 2
  U([Người dùng<br/>trình duyệt]):::ext
  H([HTTT thành viên]):::ext
  PAY([PayGov]):::ext
  NDXP([NDXP]):::ext
  LLM([Mô hình AI ngoài<br/>nếu tỉnh cho phép]):::ext
  subgraph TB1[Ranh giới 1: Internet → Biên]
    WAF[P1 APISIX + WAF]
  end
  subgraph TB2[Ranh giới 2: Biên → Cổng]
    BFF[P2 BFF console/portal]
    GW[P3 APISIX + OPA]
  end
  subgraph TB3[Ranh giới 3: Cổng → Ứng dụng]
    CP[P4 DU control plane]
    PAYD[P5 dh-payment]
    AST[P6 dh-assist]
    RT[P7 dh-runtime Camel]
  end
  subgraph TB4[Ranh giới 4: Ứng dụng → Dữ liệu và bảo mật lõi]
    DB[(D1 PostgreSQL RLS)]
    KF[(D2 Kafka)]
    S3[(D3 Garage)]
    BAO[(D4 OpenBao)]
    AUD[(D5 Nhật ký kiểm toán + WORM)]
    KC[P8 Keycloak]
  end
  subgraph TB5[Ranh giới 5: Chuỗi cung ứng và GitOps]
    GIT[(D6 Git cấu hình)]
    CI[P9 CI + Harbor]
    ARGO[P10 Argo CD]
  end
  U -->|F1 HTTPS phiên| WAF --> BFF
  H -->|F2 HTTPS token/mTLS| WAF --> GW
  PAY -->|F3 callback ký| WAF
  BFF -->|F4 token phía máy chủ| GW
  GW -->|F5 mTLS mesh| CP & PAYD & AST & RT
  U -.->|F6 OIDC| KC
  CP & PAYD --> DB
  CP & RT <--> KF
  CP -->|F7 tệp nhập/xuất| S3
  CP & PAYD & RT -->|F8 khóa, bí mật| BAO
  CP & PAYD & RT -.->|F9 sự kiện kiểm toán| AUD
  CP -->|F10 YAML luồng đã duyệt| GIT
  CI -->|F11 ảnh đã ký| ARGO
  GIT --> ARGO -->|F12 đồng bộ| RT & CP
  RT & PAYD -->|F13 egress| NDXP & PAY
  AST -.->|F14 prompt đã lọc| LLM
  RT -->|F15 webhook ký| H
```

DFD mức 1 gồm 10 tiến trình (P1–P10), 6 kho dữ liệu (D1–D6), 5 tác nhân ngoài và 15 luồng (F1–F15) cắt qua 5 ranh giới tin cậy. Các luồng cắt ranh giới quan trọng nhất là F2 (HTTT vào cổng, nơi xác thực máy–máy), F3 (callback thanh toán, nơi có động cơ tài chính), F7 (tệp do người dùng tải lên, nơi phân tích cú pháp dữ liệu không tin cậy), F10–F12 (đường mã và cấu hình đi vào môi trường chạy, nơi một lần xâm phạm ảnh hưởng mọi tenant), F13 (ra ngoài, nơi SSRF và rò rỉ dữ liệu có thể xảy ra) và F14 (ra mô hình AI). Mỗi mối đe dọa ở mục 4.4 ghi phần tử DFD bị nhắm tới.

### 4.3. Tác nhân đe dọa

Bảng dưới đây mô tả các tác nhân đe dọa được xét, động cơ và năng lực giả định. Năng lực giả định là cơ sở chọn mức khả năng ở mục 4.4; thiết kế cấp độ 3 phải chống được tác nhân có năng lực đến mức "cao" ở bảng này, còn tác nhân cấp quốc gia (APT) được xử lý bằng phát hiện và ứng phó nhiều hơn là ngăn chặn tuyệt đối, và được tăng cường khi lên cấp độ 4.

| Mã | Tác nhân | Động cơ | Năng lực | Điểm vào điển hình |
|---|---|---|---|---|
| TA-01 | Kẻ tấn công từ Internet (tội phạm mạng, hacktivist) | Tống tiền (ransomware), bán dữ liệu cá nhân, phá hoại hình ảnh | Trung bình–cao; dùng công cụ quét tự động, khai thác lỗ hổng đã công bố, nhồi thông tin xác thực | F1, F2, F3; thư điện tử lừa đảo cán bộ |
| TA-02 | HTTT thành viên bị chiếm quyền | Kẻ tấn công dùng định danh hợp lệ của HTTT để khai thác dữ liệu vượt phạm vi | Cao trong phạm vi quyền của HTTT đó; có token, có thể có khóa client | F2, F15 |
| TA-03 | Quản trị tỉnh độc hại hoặc bị lừa | Lấy dữ liệu tỉnh khác, che giấu sai phạm, bán dữ liệu | Có quyền quản trị realm và cấu hình tenant | F1, giao diện quản trị |
| TA-04 | Nhà thầu HTTT, kỹ sư tích hợp bên ngoài | Lấy dữ liệu, cài cửa hậu trong luồng tích hợp | Có quyền thiết kế luồng, có thể có quyền chạy thử | Trình thiết kế luồng, F7 |
| TA-05 | Nội gián nền tảng (nhân sự vận hành, phát triển của nhà cung cấp) | Tài chính, bị ép buộc, bất mãn | Rất cao: truy cập hạ tầng, CI, kho Git | Z7, F10–F12, CSDL |
| TA-06 | Tenant khác trên nền tảng dùng chung | Tò mò hoặc cố ý đọc dữ liệu tỉnh khác; gây quá tải | Người dùng hợp lệ của tenant khác | API, Kafka, tài nguyên chung |
| TA-07 | Kẻ tấn công chuỗi cung ứng | Cài mã độc vào thư viện, ảnh nền, công cụ CI | Cao; có thể ở cấp quốc gia | Phụ thuộc Maven/npm, ảnh gốc, plugin CI |
| TA-08 | Kẻ gian lận thanh toán | Ghi nhận giao dịch "đã thanh toán" mà không trả tiền, hoàn tiền trái phép | Trung bình; có thể có người trong cuộc | F3, PH-19 giao diện đối soát |
| TA-09 | Tác nhân cấp quốc gia (APT) | Gián điệp, thu thập dữ liệu dân cư | Rất cao, kiên nhẫn | Mọi điểm, đặc biệt chuỗi cung ứng và quản trị |

: Chín tác nhân đe dọa TA-01…TA-09: động cơ, năng lực, điểm vào

### 4.4. Danh mục mối đe dọa

Danh mục được trình bày theo thành phần. Mỗi bảng có câu dẫn nêu đặc thù của thành phần. Các biện pháp `SEC-nn` được định nghĩa ở mục 5; mục tiêu ở đây là cho thấy mỗi biện pháp tồn tại vì chống lại mối đe dọa nào.

#### 4.4.1. Biên và cổng API (P1, P3, F1, F2)

Biên là nơi Datahub tiếp xúc với Internet, nên khả năng bị tấn công luôn cao; các mối đe dọa tập trung vào giả mạo client, vượt qua kiểm soát truy cập ở tầng API (lớp lỗi phổ biến nhất theo OWASP API Top 10) và làm cạn tài nguyên.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-01 | D | Tấn công DDoS thể tích hoặc tầng 7 (HTTP flood) làm cổng không phục vụ được, gián đoạn dịch vụ công | P1, P3 | 4 | 4 | C 16 | SEC-10, SEC-11, SEC-86, SEC-71 | TB 8 |
| THR-02 | S | Kẻ tấn công dùng `client_secret` bị lộ (từ mã nguồn của nhà thầu, tệp cấu hình) để gọi API như HTTT hợp lệ | F2 | 4 | 4 | C 16 | SEC-24 (mTLS/private_key_jwt bắt buộc cho hợp đồng Hạn chế trở lên), SEC-25, SEC-64 | TB 6 |
| THR-03 | E | Lỗi ủy quyền mức đối tượng (BOLA): HTTT A đổi mã đối tượng trên đường dẫn để đọc bản ghi của HTTT B cùng tenant | P3, P4 | 4 | 4 | C 16 | SEC-26 (OPA kiểm tra chủ sở hữu đối tượng), SEC-43, SEC-42 | TB 6 |
| THR-04 | E | Gọi đường dẫn quản trị hoặc phương thức HTTP không được công bố (lỗi ủy quyền mức chức năng) qua APISIX | P3 | 3 | 4 | C 12 | SEC-26, SEC-43 (chỉ route khai báo trong OpenAPI được đồng bộ), SEC-11 | TH 4 |
| THR-05 | I | Lộ thông tin qua thông báo lỗi chi tiết, header phiên bản, endpoint `/actuator`, Admin API APISIX bị công bố ra ngoài | P3 | 4 | 3 | C 12 | SEC-43 (RFC 9457 không stack trace), SEC-14 (Admin API chỉ trong Z3), SEC-11 | TH 3 |
| THR-06 | T | Tiêm header nội bộ `X-DH-Tenant`, `X-Forwarded-For` giả để đổi tenant hoặc vượt `ip-restriction` | P3 | 3 | 5 | C 15 | SEC-80 (xóa header client gửi, tenant chỉ từ token), SEC-15 | TH 3 |
| THR-07 | D | Một HTTT hoặc một tenant gửi lưu lượng lớn hợp lệ làm chậm tenant khác (hàng xóm ồn ào) | P3, P7 | 4 | 3 | C 12 | SEC-86, SEC-10 | TH 4 |
| THR-08 | T | Hạ cấp TLS hoặc dùng bộ mã yếu với HTTT cũ để nghe lén/sửa nội dung | F2 | 2 | 4 | TB 8 | SEC-12 | TH 2 |

: Mối đe dọa tại biên và cổng API

#### 4.4.2. Giao diện và BFF (P2, F1, F6)

Giao diện quản trị là đường vào của những người có quyền cao nhất, nên chiếm phiên của một quản trị viên tương đương chiếm cả tenant.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-09 | S | Lừa đảo (phishing) lấy mật khẩu quản trị tỉnh, đăng nhập từ nơi khác | F6 | 4 | 5 | NT 20 | SEC-23 (WebAuthn cho quản trị), SEC-22, SEC-64, SEC-03 | TB 5 |
| THR-10 | I | XSS (kể cả qua tên danh mục, mô tả API do người dùng nhập) đánh cắp token trong trình duyệt | P2 | 3 | 5 | C 15 | SEC-21 (BFF, token không ở trình duyệt), SEC-44 (CSP nghiêm ngặt), SEC-41 | TH 3 |
| THR-11 | T | CSRF ép người dùng đã đăng nhập thực hiện thao tác (duyệt, phát hành) | P2 | 3 | 4 | C 12 | SEC-44 (cookie `SameSite=Strict`, token CSRF, kiểm tra `Origin`) | TH 2 |
| THR-12 | S | Nhồi thông tin xác thực (credential stuffing) và dò mật khẩu vào realm | F6 | 5 | 3 | C 15 | SEC-22 (khóa tạm, danh sách mật khẩu lộ), SEC-23, SEC-10 | TH 3 |
| THR-13 | E | Phiên bị bỏ quên trên máy dùng chung tại xã; người khác tiếp tục thao tác | P2 | 3 | 4 | C 12 | SEC-29 (tự khóa 15 phút), SEC-23 (bước xác thực lại cho thao tác nhạy cảm) | TH 3 |

: Mối đe dọa tại giao diện và BFF

#### 4.4.3. Control plane, quy trình duyệt và trình thiết kế luồng (P4, P7)

Trình thiết kế luồng cho phép người dùng mô tả logic chạy trên data plane; nếu không kiểm soát, đây là một cách "thực thi mã từ xa có giấy phép". Camel hỗ trợ nhiều ngôn ngữ biểu thức (Simple, Groovy, JavaScript, OGNL, MVEL, JQ, XPath) và nhiều component có thể đọc tệp, chạy lệnh, mở kết nối tùy ý.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-14 | E | Kỹ sư tích hợp viết biểu thức Groovy/JavaScript/OGNL hoặc dùng component `exec`, `file`, `bean`, `class` để chạy lệnh trên pod runtime | P7 | 3 | 5 | C 15 | SEC-46 (danh sách trắng component và ngôn ngữ, kiểm tra tĩnh YAML), SEC-52, SEC-83 | TH 3 |
| THR-15 | I | SSRF: luồng gọi URL do người dùng cấu hình tới dịch vụ nội bộ (API server K8s, OpenBao, siêu dữ liệu cloud `169.254.169.254`) | P7, F13 | 4 | 5 | NT 20 | SEC-46 (đích HTTP phải là kết nối đã đăng ký), SEC-16 (egress danh sách), SEC-14 | TB 5 |
| THR-16 | E | Tự phát hành luồng mà không qua duyệt, hoặc người tạo tự duyệt | P4, F10 | 3 | 4 | C 12 | SEC-07 (bốn mắt FR-00-071), SEC-59 (chỉ `dh-integration` ghi Git, nhánh được bảo vệ) | TH 3 |
| THR-17 | T | Biểu thức JQ/JSONata gây vòng lặp vô hạn hoặc tiêu tốn bộ nhớ, làm sập runtime dùng chung | P7 | 3 | 3 | TB 9 | SEC-46 (giới hạn thời gian, kích thước), SEC-83 (giới hạn tài nguyên theo namespace) | TH 3 |
| THR-18 | I | Luồng ghi thân bản tin chứa dữ liệu Nhạy cảm vào log bằng bước `log` | P7 | 4 | 4 | C 16 | SEC-32 (bộ che ở OTel Collector và Logback), SEC-46 (lint cấm `log` thân bản tin hợp đồng Nhạy cảm) | TB 6 |
| THR-19 | R | Người dùng phủ nhận đã duyệt, sửa cấu hình, xem dữ liệu Nhạy cảm | P4 | 3 | 3 | TB 9 | SEC-60, SEC-62 | TH 2 |

: Mối đe dọa tại control plane, quy trình duyệt và trình thiết kế luồng

#### 4.4.4. Nhập tệp Excel/CSV và xử lý tài liệu (F7)

Nhập tệp là nơi phân tích cú pháp dữ liệu không tin cậy với thư viện phức tạp (Apache POI, bộ phân tích XML), và tệp xuất lại được mở trong Excel của cán bộ.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-20 | T | Tiêm công thức CSV/Excel (`=HYPERLINK`, `=cmd|…`, `+`, `-`, `@`) vào danh mục; khi cán bộ khác xuất và mở tệp, công thức chạy | F7 | 4 | 3 | C 12 | SEC-45 (thoát ký tự đầu ô khi xuất, kiểm tra khi nhập) | TH 3 |
| THR-21 | I | XXE trong .xlsx (là gói XML) hoặc XML/SOAP đầu vào: đọc tệp hệ thống, SSRF | F7, P7 | 3 | 4 | C 12 | SEC-45, SEC-43 (bộ phân tích XML tắt DTD và thực thể ngoài) | TH 2 |
| THR-22 | D | Bom nén (zip bomb) .xlsx, tệp rất nhiều dòng hoặc ô làm cạn bộ nhớ DU | F7 | 4 | 3 | C 12 | SEC-45 (giới hạn tỉ lệ nén, kích thước giải nén, số dòng; xử lý dạng luồng), SEC-83 | TH 3 |
| THR-23 | T | Tải lên tệp chứa mã độc, được lưu ở Garage và phát tán tới người tải về | F7 | 3 | 3 | TB 9 | SEC-45 (quét ClamAV, kiểm tra kiểu theo nội dung), SEC-54 | TH 3 |

: Mối đe dọa khi nhập tệp Excel/CSV và xử lý tài liệu

#### 4.4.5. Sự kiện Kafka và webhook (D2, F15)

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-24 | S | HTTT phát sự kiện giả vào topic của HTTT khác (giả mạo bên phát) | D2 | 3 | 4 | C 12 | SEC-82 (ACL theo principal và tiền tố), SEC-15, SEC-18 | TH 3 |
| THR-25 | I | Consumer của tenant B đọc topic tenant A do ACL tiền tố sai | D2 | 2 | 5 | C 10 | SEC-82, SEC-87 (kiểm thử ACL tự động khi khởi tạo tenant) | TH 4 |
| THR-26 | S | Kẻ tấn công giả mạo webhook của Datahub gửi tới HTTT, hoặc phát lại webhook cũ | F15 | 3 | 4 | C 12 | SEC-47 (HMAC-SHA256, dấu thời gian ±5 phút, `webhook-id` duy nhất) | TH 3 |
| THR-27 | I | URL webhook do HTTT khai báo trỏ vào địa chỉ nội bộ (SSRF qua webhook) | F15 | 3 | 4 | C 12 | SEC-47 (kiểm tra đích, chặn dải nội bộ, chỉ HTTPS), SEC-16 | TH 3 |
| THR-28 | T | Đầu độc schema: đăng ký schema mới làm hỏng consumer hoặc lách kiểm tra | D2 | 2 | 3 | TB 6 | SEC-82 (nhóm Apicurio theo tenant, quy tắc tương thích), SEC-07 | TH 2 |

: Mối đe dọa với sự kiện Kafka và webhook

#### 4.4.6. Dữ liệu, CSDL và đa tenant (D1, D3)

Rò rỉ chéo tenant là mối đe dọa có tác động lớn nhất với sản phẩm đa tỉnh, vì một sự cố làm mất niềm tin của mọi tỉnh cùng lúc và là vi phạm DLCN ở quy mô lớn.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-29 | I | Lỗi lập trình (truy vấn native, kết nối ngoài `DataSource`, tác vụ nền quên `TenantContext`) làm đọc dữ liệu tenant khác | D1 | 3 | 5 | C 15 | SEC-81 (RLS `FORCE`, vai trò không `BYPASSRLS`, `current_setting(...,false)`), SEC-87, SEC-41 | TH 4 |
| THR-30 | I | Biến phiên `app.tenant_id` còn sót trên kết nối trả về pool, giao dịch sau dùng nhầm tenant | D1 | 3 | 5 | C 15 | SEC-81 (`SET LOCAL` trong giao dịch, kiểm tra khi lấy kết nối), SEC-87 | TH 3 |
| THR-31 | I | Bộ nhớ đệm Valkey dùng khóa thiếu tiền tố tenant trả kết quả của tenant khác | AS-09 | 3 | 4 | C 12 | SEC-82 (hàm tạo khóa bắt buộc), SEC-87 | TH 3 |
| THR-32 | I | Kẻ tấn công lấy được bản sao lưu hoặc ổ đĩa (ví dụ khi thay thiết bị tại TTDL) | AS-17 | 2 | 5 | C 10 | SEC-30, SEC-31, SEC-39 (xóa an toàn thiết bị) | TH 2 |
| THR-33 | I | Quản trị CSDL đọc trực tiếp bảng chứa số định danh, dữ liệu sức khỏe | D1 | 3 | 5 | C 15 | SEC-31 (mã hóa trường, khóa ở OpenBao), SEC-28, SEC-61 (pgaudit) | TB 5 |
| THR-34 | T | Sửa trực tiếp hoặc xóa bản ghi nhật ký kiểm toán để che dấu vết | D5 | 3 | 4 | C 12 | SEC-62 (chuỗi băm, neo, WORM Object Lock chế độ tuân thủ) | TH 2 |
| THR-35 | I | Tenant khác suy ra sự tồn tại của dữ liệu qua mã lỗi `403` thay vì `404`, qua thời gian phản hồi hay qua bộ đếm | P4 | 3 | 2 | TB 6 | SEC-85, SEC-87 (kỳ vọng `404`) | TH 2 |

: Mối đe dọa với dữ liệu, CSDL và cách ly đa tenant

#### 4.4.7. Bảo mật lõi: OpenBao, Keycloak, OPA (D4, P8)

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-36 | I | Lộ token gốc (root token) hoặc khóa mở niêm phong OpenBao; kẻ tấn công đọc mọi bí mật | D4 | 2 | 5 | C 10 | SEC-33 (thu hồi root token sau khởi tạo, Shamir 3/5 hoặc auto-unseal), SEC-34, SEC-28, SEC-90 (cấp độ 4) | TB 5 |
| THR-37 | E | Service account của một DU bị chiếm được dùng để đọc bí mật của DU/tenant khác trong OpenBao | D4 | 3 | 4 | C 12 | SEC-33 (chính sách theo service account và đường dẫn tenant), SEC-53 | TH 3 |
| THR-38 | E | Quản trị tỉnh tự cấp vai trò nền tảng, sửa cấu hình realm (tắt MFA), tạo client có scope rộng | P8 | 3 | 5 | C 15 | SEC-20 (quản trị tỉnh không có `manage-realm` đầy đủ; cấu hình bảo mật realm do GitOps quản), SEC-65, SEC-60 | TB 5 |
| THR-39 | T | Sửa gói chính sách OPA để cho phép truy cập trái phép | AS-12 | 2 | 5 | C 10 | SEC-26 (bundle ký, xác minh chữ ký), SEC-07, SEC-58 | TH 3 |
| THR-40 | D | Keycloak hoặc OPA không sẵn sàng làm toàn bộ API từ chối | P8 | 3 | 4 | C 12 | SEC-25 (xác minh JWT cục bộ bằng JWKS bộ đệm), SEC-26 (OPA chạy cạnh, bundle nạp sẵn), SEC-71 | TH 4 |

: Mối đe dọa với OpenBao, Keycloak và OPA

#### 4.4.8. Chuỗi cung ứng, CI/CD và GitOps (P9, P10, D6)

Một lần xâm phạm ở chuỗi cung ứng tác động tới mọi tenant và mọi tỉnh tự vận hành dùng cùng bản phát hành, nên tác động luôn được chấm 5.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-41 | T | Thư viện Maven/npm bị cài mã độc hoặc nhầm tên (typosquatting) đi vào bản dựng | P9 | 3 | 5 | C 15 | SEC-41 (SCA, khóa phiên bản, kho trung gian), SEC-55 (SBOM), SEC-57 | TB 5 |
| THR-42 | T | Ảnh container không qua CI (đẩy tay, ảnh từ Docker Hub) chạy trong cụm | P10 | 3 | 5 | C 15 | SEC-56 (Kyverno chỉ cho ảnh ký từ Harbor), SEC-52 | TH 3 |
| THR-43 | E | Runner CI bị chiếm, lấy khóa ký hoặc thông tin đẩy ảnh | P9 | 2 | 5 | C 10 | SEC-58 (runner tạm thời, OIDC không bí mật dài hạn), SEC-56 (cosign khóa trong OpenBao/keyless nội bộ) | TB 5 |
| THR-44 | T | Commit trực tiếp vào kho Git cấu hình PROD, Argo CD đồng bộ thay đổi độc hại | D6, P10 | 2 | 5 | C 10 | SEC-58 (bảo vệ nhánh, ký commit, review bắt buộc), SEC-59 (dự án Argo CD giới hạn nguồn và đích), SEC-07 | TH 4 |
| THR-45 | E | Lỗ hổng 0-day trong thư viện phổ biến (lớp sự cố như Log4Shell) bị khai thác hàng loạt | P4, P7 | 3 | 5 | C 15 | SEC-09 (SLA vá), SEC-11 (luật ảo hóa vá tại WAF), SEC-16 (chặn egress làm vô hiệu nhiều chuỗi khai thác), SEC-54, SEC-73 | TB 6 |

: Mối đe dọa với chuỗi cung ứng, CI/CD và GitOps

#### 4.4.9. Thanh toán PH-19 (P5, F3)

PH-19 có động cơ tài chính trực tiếp: kẻ gian chỉ cần làm Datahub ghi nhận "đã thanh toán" để hồ sơ thủ tục được xử lý mà không nộp tiền, hoặc tạo lệnh hoàn tiền trái phép.

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-46 | S | Giả mạo callback PayGov báo giao dịch thành công | F3 | 4 | 5 | NT 20 | SEC-48 (xác minh chữ ký theo đặc tả PayGov, mTLS/danh sách nguồn nếu PayGov hỗ trợ, truy vấn ngược trạng thái trước khi ghi nhận), SEC-67 | TB 5 |
| THR-47 | T | Phát lại callback hợp lệ cũ cho giao dịch khác hoặc nhiều lần | F3 | 4 | 4 | C 16 | SEC-48 (idempotency theo mã giao dịch nhà cung cấp, kiểm tra dấu thời gian, trạng thái máy hữu hạn) | TH 4 |
| THR-48 | T | Sai lệch số tiền: callback báo thành công với số tiền khác số tiền yêu cầu (sửa tham số chuyển hướng trình duyệt) | F3 | 3 | 5 | C 15 | SEC-48 (so khớp số tiền, đơn vị tiền, mã dịch vụ với bản ghi gốc; không tin tham số trên URL quay về) | TH 3 |
| THR-49 | E | Cán bộ đối soát tạo và tự duyệt lệnh hoàn tiền trái phép | P5 | 2 | 5 | C 10 | SEC-07 (bốn mắt), SEC-28, SEC-60, SEC-67 (cảnh báo hoàn tiền bất thường) | TH 4 |
| THR-50 | I | Lộ khóa ký/khóa bí mật với kênh thanh toán | AS-19 | 2 | 5 | C 10 | SEC-36 (khóa ký trong transit, không xuất), SEC-33 | TH 4 |

: Mối đe dọa với thanh toán PH-19

#### 4.4.10. Kết nối quốc gia PH-14 (F13)

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-51 | E | HTTT tỉnh khai thác CSDL quốc gia vượt mục đích đã đăng ký (tra cứu hàng loạt dân cư) qua thông tin xác thực NDXP dùng chung của tỉnh | F13 | 3 | 5 | C 15 | SEC-26 (OPA theo mục đích), SEC-37 (PH-09 mục đích, chấp thuận), SEC-86 (hạn ngạch theo HTTT), SEC-64 (cảnh báo tra cứu hàng loạt) | TB 6 |
| THR-52 | I | Lộ thông tin xác thực NDXP của tỉnh, bị dùng ngoài Datahub | AS-19 | 2 | 5 | C 10 | SEC-33, SEC-24 (mTLS với NDXP nếu được hỗ trợ), SEC-16 | TB 5 |
| THR-53 | S | Giả mạo NDXP (DNS hoặc trung gian) trả dữ liệu sai | F13 | 2 | 4 | TB 8 | SEC-12 (xác minh chứng thư, ghim CA), SEC-17 | TH 2 |
| THR-54 | R | Không chứng minh được HTTT nào đã tra cứu dữ liệu quốc gia khi có khiếu nại | F13 | 3 | 4 | C 12 | SEC-60 (ghi HTTT gốc, mục đích, băm khóa tra cứu), SEC-62 | TH 2 |

: Mối đe dọa với kết nối quốc gia PH-14

#### 4.4.11. Trợ lý AI PH-17 (P6, F14)

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-55 | E | Tiêm lệnh gián tiếp (indirect prompt injection) qua mô tả API, tên danh mục, nội dung log được đưa vào ngữ cảnh, khiến trợ lý gọi công cụ ngoài ý người dùng | P6 | 4 | 3 | C 12 | SEC-49 (công cụ chỉ đọc, thực thi với quyền của người dùng hiện tại, xác nhận người dùng cho mọi hành động ghi) | TH 4 |
| THR-56 | I | Rò rỉ dữ liệu: trợ lý trả lời bằng dữ liệu của tenant khác hoặc dữ liệu Nhạy cảm trong chỉ mục pgvector | P6 | 3 | 5 | C 15 | SEC-49 (chỉ mục theo tenant có RLS, không lập chỉ mục dữ liệu Hạn chế/Nhạy cảm), SEC-81 | TH 4 |
| THR-57 | I | Gửi dữ liệu ra mô hình bên ngoài nằm ngoài lãnh thổ hoặc nhà cung cấp lưu lại để huấn luyện | F14 | 3 | 4 | C 12 | SEC-49 (mặc định mô hình nội bộ; mô hình ngoài cần tenant bật và cam kết hợp đồng), SEC-16, SEC-32 | TH 3 |

: Mối đe dọa với trợ lý AI PH-17

#### 4.4.12. Hạ tầng và vận hành (AS-18, Z7)

| Mã | STRIDE | Kịch bản | Phần tử | K | T | Mức | Biện pháp | Tồn dư |
|---|---|---|---|---|---|---|---|---|
| THR-58 | E | Thoát khỏi container (container escape) qua pod đặc quyền hoặc lỗ hổng kernel, chiếm nút | AS-18 | 2 | 5 | C 10 | SEC-52 (restricted, không privileged, seccomp), SEC-50, SEC-54 | TH 4 |
| THR-59 | D/T | Ransomware mã hóa volume, xóa bản sao lưu trực tuyến | AS-06, AS-17 | 3 | 5 | C 15 | SEC-70 (sao lưu bất biến ngoài site, tài khoản tách biệt), SEC-71, SEC-28 | TB 5 |
| THR-60 | E | Chiếm tài khoản quản trị cụm (kubeconfig lộ) | Z7 | 2 | 5 | C 10 | SEC-19 (OIDC cho API server, không kubeconfig tĩnh), SEC-28, SEC-53 | TB 5 |
| THR-61 | R | Nội gián nền tảng thao tác trên PROD rồi xóa dấu vết | Z7 | 2 | 4 | TB 8 | SEC-61 (audit log K8s ra WORM), SEC-28 (ghi phiên), SEC-62 | TH 2 |
| THR-62 | I | Đọc Secret Kubernetes trong etcd hoặc bản sao lưu etcd | AS-18 | 2 | 5 | C 10 | SEC-51 (mã hóa etcd bằng KMS provider), SEC-33 (bí mật quan trọng không đặt tĩnh trong Secret) | TH 4 |

: Mối đe dọa với hạ tầng và vận hành

Tổng cộng có 62 mối đe dọa; trước biện pháp có 3 mối đe dọa mức Nghiêm trọng (THR-09, THR-15, THR-46), 51 mức Cao và 8 mức Trung bình. Sau biện pháp không còn mối đe dọa ở mức Cao trở lên; 17 mối đe dọa còn ở mức Trung bình và được theo dõi trong sổ rủi ro (D01-02). Rủi ro tồn dư Trung bình chủ yếu thuộc ba loại: tấn công do con người (lừa đảo, nội gián) mà biện pháp kỹ thuật chỉ giảm chứ không loại trừ; phụ thuộc vào năng lực của bên ngoài (đặc tả bảo mật của PayGov, NDXP); và tác nhân cấp quốc gia. Nhóm thứ ba là lý do chính để giữ lộ trình cấp độ 4 (mục 10).

> **Câu hỏi mở Q302:** Đặc tả kỹ thuật hiện hành của PayGov quy định cơ chế bảo vệ callback cụ thể nào (thuật toán chữ ký, chứng thư, danh sách IP nguồn, API truy vấn trạng thái)? THR-46 giả định có API truy vấn ngược; nếu không có, tồn dư tăng lên Cao và cần biện pháp bù (đối soát tệp trong ngày trước khi xác nhận hồ sơ).

## 5. Danh mục biện pháp an toàn thông tin

### 5.1. Cách đọc danh mục

Mỗi biện pháp có mã `SEC-nn`, tên, mô tả cách hiện thực trong ngăn xếp Datahub, tham số đo được, thành phần chịu trách nhiệm và cách kiểm chứng. Cột "Kiểm chứng" ghi loại hoạt động mà D05-01 phải lập ca kiểm thử: **CI** (kiểm tra tự động trong đường ống, chặn merge hoặc phát hành), **KT** (kiểm thử chức năng/bảo mật tự động ở môi trường thử), **PT** (kiểm thử xâm nhập), **RS** (rà soát cấu hình hoặc tài liệu bởi người), **DT** (diễn tập). Mỗi nhóm có một bảng tóm tắt và phần văn xuôi giải thích những biện pháp cần lập luận. Ngưỡng tham số được chọn **bằng hoặc chặt hơn** ngưỡng đã đọc được ở TCVN 14423:2026; nơi nào chặt hơn SRS thì được ghi ở mục 14 để sửa SRS.

Bảng ngưỡng tham số chính dưới đây gom các con số mà đội vận hành và hội đồng hay hỏi nhất về một chỗ, kèm so sánh với tham chiếu.

| Tham số | Giá trị thiết kế Datahub | Tham chiếu | Biện pháp |
|---|---|---|---|
| Tự khóa phiên giao diện khi không thao tác | 15 phút (cấu hình theo tenant trong khoảng 5–15 phút); cảnh báo trước 2 phút | TCVN 14423:2026 ≤ 15 phút (ngưỡng cấp 1 đã đọc); FR-00-003 hiện ghi 30 phút, 5–120 phút → **phải sửa** | SEC-29 |
| Thời gian sống tối đa của phiên đăng nhập | 10 giờ (một ca làm việc), sau đó đăng nhập lại | — | SEC-29 |
| Vô hiệu hóa tài khoản không hoạt động | 45 ngày cho người dùng; 30 ngày cho tài khoản quản trị; client máy không gọi trong 90 ngày bị tạm ngừng và thông báo đầu mối | TCVN 14423:2026: 45 ngày | SEC-27 |
| Độ dài mật khẩu | ≥ 14 ký tự cho mọi tài khoản cục bộ (kể cả khi có MFA); tối đa ≥ 64 ký tự; cho phép mọi ký tự Unicode | TCVN 14423:2026 ≥ 14 nếu không MFA; NFR-00-026 hiện ghi 12 → **đề xuất sửa thành 14** | SEC-22 |
| Khóa tài khoản do đăng nhập sai | Khóa tạm 15 phút sau 5 lần sai liên tiếp; khóa vĩnh viễn (cần quản trị mở) sau 3 lần khóa tạm trong 24 giờ | NFR-00-025 | SEC-22 |
| MFA | Bắt buộc với mọi vai trò `_ADMIN`, vai trò duyệt, cán bộ đối soát PH-19, mọi truy cập Z7; quản trị nền tảng và quản trị tỉnh bắt buộc WebAuthn (khóa phần cứng hoặc passkey) | FR-00-002 | SEC-23 |
| Thời hạn access token | Máy: 5 phút; người dùng (giữ ở BFF): 5 phút; refresh token người dùng: hết hạn khi phiên nhàn rỗi 15 phút, xoay vòng mỗi lần dùng | SAD §9 ghi 15 phút cho người → điều chỉnh xuống 5 phút vì BFF làm mới trong suốt | SEC-25 |
| Phiên bản TLS ở biên | TLS 1.3; TLS 1.2 chỉ với bộ mã ECDHE + AEAD cho HTTT cũ có đăng ký ngoại lệ | NFR-00-020 | SEC-12 |
| Hạn chứng thư | Chứng thư biên ≤ 90 ngày, gia hạn khi còn 30 ngày; chứng thư mesh 24 giờ; chứng thư client HTTT ≤ 1 năm | — | SEC-35 |
| Vá lỗ hổng | CRITICAL: ≤ 72 giờ (≤ 24 giờ nếu đang bị khai thác hoặc có trong danh sách KEV); HIGH: ≤ 7 ngày; MEDIUM: ≤ 30 ngày; vá định kỳ hệ điều hành nút ≥ 1 lần/tháng | TCVN 14423:2026: vá ≥ 1 lần/tháng | SEC-09 |
| Kiểm kê tài sản | Tự động hằng ngày; rà soát có ký xác nhận mỗi quý | TCVN 14423:2026: ≥ 1 lần/năm | SEC-04 |
| Rà soát quyền | Mỗi quý cho vai trò quản trị; mỗi 6 tháng cho vai trò khác | — | SEC-27 |
| Lưu nhật ký kiểm toán | Trực tuyến 12 tháng; lưu trữ WORM 5 năm (không dưới 3 năm khi tỉnh cấu hình) | Chốt Q08 của SRS, mục 7.3 | SEC-62 |
| Lưu log vận hành | Trực tuyến 90 ngày; log an ninh (xác thực, WAF, K8s audit) 12 tháng | NFR-00-028 | SEC-61 |
| Kiểm thử xâm nhập | Trước vận hành chính thức, trước mỗi phát hành lớn, và tối thiểu 1 lần/năm | — | SEC-08 |
| Diễn tập ứng phó sự cố | 2 lần/năm (một lần kỹ thuật, một lần trên bàn) | — | SEC-73 |
| Diễn tập khôi phục sao lưu | Mỗi quý | NFR-00-014 | SEC-70 |

: Ngưỡng tham số ATTT chính của Datahub và tham chiếu

### 5.2. Nhóm SEC-01…09: Quản trị, chính sách, tổ chức, nhân sự, nhà cung cấp

Các biện pháp quản lý thường bị coi nhẹ trong thiết kế kỹ thuật, nhưng TCVN 14423:2026 và TCVN 11930:2017 đều đặt chúng ngang hàng với biện pháp kỹ thuật, và phần lớn sự cố nghiêm trọng bắt đầu từ lỗ hổng quy trình. Datahub hiện thực chúng bằng tài liệu chính sách kèm công cụ tự động để chính sách không chỉ nằm trên giấy.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-01 | Chính sách và quy chế an ninh mạng | Bộ chính sách gồm: chính sách ATTT chung, quy chế quản lý tài khoản, quy chế sử dụng dữ liệu, quy chế ứng phó sự cố, quy chế làm việc với nhà cung cấp. Mẫu do nhà cung cấp sản phẩm soạn (D06-xx), chủ quản từng tỉnh ban hành | Ban hành trước vận hành chính thức; rà soát ≥ 1 lần/năm hoặc khi có thay đổi lớn | Chủ quản HTTT (ban hành), nhà cung cấp (soạn mẫu) | RS |
| SEC-02 | Tổ chức và bộ phận chuyên trách | Chủ quản chỉ định bộ phận/nhân sự chuyên trách an ninh mạng (NĐ 331/2026 Điều 31); có đầu mối ATTT ở đơn vị vận hành và ở nhà cung cấp; RACI tại mục 12 | Có quyết định phân công; đầu mối liên lạc 24/7 cho sự cố | Chủ quản | RS |
| SEC-03 | An ninh nhân sự và đào tạo | Kiểm tra lý lịch nhân sự có quyền Z7; cam kết bảo mật; đào tạo nhận thức ATTT khi nhận việc và hằng năm; diễn tập lừa đảo cho cán bộ quản trị; thu hồi mọi quyền trong ngày nghỉ việc (đồng bộ từ LDAP/AD tắt tài khoản) | 100% nhân sự Z7 có cam kết; ≥ 1 buổi đào tạo/năm; thu hồi quyền ≤ 24 giờ | Chủ quản, đơn vị vận hành, nhà cung cấp | RS |
| SEC-04 | Quản lý tài sản | Kiểm kê tự động: workload và ảnh từ Argo CD, SBOM từ Harbor, nút từ K8s API, chứng thư từ cert-manager, bí mật (siêu dữ liệu) từ OpenBao; xuất báo cáo kiểm kê hằng ngày vào PH-13; tài sản ở mục 3.1 có chủ sở hữu | Cập nhật hằng ngày; rà soát ký xác nhận mỗi quý | Đơn vị vận hành | CI, RS |
| SEC-05 | Quản lý nhà cung cấp, nhà thầu | Hợp đồng có điều khoản ATTT và DLCN (bên xử lý dữ liệu, thông báo sự cố ≤ 24 giờ cho chủ quản, quyền kiểm tra); nhà thầu HTTT chỉ có vai trò trong tenant với thời hạn; tài khoản nhà thầu hết hạn tự khóa; đánh giá nhà cung cấp cloud theo QĐ 8297/QĐ-BCA-A05 | 100% tài khoản nhà thầu có ngày hết hạn ≤ 12 tháng | Chủ quản | RS |
| SEC-06 | Quản lý rủi ro | Đánh giá rủi ro theo mục 4 khi khởi tạo, mỗi 6 tháng và khi thay đổi kiến trúc; sổ rủi ro D01-02; rủi ro tồn dư Trung bình được chủ quản chấp thuận | Rà soát ≥ 2 lần/năm | Kiến trúc sư ATTT | RS |
| SEC-07 | Quản lý thay đổi và cấu hình | Mọi thay đổi PROD qua Git (NT-06) có review của người thứ hai; luồng tích hợp và chính sách qua quy trình duyệt bốn mắt (FR-00-071); thay đổi khẩn có quy trình riêng nhưng vẫn ghi Git và review sau ≤ 2 ngày làm việc; cấu hình chuẩn (baseline) cho mọi thành phần lưu trong Git | 0 thay đổi PROD ngoài Git (đo bằng phát hiện lệch, SEC-65) | Nhóm nền tảng | CI, RS |
| SEC-08 | Kiểm tra, đánh giá an ninh mạng | Kiểm thử xâm nhập độc lập; đánh giá cấu hình theo CIS hằng quý bằng kube-bench; tự đánh giá theo ma trận mục 11 hằng năm; kiểm tra của cơ quan có thẩm quyền theo NĐ 331/2026 | Pentest ≥ 1 lần/năm và trước phát hành lớn; 0 phát hiện Cao chưa xử lý quá 30 ngày | Chủ quản, nhà cung cấp | PT, RS |
| SEC-09 | Quản lý lỗ hổng và vá | Trivy Operator quét liên tục ảnh đang chạy; Renovate mở PR cập nhật phụ thuộc; theo dõi cảnh báo từ cơ quan chuyên trách và CVE; SLA vá theo bảng 5.1; ngoại lệ có thời hạn ≤ 30 ngày được kiến trúc sư ATTT duyệt | Đạt SLA ≥ 95%; báo cáo hằng tháng | Nhóm DevSecOps, đơn vị vận hành | CI, RS |

: Biện pháp SEC-01…09 về quản trị, chính sách, tổ chức, nhân sự, nhà cung cấp

Biện pháp SEC-09 được thiết kế với hai luồng vá khác nhau. Ảnh do Datahub xây được vá bằng phát hành mới qua CI (SEC-55…57), triển khai cuốn chiếu nên không gián đoạn data plane (NFR-00-013). Hệ điều hành nút được vá bằng thay nút (node rotation): nút mới từ ảnh hệ điều hành đã vá được thêm vào, nút cũ được rút tải (drain) và loại bỏ, nhờ đó mỗi tháng toàn bộ nút được thay mới thay vì vá tại chỗ. Ở hồ sơ tỉnh độc lập có máy chủ vật lý cố định, việc vá tại chỗ theo lịch tháng và khởi động lại từng nút một. Với lỗ hổng 0-day chưa có bản vá, quy trình khẩn ở playbook PB-07 (mục 8.5) áp dụng biện pháp giảm thiểu tạm thời: luật ảo hóa vá tại WAF, tắt tính năng, chặn egress.

### 5.3. Nhóm SEC-10…19: Biên và mạng

Mục tiêu của nhóm này là bảo đảm mỗi luồng mạng phải được cho phép tường minh (NT-03) và mọi luồng đều được mã hóa và xác thực hai đầu.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-10 | Chống DDoS và giới hạn lưu lượng nhiều tầng | Tầng 3/4: dịch vụ chống DDoS của TTDL/cloud và giới hạn kết nối tại bộ cân bằng tải. Tầng 7: APISIX `limit-conn` và `limit-req` theo IP nguồn (mặc định 50 yêu cầu/giây/IP cho đường dẫn giao diện), APISIX `limit-req` theo consumer, `limit-count` theo gói và theo tenant (D03-10 §5.3). Đường dẫn đăng nhập Keycloak giới hạn 10 yêu cầu/phút/IP | Chịu được tải gấp 3 lần cao điểm (900 lượt/giây) không suy giảm data plane; nguồn tấn công bị chặn ≤ 60 giây | Bên cung cấp hạ tầng, nhóm nền tảng | KT (kiểm thử tải), DT |
| SEC-11 | Tường lửa ứng dụng web (WAF) | Coraza chạy dạng plugin proxy-wasm trong APISIX (ADR-033) với OWASP CRS 4.x mức độ hoang tưởng (paranoia level) 2 cho giao diện, mức 1 cho API máy–máy (đã có kiểm tra lược đồ ở APISIX); chế độ chặn trên PROD sau 2 tuần chạy phát hiện ở môi trường thử; luật ảo hóa vá (virtual patch) bổ sung khi có lỗ hổng 0-day; log WAF đẩy về SIEM | Tỉ lệ chặn nhầm < 0,1% lượt hợp lệ; luật vá ảo triển khai ≤ 4 giờ từ khi có thông tin lỗ hổng | Nhóm nền tảng | KT, PT |
| SEC-12 | Cấu hình TLS | Biên: TLS 1.3 với `TLS_AES_256_GCM_SHA384`, `TLS_AES_128_GCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256`; TLS 1.2 chỉ khi HTTT có ngoại lệ, giới hạn `ECDHE-ECDSA/RSA-AES128/256-GCM-SHA256/384` và `ECDHE-*-CHACHA20-POLY1305`; nhóm khóa X25519, secp256r1; HSTS `max-age=31536000; includeSubDomains`; OCSP stapling; không nén TLS, không renegotiation. Chứng thư biên RSA 3072 hoặc ECDSA P-256. Ra ngoài (NDXP, PayGov): xác minh đầy đủ chứng thư, ghim CA gốc trong truststore riêng của adapter | Điểm A+ trên công cụ kiểm tra TLS nội bộ (testssl.sh): 0 giao thức/bộ mã yếu | Nhóm nền tảng | CI (testssl.sh trong kiểm thử khói), RS |
| SEC-13 | Phân vùng mạng | Tám vùng Z0–Z7 (mục 3.3); tầng hạ tầng tách VLAN/subnet cho biên, nút worker, nút dữ liệu, mạng quản trị và mạng lưu trữ; namespace K8s gắn nhãn vùng `dh.gov.vn/zone`, danh sách đầy đủ ở D03-09 mục bố trí namespace (ví dụ `dh-edge` Z1; `dh-gateway` Z2; `dh-control`, `dh-payment` Z3; `dh-runtime`, `dh-rt-*` Z4; `dh-db`, `dh-kafka`, `dh-s3` Z5; `dh-iam`, `dh-secrets` Z6; `dh-obs`, `dh-system` Z7) | 100% namespace có nhãn vùng; sơ đồ mạng D03-09 khớp cấu hình | Bên cung cấp hạ tầng, nhóm nền tảng | RS |
| SEC-14 | Network policy từ chối mặc định | Mỗi namespace có `CiliumNetworkPolicy` từ chối mọi ingress/egress, sau đó mở theo cặp nhãn `app.kubernetes.io/name`; DNS chỉ tới CoreDNS; Admin API APISIX, `/actuator`, cổng quản trị Kafka/PG chỉ nhận từ namespace được liệt kê; Hubble ghi luồng bị chặn | 100% namespace có chính sách mặc định từ chối (Kyverno kiểm tra); 0 luồng bất ngờ trong báo cáo Hubble tuần | Nhóm nền tảng | CI (kiểm thử kết nối âm tính), KT |
| SEC-15 | mTLS trong cụm và ủy quyền dịch vụ | Istio ambient: `PeerAuthentication` mặc định `STRICT` toàn mesh; `AuthorizationPolicy` mặc định từ chối, cho phép theo SPIFFE ID của service account (ví dụ chỉ `dh-connect` được gọi Admin API APISIX); waypoint proxy cho dịch vụ cần chính sách tầng 7. Chứng thư workload do istiod cấp, sống 24 giờ, CA trung gian của mesh được ký từ PKI OpenBao (SEC-35) | 0 kết nối văn bản thô giữa pod (đo bằng chỉ số Istio `connection_security_policy`) | Nhóm nền tảng | KT |
| SEC-16 | Kiểm soát lưu lượng ra (egress) | Mọi lưu lượng ra Internet qua egress gateway Istio có `ServiceEntry` liệt kê FQDN đích (NDXP, PayGov, kho cập nhật đã duyệt); `CiliumNetworkPolicy` với `toFQDNs` cho pod cần ra ngoài; chặn dải siêu dữ liệu cloud `169.254.169.254/32`, dải nội bộ cụm, dải quản trị đối với egress từ `dh-runtime`; đích mới cho kết nối của luồng được tạo qua quy trình duyệt PH-05 | 0 kết nối ra đích ngoài danh sách; cảnh báo ≤ 5 phút khi bị chặn | Nhóm nền tảng | KT, PT |
| SEC-17 | DNS và thời gian | CoreDNS nội bộ, chuyển tiếp ra DNS của TTDL có DNSSEC xác minh nếu hạ tầng hỗ trợ; đồng bộ NTP tất cả nút với nguồn thời gian chuẩn quốc gia/TTDL qua chrony, độ lệch cảnh báo > 1 giây | Độ lệch đồng hồ ≤ 1 giây (cần cho nhật ký, TOTP, chống phát lại) | Bên cung cấp hạ tầng | KT |
| SEC-18 | Bảo vệ điểm cuối dịch vụ dữ liệu | PostgreSQL: TLS bắt buộc (`hostssl` với `scram-sha-256`), người dùng ứng dụng theo DU; Kafka: listener nội bộ mTLS, xác thực principal theo chứng thư, `allow.everyone.if.no.acl.found=false`; Valkey: TLS và ACL người dùng; Garage: khóa truy cập theo DU và tenant, chỉ HTTPS | 0 listener văn bản thô | Nhóm nền tảng | CI (kiểm tra cấu hình), KT |
| SEC-19 | Truy cập quản trị từ xa | Truy cập Z7 chỉ qua VPN quản trị (WireGuard/IPsec) có MFA, rồi qua bastion; API server K8s xác thực OIDC với Keycloak realm `dh-ops` (nhóm → ClusterRole), không phát hành kubeconfig tĩnh; Argo CD, Grafana quản trị, OpenBao UI chỉ trong Z7 | 0 kubeconfig dài hạn (rà soát); 100% phiên Z7 có MFA | Đơn vị vận hành | RS, PT |

: Biện pháp SEC-10…19 về biên và mạng

Lựa chọn Istio ambient thay cho sidecar truyền thống được giữ theo ADR-013 và SAD §6: chế độ ambient đặt mTLS ở tầng ztunnel trên mỗi nút, không cần sửa pod, nên mọi workload kể cả thành phần bên thứ ba đều được bảo vệ ngay khi vào namespace có nhãn `istio.io/dataplane-mode=ambient`. Cilium và Istio bổ trợ nhau: Cilium thực thi tầng 3/4 theo danh tính nhãn (khó vượt kể cả khi một pod bị chiếm), Istio thực thi danh tính mật mã (SPIFFE) và tầng 7. Thành phần dữ liệu có giao thức riêng (PostgreSQL, Kafka) vẫn bật TLS ở tầng ứng dụng (SEC-18) vì một số thao tác vận hành (sao chép CNPG giữa site, MirrorMaker 2) đi ngoài mesh.

Đoạn cấu hình mẫu dưới đây minh họa chính sách mặc định của một namespace ứng dụng; tệp đầy đủ nằm trong kho cấu hình nền tảng.

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: { name: default, namespace: istio-system }
spec: { mtls: { mode: STRICT } }
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata: { name: allow-connect-to-apisix-admin, namespace: dh-gateway }
spec:
  selector: { matchLabels: { app.kubernetes.io/name: apisix } }
  action: ALLOW
  rules:
    - from: [{ source: { principals: ["cluster.local/ns/dh-control/sa/dh-connect"] } }]
      to:   [{ operation: { ports: ["9180"] } }]
---
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata: { name: default-deny, namespace: dh-control }
spec:
  endpointSelector: {}
  ingress: [{}]   # chỉ để kích hoạt chế độ từ chối; các chính sách cho phép bổ sung riêng
  egress:
    - toEndpoints: [{ matchLabels: { k8s:io.kubernetes.pod.namespace: kube-system, k8s-app: kube-dns } }]
      toPorts: [{ ports: [{ port: "53", protocol: UDP }] }]
```

### 5.4. Nhóm SEC-20…29: Định danh, xác thực, ủy quyền

Nhóm này hiện thực ADR-006 (Keycloak cho xác thực, OPA cho ủy quyền) ở mức tham số cụ thể. Có ba loại chủ thể với cơ chế khác nhau: người dùng (OIDC qua BFF), máy (OAuth 2.1 client_credentials ràng buộc chứng thư hoặc private_key_jwt) và workload nội bộ (SPIFFE qua mesh, service account K8s cho OpenBao).

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-20 | Tăng cứng Keycloak và realm | Realm theo tenant tạo từ mẫu (D03-10 §5.2); cấu hình bảo mật của realm (chính sách mật khẩu, luồng xác thực, MFA, thời hạn token, danh sách grant cho phép) được quản bằng GitOps (keycloak-config-cli) và không sửa được qua giao diện quản trị tỉnh. Quản trị tỉnh có vai trò tùy biến `realm-user-admin` (quản lý người dùng, nhóm, gán vai trò Datahub), không có `manage-realm`, `manage-clients`, `manage-authorization`. Tắt grant `password` và `implicit`; tắt đăng ký tự do; bật `Brute Force Detection`; bật sự kiện đăng nhập và sự kiện quản trị, đẩy ra SIEM. Console quản trị Keycloak chỉ trong Z7. Keycloak 26 chạy chế độ production, CSDL riêng trong Z6 | 0 khác biệt giữa cấu hình realm thực tế và Git (kiểm tra hằng giờ) | Nhóm nền tảng (mẫu), vận hành ATTT | CI, KT |
| SEC-21 | Xác thực người dùng OIDC + PKCE qua BFF | `dh-console` và `dh-portal` dùng mẫu Backend-for-Frontend: BFF (Spring Cloud Gateway nhẹ trong Z2, mỗi ứng dụng một client bí mật) thực hiện Authorization Code + PKCE (`S256`), giữ access/refresh token phía máy chủ trong Valkey (mã hóa, khóa theo phiên), trình duyệt chỉ có cookie phiên `__Host-dh-sid` (`Secure`, `HttpOnly`, `SameSite=Strict`, `Path=/`). BFF chuyển tiếp lời gọi `/api/...` tới APISIX kèm token. Đăng xuất gọi `end_session_endpoint` và back-channel logout | 0 token xuất hiện trong bộ nhớ JavaScript, `localStorage`, `sessionStorage` (kiểm thử Playwright) | Nhóm giao diện, nhóm nền tảng | KT, PT |
| SEC-22 | Chính sách mật khẩu và chống dò | Chính sách Keycloak: `length(14) and maxLength(128) and notUsername and notEmail and passwordHistory(5) and passwordBlacklist(dh-breached.txt)` (danh sách ≥ 100.000 mật khẩu lộ phổ biến, cập nhật mỗi quý); băm `argon2` (Keycloak 26) hoặc `pbkdf2-sha512` ≥ 210.000 vòng; không bắt đổi định kỳ, bắt đổi khi nghi lộ; khóa tạm 15 phút sau 5 lần sai, khóa vĩnh viễn sau 3 lần khóa tạm/24 giờ; thông báo lỗi đăng nhập không phân biệt "sai tên" và "sai mật khẩu". Ưu tiên liên kết LDAP/AD của tỉnh (chính sách của tỉnh phải đạt ngưỡng tương đương, được kiểm tra khi kết nạp) | Mật khẩu ≥ 14 ký tự; 5 lần/15 phút | Vận hành ATTT | KT |
| SEC-23 | Xác thực đa yếu tố | Luồng xác thực có điều kiện: người dùng có vai trò thuộc nhóm `mfa-required` (mọi `_ADMIN`, vai trò duyệt, `ROLE-PAY_RECONCILER`, vai trò nền tảng) bắt buộc OTP (TOTP RFC 6238, 6 số, 30 giây) hoặc WebAuthn; vai trò nền tảng và quản trị tỉnh bắt buộc WebAuthn (khóa FIDO2 hoặc passkey, `userVerification=required`). Thao tác nhạy cảm (xem đầy đủ dữ liệu Nhạy cảm, hoàn tiền, đổi chính sách, phát hành luồng PROD) yêu cầu xác thực lại bước lên (step-up) nếu lần xác thực cuối > 5 phút, kiểm tra qua claim `acr`/`auth_time`. Khôi phục MFA chỉ qua quản trị cấp trên, có ghi kiểm toán | 100% tài khoản trong nhóm có yếu tố thứ hai đăng ký (báo cáo hằng ngày) | Vận hành ATTT | KT |
| SEC-24 | Xác thực máy–máy | OAuth 2.1 `client_credentials` với hai phương thức xác thực client được phép: (a) `tls_client_auth` theo RFC 8705, token ràng buộc chứng thư (claim `cnf.x5t#S256`), APISIX đối chiếu dấu vân tay chứng thư của kết nối mTLS với claim; (b) `private_key_jwt` theo RFC 7523 (khóa ES256/PS256, JWT sống ≤ 60 giây, `jti` không lặp). `client_secret_basic` chỉ cho hợp đồng mức Công khai/Nội bộ trong giai đoạn chuyển đổi, bí mật ≥ 256 bit, hết hạn ≤ 180 ngày. Hợp đồng mức Hạn chế: bắt buộc (a) hoặc (b); mức Nhạy cảm: bắt buộc (a). Chứng thư client do CA HTTT của Datahub (OpenBao PKI) cấp qua PH-01 hoặc CA được tỉnh chấp nhận | 0 client dùng `client_secret` cho hợp đồng ≥ Hạn chế (kiểm tra khi đăng ký sử dụng) | Nhóm PH-01/PH-03 | KT, PT |
| SEC-25 | Token: thời hạn, đối tượng, thu hồi | Access token JWT ký ES256 (hoặc PS256), sống 5 phút cho cả máy và người; claim bắt buộc `iss`, `aud` (theo nhóm API), `tenant`, `azp`, `scope`, `cnf` (nếu ràng buộc); APISIX kiểm tra `iss` khớp realm của `tenant`, `aud`, `exp` với dung sai ≤ 30 giây; JWKS bộ đệm 10 phút và làm mới khi gặp `kid` lạ. Refresh token người dùng xoay vòng mỗi lần dùng, phát hiện dùng lại thì thu hồi cả họ token. Khóa ký realm xoay vòng mỗi 90 ngày, giữ khóa cũ để xác minh thêm 1 ngày. Thu hồi khẩn: vô hiệu client hoặc người dùng trong Keycloak và đẩy danh sách chặn `jti`/`sub` tới APISIX (hiệu lực ≤ 60 giây), không chờ token hết hạn | Thời hạn token đúng cấu hình; thu hồi có hiệu lực ≤ 60 giây | Nhóm nền tảng | KT |
| SEC-26 | Ủy quyền tập trung bằng OPA | OPA chạy cạnh (sidecar hoặc plugin `opa` của APISIX gọi OPA cục bộ trong pod) tại APISIX và tại mỗi DU (qua thư viện PEP dùng chung). Chính sách Rego trong kho `dh-policies`, có kiểm thử đơn vị (`opa test`, độ phủ ≥ 90%), đóng gói bundle ký (`opa build --signing-key`), OPA xác minh chữ ký trước khi nạp. Mô hình: RBAC theo `ROLE`/`PERM` (D02-08) + ABAC theo tenant, tổ chức, chủ sở hữu đối tượng, mức phân loại, mục đích khai thác (PH-09). Quy tắc gốc: `default allow := false`; mọi quyết định có `input.tenant == data.resource.tenant` trừ đường liên tenant (SEC-85). Ghi nhật ký quyết định (decision log) có che dữ liệu ra Loki | Độ trễ quyết định p99 ≤ 2 ms (cục bộ); 100% route có chính sách (kiểm tra khi đồng bộ cấu hình) | Kiến trúc sư ATTT, nhóm phát triển | CI, KT |
| SEC-27 | Vòng đời tài khoản và rà soát quyền | Cấp tài khoản qua yêu cầu có duyệt (PH-12) hoặc đồng bộ LDAP/AD; tài khoản không đăng nhập 45 ngày (quản trị 30 ngày) tự vô hiệu bởi tác vụ hằng ngày; client máy không gọi 90 ngày tự tạm ngừng; tài khoản nhà thầu có ngày hết hạn; chiến dịch rà soát quyền định kỳ trong PH-12 (người quản lý xác nhận từng quyền, không phản hồi trong 14 ngày thì gỡ quyền) | Vô hiệu ≤ 24 giờ sau ngưỡng; rà soát quý cho quản trị | Quản trị tỉnh, vận hành ATTT | KT, RS |
| SEC-28 | Quản lý đặc quyền và truy cập khẩn (break-glass) | Không có tài khoản quản trị dùng chung. Quyền cao (cluster-admin, OpenBao admin, CSDL superuser, Keycloak master realm) không gán thường trực: cấp theo yêu cầu, có thời hạn (just-in-time ≤ 4 giờ), duyệt bởi người thứ hai, qua bastion ghi phiên (Teleport hoặc công cụ tương đương mã nguồn mở). Tài khoản break-glass: 2 tài khoản cho mỗi hệ quan trọng, thông tin xác thực chia làm hai phần niêm phong giữ bởi hai người khác nhau (hoặc khóa FIDO2 trong két), mọi lần dùng phát cảnh báo nghiêm trọng tới SOC và chủ quản, xoay vòng ngay sau khi dùng, kiểm tra hoạt động 6 tháng/lần. Thao tác dữ liệu trực tiếp trên CSDL PROD chỉ qua break-glass | 0 quyền cao thường trực ngoài tài khoản dịch vụ; 100% phiên đặc quyền được ghi | Đơn vị vận hành, chủ quản | RS, DT |
| SEC-29 | Quản lý phiên | Phiên BFF: nhàn rỗi 15 phút (cấu hình 5–15 theo tenant), tối đa 10 giờ; cảnh báo 2 phút trước khi khóa; tối đa 3 phiên đồng thời mỗi người dùng (quản trị: 1), phiên mới vượt hạn mức thu hồi phiên cũ nhất và thông báo; người dùng xem và thu hồi phiên (FR-00-005); đổi mật khẩu, đổi MFA hoặc bị khóa thì thu hồi mọi phiên; mã phiên sinh lại sau đăng nhập và sau step-up | Khóa đúng 15 phút ± 5 giây (kiểm thử đồng hồ giả lập) | Nhóm giao diện | KT |

: Biện pháp SEC-20…29 về định danh, xác thực, ủy quyền

**Vì sao chọn BFF thay cho token trong SPA.** Có hai cách để ứng dụng trang đơn (SPA) React gọi API có xác thực: giữ token trong trình duyệt (SPA là client công khai, dùng PKCE) hoặc dùng BFF (token ở máy chủ, trình duyệt chỉ giữ cookie phiên). Giữ token trong trình duyệt đơn giản hơn và đã được OAuth 2.1 cho phép, nhưng bất kỳ lỗ XSS nào cũng cho kẻ tấn công lấy token và dùng ngoài trình duyệt trong suốt thời hạn còn lại, kể cả refresh token. Với giao diện quản trị của một hệ cấp độ 3, nơi mỗi phiên quản trị tỉnh có thể điều khiển dữ liệu cả tỉnh, rủi ro đó không chấp nhận được (THR-10). BFF loại bỏ khả năng đánh cắp token; XSS vẫn có thể thực hiện thao tác trong phiên, nhưng bị giới hạn bởi CSP (SEC-44), step-up (SEC-23) và không kéo dài sau khi đóng trình duyệt. Chi phí là thêm một thành phần phía máy chủ và phụ thuộc Valkey cho phiên; cả hai chấp nhận được vì Valkey đã có trong ngăn xếp và BFF không giữ logic nghiệp vụ. Hướng dẫn "OAuth 2.0 for Browser-Based Applications" của IETF cũng xếp BFF là mẫu an toàn nhất cho ứng dụng có yêu cầu bảo mật cao.

**Vì sao token ràng buộc chứng thư là mặc định cho dữ liệu Nhạy cảm.** Bearer token, dù sống 5 phút, vẫn dùng được bởi bất kỳ ai lấy được nó (từ log của HTTT, proxy trung gian). Token ràng buộc chứng thư theo RFC 8705 chỉ dùng được trên kết nối TLS có khóa riêng tương ứng, nên lộ token không đủ để giả mạo. `private_key_jwt` bảo vệ khâu lấy token (không có bí mật chia sẻ để lộ) nhưng token phát ra vẫn là bearer, nên được chấp nhận cho mức Hạn chế. DPoP (RFC 9449) là phương án ràng buộc token không cần mTLS; được theo dõi để bổ sung khi APISIX hỗ trợ ổn định (Q303).

> **Câu hỏi mở Q303:** Các HTTT của tỉnh (thường do nhiều nhà thầu khác nhau xây) có đủ năng lực triển khai mTLS phía client không? Nếu tỷ lệ thấp, cần chính sách chuyển tiếp: cho phép `private_key_jwt` cho mức Nhạy cảm trong thời hạn 12 tháng kể từ T0, kèm giới hạn IP nguồn.

Ma trận phương thức xác thực theo loại chủ thể dưới đây tổng hợp lại các quy tắc trên để đội PH-01 và PH-03 cấu hình đúng khi kết nạp HTTT.

| Chủ thể | Phương thức | Token | Ràng buộc |
|---|---|---|---|
| Cán bộ qua `dh-console` | OIDC Code + PKCE qua BFF, MFA theo vai trò | Ở BFF, 5 phút | Cookie phiên `__Host-` |
| Nhà phát triển qua `dh-portal` | Như trên; tài khoản thuộc realm tenant hoặc realm `dh-dev` cho sandbox | Ở BFF | — |
| HTTT, hợp đồng Công khai/Nội bộ | client_credentials, `private_key_jwt` (khuyến nghị) hoặc `client_secret` (chuyển tiếp) | 5 phút, bearer | IP nguồn tùy chọn |
| HTTT, hợp đồng Hạn chế | client_credentials, `private_key_jwt` hoặc `tls_client_auth` | 5 phút | — hoặc `cnf` |
| HTTT, hợp đồng Nhạy cảm | client_credentials, `tls_client_auth` | 5 phút, ràng buộc chứng thư | `cnf.x5t#S256` |
| Workload nội bộ ↔ workload | mTLS mesh (SPIFFE) | Không cần token, hoặc token người dùng gốc được truyền tiếp để ủy quyền | AuthorizationPolicy |
| DU → OpenBao | Xác thực Kubernetes (service account token có `aud` riêng) | Token OpenBao 1 giờ, gia hạn | Vai trò theo service account |
| Datahub → NDXP, PayGov | Theo đặc tả bên kia; thông tin xác thực trong OpenBao | Theo bên kia | mTLS nếu hỗ trợ |

: Phương thức xác thực và thời hạn token theo từng chủ thể

### 5.5. Nhóm SEC-30…39: Bảo vệ dữ liệu, mã hóa, khóa, bí mật, dữ liệu cá nhân

Nhóm này bảo vệ dữ liệu ở ba trạng thái (lưu, truyền, đang dùng) và quản lý vòng đời khóa, bí mật, dữ liệu cá nhân. Bảng dưới đây liệt kê từng biện pháp với cách hiện thực và tham số đo được.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-30 | Mã hóa khi lưu | Volume của nút dữ liệu mã hóa ở tầng khối (LUKS2 AES-256-XTS do hạ tầng cấp, hoặc lớp lưu trữ của cloud có mã hóa với khóa do chủ quản quản lý); Garage mã hóa phía máy chủ bằng khóa SSE-C do DU cung cấp từ OpenBao cho bucket chứa dữ liệu ≥ Hạn chế; Kafka: volume mã hóa, topic Nhạy cảm mã hóa thân bản tin ở tầng ứng dụng; sao lưu CNPG và Velero mã hóa trước khi rời site | 100% volume PV thuộc lớp lưu trữ mã hóa (Kyverno chặn PVC dùng lớp không mã hóa) | Bên cung cấp hạ tầng, nhóm nền tảng | CI, RS |
| SEC-31 | Mã hóa trường Nhạy cảm | Envelope encryption theo ADR-032: mỗi tenant một khóa mã hóa khóa (KEK) trong OpenBao transit (`transit/keys/dh-{tenant}-pii`, AES-256-GCM96, không cho xuất); DU sinh khóa dữ liệu (DEK) qua `transit/datakey`, mã hóa trường bằng AES-256-GCM với dữ liệu liên kết (AAD) gồm `tenant_id`, tên bảng, tên cột, `id` bản ghi (chống tráo bản mã giữa dòng); lưu `{phiên bản KEK, DEK đã bọc, nonce, bản mã}`. Bộ đệm DEK giải bọc trong bộ nhớ ≤ 5 phút. Tìm kiếm chính xác bằng cột HMAC-SHA256 với khóa riêng theo tenant | 100% trường gắn nhãn Nhạy cảm được mã hóa (kiểm tra bằng quét CSDL tìm mẫu số định danh rõ: 0 kết quả) | Nhóm phát triển (thư viện `dh-crypto`) | CI, KT |
| SEC-32 | Che dữ liệu trong log, trace, giao diện | Ba lớp: (1) thư viện log dùng chung che theo chú thích `@Classified` và theo mẫu (số định danh 12 số, số điện thoại, thẻ, thư điện tử) trước khi ghi; (2) OTel Collector có processor `redaction`/`transform` loại thuộc tính không thuộc danh sách cho phép và che theo mẫu; (3) APISIX `http-logger` chỉ ghi siêu dữ liệu, không ghi thân. Giao diện che theo bảng mục 3.2 | NFR-00-029: 0 giá trị Nhạy cảm trong log (bộ quét mẫu chạy hằng ngày trên Loki) | Nhóm phát triển, nhóm nền tảng | CI, KT |
| SEC-33 | Quản lý bí mật | OpenBao HA (3 nút, lưu trữ Raft tích hợp) trong Z6; External Secrets Operator đồng bộ bí mật cần thiết dưới dạng Secret tạm cho thành phần bên thứ ba; DU Spring/Quarkus đọc trực tiếp OpenBao qua Spring Cloud Vault/Quarkus Vault, không qua biến môi trường. Bí mật CSDL dùng engine `database` sinh tài khoản động sống 24 giờ. Đường dẫn `kv/dh/{tenant}/...`, chính sách theo service account. Token gốc thu hồi sau khởi tạo; mở niêm phong bằng auto-unseal qua transit của OpenBao cụm quản lý hoặc Shamir 3/5 giữ bởi 5 người. Nhật ký kiểm toán OpenBao bật hai thiết bị (file + socket) đẩy ra SIEM; OpenBao từ chối phục vụ nếu không ghi được nhật ký | 0 bí mật trong Git, ảnh, biến môi trường (gitleaks, Trivy, Kyverno cấm `env.value` có mẫu bí mật) | Vận hành ATTT | CI, RS |
| SEC-34 | Quản lý khóa mật mã | Phân cấp khóa: khóa gốc (unseal/root của OpenBao; ở cấp độ 4 nằm trong HSM) → KEK theo tenant và theo mục đích (PII, ký nhật ký, ký webhook, ký callback) → DEK. Xoay vòng KEK mỗi 12 tháng (`transit/keys/.../rotate`, phiên bản cũ chỉ giải mã), tác vụ nền bọc lại DEK (`rewrap`) không cần giải mã dữ liệu; khóa ký JWT 90 ngày; khóa HMAC webhook 12 tháng hoặc theo yêu cầu HTTT; hủy khóa có quy trình hai người. Thuật toán cho phép: AES-256-GCM, ChaCha20-Poly1305, ECDSA P-256/P-384, Ed25519, RSA ≥ 3072, SHA-256/384; cấm MD5, SHA-1, DES/3DES, RC4, RSA < 2048. Danh mục khóa (không chứa vật liệu khóa) được kiểm kê ở SEC-04 | 100% khóa trong hạn xoay vòng | Vận hành ATTT | RS, KT |
| SEC-35 | Hạ tầng khóa công khai và vòng đời chứng thư | CA gốc nội bộ ngoại tuyến (offline, sinh trên máy cách ly, khóa giữ trong két hoặc HSM) ký các CA trung gian trong OpenBao PKI: `pki-mesh` (ký CA của istiod), `pki-internal` (TLS dịch vụ dữ liệu), `pki-clients` (chứng thư client HTTT). cert-manager với `ClusterIssuer` kiểu Vault/OpenBao cấp và gia hạn tự động; chứng thư biên công khai từ CA được tin cậy (ACME nếu hạ tầng cho phép, hoặc CA do cơ quan cấp). CRL/OCSP cho `pki-clients`; thu hồi chứng thư client HTTT khi chấm dứt kết nối có hiệu lực ≤ 15 phút | 0 chứng thư hết hạn trên PROD; cảnh báo khi còn ≤ 21 ngày (biên) | Vận hành ATTT, nhóm nền tảng | KT, RS |
| SEC-36 | Khóa ký và chữ ký số | Khóa ký callback/thanh toán, ký chuỗi neo nhật ký, ký bundle OPA, ký ảnh cosign đều là khóa transit không xuất được: dịch vụ gửi băm cần ký tới `transit/sign`, nhận chữ ký. Khóa ký HMAC webhook theo từng đăng ký, lưu ở `kv/dh/{tenant}/webhook/{id}`, hiển thị cho HTTT một lần khi tạo | 0 khóa ký nằm ngoài OpenBao | Vận hành ATTT | RS |
| SEC-37 | Quản lý xử lý dữ liệu cá nhân | PH-09 duy trì: danh mục phân loại trường; sổ hoạt động xử lý DLCN (mục đích, cơ sở pháp lý, loại dữ liệu, bên nhận, thời hạn lưu); chấp thuận khai thác của chủ quản dữ liệu gắn với mục đích; OPA dùng `purpose` trong token/yêu cầu để quyết định. Mục 6 chi tiết | 100% hợp đồng mức Nhạy cảm có mục đích và chấp thuận trước khi kích hoạt | Nhóm PH-09, chủ quản dữ liệu | KT, RS |
| SEC-38 | Giả danh hóa và dữ liệu thử | Môi trường không phải PROD chỉ dùng dữ liệu sinh (bộ sinh dữ liệu giả theo D05-01) hoặc dữ liệu giả danh hóa không thể đảo ngược; xuất phục vụ thống kê dùng tổng hợp có ngưỡng tối thiểu (k ≥ 10) | 0 bộ dữ liệu thật ngoài PROD (rà soát) | Nhóm kiểm thử, vận hành | RS |
| SEC-39 | Thời hạn lưu và xóa an toàn | Mỗi bảng chứa DLCN có thời hạn lưu trong sổ PH-09; tác vụ nền xóa hoặc giả danh hóa khi hết hạn; DLQ hợp đồng Nhạy cảm ≤ 7 ngày; tệp nhập tạm ≤ 24 giờ sau khi xử lý; tệp xuất hạn tải 24 giờ (FR-00-031). Xóa mật mã (crypto-shredding): khi tenant bị chấm dứt, hủy KEK của tenant làm toàn bộ bản mã (kể cả trong sao lưu) không giải được. Thiết bị lưu trữ thải loại được xóa theo NIST SP 800-88 hoặc hủy vật lý có biên bản | Tác vụ xóa chạy hằng ngày, báo cáo số bản ghi đã xóa | Nhóm phát triển, vận hành | KT, RS |

: Biện pháp SEC-30…39 về mã hóa, khóa, bí mật và dữ liệu cá nhân

Biện pháp SEC-39 có một điểm thiết kế đáng chú ý: bản sao lưu bất biến (SEC-70) không xóa được trước hạn, nên không thể "xóa" một bản ghi DLCN khỏi sao lưu theo yêu cầu của chủ thể. Xóa mật mã giải quyết mâu thuẫn này ở mức tenant (hủy KEK). Ở mức từng chủ thể, Datahub áp dụng quy tắc: bản ghi bị xóa trong CSDL sống, bản sao lưu cũ hết hạn tự nhiên theo vòng đời sao lưu (tối đa 35 ngày cho sao lưu thường, mục 7 D03-09), và quy trình khôi phục có bước áp lại danh sách xóa (tombstone) trước khi đưa dữ liệu khôi phục vào phục vụ.

### 5.6. Nhóm SEC-40…49: Ứng dụng, API và phát triển an toàn

Mục tiêu đo được của nhóm này là đạt OWASP ASVS 5.0 mức 2 (NFR-00-024) cho mọi ứng dụng web và API, và phủ các mục đặc thù của Datahub mà ASVS không nói tới (trình thiết kế luồng, thanh toán, AI).

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-40 | Vòng đời phát triển an toàn | Yêu cầu bảo mật đưa vào FRS (mục "Kiểm toán", mức phân loại trường); mô hình mối đe dọa cập nhật cho mỗi phân hệ ở SDD; danh sách kiểm tra ASVS L2 gắn vào định nghĩa hoàn thành; review mã bắt buộc (ADR-037) có mục bảo mật; đào tạo lập trình an toàn cho đội phát triển hằng năm | 100% phân hệ có mục mô hình mối đe dọa trong SDD | Trưởng nhóm kỹ thuật | RS |
| SEC-41 | Phân tích tĩnh, phụ thuộc, bí mật | Trong CI: Semgrep (bộ luật Java/Spring, TypeScript/React, luật riêng Datahub như cấm `@Query(nativeQuery=true)` ngoài danh sách, cấm ghép chuỗi SQL, cấm `dangerouslySetInnerHTML`), SpotBugs + FindSecBugs, ESLint plugin security; SCA bằng OWASP Dependency-Check/Trivy fs; gitleaks trên mọi commit và lịch sử; kho trung gian Maven/npm qua Harbor/Nexus nội bộ, khóa phiên bản (`package-lock.json`, Maven enforcer) | 0 phát hiện CRITICAL/HIGH mở khi merge; 0 bí mật (NFR-00-022, 023) | Nhóm DevSecOps | CI |
| SEC-42 | Kiểm thử động và kiểm thử API | OWASP ZAP quét chủ động có xác thực trên môi trường thử hằng tuần và trước phát hành; bộ kiểm thử API từ OpenAPI (Schemathesis) tìm lỗi lược đồ và lỗi 5xx; bộ kiểm thử phân quyền tự động sinh từ ma trận `ROLE`/`PERM` (mỗi API × mỗi vai trò không được phép → kỳ vọng `403`/`404`); kiểm thử BOLA (đổi `id` sang đối tượng của chủ thể khác) | 0 phát hiện Cao trước phát hành | Nhóm kiểm thử | KT |
| SEC-43 | Kiểm tra đầu vào và hợp đồng API | APISIX chỉ công bố route khai báo trong OpenAPI đã duyệt; plugin `request-validation` kiểm tra lược đồ cho API của HTTT; DU kiểm tra lại bằng Bean Validation từ OpenAPI sinh mã; giới hạn thân yêu cầu mặc định 1 MB (API), 50 MB (tải tệp), độ sâu JSON ≤ 32, số phần tử mảng ≤ 10.000; bộ phân tích XML tắt DTD (`disallow-doctype-decl`), thực thể ngoài, XInclude; không dùng giải tuần tự hóa Java gốc; lỗi trả RFC 9457 không có stack trace, phiên bản; tắt `/actuator` ngoài `health`, `prometheus` trên cổng quản lý riêng | 0 route không có lược đồ; 0 lỗi 5xx từ fuzzing | Nhóm phát triển, nhóm PH-03 | CI, KT |
| SEC-44 | Bảo vệ phía trình duyệt | Header do BFF đặt: `Content-Security-Policy: default-src 'self'; script-src 'self' 'nonce-{n}'; style-src 'self' 'nonce-{n}'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'; object-src 'none'`, `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` tắt camera/micro/địa vị; Trusted Types bật ở chế độ báo cáo rồi bắt buộc; Subresource Integrity cho tài nguyên tĩnh; chống CSRF bằng `SameSite=Strict` + token đồng bộ cho thao tác thay đổi + kiểm tra `Origin`; React không dùng HTML thô, Markdown hiển thị qua bộ lọc (DOMPurify) | Điểm A trên bộ kiểm tra header nội bộ; 0 vi phạm CSP trên luồng chính | Nhóm giao diện | CI, KT |
| SEC-45 | Xử lý tệp tải lên | Kiểm tra phần mở rộng và kiểu theo nội dung (Apache Tika) trong danh sách cho phép (.xlsx, .csv, .json, .xml, .yaml, .pdf cho tài liệu); giới hạn kích thước 50 MB, kích thước giải nén ≤ 200 MB, tỉ lệ nén ≤ 100:1, số mục trong gói ≤ 1.000; đọc .xlsx bằng chế độ luồng (SAX/`XSSFReader`), `ZipSecureFile.setMinInflateRatio(0.01)`; giới hạn 1.000.000 dòng; quét mã độc ClamAV trước khi xử lý; lưu tệp với tên do hệ thống sinh trong bucket riêng, không bao giờ thực thi; khi xuất CSV/Excel, ô bắt đầu bằng `=`, `+`, `-`, `@`, tab, CR được thêm dấu nháy đơn đầu; khi nhập, cảnh báo ô có dạng công thức | Bộ tệp tấn công mẫu (zip bomb, XXE, công thức) bị từ chối 100% | Nhóm phát triển (thư viện `dh-import`) | KT |
| SEC-46 | An toàn trình thiết kế luồng | Luồng chỉ được dùng Kamelet và component trong danh sách được duyệt (PH-05); ngôn ngữ biểu thức cho phép: `simple` (chế độ hạn chế, không gọi bean/phương thức), `jq`, `jsonpath`, `xpath` (bảo mật); cấm `groovy`, `js`, `ognl`, `mvel`, `spel`, `bean`, `class`, `exec`, `file` ghi ra đĩa, `ssh`, `language`; trình kiểm tra tĩnh YAML ở `dh-integration` khi lưu và lần nữa trong CI của kho Git cấu hình (chặn merge); đích HTTP/SOAP/CSDL chỉ được tham chiếu qua "kết nối" đã đăng ký và duyệt (không nhận URL tự do), DNS của đích được phân giải và kiểm tra không thuộc dải nội bộ ở thời điểm kết nối; giới hạn thời gian mỗi bước biểu thức 2 giây, kích thước bản tin 10 MB; chạy thử ở namespace sandbox với dữ liệu giả và egress bị chặn trừ đích sandbox | 0 luồng chứa thành phần ngoài danh sách được phát hành (CI) | Nhóm PH-04/PH-05 | CI, PT |
| SEC-47 | Webhook có ký và chống phát lại | Theo mẫu Standard Webhooks: header `webhook-id` (ULID), `webhook-timestamp` (giây Unix), `webhook-signature: v1,{base64(HMAC-SHA256(khóa, id.timestamp.body))}`; bên nhận từ chối nếu lệch thời gian > 5 phút hoặc `webhook-id` đã gặp; hỗ trợ hai khóa song song khi xoay vòng; URL đích phải HTTPS, đăng ký qua PH-10 có duyệt, được phân giải và chặn dải nội bộ/siêu dữ liệu; thử lại với lùi thời gian theo cấp số, sau 24 giờ chuyển DLQ. Datahub nhận webhook từ ngoài (ví dụ PayGov) theo cùng nguyên tắc với thuật toán của bên gửi | Thư viện kiểm chứng mẫu cung cấp cho HTTT (Java, .NET, PHP, Node) | Nhóm PH-10 | KT |
| SEC-48 | An toàn thanh toán | Callback PayGov: xác minh chữ ký theo đặc tả (khóa công khai của PayGov ghim trong truststore), giới hạn nguồn nếu PayGov công bố dải; **không tin kết quả từ chuyển hướng trình duyệt**, chỉ cập nhật trạng thái từ callback máy–máy hoặc truy vấn trạng thái chủ động; so khớp mã giao dịch, số tiền (`T-MONEY`), đơn vị tiền, mã dịch vụ, mã đơn vị thụ hưởng với bản ghi gốc, sai lệch thì đánh dấu `MISMATCH` và cảnh báo; máy trạng thái giao dịch chỉ cho chuyển tiếp hợp lệ (`PENDING→PAID` một lần); idempotency theo mã giao dịch của nhà cung cấp (ràng buộc duy nhất CSDL); đối soát tệp hằng ngày; hoàn tiền bắt buộc bốn mắt và step-up MFA; giới hạn giá trị hoàn tiền mỗi ngày theo tenant | 100% callback sai chữ ký/sai số tiền bị từ chối (KT với bộ ca tấn công); đối soát lệch = 0 sau xử lý | Nhóm PH-19 | KT, PT |
| SEC-49 | An toàn trợ lý AI | `dh-assist` tắt mặc định, tenant bật bằng quyết định có ghi kiểm toán; mặc định dùng mô hình triển khai nội bộ, mô hình ngoài chỉ khi tenant bật riêng, nhà cung cấp lưu dữ liệu trong nước và cam kết không huấn luyện; chỉ lập chỉ mục dữ liệu Công khai/Nội bộ (mô tả API, tài liệu, danh mục), chỉ mục pgvector có `tenant_id` và RLS; mọi công cụ (tool) của trợ lý chạy với token của người dùng hiện tại qua APISIX (không có quyền riêng), chỉ đọc; hành động ghi (ví dụ tạo bản nháp ánh xạ) chỉ đề xuất, người dùng xác nhận; nội dung lấy từ dữ liệu được bọc như dữ liệu không tin cậy trong prompt; bộ lọc đầu ra che mẫu DLCN; giới hạn số lượt và độ dài; ghi nhật ký prompt/đáp (đã che) 90 ngày | Bộ ca tiêm lệnh mẫu (≥ 50 ca) không làm trợ lý gọi công cụ ngoài ý định | Nhóm PH-17 | KT, PT |

: Biện pháp SEC-40…49 về ứng dụng, API và phát triển an toàn

Hai biện pháp SEC-46 và SEC-48 cần lập luận thêm. Với SEC-46, cách an toàn nhất là không cho người dùng viết logic tùy ý; nhưng Datahub thay hệ cũ nơi kỹ sư viết Camel XML tự do, nên một số luồng di trú sẽ dùng thành phần bị cấm. Quy tắc là: luồng di trú cần thành phần ngoài danh sách thì được viết lại thành Kamelet mới qua quy trình đăng ký Kamelet (PH-05) do nhóm nền tảng review mã, chứ không mở ngoại lệ trong luồng. Như vậy logic tùy biến luôn nằm trong mã được review và ký, còn YAML của luồng chỉ là cấu hình.

Với SEC-48, nguyên tắc cốt lõi là "kết quả thanh toán chỉ đến từ kênh máy–máy được xác thực và phải khớp với điều Datahub đã yêu cầu". Tham số trên URL quay về của trình duyệt chỉ dùng để hiển thị trang chờ; trạng thái hồ sơ chỉ đổi khi callback hợp lệ hoặc truy vấn trạng thái chủ động xác nhận. Nếu PayGov không có API truy vấn trạng thái (Q302), lớp đối soát tệp cuối ngày là chốt chặn cuối cùng, và hệ thống nghiệp vụ được khuyến nghị không cấp kết quả thủ tục có giá trị cao trước khi đối soát.

### 5.7. Nhóm SEC-50…59: Nền tảng, container, Kubernetes và chuỗi cung ứng

Nhóm này tăng cứng lớp chạy (nút, container, cụm Kubernetes) và kiểm soát đường đi của mã từ nguồn đến môi trường chạy. Bảng dưới đây nêu từng biện pháp, tham số và cách kiểm chứng.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-50 | Tăng cứng nút và hệ điều hành | Hệ điều hành tối giản cho K8s (Talos Linux, Flatcar hoặc RHEL-compatible tối giản theo D03-09) với cấu hình theo CIS Benchmark mức 1; không SSH thường trực (Talos dùng API có mTLS); SELinux/AppArmor bật; tắt dịch vụ thừa; ảnh hệ điều hành bất biến, thay nút thay vì sửa | kube-bench và CIS-CAT/OpenSCAP: ≥ 95% mục đạt, ngoại lệ ghi lý do | Bên cung cấp hạ tầng, nhóm nền tảng | RS |
| SEC-51 | Tăng cứng control plane Kubernetes | API server: `--anonymous-auth=false`, OIDC, RBAC, admission `NodeRestriction`, audit policy ghi mức `RequestResponse` cho Secret/RBAC/exec và `Metadata` cho phần còn lại, đẩy audit log ra SIEM; etcd mã hóa Secret bằng KMS provider v2 trỏ tới OpenBao transit; etcd chỉ nhận mTLS từ API server; kubelet `--anonymous-auth=false`, `--authorization-mode=Webhook`; phiên bản K8s trong cửa sổ hỗ trợ (≥ 1.31) | kube-bench mục control plane: 0 FAIL chưa có ngoại lệ | Nhóm nền tảng | CI (kube-bench hằng tuần) |
| SEC-52 | Pod Security và chính sách admission | Nhãn `pod-security.kubernetes.io/enforce: restricted` cho mọi namespace ứng dụng; ngoại lệ (Cilium, Istio ztunnel, CSI) ở namespace hệ thống có danh sách. Kyverno (chế độ `Enforce`) bổ sung: cấm `privileged`, `hostPath`, `hostNetwork`, `hostPID`; bắt buộc `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`, `capabilities.drop: [ALL]`, `seccompProfile: RuntimeDefault`; bắt buộc `resources.limits`; cấm thẻ ảnh `latest`, bắt buộc tham chiếu theo digest; cấm `automountServiceAccountToken` khi không cần; Kyverno chạy HA, `failurePolicy: Fail` | 0 vi phạm trên PROD (báo cáo PolicyReport) | Nhóm nền tảng | CI (kyverno test), KT |
| SEC-53 | RBAC Kubernetes và service account | Mỗi DU một service account riêng, không gán Role nào trên API K8s trừ khi cần (ví dụ Strimzi, CNPG operator); không ai trong nhóm phát triển có quyền ghi PROD; quyền người theo nhóm OIDC: `dh-viewer`, `dh-operator` (không đọc Secret, không exec), `dh-admin` (JIT qua SEC-28); `kubectl exec` vào pod PROD chỉ qua break-glass | 0 ClusterRoleBinding tới `cluster-admin` ngoài danh sách hệ thống | Nhóm nền tảng | RS, CI |
| SEC-54 | Phòng chống mã độc và phát hiện lúc chạy | Phát hiện hành vi lúc chạy bằng Falco hoặc Tetragon (eBPF) với luật: shell trong container, ghi vào thư mục hệ thống, kết nối ra ngoài bất thường, đọc `/var/run/secrets` bởi tiến trình lạ, tải công cụ dò quét; ảnh không có trình biên dịch, shell (distroless/UBI-micro; Quarkus native trên ảnh tối giản); quét mã độc tệp tải lên (SEC-45); quét mã độc định kỳ máy trạm quản trị theo quy chế của chủ quản | Cảnh báo lúc chạy tới SIEM ≤ 1 phút | Nhóm nền tảng, vận hành ATTT | KT |
| SEC-55 | Bản dựng tái lập, SBOM, chứng thực nguồn gốc | Mọi ảnh do Datahub xây qua CI trên runner tạm thời; sinh SBOM CycloneDX (Syft/CycloneDX Maven plugin) và chứng thực nguồn gốc SLSA provenance (in-toto), đính kèm ảnh trong Harbor dưới dạng attestation ký cosign; ảnh nền chỉ từ danh sách ảnh gốc được duyệt và được mirror vào Harbor | 100% ảnh PROD có SBOM và provenance; mục tiêu SLSA Build L3 | Nhóm DevSecOps | CI |
| SEC-56 | Ký và xác minh ảnh | cosign ký ảnh bằng khóa trong OpenBao transit (KMS URI `hashivault://`) hoặc chế độ keyless với Fulcio/Rekor nội bộ khi triển khai được; Kyverno `verifyImages` trên mọi namespace: chỉ chấp nhận ảnh từ `harbor.example.gov.vn/datahub/*` và `harbor.example.gov.vn/mirror/*` có chữ ký của khóa phát hành và attestation SBOM; thành phần bên thứ ba được mirror, quét và ký lại bằng khóa "đã duyệt" | 0 pod chạy ảnh không ký (Kyverno chặn) | Nhóm DevSecOps | CI, KT |
| SEC-57 | Quét lỗ hổng ảnh và cổng phát hành | Trivy quét ảnh trong CI (chặn CRITICAL, chặn HIGH có bản sửa trừ ngoại lệ), Harbor quét lại khi đẩy và định kỳ hằng ngày, Trivy Operator quét ảnh đang chạy; ngoại lệ dùng tệp VEX có hạn | NFR-00-023 | Nhóm DevSecOps | CI |
| SEC-58 | Bảo vệ kho mã và CI/CD | Nhánh chính được bảo vệ: cấm đẩy trực tiếp, cấm force-push, ≥ 1 review (≥ 2 cho kho chính sách, kho cấu hình PROD, mã PH-19), CI xanh, commit ký (SSH/GPG/Sigstore gitsign); runner tạm thời cách ly, không dùng chung với dự án khác; CI lấy thông tin xác thực qua OIDC liên kết (OpenBao JWT auth) thay cho bí mật dài hạn; CODEOWNERS cho thư mục nhạy cảm; MFA bắt buộc cho tài khoản kho mã; rà soát quyền kho mã mỗi quý | 0 commit chưa review trên nhánh chính | Nhóm DevSecOps | RS, CI |
| SEC-59 | Bảo vệ GitOps và Argo CD | Argo CD trong Z7, SSO qua Keycloak, RBAC theo dự án; mỗi `AppProject` giới hạn kho nguồn, namespace đích và loại tài nguyên được phép (dự án `dh-flows-{tenant}` chỉ được tạo tài nguyên luồng trong `dh-rt-{tenant}`); chỉ service account của `dh-integration` được ghi kho luồng, qua PR tự động có duyệt; Argo CD xác minh chữ ký commit (GnuPG keys) trước khi đồng bộ; tự sửa lệch (self-heal) bật để thao tác tay bị hoàn tác và cảnh báo | 0 đồng bộ từ commit không ký | Nhóm nền tảng | KT, RS |

: Biện pháp SEC-50…59 về nền tảng, container, Kubernetes và chuỗi cung ứng

### 5.8. Nhóm SEC-60…69: Nhật ký, giám sát, phát hiện

Bảng dưới đây tóm tắt nhóm giám sát; thiết kế chi tiết (trường bắt buộc, chuỗi băm, thời hạn, luật phát hiện) ở mục 7.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-60 | Nhật ký kiểm toán ứng dụng | Sự kiện kiểm toán theo FR-00-040/041 do thư viện `dh-audit` sinh trong cùng giao dịch nghiệp vụ (outbox), PH-13 nhận và ghi chỉ-thêm (ADR-031); trường bắt buộc ở mục 7.1 | 100% thao tác thuộc FR-00-040 có bản ghi (kiểm thử đối chiếu) | Nhóm PH-13 | KT |
| SEC-61 | Nhật ký hệ thống và hạ tầng tập trung | Thu thập bằng OTel Collector/Fluent Bit: log ứng dụng JSON, sự kiện Keycloak, nhật ký quyết định OPA, log APISIX và WAF, audit log K8s, nhật ký OpenBao, `pgaudit` (DDL, vai trò, truy cập bảng Nhạy cảm), Hubble (luồng bị chặn), Falco/Tetragon | Độ trễ thu thập p95 ≤ 60 giây; mất log < 0,01% | Nhóm nền tảng | KT |
| SEC-62 | Toàn vẹn và lưu giữ nhật ký | Chuỗi băm theo tenant, neo băm ký hằng giờ, sao WORM Object Lock chế độ tuân thủ; trực tuyến 12 tháng, WORM 5 năm (ADR-031) | Công cụ kiểm tra chuỗi chạy hằng ngày: 0 đứt chuỗi | Nhóm PH-13, vận hành ATTT | KT, DT |
| SEC-63 | Tích hợp SIEM/SOC | Đẩy log an ninh ra SIEM của tỉnh/SOC qua syslog RFC 5424 trên TLS hoặc OTLP (IF-08); định dạng ánh xạ sang trường chung (ECS/OCSF); khi tỉnh chưa có SIEM, dùng Wazuh hoặc bộ luật cảnh báo trên Loki/Grafana trong gói Datahub làm SIEM tối thiểu | Độ trễ tới SIEM ≤ 5 phút | Đơn vị vận hành | KT |
| SEC-64 | Luật phát hiện và cảnh báo | Bộ luật UC-SEC-01…25 ở mục 7.5, có mức độ, ngưỡng và người nhận; mỗi luật có ca kiểm thử sinh sự kiện giả | MTTD ≤ 5 phút cho luật mức Nghiêm trọng (KPI-15) | Vận hành ATTT | KT, DT |
| SEC-65 | Giám sát toàn vẹn cấu hình | Argo CD phát hiện lệch so với Git; so khớp cấu hình realm Keycloak, chính sách OpenBao, cấu hình APISIX với nguồn khai báo hằng giờ; Kyverno PolicyReport; cảnh báo khi có thay đổi ngoài Git | Phát hiện lệch ≤ 1 giờ | Nhóm nền tảng | KT |
| SEC-66 | Kết nối giám sát với cơ quan chuyên trách | Chuẩn bị điểm xuất dữ liệu giám sát (syslog/OTLP, có lọc DLCN) để kết nối với hệ thống giám sát của đơn vị chuyên trách an ninh mạng hoặc Bộ Công an nếu quy định yêu cầu; có thể bật theo tenant | Sẵn sàng kết nối ≤ 5 ngày làm việc từ khi có yêu cầu | Chủ quản, đơn vị vận hành | RS |
| SEC-67 | Giám sát bất thường nghiệp vụ và gian lận | Luật trên dữ liệu PH-19 (tỉ lệ callback lỗi chữ ký, giao dịch `MISMATCH`, hoàn tiền vượt ngưỡng, hoàn tiền ngoài giờ), PH-14 (tra cứu hàng loạt, tra cứu ngoài giờ), PH-02 (đăng ký sử dụng hàng loạt), xuất dữ liệu số lượng lớn | Cảnh báo trong ≤ 15 phút | Nhóm PH-19, PH-14, vận hành ATTT | KT |

: Biện pháp SEC-60…69 về nhật ký, giám sát, phát hiện

### 5.9. Nhóm SEC-70…79: Sao lưu, liên tục hoạt động, ứng phó sự cố

Nhóm này bảo đảm Datahub khôi phục được sau sự cố hoặc phá hoại và ứng phó có tổ chức khi sự cố xảy ra. Quy trình ứng phó chi tiết ở mục 8; bảng dưới đây là các biện pháp tương ứng.

| Mã | Tên | Hiện thực trong Datahub | Tham số đo được | Chịu trách nhiệm | Kiểm chứng |
|---|---|---|---|---|---|
| SEC-70 | Sao lưu mã hóa, bất biến, ngoài site | CNPG backup (Barman Cloud plugin) liên tục WAL + bản đầy đủ hằng ngày; Velero cho tài nguyên K8s và volume; Kafka topic cấu hình qua Git; OpenBao snapshot Raft mã hóa mỗi giờ; tất cả gửi tới kho S3 ngoài site với Object Lock và thông tin xác thực ghi-không-xóa tách khỏi tài khoản vận hành (ADR-035, D03-09); quy tắc 3-2-1-1-0 | RPO ≤ 15 phút; khôi phục thử mỗi quý đạt 100% | Đơn vị vận hành | DT |
| SEC-71 | Khôi phục thảm họa và liên tục hoạt động | Hai site active–standby (ADR-034), RTO ≤ 1 giờ data plane, ≤ 4 giờ control plane; kế hoạch liên tục hoạt động có danh sách dịch vụ thiết yếu và thứ tự khôi phục | Diễn tập DR mỗi quý (NFR-00-014) | Đơn vị vận hành | DT |
| SEC-72 | Quy trình ứng phó sự cố | Quy trình 6 bước ở mục 8, phân mức sự cố, RACI, đầu mối 24/7, mốc báo cáo | Thời gian phân loại sự cố ≤ 30 phút | Chủ quản, đơn vị vận hành | DT |
| SEC-73 | Playbook và diễn tập | 8 playbook ở mục 8.5, cập nhật sau mỗi sự cố và mỗi lần diễn tập | Diễn tập 2 lần/năm | Vận hành ATTT | DT |
| SEC-74 | Báo cáo sự cố và thông báo vi phạm DLCN | Báo cáo sự cố an ninh mạng tới cơ quan có thẩm quyền theo Luật 116/2025; thông báo vi phạm DLCN trong 72 giờ theo Luật 91/2025; mẫu báo cáo soạn sẵn trong PH-13 | Đúng hạn 100% | Chủ quản | DT |
| SEC-75 | Pháp y và bảo toàn chứng cứ | Thu snapshot volume, bộ nhớ pod (khi cần), log, trace liên quan vào bucket chứng cứ có Object Lock; ghi chuỗi bảo quản chứng cứ (ai thu, khi nào, băm); cách ly pod nghi nhiễm bằng nhãn `quarantine=true` kích hoạt network policy chặn toàn bộ, không xóa pod trước khi thu chứng cứ | Có bộ công cụ thu chứng cứ được diễn tập | Vận hành ATTT | DT |

: Biện pháp SEC-70…79 về sao lưu, liên tục hoạt động, ứng phó sự cố

Các nhóm `SEC-80…89` (cách ly đa tenant) và `SEC-90…99` (bổ sung khi nâng lên cấp độ 4) được trình bày ở mục 9 và mục 10 vì chúng gắn với lập luận riêng.

## 6. Bảo vệ dữ liệu cá nhân

### 6.1. Ánh xạ từ Nghị định 13/2023 sang văn bản mới

Nhiều tài liệu của hệ cũ và yêu cầu ban đầu viện dẫn Nghị định 13/2023/NĐ-CP. Từ 01/01/2026, Nghị định này được thay bởi Luật Bảo vệ dữ liệu cá nhân số 91/2025/QH15 và Nghị định 356/2025/NĐ-CP. Các khái niệm cốt lõi được giữ (bên kiểm soát, bên xử lý, bên kiểm soát và xử lý; dữ liệu cá nhân cơ bản và nhạy cảm; đánh giá tác động; thông báo vi phạm trong 72 giờ; cơ quan chuyên trách là Cục A05 Bộ Công an), nên thiết kế chỉ cần đổi căn cứ viện dẫn, không đổi cơ chế. Những điểm cụ thể của Nghị định 356/2025 (mẫu hồ sơ, trường hợp miễn trừ cho cơ quan nhà nước, quy định về chuyển dữ liệu ra nước ngoài) chưa được đối chiếu toàn văn và được ghi thành câu hỏi mở.

> **Câu hỏi mở Q304:** Luật 91/2025 và NĐ 356/2025 có quy định riêng nào cho cơ quan nhà nước xử lý DLCN để thực hiện nhiệm vụ công (miễn sự đồng ý, miễn hoặc đơn giản hóa hồ sơ đánh giá tác động) không? Cần chuyên viên pháp chế đối chiếu toàn văn để chốt mục 6.3.

### 6.2. Vai trò của Datahub theo từng luồng

Vai trò pháp lý của bên vận hành Datahub với DLCN không cố định mà phụ thuộc loại dữ liệu, theo cách phân biệt "dữ liệu đi qua" và "dữ liệu lưu lại" ở SAD §8.3. Việc xác định đúng vai trò quyết định ai chịu nghĩa vụ đánh giá tác động, ai trả lời yêu cầu của chủ thể và ai thông báo vi phạm.

| Luồng dữ liệu | Ví dụ | Vai trò của chủ quản Datahub | Bên kiểm soát | Hệ quả thiết kế |
|---|---|---|---|---|
| Dữ liệu đi qua giữa hai HTTT | Sở Tư pháp gọi API dân cư của Sở X qua APISIX | Bên xử lý (chỉ truyền dẫn theo chỉ thị) | Cơ quan cung cấp và cơ quan khai thác (mỗi bên với mục đích của mình) | Không lưu nội dung; chỉ siêu dữ liệu; DLQ ≤ 7 ngày mã hóa; hợp đồng/quy chế kết nối ghi rõ vai trò |
| Khai thác CSDL quốc gia qua PH-14 | Tra cứu dân cư cho hồ sơ TTHC | Bên xử lý cho cơ quan khai thác của tỉnh; đồng thời là đầu mối kỹ thuật chịu trách nhiệm kiểm soát mục đích theo NĐ 278/2025 | Cơ quan khai thác của tỉnh | Bắt buộc mục đích, chấp thuận, nhật ký có băm khóa tra cứu (THR-51, THR-54) |
| Dữ liệu chủ PH-06 | Bản ghi vàng công dân, tổ chức | Bên kiểm soát và xử lý (Datahub quyết định cách đối sánh, hợp nhất, lưu trữ) | Chủ quản Datahub (cơ quan chủ quản của tỉnh) | Hồ sơ đánh giá tác động riêng; quyền chủ thể; thời hạn lưu |
| Giao dịch thanh toán PH-19 | Họ tên, số tiền, mã hồ sơ người nộp | Bên kiểm soát và xử lý (cùng với đơn vị thụ hưởng) | Chủ quản Datahub và đơn vị thụ hưởng | Thời hạn lưu theo quy định kế toán (Q305) |
| Danh mục dùng chung PH-07 | Thông thường không có DLCN | Không áp dụng (nếu có danh mục chứa DLCN, ví dụ danh sách cán bộ đầu mối, thì là bên kiểm soát) | — | PH-09 phân loại để phát hiện |
| Tài khoản người dùng, nhật ký kiểm toán | Họ tên, thư điện tử, IP của cán bộ | Bên kiểm soát | Chủ quản Datahub | Cơ sở pháp lý: thực hiện nhiệm vụ, bảo đảm an ninh |
| Nền tảng dùng chung (cloud) | Mọi dữ liệu của tenant | Nhà cung cấp nền tảng là bên xử lý cho chủ quản của từng tỉnh | Chủ quản của tỉnh | Hợp đồng xử lý dữ liệu; cách ly tenant (mục 9) |

: Vai trò xử lý dữ liệu cá nhân của Datahub theo từng luồng

> **Câu hỏi mở Q305:** Thời hạn lưu dữ liệu giao dịch thanh toán PH-19 có phải theo thời hạn lưu chứng từ kế toán (thường 10 năm với chứng từ dùng ghi sổ) hay do đơn vị thụ hưởng lưu, Datahub chỉ lưu bản tham chiếu ngắn hạn? Câu trả lời ảnh hưởng dung lượng WORM và sổ xử lý PH-09.

### 6.3. Cơ sở pháp lý và mục đích xử lý

Mỗi hoạt động xử lý DLCN của Datahub phải có cơ sở pháp lý ghi trong sổ xử lý PH-09. Với cơ quan nhà nước, cơ sở thường là thực hiện nhiệm vụ, quyền hạn theo luật (TTHC, kết nối chia sẻ bắt buộc theo NĐ 278/2025) thay vì sự đồng ý; sự đồng ý chỉ dùng cho tiện ích không bắt buộc (ví dụ đăng ký nhận thông báo). Về kỹ thuật, mục đích được mô hình hóa thành mã `purpose` (ví dụ `TTHC-HO-TICH`, `THONG-KE`) gắn vào đăng ký sử dụng API (PH-02) và vào token máy qua `scope`; OPA từ chối lời gọi tới hợp đồng có trường Nhạy cảm nếu `purpose` không nằm trong danh sách được chủ quản dữ liệu chấp thuận cho HTTT đó.

### 6.4. Đánh giá tác động xử lý dữ liệu cá nhân

Chủ quản Datahub lập hồ sơ đánh giá tác động xử lý DLCN cho các hoạt động mà Datahub là bên kiểm soát (PH-06, PH-19, tài khoản và nhật ký) và hồ sơ của bên xử lý cho phần truyền dẫn, gửi Cục A05 theo quy định. Tài liệu này và D03-08 cung cấp phần kỹ thuật của hồ sơ: mô tả luồng (mục 3.3, 4.2), biện pháp bảo vệ (mục 5), đánh giá rủi ro (mục 4). PH-09 lưu phiên bản hồ sơ và nhắc cập nhật khi thêm hoạt động xử lý mới hoặc tối thiểu mỗi năm.

### 6.5. Quyền của chủ thể dữ liệu

Datahub hỗ trợ chủ quản trả lời yêu cầu của chủ thể (biết, truy cập, chỉnh sửa, xóa, hạn chế xử lý, phản đối) cho dữ liệu Datahub làm chủ. PH-09 cung cấp công cụ tra cứu theo băm định danh để tìm mọi bản ghi liên quan một chủ thể trong PH-06 và PH-19, và tra nhật ký kiểm toán "ai đã truy cập dữ liệu của tôi" qua băm khóa tra cứu (bao gồm truy cập qua PH-14). Với dữ liệu đi qua, Datahub chuyển yêu cầu tới bên kiểm soát tương ứng vì Datahub không lưu nội dung. Thời hạn trả lời theo luật (cần xác minh số ngày ở NĐ 356/2025, Q304) được cấu hình làm hạn xử lý của quy trình PH-11.

### 6.6. Thông báo vi phạm và chuyển dữ liệu

Khi phát hiện vi phạm DLCN, quy trình ứng phó sự cố (mục 8) có nhánh bắt buộc: chủ quản thông báo cho Cục A05 trong 72 giờ kể từ khi phát hiện (SEC-74), bên xử lý (nhà cung cấp nền tảng) thông báo cho chủ quản trong ≤ 24 giờ để chủ quản kịp hạn. Datahub không chuyển dữ liệu ra nước ngoài: dữ liệu lưu trong lãnh thổ (RB-05), egress chỉ tới đích khai báo trong nước (SEC-16), mô hình AI ngoài chỉ được bật khi xử lý trong nước (SEC-49). Mọi ngoại lệ cần đánh giá tác động chuyển dữ liệu theo luật.

### 6.7. Che, giả danh hóa và vai trò của PH-09

Các biện pháp kỹ thuật bảo vệ DLCN được gom về PH-09 để có một nơi quản lý: danh mục phân loại trường (đầu vào cho SEC-31, SEC-32), sổ hoạt động xử lý, mục đích và chấp thuận (SEC-37), chính sách che theo vai trò (SEC-32), lịch xóa và giả danh hóa (SEC-38, SEC-39), công cụ hỗ trợ quyền chủ thể. Giả danh hóa trong Datahub dùng HMAC-SHA256 với khóa riêng theo tenant và theo mục đích (để hai bộ dữ liệu xuất cho hai mục đích không nối được với nhau), còn ẩn danh hóa cho thống kê dùng tổng hợp có ngưỡng k ≥ 10 và loại bỏ trường định danh gián tiếp hiếm.

## 7. Nhật ký kiểm toán và giám sát an ninh mạng

### 7.1. Hai loại nhật ký

Datahub tách rõ **nhật ký kiểm toán** (bằng chứng pháp lý: ai làm gì với đối tượng nào, khi nào, kết quả ra sao; không lấy mẫu, không sửa, lưu dài) và **log vận hành** (phục vụ gỡ lỗi và giám sát; có thể lấy mẫu, lưu ngắn). Nhầm lẫn hai loại dẫn tới hoặc mất bằng chứng do lấy mẫu, hoặc phình dung lượng vì lưu mọi log nhiều năm. Log an ninh (xác thực, WAF, audit K8s, OpenBao, quyết định OPA từ chối) là nhóm giữa: thuộc log vận hành về kênh thu thập nhưng được lưu 12 tháng và đẩy SIEM.

Bản ghi kiểm toán có các trường bắt buộc sau, mở rộng FR-00-041 bằng các trường phục vụ chuỗi băm và tra cứu DLCN.

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | `T-ID` | UUID v7 |
| `tenant_id` | `T-TENANT` | Tenant; tenant `PLATFORM` cho thao tác nền tảng |
| `seq` | `bigint` | Số thứ tự liên tục trong chuỗi của tenant |
| `occurred_at`, `recorded_at` | `T-TS` | Thời điểm xảy ra (từ DU) và thời điểm ghi (từ PH-13) |
| `actor_type`, `actor_id`, `actor_name` | `T-ENUM`, `T-ID`, `T-NAME` | Người (`USER`), máy (`CLIENT`), hệ thống (`SYSTEM`); khi thao tác liên tenant có thêm `actor_home_tenant` |
| `source_ip`, `user_agent`, `session_id` (băm) | — | Nguồn |
| `action` | `T-CODE` | Ví dụ `CATALOG.PUBLISH`, `PII.REVEAL`, `PAYMENT.REFUND.APPROVE` |
| `object_type`, `object_id`, `object_key_hmac` | — | Đối tượng; `object_key_hmac` là băm có khóa của khóa nghiệp vụ nhạy cảm (ví dụ số định danh được tra cứu) |
| `before`, `after` | `T-JSON` | Giá trị trước/sau đã che theo mục 3.2 |
| `outcome`, `error_code` | `T-ENUM`, `T-CODE` | `SUCCESS`, `DENIED`, `FAILED` |
| `reason`, `purpose` | `T-TEXT`, `T-CODE` | Lý do (bắt buộc với thao tác FR-00-050, xem Nhạy cảm, liên tenant), mục đích khai thác |
| `trace_id` | `T-TRACE` | Liên kết trace |
| `prev_hash`, `hash` | `char(64)` | Chuỗi băm (mục 7.2) |

: Hai loại nhật ký và các trường chung

### 7.2. Chuỗi băm, neo và WORM

Thiết kế theo ADR-031. PH-13 ghi bản ghi vào bảng `ph13_audit.audit_event` chỉ-thêm: vai trò ứng dụng chỉ có `INSERT` và `SELECT`, không có `UPDATE`, `DELETE`, `TRUNCATE`; trigger từ chối sửa đổi dù với vai trò nào trừ quy trình lưu trữ (archive) chạy bằng vai trò riêng chỉ được xóa phân vùng đã hết hạn trực tuyến và đã xác minh có trong WORM. Mỗi bản ghi có `hash = SHA-256(prev_hash || canonical_json(bản ghi không gồm hash))`, chuỗi riêng cho từng tenant để ghi song song và để xuất bằng chứng cho một tỉnh không lộ bản ghi tỉnh khác. Ghi được tuần tự hóa theo tenant bằng khóa tư vấn (advisory lock) hoặc một consumer Kafka mỗi phân vùng tenant.

Mỗi giờ, PH-13 tính neo (anchor) gồm `{tenant, seq cuối, hash cuối, thời điểm}`, ký bằng khóa transit `dh-audit-sign` và ghi vào ba nơi: bảng neo, kho WORM, và (khi được cấu hình) gửi tới SIEM của tỉnh. Kẻ tấn công muốn sửa nhật ký phải dựng lại chuỗi và giả chữ ký neo, đồng thời sửa được bản ở WORM và ở SIEM, là điều không khả thi với cả nội gián nền tảng. Bản ghi được sao sang WORM theo lô mỗi 5 phút dưới dạng tệp JSON Lines nén, kèm neo; bucket WORM bật S3 Object Lock chế độ tuân thủ (compliance), thời hạn giữ mặc định 5 năm, không rút ngắn được kể cả bằng tài khoản quản trị kho đối tượng.

Garage hiện chưa hỗ trợ đầy đủ S3 Object Lock; vì vậy SAD đã ghi lựa chọn SeaweedFS hoặc Ceph RGW cho WORM. Kho WORM phải là hệ lưu trữ riêng (khác cụm Garage dữ liệu nghiệp vụ), tốt nhất ở site DR hoặc hạ tầng do bên khác quản trị, để một sự cố quản trị ở site chính không chạm tới bằng chứng.

> **Q306 (đã chốt 25/11/2026):** chọn Ceph RGW với Object Lock chế độ compliance làm kho WORM. *Câu hỏi gốc:* Chọn SeaweedFS hay Ceph RGW (hoặc dịch vụ lưu trữ có Object Lock của cloud Chính phủ) cho kho WORM? Cần kiểm chứng chế độ compliance thực sự không thể rút ngắn trên phiên bản chọn; luồng C (D03-09) chốt.

Công cụ kiểm tra toàn vẹn chạy hằng ngày: duyệt lại chuỗi từ neo đã xác minh gần nhất, đối chiếu với bản WORM, báo cáo đứt chuỗi qua luật UC-SEC-20. Kiểm toán viên có công cụ xuất gói bằng chứng cho một tenant và khoảng thời gian, kèm neo và khóa công khai để tự xác minh ngoại tuyến.

### 7.3. Thời hạn lưu (chốt câu hỏi Q08 của SRS)

Bảng dưới đây chốt thời hạn lưu cho từng loại nhật ký. Căn cứ: NFR-00-027/028 của SRS; tài liệu PH-13 của repo đã dùng mức ≥ 5 năm cho nhật ký kiểm toán WORM; Luật An ninh mạng có yêu cầu lưu nhật ký phục vụ điều tra (thời hạn cụ thể trong văn bản hướng dẫn hiện hành chưa được xác minh); và TCVN 14423:2026 cấp độ 3 có yêu cầu về thời hạn lưu nhật ký mà giá trị chính xác chưa được đọc. Datahub chọn mức đủ dài để chặt hơn mọi giá trị thường gặp trong các văn bản trước đây (TCVN 11930:2017 cấp 3 và hướng dẫn cũ thường yêu cầu tối thiểu 3 tháng đến 1 năm trực tuyến) và phù hợp với chu kỳ thanh tra, kiểm toán nhà nước nhiều năm.

| Loại | Trực tuyến (tra cứu ngay) | Lưu trữ | Sau hạn |
|---|---|---|---|
| Nhật ký kiểm toán ứng dụng | 12 tháng (PostgreSQL phân vùng theo tháng) | WORM 5 năm kể từ ngày ghi; tenant có thể cấu hình dài hơn, không được ngắn hơn 3 năm | Xóa tự động khi Object Lock hết hạn, ghi biên bản |
| Neo băm | Vĩnh viễn trong thời gian vận hành (dung lượng nhỏ) | WORM như trên | — |
| Log an ninh (Keycloak, WAF, OPA từ chối, K8s audit, OpenBao, pgaudit, Falco) | 12 tháng | 3 năm ở kho lưu trữ nén (có thể cùng WORM) | Xóa |
| Log vận hành ứng dụng | 90 ngày (NFR-00-028) | Không | Xóa |
| Siêu dữ liệu lượt gọi API | 12 tháng (NFR-00-062) | Tổng hợp thống kê 5 năm | Xóa chi tiết |
| Trace | 14 ngày | Không | Xóa |
| Chỉ số | 13 tháng | Giảm độ phân giải lưu 5 năm | — |
| Ghi phiên đặc quyền (SEC-28) | 12 tháng | 3 năm | Xóa |

: Thời hạn lưu từng loại nhật ký (chốt Q08 của SRS)

Như vậy NFR-00-027 được chốt là "trực tuyến 12 tháng, lưu trữ WORM 5 năm (tối thiểu 3 năm)". Nếu văn bản hướng dẫn hiện hành (khi xác minh) yêu cầu thời hạn dài hơn, giá trị cấu hình được nâng lên mà không đổi thiết kế; vì Object Lock chỉ cho kéo dài, không cho rút ngắn, việc bắt đầu với 5 năm là lựa chọn an toàn.

> **Câu hỏi mở Q307:** Văn bản hướng dẫn Luật An ninh mạng 116/2025 và TCVN 14423:2026 (mục nhật ký ở chương 5) quy định thời hạn lưu nhật ký tối thiểu cụ thể bao nhiêu cho hệ cấp độ 3? Nếu > 5 năm, nâng cấu hình mặc định.

### 7.4. Tích hợp SIEM/SOC của tỉnh

Datahub không đặt giả định tỉnh nào cũng có SOC. Thiết kế có ba mức: (1) tỉnh có SIEM/SOC: Datahub đẩy log an ninh và cảnh báo qua IF-08 (syslog RFC 5424 trên TLS, hoặc OTLP), mỗi sự kiện có trường chuẩn hóa (`event.category`, `event.action`, `user.id`, `source.ip`, `tenant`, `trace_id`) theo ECS hoặc OCSF; (2) tỉnh chưa có SOC: gói Datahub kèm SIEM tối thiểu (Wazuh, hoặc luật cảnh báo trên Loki + Alertmanager) và bảng điều khiển an ninh trên Grafana, cảnh báo tới đầu mối ATTT qua thư điện tử, tin nhắn; (3) nền tảng dùng chung: SOC của nhà cung cấp nền tảng giám sát toàn nền tảng, đồng thời mỗi tỉnh nhận luồng sự kiện đã lọc theo tenant để đẩy vào SOC của tỉnh. Ở cấp độ 4, mức (2) không còn được chấp nhận (SEC-95).

Kết nối giám sát với cơ quan chuyên trách (SEC-66) dùng cùng điểm xuất, có bộ lọc loại bỏ DLCN; phạm vi và giao thức theo yêu cầu cụ thể của cơ quan khi có văn bản.

> **Câu hỏi mở Q308:** NĐ 331/2026 hoặc văn bản hướng dẫn có bắt buộc hệ cấp độ 3 kết nối, chia sẻ dữ liệu giám sát với hệ thống giám sát của Bộ Công an (hoặc của tỉnh) không, và theo giao thức nào?

### 7.5. Use case phát hiện

Bảng dưới đây là bộ luật phát hiện khởi điểm (SEC-64). Mỗi luật có mức độ (NT nghiêm trọng, C cao, TB trung bình), nguồn dữ liệu, ngưỡng và người nhận mặc định. Ngưỡng được tinh chỉnh sau 30 ngày chạy ở PROD để giảm cảnh báo nhầm; mỗi luật có ca kiểm thử sinh sự kiện giả trong D05-01.

| Mã | Luật | Nguồn | Ngưỡng mặc định | Mức | Mối đe dọa |
|---|---|---|---|---|---|
| UC-SEC-01 | Đăng nhập sai hàng loạt từ một IP hoặc trên nhiều tài khoản | Keycloak | ≥ 20 lần sai/5 phút/IP hoặc ≥ 10 tài khoản khác nhau/IP | C | THR-12 |
| UC-SEC-02 | Đăng nhập thành công của quản trị từ quốc gia/ASN mới hoặc ngoài giờ | Keycloak | Lần đầu thấy ASN; 22:00–06:00 | C | THR-09 |
| UC-SEC-03 | Tắt MFA, xóa yếu tố thứ hai, đặt lại mật khẩu quản trị | Keycloak admin events | Mọi sự kiện | C | THR-09, THR-38 |
| UC-SEC-04 | Sử dụng tài khoản break-glass | Keycloak, PAM | Mọi lần | NT | THR-60 |
| UC-SEC-05 | Gán vai trò quản trị hoặc vai trò nền tảng | Keycloak, PH-12 | Mọi sự kiện | C | THR-38 |
| UC-SEC-06 | Token bị từ chối do sai `cnf`, sai `aud`, `iss` không khớp tenant | APISIX | ≥ 5/phút/client | C | THR-02, THR-06 |
| UC-SEC-07 | Client gọi từ IP mới hoặc vượt 5 lần lưu lượng trung bình 7 ngày | APISIX | Như mô tả | TB | THR-02 |
| UC-SEC-08 | Tỉ lệ `403`/`404` cao của một chủ thể (dò đối tượng, BOLA) | APISIX, OPA | ≥ 50 từ chối/5 phút | C | THR-03 |
| UC-SEC-09 | Từ chối do tenant không khớp (header, sự kiện Kafka, RLS lỗi `app.tenant_id`) | DU, Kafka consumer, PostgreSQL | Mọi sự kiện | NT | THR-29, THR-30 |
| UC-SEC-10 | Tra cứu CSDL quốc gia hàng loạt hoặc ngoài giờ | PH-14 | ≥ 500 khóa khác nhau/giờ/HTTT hoặc ngoài giờ vượt 3 lần trung bình | C | THR-51 |
| UC-SEC-11 | Xem đầy đủ dữ liệu Nhạy cảm nhiều lần | PH-13 audit `PII.REVEAL` | ≥ 20 lần/giờ/người | C | THR-33 |
| UC-SEC-12 | Xuất dữ liệu số lượng lớn | PH-13 audit | ≥ 100.000 dòng/ngày/người | TB | THR-33 |
| UC-SEC-13 | Callback thanh toán sai chữ ký hoặc `MISMATCH` số tiền | PH-19 | ≥ 1 sự kiện | C | THR-46, THR-48 |
| UC-SEC-14 | Hoàn tiền vượt ngưỡng hoặc ngoài giờ | PH-19 | Tổng ngày > ngưỡng tenant | C | THR-49 |
| UC-SEC-15 | WAF chặn tấn công tiêm, hoặc tăng đột biến luật CRS | Coraza | ≥ 100 lần chặn/5 phút/IP | TB | THR-04, THR-45 |
| UC-SEC-16 | Lưu lượng bất thường tới biên (dấu hiệu DDoS) | APISIX, LB | > 3 lần cao điểm 5 phút | NT | THR-01 |
| UC-SEC-17 | Egress bị chặn từ pod ứng dụng | Hubble, Istio egress | ≥ 1 lần với đích lạ | C | THR-15, THR-45 |
| UC-SEC-18 | Shell hoặc tiến trình lạ trong container | Falco/Tetragon | Mọi sự kiện | NT | THR-14, THR-58 |
| UC-SEC-19 | Pod bị Kyverno chặn vì ảnh không ký hoặc vi phạm PSS | Kyverno | Mọi sự kiện ở PROD | C | THR-42 |
| UC-SEC-20 | Đứt chuỗi băm nhật ký hoặc neo không khớp | PH-13 | Mọi sự kiện | NT | THR-34 |
| UC-SEC-21 | Lệch cấu hình so với Git (Argo CD OutOfSync do thay đổi tay, realm, APISIX) | Argo CD, SEC-65 | Mọi sự kiện ở PROD | C | THR-38, THR-44 |
| UC-SEC-22 | Truy cập Secret K8s, `exec` vào pod PROD, tạo ClusterRoleBinding | K8s audit | Mọi sự kiện ngoài service account hệ thống | C | THR-60, THR-62 |
| UC-SEC-23 | OpenBao: đăng nhập root, thay đổi chính sách, từ chối truy cập hàng loạt | OpenBao audit | Root: mọi lần (NT); từ chối ≥ 20/5 phút (C) | NT/C | THR-36, THR-37 |
| UC-SEC-24 | Chứng thư sắp hết hạn hoặc bị thu hồi vẫn được dùng | cert-manager, APISIX | ≤ 21 ngày; mọi lần dùng chứng thư thu hồi | TB/C | THR-08 |
| UC-SEC-25 | Truy cập liên tenant | PH-13 audit | Mọi sự kiện (thông báo cho quản trị tỉnh bị truy cập) | TB | THR-38 |

: Use case phát hiện UC-SEC và nguồn, ngưỡng, hành động

## 8. Ứng phó sự cố

### 8.1. Phân loại mức sự cố

Sự cố an ninh mạng được phân bốn mức để quyết định tốc độ phản ứng và ai phải được báo. Mức được gán khi phân loại ban đầu và có thể nâng trong quá trình xử lý.

| Mức | Tiêu chí (một trong các điều kiện) | Thời gian phản hồi đầu tiên | Người chỉ huy |
|---|---|---|---|
| P1 Nghiêm trọng | Lộ DLCN hoặc rò rỉ chéo tenant đã xác nhận; ransomware; chiếm quyền quản trị nền tảng, OpenBao hoặc chuỗi cung ứng; data plane ngừng toàn tỉnh > 30 phút do tấn công; gian lận thanh toán đã ghi nhận | ≤ 15 phút, 24/7 | Trưởng nhóm ứng phó; báo ngay lãnh đạo chủ quản |
| P2 Cao | Tài khoản quản trị tỉnh hoặc client HTTT bị chiếm nhưng chưa xác nhận lộ dữ liệu; khai thác lỗ hổng đang diễn ra; DDoS gây suy giảm | ≤ 30 phút, 24/7 | Trưởng ca vận hành ATTT |
| P3 Trung bình | Lỗ hổng nghiêm trọng mới công bố ảnh hưởng thành phần đang chạy; mã độc bị chặn; vi phạm chính sách nội bộ | ≤ 4 giờ làm việc | Đầu mối ATTT |
| P4 Thấp | Quét dò, cảnh báo nhầm cần tinh chỉnh | ≤ 1 ngày làm việc | Vận hành |

: Phân loại mức sự cố P1…P4, thời gian phản hồi và người chỉ huy

### 8.2. Quy trình

Quy trình ứng phó dưới đây áp dụng cho mọi sự cố, đi từ phát hiện đến rút kinh nghiệm, và tách hai nhánh thông báo bắt buộc: thông báo vi phạm dữ liệu cá nhân tới A05 trong 72 giờ theo Luật BVDLCN 91/2025/QH15, và báo cáo sự cố an ninh mạng tới cơ quan có thẩm quyền.

```{.mermaid caption="Sơ đồ quy trình ứng phó sự cố ATTT và hai nhánh thông báo bắt buộc"}
flowchart TB
  A[Phát hiện<br/>cảnh báo SIEM, báo cáo người dùng,<br/>thông báo cơ quan] --> B[Phân loại<br/>xác nhận, gán mức P1–P4]
  B -->|P1/P2| C[Ngăn chặn ngắn hạn<br/>cô lập, thu hồi, chặn]
  B -->|P3/P4| F
  C --> D[Thu chứng cứ<br/>SEC-75]
  D --> E[Loại trừ và khôi phục<br/>vá, xoay khóa, khôi phục sạch]
  E --> F[Theo dõi tăng cường]
  F --> G[Rút kinh nghiệm<br/>≤ 10 ngày làm việc]
  B -->|có DLCN| N[Nhánh thông báo<br/>A05 ≤ 72 giờ]
  B -->|sự cố ANM| R[Báo cáo cơ quan<br/>có thẩm quyền]
  G --> H[Cập nhật THR, SEC,<br/>playbook, luật phát hiện]
```

Quy trình theo sáu bước kinh điển (chuẩn bị là SEC-72/73 có trước). Hai nhánh thông báo chạy song song ngay khi phân loại xác định có liên quan DLCN hoặc là sự cố an ninh mạng phải báo cáo, không đợi xử lý xong, vì thời hạn 72 giờ tính từ khi phát hiện. Bước thu chứng cứ đặt trước loại trừ: không xóa pod, không khôi phục đè lên volume nghi nhiễm trước khi đã chụp. Bước cuối biến bài học thành thay đổi cụ thể trong tài liệu này (mối đe dọa mới, biện pháp mới) và trong bộ luật phát hiện.

Hình dưới đây vẽ riêng đồng hồ 72 giờ của nhánh thông báo vi phạm dữ liệu cá nhân, để đội ứng phó thấy ngay mốc nào bên nào phải hoàn thành.

```{.mermaid caption="Sơ đồ các mốc thông báo vi phạm dữ liệu cá nhân trong 72 giờ"}
flowchart TB
  T0["T0: Phát hiện sự cố có liên quan DLCN<br/>(đồng hồ 72 giờ bắt đầu)"] --> T1["Nhà cung cấp nền tảng báo chủ quản<br/>≤ 1 giờ với P1, ≤ 4 giờ với P2"]
  T1 --> T2["Bên xử lý báo bên kiểm soát<br/>≤ 24 giờ"]
  T2 --> T3["Bộ phận chuyên trách ANM đánh giá<br/>phạm vi, loại dữ liệu, số chủ thể"]
  T3 --> T4["Lãnh đạo chủ quản ký<br/>thông báo gửi A05"]
  T4 --> T5["Thông báo vi phạm tới A05<br/>≤ 72 giờ kể từ T0"]
  T5 --> T6["Thông báo chủ thể dữ liệu<br/>nếu có nguy cơ gây hại"]
```

Hình nhấn mạnh hai điều: đồng hồ chạy từ lúc phát hiện chứ không từ lúc kết luận, nên các bước nội bộ (1 giờ, 24 giờ) phải ngắn để chừa thời gian đánh giá và ký; và người ký thông báo là lãnh đạo chủ quản, vì vậy việc báo lên lãnh đạo ngay ở P1 là điều kiện để kịp hạn. Mốc gửi cơ quan an ninh mạng về sự cố ANM chưa chốt (Q309).

### 8.3. RACI

Bảng RACI dưới đây áp dụng cho sự cố P1/P2 (R: thực hiện, A: chịu trách nhiệm cuối cùng, C: được hỏi ý kiến, I: được thông báo). Ở hồ sơ tỉnh độc lập, "nhà cung cấp nền tảng" là nhà cung cấp sản phẩm theo hợp đồng hỗ trợ.

| Hoạt động | Lãnh đạo chủ quản | Bộ phận chuyên trách ANM | Đơn vị vận hành (TTDL/tỉnh) | Nhà cung cấp nền tảng | Chủ quản dữ liệu bị ảnh hưởng | Cơ quan có thẩm quyền |
|---|---|---|---|---|---|---|
| Phát hiện, phân loại | I | A | R | R (SOC nền tảng) | — | — |
| Ngăn chặn kỹ thuật | I | A | R | R | I | — |
| Quyết định tạm ngừng tenant/dịch vụ | A | R | C | C | C | — |
| Thu chứng cứ | — | A | R | R | — | C |
| Thông báo vi phạm DLCN tới A05 | A | R | C | C (cung cấp thông tin ≤ 24 giờ) | C | I |
| Báo cáo sự cố an ninh mạng | A | R | C | C | — | I |
| Thông báo chủ thể dữ liệu (nếu phải) | A | R | — | — | R | — |
| Khôi phục | I | A | R | R | I | — |
| Rút kinh nghiệm | I | A | R | R | C | — |

: Ma trận RACI của sự cố P1 và P2 theo bên liên quan

### 8.4. Mốc thời gian báo cáo

Các mốc sau là cam kết thiết kế; mốc pháp lý được đánh dấu và cần đối chiếu văn bản hướng dẫn.

| Mốc | Thời hạn | Căn cứ |
|---|---|---|
| Nhà cung cấp nền tảng báo chủ quản | ≤ 1 giờ với P1, ≤ 4 giờ với P2 kể từ khi xác nhận | Hợp đồng (SEC-05) |
| Bên xử lý báo bên kiểm soát vi phạm DLCN | ≤ 24 giờ | Hợp đồng, để bên kiểm soát kịp hạn luật |
| Thông báo vi phạm DLCN tới Cục A05 | ≤ 72 giờ kể từ khi phát hiện | Luật 91/2025 |
| Báo cáo sự cố an ninh mạng tới cơ quan chuyên trách | Theo văn bản hướng dẫn Luật 116/2025 (Q309) | Cần đối chiếu |
| Báo cáo kết thúc sự cố và rút kinh nghiệm | ≤ 10 ngày làm việc sau khi đóng | Nội bộ |

: Mốc thời gian báo cáo và thông báo sự cố

> **Câu hỏi mở Q309:** Thời hạn và mẫu báo cáo sự cố an ninh mạng theo Luật 116/2025 và NĐ 331/2026 (thay cho cơ chế điều phối ứng cứu sự cố cũ) là gì, gửi cơ quan nào ở cấp tỉnh?

### 8.5. Playbook tóm lược

Tám playbook dưới đây là bản tóm lược; bản đầy đủ từng bước, câu lệnh và danh sách liên lạc thuộc tài liệu vận hành D06-03. Mỗi playbook nêu điều kiện kích hoạt, hành động ngăn chặn trong giờ đầu, loại trừ, khôi phục và thông báo.

**PB-01 Lộ khóa API hoặc thông tin xác thực client HTTT.** Kích hoạt khi gitleaks phát hiện bí mật trong kho công khai, HTTT báo lộ, hoặc UC-SEC-06/07. Trong giờ đầu: vô hiệu client trong Keycloak và đẩy danh sách chặn tới APISIX (SEC-25, ≤ 60 giây); thu hồi chứng thư client nếu dùng mTLS (SEC-35); tra siêu dữ liệu lượt gọi 30 ngày của client để xác định lời gọi bất thường (IP, khối lượng, API). Loại trừ: cấp thông tin xác thực mới qua PH-01 theo phương thức mạnh hơn (chuyển sang mTLS nếu đang dùng `client_secret`). Nếu lời gọi bất thường chạm hợp đồng có DLCN thì kích hoạt nhánh thông báo 72 giờ.

**PB-02 Rò rỉ chéo tenant.** Kích hoạt từ UC-SEC-09, kiểm thử phát hiện, hoặc tỉnh báo thấy dữ liệu lạ. Đây luôn là P1. Trong giờ đầu: xác định API/luồng gây rò rỉ qua `trace_id`; tắt route đó tại APISIX hoặc tạm dừng luồng; nếu nghi lỗi diện rộng (ví dụ RLS bị vô hiệu), chuyển các DU liên quan về chế độ chỉ-đọc hoặc tạm ngừng tenant bị ảnh hưởng. Thu chứng cứ: log, audit, cấu hình vai trò CSDL. Loại trừ: sửa lỗi, thêm ca kiểm thử rò rỉ tái hiện vào bộ hồi quy (SEC-87). Thông báo: chủ quản của cả tenant bị lộ và tenant đã nhận dữ liệu; nhánh A05.

**PB-03 Ransomware hoặc phá hoại dữ liệu.** Kích hoạt khi Falco phát hiện mã hóa hàng loạt, volume không đọc được, bản sao lưu bị xóa thử. Trong giờ đầu: cô lập nút/namespace bị ảnh hưởng (nhãn quarantine, cordon nút), thu hồi thông tin xác thực vận hành có thể bị lộ, xác nhận bản sao lưu bất biến ngoài site còn nguyên (SEC-70). Không trả tiền chuộc. Khôi phục: dựng lại cụm từ Git (GitOps) và ảnh đã ký trên nút sạch, khôi phục CSDL về điểm trước thời điểm xâm nhập (PITR), xoay mọi bí mật. Mục tiêu theo RTO ở SEC-71; nếu site chính không tin cậy được thì chuyển sang site DR.

**PB-04 DDoS.** Kích hoạt từ UC-SEC-16. Trong giờ đầu: bật chế độ chống DDoS tăng cường ở tầng hạ tầng (liên hệ TTDL/nhà cung cấp cloud), siết giới hạn tầng 7 tại APISIX (chỉ cho phép IP nguồn của HTTT đã đăng ký vào API máy–máy, thách thức hoặc chặn theo quốc gia với đường dẫn giao diện nếu cần), ưu tiên tài nguyên cho API thiết yếu (đánh dấu ở PH-02). Theo dõi để phân biệt với tải hợp lệ cao điểm (đầu năm học, cuối tháng thanh toán).

**PB-05 Chiếm tài khoản quản trị.** Kích hoạt từ UC-SEC-02/03/05 hoặc người dùng báo. Trong giờ đầu: khóa tài khoản, thu hồi mọi phiên và refresh token, xem lại mọi thao tác của tài khoản trong 30 ngày (audit), hoàn tác thay đổi cấu hình nguy hiểm (Argo CD đồng bộ lại từ Git; realm Keycloak áp lại cấu hình từ Git), kiểm tra tài khoản/client mới được tạo bởi tài khoản đó. Loại trừ: đặt lại thông tin xác thực, đăng ký lại WebAuthn có kiểm tra danh tính trực tiếp.

**PB-06 Gian lận callback thanh toán.** Kích hoạt từ UC-SEC-13/14 hoặc đối soát lệch. Trong giờ đầu: chuyển các giao dịch liên quan về trạng thái chờ xác minh, tạm khóa cấp kết quả hồ sơ phụ thuộc, truy vấn trạng thái thực tại PayGov, đối chiếu tệp đối soát. Nếu phát hiện khóa ký hoặc kênh bị xâm phạm: xoay khóa với PayGov theo thủ tục của PayGov. Thông báo đơn vị thụ hưởng và cơ quan tài chính theo quy chế; giữ chứng cứ cho điều tra.

**PB-07 Lỗ hổng 0-day trong thư viện.** Kích hoạt khi có công bố lỗ hổng nghiêm trọng (cảnh báo từ cơ quan chuyên trách, CVE mức CRITICAL đang bị khai thác). Trong giờ đầu: dùng SBOM (SEC-55) và Trivy Operator xác định mọi ảnh và tenant chứa thành phần; triển khai luật vá ảo tại WAF (≤ 4 giờ); xác nhận egress đang bị chặn (giảm khả năng khai thác kiểu tải mã từ xa); tắt tính năng liên quan nếu được. Loại trừ: phát hành bản vá qua CI theo SLA 24–72 giờ (SEC-09); tra log để tìm dấu hiệu đã bị khai thác trước khi vá.

**PB-08 Xâm phạm chuỗi cung ứng.** Kích hoạt khi thư viện, ảnh nền hoặc công cụ CI được công bố bị cài mã độc, hoặc Kyverno chặn ảnh không ký bất thường. Trong giờ đầu: đóng băng phát hành; xác định bản dựng bị ảnh hưởng qua SBOM và provenance; thu hồi khóa ký nếu nghi lộ (chuyển sang khóa mới, cập nhật chính sách Kyverno chỉ tin khóa mới, ký lại ảnh sạch); xoay thông tin xác thực CI. Khôi phục: dựng lại từ commit đã xác minh, trên runner mới. Thông báo các tỉnh tự vận hành đã nhận bản phát hành bị ảnh hưởng qua kênh bảo mật của nhà cung cấp.

## 9. Cách ly đa tenant dưới góc độ an ninh

D03-10 là nguồn sự thật về cơ chế cách ly theo tầng. Mục này không lặp lại cơ chế mà đặt chúng thành biện pháp an ninh có mã, bổ sung ba điểm D03-10 chưa xử lý: cách ly mật mã (khóa riêng theo tenant), truy cập liên tenant dưới góc nhìn kiểm soát đặc quyền, và cách kiểm chứng liên tục. Nguyên tắc chung là **phòng thủ nhiều lớp**: một lỗi ở một lớp (ví dụ mã ứng dụng quên điều kiện) không được dẫn tới rò rỉ, vì lớp dưới (RLS, ACL, khóa mật mã) vẫn chặn.

| Mã | Tên | Hiện thực (bổ sung cho D03-10) | Tham số đo được | Kiểm chứng |
|---|---|---|---|---|
| SEC-80 | Xác định tenant từ token | Tenant chỉ lấy từ token đã xác minh (D03-10 §3); APISIX xóa `X-DH-*` client gửi; DU chỉ tin `X-DH-Tenant` khi đến từ APISIX qua mesh (kiểm tra SPIFFE ID người gọi) | 0 API đọc tenant từ tham số (luật Semgrep) | CI, PT |
| SEC-81 | RLS bắt buộc và tự kiểm tra | `FORCE ROW LEVEL SECURITY`, vai trò không `BYPASSRLS`, không là chủ sở hữu bảng; `SET LOCAL app.tenant_id` trong giao dịch, bộ kiểm tra khi lấy kết nối từ pool xác nhận biến rỗng; DU từ chối khởi động nếu phát hiện bảng thiếu chính sách | 100% bảng nghiệp vụ có chính sách (lint migration) | CI, KT |
| SEC-82 | Cách ly Kafka, kho đối tượng, bộ đệm, kho bí mật | ACL Kafka theo tiền tố và principal; bucket và khóa truy cập theo tenant; khóa Valkey qua hàm tạo tên; chính sách OpenBao theo đường dẫn tenant; nhóm Apicurio theo tenant | Kiểm thử ACL âm tính khi khởi tạo tenant: 100% đạt | KT |
| SEC-83 | Cách ly thời gian chạy | Namespace `dh-rt-{tenant}` cho tenant lớn hoặc có hợp đồng Nhạy cảm; `ResourceQuota`, `LimitRange` theo namespace; network policy chặn giao tiếp giữa namespace runtime của tenant khác nhau; bản tin của tenant A không được xử lý trong pod của tenant B ở namespace chung (định tuyến theo nhãn) | 0 luồng giữa namespace runtime khác tenant (Hubble) | KT |
| SEC-84 | Cách ly quan sát và nhật ký | Nhãn `tenant` bắt buộc (OTel Collector từ chối dữ liệu thiếu nhãn); Grafana tách organization; Loki/Mimir/Tempo dùng `X-Scope-OrgID` theo tenant (multi-tenancy gốc của LGTM); chuỗi băm kiểm toán theo tenant | Quản trị tỉnh chỉ truy vấn được dữ liệu tenant mình (KT) | KT |
| SEC-85 | Truy cập liên tenant có kiểm soát | Chỉ vai trò nền tảng; qua API nhóm `/api/platform/`; bắt buộc lý do và mã phiếu hỗ trợ; quyền có thời hạn (JIT ≤ 4 giờ) do người thứ hai duyệt; mỗi truy cập sinh bản ghi kiểm toán trong chuỗi của **tenant bị truy cập** và thông báo cho quản trị tỉnh đó (UC-SEC-25); thống kê toàn nền tảng chỉ dùng dữ liệu tổng hợp | 100% truy cập liên tenant có lý do và thông báo | KT, RS |
| SEC-86 | Hạn mức chống hàng xóm ồn ào | Hạn mức D03-10 §5.3 thực thi tại APISIX, Kafka quota, ResourceQuota; cảnh báo khi tenant đạt 80% | Một tenant vượt hạn mức không làm tăng p95 tenant khác quá 10% (kiểm thử tải) | KT |
| SEC-87 | Kiểm thử rò rỉ chéo tenant liên tục | Bộ kiểm thử bắt buộc trong CI (mỗi API mới ≥ 1 ca, kỳ vọng `404`); kiểm thử định kỳ hằng ngày trên môi trường thử với hai tenant giả; kiểm thử ACL Kafka/S3/OpenBao; mục riêng trong pentest | 100% API có ca kiểm thử (FR-00-011) | CI, KT, PT |
| SEC-88 | Cách ly mật mã theo tenant | KEK riêng cho mỗi tenant (ADR-032), khóa HMAC tìm kiếm riêng, khóa SSE kho đối tượng riêng; dữ liệu của tenant A dù bị đọc nhầm ở tầng lưu trữ cũng không giải mã được bằng ngữ cảnh tenant B vì AAD chứa `tenant_id`; hủy KEK khi chấm dứt tenant (xóa mật mã) | 100% tenant có KEK riêng | KT |

: Biện pháp SEC-80…89 về cách ly đa tenant

Một quy tắc an ninh đáng nhấn mạnh từ D03-10 §6 là trả về `404` thay vì `403` khi truy cập đối tượng của tenant khác (THR-35). Điều này áp dụng nhất quán ở mọi tầng: OPA trả quyết định "không tồn tại" cho đối tượng khác tenant, và thời gian phản hồi của hai trường hợp không được khác biệt đáng kể (truy vấn RLS trả rỗng tự nhiên đạt điều này).

Ở hồ sơ nền tảng dùng chung, còn một ranh giới mà RLS không bảo vệ: **quản trị nền tảng** có thể truy cập hạ tầng dùng chung. SEC-85, SEC-28 và SEC-31/SEC-88 kết hợp để giới hạn rủi ro này: quản trị nền tảng thao tác hạ tầng không cần đọc dữ liệu; nếu đọc trực tiếp CSDL thì trường Nhạy cảm vẫn là bản mã; khóa giải mã chỉ cấp cho service account của DU chứ không cho tài khoản người. Ở cấp độ 4, `DEDICATED_DB` hoặc `DEDICATED_CLUSTER` cùng HSM theo tenant giảm thêm rủi ro này (SEC-92, SEC-90).

## 10. Lộ trình nâng lên cấp độ 4

### 10.1. Nguyên tắc "sẵn sàng cấp độ 4"

"Sẵn sàng nâng lên cấp độ 4" không có nghĩa là xây sẵn mọi biện pháp cấp độ 4 (chi phí không tương xứng cho đa số tỉnh), mà là: kiến trúc không chứa quyết định nào phải làm lại khi nâng cấp; mọi biện pháp bổ sung cắm được vào điểm đã chừa; và có bảng chênh lệch rõ ràng để lập dự toán khi có quyết định nâng cấp. ADR-030 ghi quyết định này. Chương 6 của TCVN 14423:2026 (cấp độ 4) có cùng 18 nhóm như chương 5; phần lớn chênh lệch là mức độ (tần suất, độc lập, dự phòng) hơn là nhóm mới. Danh sách dưới đây dựa trên khác biệt thường gặp giữa cấp 3 và cấp 4 trong khung cũ và các điểm SAD §9 đã chừa; cần đối chiếu từng yêu cầu chương 6 khi có toàn văn (Q310).

> **Câu hỏi mở Q310:** Tiêu chí xác định cấp độ 4 và các yêu cầu cụ thể ở chương 6 TCVN 14423:2026 khác chương 5 ở những điểm nào? Bảng 10.2 cần được đối chiếu lại khi có toàn văn.

### 10.2. Bảng điểm chờ

Bảng dưới đây liệt kê các biện pháp chỉ cần khi nâng lên cấp độ 4, kèm điểm đã chừa sẵn ở cấp độ 3 và điều kiện kích hoạt, để chủ quản dự toán trước chi phí nâng cấp.

| Mã | Biện pháp bổ sung | Điểm đã chừa ở cấp độ 3 | Chi phí/ảnh hưởng ước lượng | Điều kiện kích hoạt |
|---|---|---|---|---|
| SEC-90 | HSM cho khóa gốc và KEK | OpenBao dùng seal và transit qua giao diện PKCS#11 được (OpenBao hỗ trợ seal PKCS#11); ADR-032 đã tách KEK khỏi dữ liệu | HSM đạt FIPS 140-2/3 mức 3 hoặc tương đương được cơ quan có thẩm quyền chấp nhận, 2 thiết bị (mỗi site 1); di chuyển khóa: bọc lại DEK, không mã hóa lại dữ liệu | Có quyết định cấp độ 4, hoặc yêu cầu chữ ký số chuyên dùng |
| SEC-91 | Hai TTDL hoạt động song song (active–active) cho data plane | Data plane không trạng thái (APISIX, runtime); Kafka có MirrorMaker 2; CNPG replica cluster (ADR-034) | Gấp đôi tài nguyên data plane; đường truyền giữa hai site độ trễ ≤ 10 ms; cần giải pháp ghi đồng thời cho PostgreSQL (vẫn active–standby cho CSDL, active–active cho data plane) | Yêu cầu sẵn sàng > 99,95% hoặc cấp độ 4 |
| SEC-92 | Cách ly CSDL vật lý theo tenant | Chế độ `DEDICATED_DB` và `DEDICATED_CLUSTER` đã có (ADR-003, D03-10) | Mỗi tenant thêm một cụm CNPG 3 nút; vận hành tăng tuyến tính | Tenant cấp độ 4 trên nền tảng dùng chung |
| SEC-93 | Mạng quản trị tách riêng out-of-band | Vùng Z7 đã tách logic | Mạng vật lý riêng, thiết bị chuyển mạch riêng, cổng quản trị nút (IPMI/BMC) chỉ trên mạng này | Cấp độ 4 |
| SEC-94 | PAM ghi phiên đầy đủ, truy cập JIT bắt buộc mọi thao tác | SEC-28 đã có JIT cho quyền cao và ghi phiên | Mở rộng cho mọi truy cập hạ tầng (cả quyền xem); lưu ghi phiên 3 năm | Cấp độ 4 |
| SEC-95 | SOC 24/7 chuyên trách | SEC-63 điểm xuất chuẩn hóa | Hợp đồng SOC hoặc đội SOC riêng; MTTD/MTTR cam kết | Cấp độ 4 (mức SIEM tối thiểu không còn chấp nhận) |
| SEC-96 | Kiểm thử xâm nhập dày hơn và red team | SEC-08 | Pentest 2 lần/năm + sau mỗi thay đổi lớn; red team 1 lần/năm; đơn vị kiểm thử độc lập được cấp phép | Cấp độ 4 |
| SEC-97 | Máy trạm quản trị chuyên dụng (PAW) | Truy cập Z7 qua VPN + MFA | Thiết bị cấp riêng, tăng cứng, không dùng thư điện tử/Internet chung | Cấp độ 4 |
| SEC-98 | Ngăn chặn rò rỉ dữ liệu (DLP) và giám sát hành vi người dùng | SEC-67, UC-SEC-11/12 | Công cụ DLP cho xuất dữ liệu, phân tích hành vi (UEBA) trên SIEM | Cấp độ 4 hoặc sau sự cố rò rỉ |
| SEC-99 | Chuỗi cung ứng mức cao hơn | SEC-55…58 (mục tiêu SLSA L3) | Build kín (hermetic), hai người duyệt phát hành, tái lập độc lập; xác minh nguồn gốc mọi phụ thuộc | Cấp độ 4 |

: Điểm chờ nâng cấp lên cấp độ 4: biện pháp, chi phí, điều kiện kích hoạt

Ảnh hưởng tổng thể khi nâng lên cấp độ 4 tập trung ở hạ tầng và tổ chức (HSM, site thứ hai active, mạng quản trị, SOC), không ở mã ứng dụng; đây là kết quả trực tiếp của việc chừa điểm từ đầu. Đội phát triển chỉ cần thay đổi cấu hình (địa chỉ seal PKCS#11, chế độ tenant) và chạy tác vụ bọc lại khóa.

## 11. Ma trận tuân thủ

Bốn ma trận dưới đây cho phép hội đồng thẩm định đi từ một yêu cầu của văn bản hoặc tiêu chuẩn tới biện pháp đáp ứng. D03-08 dùng ma trận (a) làm phương án bảo vệ trong hồ sơ.

### 11.a. TCVN 14423:2026, cấp độ 3 (chương 5)

Tên các nhóm 5.1–5.18 dưới đây được ghi theo chủ đề vì chưa đối chiếu được toàn văn; cột "Số mục" đánh dấu "cần đối chiếu" ở những dòng chưa chắc. Ba nhóm 5.13, 5.17, 5.18 (giám sát và phòng thủ, phát triển ứng dụng an toàn, quản lý kiểm tra) là nhóm cấp độ 3 có thêm so với cấp độ 2 và đã được xác định.

| Số mục | Chủ đề yêu cầu | Biện pháp đáp ứng |
|---|---|---|
| 5.1 | Quản lý rủi ro an ninh mạng | SEC-06, mục 4 |
| 5.2 | Quản lý tài sản | SEC-04, mục 3.1 |
| 5.x (cần đối chiếu) | Chính sách, tổ chức, nhân sự | SEC-01, SEC-02, SEC-03 |
| 5.x (cần đối chiếu) | Quản lý cấu hình và thay đổi | SEC-07, SEC-50, SEC-51, SEC-52, SEC-65 |
| 5.x (cần đối chiếu) | Quản lý tài khoản, xác thực, kiểm soát truy cập | SEC-20…29, SEC-85 |
| 5.x (cần đối chiếu) | Quản lý lỗ hổng, vá | SEC-09, SEC-57 |
| 5.x (cần đối chiếu) | Nhật ký | SEC-60, SEC-61, SEC-62 |
| 5.x (cần đối chiếu) | Phòng chống mã độc | SEC-54, SEC-45 |
| 5.x (cần đối chiếu) | Bảo vệ trình duyệt, thư điện tử | SEC-44; quy chế máy trạm thuộc chủ quản (mục 12) |
| 5.x (cần đối chiếu) | Bảo vệ hạ tầng mạng | SEC-10…19 |
| 5.x (cần đối chiếu) | Bảo vệ dữ liệu, mã hóa | SEC-30…39, SEC-88 |
| 5.x (cần đối chiếu) | Sao lưu, khôi phục | SEC-70, SEC-71 |
| 5.13 | Giám sát và phòng thủ an ninh mạng | SEC-63, SEC-64, SEC-66, SEC-67, mục 7 |
| 5.x (cần đối chiếu) | Quản lý nhà cung cấp | SEC-05, SEC-55…58 |
| 5.15 | Ứng phó sự cố | SEC-72…75, mục 8 |
| 5.17 | Phát triển ứng dụng an toàn | SEC-40…49 |
| 5.18 | Quản lý kiểm tra an ninh mạng | SEC-08, SEC-42, SEC-87 |
| Phụ lục A | An toàn vật lý | Yêu cầu với bên cung cấp hạ tầng (mục 12), D03-09 |

: Ma trận tuân thủ TCVN 14423:2026 cấp độ 3 (chương 5)

### 11.b. TCVN 11930:2017 cấp độ 3 và Thông tư 12/2022 (đối chiếu kế thừa)

Ma trận này giúp hội đồng quen khung cũ đối chiếu nhanh, và dùng nếu hồ sơ được thẩm định theo chuyển tiếp (Q300).

| Nhóm yêu cầu TCVN 11930:2017 | Biện pháp đáp ứng |
|---|---|
| Quản lý: Thiết lập chính sách an toàn thông tin | SEC-01, SEC-06 |
| Quản lý: Tổ chức bảo đảm ATTT | SEC-02, SEC-05, mục 12 |
| Quản lý: Bảo đảm nguồn nhân lực | SEC-03 |
| Quản lý: Quản lý thiết kế, xây dựng hệ thống | SEC-40…42, SEC-55…58, SEC-07 |
| Quản lý: Quản lý vận hành hệ thống | SEC-04, SEC-09, SEC-28, SEC-61…65, SEC-70…75 |
| Kỹ thuật: Bảo đảm an toàn mạng | SEC-10…19 |
| Kỹ thuật: Bảo đảm an toàn máy chủ | SEC-50…54 |
| Kỹ thuật: Bảo đảm an toàn ứng dụng | SEC-20…29, SEC-40…49 |
| Kỹ thuật: Bảo đảm an toàn dữ liệu | SEC-30…39, SEC-70 |
| Thông tư 12/2022: hồ sơ đề xuất cấp độ, phương án bảo đảm ATTT | D03-08 dùng mục 3, 4, 5, 11 |

: Ma trận đối chiếu TCVN 11930:2017 cấp độ 3 và Thông tư 12/2022

### 11.c. OWASP ASVS 5.0 (mức 2)

Ma trận này ánh xạ từng chương của OWASP ASVS 5.0 ở mức 2, chuẩn kiểm thử ứng dụng web và API đã chọn cho Datahub (NFR-00-024), sang các biện pháp `SEC-nn` đáp ứng.

| Chương ASVS 5.0 | Biện pháp đáp ứng |
|---|---|
| V1 Encoding and Sanitization | SEC-43, SEC-44, SEC-45 |
| V2 Validation and Business Logic | SEC-43, SEC-48, SEC-46 |
| V3 Web Frontend Security | SEC-44, SEC-21 |
| V4 API and Web Service | SEC-43, SEC-26, SEC-47 |
| V5 File Handling | SEC-45 |
| V6 Authentication | SEC-22, SEC-23, SEC-24 |
| V7 Session Management | SEC-21, SEC-29 |
| V8 Authorization | SEC-26, SEC-80, SEC-85 |
| V9 Self-contained Tokens | SEC-25 |
| V10 OAuth and OIDC | SEC-21, SEC-24, SEC-25 |
| V11 Cryptography | SEC-31, SEC-34 |
| V12 Secure Communication | SEC-12, SEC-15, SEC-18 |
| V13 Configuration | SEC-33, SEC-43, SEC-52 |
| V14 Data Protection | SEC-31, SEC-32, SEC-39 |
| V15 Secure Coding and Architecture | SEC-40, SEC-41, SEC-55 |
| V16 Security Logging and Error Handling | SEC-60, SEC-61, SEC-43 |
| V17 WebRTC | Không áp dụng (Datahub không dùng WebRTC) |

: Ma trận ánh xạ chương OWASP ASVS 5.0 mức 2 sang biện pháp

### 11.d. NFR-00-020…029 của SRS

Ma trận này cho biết từng yêu cầu ATTT phi chức năng của SRS được biện pháp nào đáp ứng và có điểm nào tài liệu này siết chặt hơn SRS.

| NFR | Biện pháp | Ghi chú |
|---|---|---|
| NFR-00-020 Mã hóa đường truyền | SEC-12, SEC-15, SEC-18 | Đáp ứng đầy đủ |
| NFR-00-021 Mã hóa khi lưu | SEC-30, SEC-31 | Đáp ứng đầy đủ |
| NFR-00-022 Không bí mật trong mã | SEC-33, SEC-41 | Đáp ứng đầy đủ |
| NFR-00-023 Lỗ hổng phụ thuộc | SEC-41, SEC-57 | Đáp ứng đầy đủ |
| NFR-00-024 ASVS 5.0 L2 | SEC-40…49, ma trận 11c | Đáp ứng đầy đủ |
| NFR-00-025 Khóa tài khoản | SEC-22 | Bổ sung khóa vĩnh viễn sau 3 lần khóa tạm |
| NFR-00-026 Mật khẩu | SEC-22 | **Đề xuất sửa 12 → 14 ký tự** để bằng TCVN 14423:2026 |
| NFR-00-027 Lưu nhật ký kiểm toán | SEC-62, ADR-031 | **Chốt**: trực tuyến 12 tháng, WORM 5 năm (tối thiểu 3 năm) |
| NFR-00-028 Lưu log vận hành | SEC-61 | Bổ sung: log an ninh 12 tháng |
| NFR-00-029 Che DLCN trong log | SEC-32 | Đáp ứng đầy đủ |

: Ma trận đáp ứng NFR-00-020…029 của SRS

## 12. Trách nhiệm và mô hình trách nhiệm chia sẻ

Datahub có bốn bên chịu trách nhiệm ATTT. **Chủ quản HTTT** (UBND tỉnh hoặc cơ quan được giao, theo NĐ 331/2026 Điều 31) chịu trách nhiệm cuối cùng: phê duyệt cấp độ, ban hành quy chế, bố trí bộ phận chuyên trách, quyết định chấp nhận rủi ro tồn dư, thông báo vi phạm. **Đơn vị vận hành** (Trung tâm CNTT/TTDL tỉnh) vận hành hằng ngày, giám sát, xử lý sự cố mức đầu. **Nhà cung cấp nền tảng** (nhà cung cấp sản phẩm, và ở hồ sơ dùng chung là đơn vị vận hành tập trung) chịu trách nhiệm an toàn của phần mềm và, ở hồ sơ dùng chung, của phần nền tảng. **Bên cung cấp hạ tầng** (TTDL tỉnh hoặc nhà cung cấp cloud Chính phủ) chịu trách nhiệm an toàn vật lý, mạng nền, ảo hóa. NĐ 331/2026 Điều 30 cho phép hệ cấp độ 3–4 dùng chung hạ tầng cloud/TTDL đạt yêu cầu, nên ranh giới trách nhiệm phải được ghi trong hợp đồng.

Bảng dưới đây phân trách nhiệm theo lớp cho hai hồ sơ triển khai (C: chủ quản/đơn vị vận hành của tỉnh; N: nhà cung cấp nền tảng; H: bên cung cấp hạ tầng).

| Lớp | Tỉnh độc lập (on-prem) | Nền tảng dùng chung (cloud) |
|---|---|---|
| An toàn vật lý, điện, làm mát (Phụ lục A TCVN 14423) | H (TTDL tỉnh) | H (nhà cung cấp cloud, đạt QĐ 8297/QĐ-BCA-A05) |
| Mạng nền, chống DDoS tầng 3/4 | H | H |
| Nút, hệ điều hành, K8s (SEC-50…53) | C (có thể thuê N hỗ trợ) | N |
| Thành phần nền tảng: mesh, gateway, CSDL, Kafka, OpenBao (SEC-10…19, 30…36) | C vận hành, N cung cấp cấu hình chuẩn | N |
| Phần mềm Datahub, bản vá, chuỗi cung ứng (SEC-40…59) | N | N |
| Giám sát, SOC (SEC-60…67) | C | N (nền tảng) + C (theo tenant) |
| Sao lưu, DR (SEC-70, 71) | C | N |
| Cấu hình tenant, người dùng, phân quyền, kết nạp HTTT (SEC-20…29 phần tenant) | C | C |
| Phân loại dữ liệu, mục đích, chấp thuận (SEC-37) | C và chủ quản dữ liệu | C và chủ quản dữ liệu |
| Ứng phó sự cố, thông báo (SEC-72…74) | C (A), N hỗ trợ | C (A cho tenant), N (R cho nền tảng) |
| Máy trạm người dùng, thư điện tử, nhận thức người dùng | C | C |

: Phân chia trách nhiệm giữa chủ quản, đơn vị hạ tầng và nhà cung cấp

> **Q311 (đã chốt 25/11/2026):** mỗi tỉnh là chủ quản tenant của mình và lập một bộ hồ sơ cấp độ cho phần của mình. *Câu hỏi gốc:* Ở hồ sơ nền tảng dùng chung, ai là chủ quản của phần nền tảng dùng chung (một cơ quan trung ương, một tỉnh đầu mối, hay mỗi tỉnh là chủ quản của tenant mình)? Câu trả lời quyết định hồ sơ cấp độ lập một bộ hay nhiều bộ (D03-08).

> **Câu hỏi mở Q312:** Danh mục HSM, thuật toán mật mã và CA được cơ quan có thẩm quyền chấp nhận cho hệ cấp độ 3–4 (ví dụ yêu cầu dùng mật mã dân sự trong nước, chứng thư từ CA chuyên dùng Chính phủ) là gì? Ảnh hưởng SEC-12, SEC-34, SEC-35, SEC-90.

## 13. Truy vết

Bảng dưới đây nối các yêu cầu, quyết định và mục kiểm kê hệ cũ với mục đáp ứng trong tài liệu này.

| Yêu cầu / quyết định | Đáp ứng tại |
|---|---|
| RB-05, RB-06 | Mục 2, 6.6, 10; ADR-030 |
| REQ-12, LGC-IAM-* | Mục 5.4 (SEC-20…29) |
| REQ-13 | Mục 7 (SEC-60…67); ADR-031 |
| REQ-09 | Mục 3.2, 6 (SEC-31, 32, 37…39) |
| REQ-14, LGC-NGSP-008 | THR-51…54; SEC-24, 33, 37 |
| REQ-19 | THR-46…50; SEC-36, 48, 67; PB-06 |
| REQ-20, FR-00-010…012 | Mục 9 (SEC-80…88) |
| FR-00-001, 002 | SEC-21, SEC-23 |
| FR-00-003, 005 | SEC-29 (đề xuất sửa FR-00-003) |
| FR-00-030…034 | SEC-45, bảng 3.2 |
| FR-00-040…043 | Mục 7.1, 7.2; SEC-60, 62 |
| FR-00-050, 071 | SEC-07, SEC-28, SEC-48 |
| FR-00-062 | Bảng 3.2 |
| FR-00-093, LGC-NFR-007 | SEC-33 |
| NFR-00-014 | SEC-70, SEC-71 |
| NFR-00-020…029 | Ma trận 11d |
| KPI-09 | SEC-33, SEC-41 |
| KPI-15 | SEC-64, mục 7.5 |
| ADR-003, ADR-013 | Mục 3.3, 9 |
| ADR-005, ADR-006 | SEC-24…26 |
| ADR-012 | SEC-33…36 |
| ADR-030, ADR-031, ADR-032 | Mục 10; 7.2–7.3; SEC-31, 34, 88 |
| ADR-033, 034, 035 (luồng C) | SEC-11, SEC-71, SEC-70 |
| CMP-LAW-05, 16, 17, 18, 19; STD-06 | Mục 2, 6, 11 |

: Truy vết yêu cầu và quyết định tới mục đáp ứng

## 14. Câu hỏi mở, mã mới và điểm cần sửa ở tài liệu khác

### 14.1. Câu hỏi mở

> **Q300 (đã chốt 25/11/2026):** Datahub là hệ mới, hồ sơ cấp độ lập theo NĐ 331/2026; phần LGSP cũ còn chạy được xử lý bằng phụ lục rủi ro chuyển tiếp. *Câu hỏi gốc:* Datahub áp dụng chuyển tiếp Điều 39 NĐ 331/2026 hay là hệ mới (mục 2.1)?

> **Câu hỏi mở Q301:** Văn bản thay Thông tư 12/2022/TT-BTTTT đã có chưa (mục 2.2)?

> **Câu hỏi mở Q302:** Cơ chế bảo vệ callback và API truy vấn trạng thái trong đặc tả PayGov hiện hành (mục 4.4.9, SEC-48)?

> **Câu hỏi mở Q303:** Năng lực mTLS phía client của HTTT tỉnh; chính sách chuyển tiếp cho hợp đồng Nhạy cảm (SEC-24)?

> **Câu hỏi mở Q304:** Quy định riêng cho cơ quan nhà nước trong Luật 91/2025, NĐ 356/2025; thời hạn trả lời chủ thể (mục 6)?

> **Câu hỏi mở Q305:** Thời hạn lưu dữ liệu giao dịch PH-19 theo quy định kế toán (mục 6.2)?

> **Q306 (đã chốt 25/11/2026):** chọn Ceph RGW với Object Lock chế độ compliance làm kho WORM. *Câu hỏi gốc:* Chọn SeaweedFS, Ceph RGW hay dịch vụ cloud cho kho WORM có Object Lock compliance (mục 7.2)?

> **Câu hỏi mở Q307:** Thời hạn lưu nhật ký tối thiểu cụ thể theo văn bản hướng dẫn Luật 116/2025 và TCVN 14423:2026 (mục 7.3)?

> **Câu hỏi mở Q308:** Có bắt buộc kết nối giám sát với hệ thống của Bộ Công an hoặc tỉnh không (mục 7.4)?

> **Câu hỏi mở Q309:** Thời hạn, mẫu và nơi nhận báo cáo sự cố an ninh mạng (mục 8.4)?

> **Câu hỏi mở Q310:** Yêu cầu cụ thể của chương 6 TCVN 14423:2026 và tiêu chí cấp độ 4 (mục 10)?

> **Q311 (đã chốt 25/11/2026):** mỗi tỉnh là chủ quản tenant của mình và lập một bộ hồ sơ cấp độ cho phần của mình. *Câu hỏi gốc:* Chủ quản của phần nền tảng dùng chung là ai (mục 12)?

> **Câu hỏi mở Q312:** Danh mục HSM, thuật toán và CA được chấp nhận cho cấp độ 3–4 (mục 12)?

> **Câu hỏi mở Q313:** Tên chính xác và số mục của 18 nhóm yêu cầu 5.1–5.18 TCVN 14423:2026 để hoàn thiện ma trận 11a và ngưỡng tham số cấp độ 3 (tự khóa phiên, thời hạn lưu nhật ký, tần suất vá) nếu chặt hơn ngưỡng cấp độ 1 đã dùng.

Các số Q314–Q319 để dành.

### 14.2. Mã và thuật ngữ mới đề xuất bổ sung D00-01

Các mã và thuật ngữ dưới đây được tài liệu này dùng lần đầu; luồng lõi gộp vào D00-01 theo §9.3.

| Loại | Mã / thuật ngữ | Định nghĩa | Định nghĩa tại |
|---|---|---|---|
| Mã truy vết | `THR-{nn}` | Mối đe dọa trong mô hình STRIDE | D03-07 mục 4.4 |
| Mã truy vết | `TA-{nn}` | Tác nhân đe dọa | D03-07 mục 4.3 |
| Mã truy vết | `AS-{nn}` | Tài sản thông tin trong kiểm kê ATTT | D03-07 mục 3.1 |
| Mã truy vết | `UC-SEC-{nn}` | Use case phát hiện an ninh (luật cảnh báo) | D03-07 mục 7.5 |
| Mã truy vết | `PB-{nn}` | Playbook ứng phó sự cố | D03-07 mục 8.5 |
| Mã vùng | `Z0`…`Z7` | Vùng tin cậy mạng | D03-07 mục 3.3 |
| Mã căn cứ | CMP-LAW-17 NĐ 331/2026; CMP-LAW-18 NĐ 356/2025; CMP-LAW-19 NĐ 278/2025; CMP-LAW-20 QĐ 8297/QĐ-BCA-A05; cập nhật CMP-LAW-03 (thay bởi CMP-LAW-19), CMP-LAW-04 (hết hiệu lực), CMP-LAW-05 (Luật 91/2025/QH15), CMP-LAW-06/07/08 (kế thừa), CMP-LAW-16 (Luật 116/2025/QH15) | Văn bản pháp lý | D03-07 mục 2.2 |
| Mã tiêu chuẩn | STD-03 cập nhật ASVS 5.0; STD-06 TCVN 14423:2026; STD-07 OWASP API Top 10 2023; STD-08 CIS K8s/NSA-CISA; STD-09 SLSA; STD-10 RFC 9700/8705/7523/7636/9449; STD-11 ISO/IEC 27001/27002:2022; STD-12 NIST SP 800-63B | Tiêu chuẩn kỹ thuật | D03-07 mục 2.3 |
| Thuật ngữ | BFF (Backend-for-Frontend) | Thành phần phía máy chủ giữ token OAuth thay cho ứng dụng trình duyệt | D03-07 SEC-21 |
| Thuật ngữ | Envelope encryption, KEK, DEK | Mã hóa dữ liệu bằng khóa dữ liệu (DEK), DEK được bọc bằng khóa mã hóa khóa (KEK) giữ trong kho khóa | ADR-032 |
| Thuật ngữ | WORM, Object Lock | Lưu trữ ghi một lần, không sửa xóa được trong thời hạn giữ | ADR-031 |
| Thuật ngữ | Break-glass | Truy cập khẩn cấp có kiểm soát vượt quy trình thường | SEC-28 |
| Thuật ngữ | Xóa mật mã (crypto-shredding) | Hủy khóa để dữ liệu mã hóa không còn giải được | SEC-39 |
| Thuật ngữ | Token ràng buộc chứng thư (certificate-bound token) | Token chỉ dùng được trên kết nối mTLS có khóa tương ứng (RFC 8705) | SEC-24 |

: Mã và thuật ngữ mới đề xuất bổ sung D00-01

### 14.3. Điểm cần sửa ở SRS và SAD (không tự sửa)

Các điểm dưới đây là chênh lệch giữa tài liệu này và tài liệu khác; luồng lõi quyết định và cập nhật.

| Tài liệu, vị trí | Hiện ghi | Đề xuất | Lý do |
|---|---|---|---|
| D02-02 FR-00-003 | Tự đăng xuất sau 30 phút, cấu hình 5–120 phút | 15 phút, cấu hình 5–15 phút; cảnh báo trước 2 phút | TCVN 14423:2026 ngưỡng ≤ 15 phút |
| D02-02 NFR-00-026 | Mật khẩu tối thiểu 12 ký tự | Tối thiểu 14 ký tự | TCVN 14423:2026 (≥ 14 nếu không MFA; áp dụng chung cho đơn giản) |
| D02-02 NFR-00-025 | Khóa tạm 15 phút sau 5 lần sai | Bổ sung khóa vĩnh viễn sau 3 lần khóa tạm trong 24 giờ | Chống dò chậm |
| D02-02 NFR-00-027 | "Lưu trữ tối thiểu theo yêu cầu cấp độ (xác định ở D03-07)" | Trực tuyến 12 tháng; WORM 5 năm, không dưới 3 năm | Chốt Q08 |
| D02-02 NFR-00-028 | Log vận hành 90 ngày | Thêm: log an ninh 12 tháng trực tuyến | Mục 7.3 |
| D02-02 Q08 | Mở | Đóng, trỏ tới D03-07 mục 7.3 và ADR-031 | — |
| D02-02 thêm NFR | — | Thêm yêu cầu vô hiệu tài khoản không hoạt động 45 ngày (quản trị 30 ngày) | TCVN 14423:2026; SEC-27 |
| D03-01 §9 mục 2 | Token 15 phút cho người | 5 phút (giữ ở BFF, làm mới trong suốt); ghi rõ mẫu BFF | SEC-21, SEC-25 |
| D03-01 §6 dòng Biên | "Ingress NGINX hoặc Envoy Gateway, ADR-03x" | APISIX ở biên, WAF Coraza trong APISIX, ADR-033 (đã gộp 25/11/2026) | Ingress NGINX cộng đồng đã ngừng phát triển |
| D03-01 §6 dòng Kho đối tượng | "SeaweedFS hoặc Ceph RGW cho WORM" | Giữ, thêm Q306 | — |
| D00-01 §2.1 dòng Datahub, CMP-LAW-03 | Viện dẫn NĐ 47/2020 | NĐ 278/2025/NĐ-CP | NĐ 47/2020 đã bị thay |
| D00-01 §7 CMP-LAW-04/05/06/07/08/16, STD-03 | Như hiện có | Cập nhật theo mục 14.2 | Khung pháp lý mới |
| D00-03 / D02-02 IF-08 | Syslog hoặc OTLP | Thêm định dạng chuẩn hóa ECS/OCSF | Mục 7.4 |

: Điểm cần sửa ở SRS và SAD, chưa tự sửa

## Lịch sử phiên bản

| Phiên bản | Ngày | Người | Nội dung |
|---|---|---|---|
| 0.1 | 21/11/2026 | Nhóm viết tài liệu (Claude) | Bản đầu: căn cứ pháp lý, đối tượng bảo vệ, mô hình mối đe dọa STRIDE, danh mục biện pháp `SEC-nn`, bảo vệ dữ liệu cá nhân, ứng phó sự cố, ma trận tuân thủ, trách nhiệm, truy vết |
| 0.2 | 26/11/2026 | Nhóm viết tài liệu (Claude) | Giữ nguyên toàn bộ nội dung và mã `SEC-nn`; thêm Tóm tắt cho hội đồng thẩm định, thuật ngữ và chữ viết tắt (1.5), tài liệu tham chiếu (1.6), cấu trúc tài liệu (1.7); viết lại chú thích bảng và hình theo tên cụ thể; thêm đoạn mở cho các mục thiếu; đổi sơ đồ vùng tin cậy và quy trình ứng phó sang chiều dọc; thêm sơ đồ mốc thông báo vi phạm DLCN 72 giờ |
