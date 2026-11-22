---
ma_tai_lieu: D01-00
ten: Bộ giả định nền dùng chung cho D01-01 và D01-02
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Dự thảo
nguoi_doc: QL, TĐ
---

# Bộ giả định nền dùng chung cho Báo cáo nghiên cứu khả thi (D01-01) và Kế hoạch dự án (D01-02)

Tệp này là **nguồn sự thật duy nhất** cho mọi con số, mốc thời gian, cơ cấu đội ngũ và quy mô tham chiếu được dùng trong D01-01 và D01-02. Khi hai tài liệu cần cùng một con số, cả hai đều trích từ đây. Muốn đổi một con số thì đổi ở đây trước, rồi cập nhật các chương tham chiếu. Mọi giá trị có nhãn **[GĐ]** là giả định cần chủ đầu tư xác nhận; giá trị có nhãn **[ĐIỀN]** là ô để trống cho chủ đầu tư điền.

## 1. Bối cảnh định danh dự án

| Trường | Giá trị |
|---|---|
| Tên dự án | Xây dựng Nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (Datahub) |
| Tên ngắn | Datahub |
| Bản chất | LGSP thế hệ mới có thêm lớp dữ liệu dùng chung (MDM, RDM, DQ, bảo vệ DLCN); chưa làm kho phân tích/lakehouse |
| Mô hình sản phẩm | Sản phẩm đóng gói multi-tenant; một bản mã nguồn, triển khai cho nhiều tỉnh; mỗi tỉnh là một tenant (hoặc một cụm riêng) |
| Tỉnh thí điểm | **[ĐIỀN]** (hệ LGSP cũ đang vận hành tại tỉnh này) |
| Chủ đầu tư | **[ĐIỀN]** — giả định Sở Khoa học và Công nghệ tỉnh thí điểm **[GĐ]** |
| Cơ quan chủ quản / người quyết định đầu tư | **[ĐIỀN]** — giả định UBND tỉnh thí điểm **[GĐ]** |
| Đơn vị vận hành | **[ĐIỀN]** — giả định Trung tâm Chuyển đổi số / Trung tâm dữ liệu tỉnh **[GĐ]** |
| Nguồn vốn | Ngân sách nhà nước (chi đầu tư phát triển và chi thường xuyên cho vận hành) **[GĐ]** |
| Hệ cũ | LGSP do Viettel triển khai năm 2021, 5 khối: Bus (Apache Camel + Productivity Tooling), Hub (Apache Pulsar), API Management (kiểu Gravitee), Danh mục dùng chung "Aita", Payment (trung gian PayGov); phụ lục kết nối NGSP |
| Tài liệu hệ cũ | `/mnt/project-files/lgsp_document/` (chỉ tham khảo, không sao chép nguyên văn) |

## 2. Phân hệ và phạm vi MVP

Datahub gồm 20 phân hệ. **MVP (đợt 1)** gồm 12 phân hệ: PH-01, PH-02, PH-03, PH-04, PH-05, PH-07, PH-10, PH-12, PH-13, PH-14, PH-18, PH-20. **Đợt 2**: PH-19, PH-15, PH-09, PH-11. **Đợt 3**: PH-06, PH-08, PH-16, PH-17. Phân đợt theo D02-01 §8.3 (nguồn sự thật).

| Mã | Phân hệ | Đợt | Công nghệ đặc thù |
|---|---|---|---|
| PH-01 | Kết nạp & định danh HTTT | MVP | Spring Boot |
| PH-02 | Quản lý API & danh mục dịch vụ | MVP | Spring Boot |
| PH-03 | Cổng API | MVP | Apache APISIX + Coraza WAF |
| PH-04 | Lõi tích hợp & trình thiết kế luồng | MVP | Camel Quarkus native |
| PH-05 | Quản lý adapter & kết nối | MVP | Camel Quarkus |
| PH-06 | Dữ liệu chủ (MDM) | Đợt 3 | Spring Boot |
| PH-07 | Danh mục dùng chung & ánh xạ | MVP | Spring Boot, Valkey |
| PH-08 | Chất lượng dữ liệu | Đợt 3 | Spring Boot |
| PH-09 | Bảo vệ dữ liệu cá nhân | Đợt 2 | Spring Boot, Vault/OpenBao Transit |
| PH-10 | Truyền thông sự kiện | MVP | Kafka (Strimzi), Apicurio |
| PH-11 | Điều phối quy trình (BPM) | Đợt 2 | Flowable |
| PH-12 | Định danh, xác thực, ủy quyền | MVP | Keycloak, OPA |
| PH-13 | Giám sát, ghi vết, cảnh báo | MVP | OpenTelemetry, LGTM, OpenSearch |
| PH-14 | Kết nối quốc gia (NDXP/NDOP) | MVP | Camel Quarkus |
| PH-15 | Cổng nhà phát triển | Đợt 2 | React (Backstage chờ ADR) |
| PH-16 | Quản trị kiến trúc & KPI | Đợt 3 | Spring Boot, ClickHouse (chờ ADR) |
| PH-17 | Cổng AI & quản trị AI | Đợt 3 | APISIX AI, pgvector |
| PH-18 | Vận hành & xử lý bản tin lỗi | MVP | Spring Boot |
| PH-19 | Thanh toán điện tử (PayGov, NCC, giao dịch, đối soát, dashboard) | Đợt 2 | Spring Boot, ClickHouse (lịch sử) |
| PH-20 | Quản trị tenant & phát hành sản phẩm | MVP | Spring Boot, Argo CD |

Stack chung: Java 21 + Spring Boot 4 (Modulith), PostgreSQL 17/18 + CloudNativePG, Valkey, Kafka, Keycloak + OPA, Vault/OpenBao, Istio ambient, Argo CD, LGTM; frontend React + Ant Design v6, phong cách Liquid Glass. Hạ tầng: Kubernetes on-prem tại TTDL tỉnh **hoặc** cloud chính phủ, không phụ thuộc dịch vụ độc quyền của một nhà cung cấp. ATTT: cấp độ 3, thiết kế sẵn để nâng cấp độ 4.

## 3. Lịch tổng thể (mốc lịch tham chiếu)

Ký hiệu **T0** là ngày khởi động hợp đồng thực hiện. **Theo chỉ đạo của chủ đầu tư (21/11/2026), tài liệu KHÔNG gắn ngày lịch cụ thể**: mọi mốc chỉ ghi tương đối dạng "T0 + n tháng" (giai đoạn chuẩn bị đầu tư ghi dạng "T0 − n tháng"). Không viết năm/tháng lịch trong các mốc.

### 3.1. Giai đoạn chuẩn bị đầu tư (trước T0)

| Bước | Thời gian tương đối |
|---|---|
| Lập, trình chủ trương đầu tư (nếu thuộc diện phải có) | T0 − 7 → T0 − 6 tháng |
| Lập Báo cáo nghiên cứu khả thi (D01-01) | T0 − 7 → T0 − 5 tháng |
| Thẩm định, phê duyệt dự án | T0 − 4 → T0 − 3 tháng |
| Thiết kế chi tiết, dự toán; thẩm định, phê duyệt | T0 − 3 → T0 − 2 tháng |
| Lựa chọn nhà thầu | T0 − 2 → T0 |

Trình tự và tên gọi các bước theo Nghị định 224/2026/NĐ-CP (quy định chi tiết Luật Chuyển đổi số; thay NĐ 45/2026, vốn đã thay NĐ 73/2019); chương căn cứ pháp lý của D01-01 xác nhận tên gọi chính xác.

### 3.2. Giai đoạn thực hiện: 6 wave, 18 tháng, sprint 2 tuần

| Wave | Nội dung | Từ – đến (tháng) | Số sprint | Cổng kết thúc |
|---|---|---|---|---|
| W0 | Khởi động, nền tảng, hợp đồng máy đọc, hạ tầng DEV/TEST, IAM khung | T0 → T0+2 | 4 | G0 Nền tảng sẵn sàng |
| W1 | Trục tích hợp: PH-01, 02, 03, 04, 05, 12; PH-13 mức cơ bản | T0+2 → T0+6 | 8 | G1 Trục tích hợp |
| W2 | Dữ liệu & mở rộng MVP: PH-07, 10, 14, 18, 20; PH-13 đầy đủ; kiểm thử hệ thống, ATTT, hiệu năng | T0+6 → T0+10 | 8 | G2 Nghiệm thu MVP |
| W3 | Thí điểm tại tỉnh 1: cài đặt PROD, di trú, chạy song song (strangler), cắt chuyển theo nhóm dịch vụ; hồ sơ cấp độ 3 được phê duyệt | T0+10 → T0+13 | 6 | G3 Vận hành chính thức MVP |
| W4 | Đợt 2: PH-19, 15, 09, 11 (chạy song song với W3 bằng đội riêng); cắt chuyển thanh toán khỏi hệ cũ | T0+10 → T0+15 | 10 | G4 Nghiệm thu đợt 2 |
| W5 | Đợt 3: PH-06, 08, 16, 17; đóng gói phát hành v1.0; nhân rộng sang tỉnh 2; tắt hệ cũ | T0+15 → T0+18 | 6 | G5 Nghiệm thu hoàn thành dự án |

Sau G5: **bảo hành 12 tháng** (T0+18 → T0+30), sau đó vận hành, hỗ trợ kỹ thuật theo hợp đồng năm. Hệ cũ chạy song song tối đa đến G5; dịch vụ thanh toán cũ tắt sau khi PH-19 chạy ổn định 30 ngày.

### 3.3. Cửa sổ TCO

TCO tính cho **5 năm kể từ T0, đánh số Năm 1 … Năm 5** (không gắn năm lịch): Năm 1 và nửa đầu Năm 2 là thực hiện (18 tháng), nửa sau Năm 2 đến nửa đầu Năm 3 là bảo hành kèm vận hành, phần còn lại là vận hành. Chi phí chuẩn bị đầu tư (tư vấn lập BCNCKT, thiết kế chi tiết) cộng vào Năm 1.

## 4. Quy mô tham chiếu theo tỉnh

Sau sắp xếp đơn vị hành chính năm 2025, cả nước còn 34 tỉnh, thành phố; quy mô mỗi tỉnh lớn hơn trước. Ba cỡ tham chiếu:

| Chỉ tiêu | Cỡ S | Cỡ M | Cỡ L |
|---|---|---|---|
| Số HTTT kết nối | ≤ 80 | ≤ 200 | ≤ 400 |
| Số API/dịch vụ công bố | ≤ 400 | ≤ 1.000 | ≤ 2.500 |
| Giao dịch đồng bộ / ngày | 2 triệu | 10 triệu | 30 triệu |
| TPS đỉnh tại cổng API | 300 | 1.000 | 3.000 |
| Sự kiện Kafka / ngày | 5 triệu | 25 triệu | 80 triệu |
| Bản ghi danh mục dùng chung | 2 triệu | 5 triệu | 15 triệu |
| Giao dịch thanh toán / tháng | 100 nghìn | 400 nghìn | 1,2 triệu |
| Lưu nhật ký nóng / lưu trữ | 90 ngày / 24 tháng | 90 ngày / 24 tháng | 90 ngày / 24 tháng |
| Mục tiêu sẵn sàng data plane | 99,9% | 99,9% | 99,95% |
| RPO / RTO | RPO 15 phút; RTO 1 giờ data plane, 4 giờ control plane (NFR-00-014) | như cỡ S | RPO 5 phút; RTO 1 giờ data plane, 2 giờ control plane |

Tỉnh thí điểm được giả định là **cỡ M** **[GĐ]**. Môi trường: DEV, TEST, STAGING, PROD và DR (warm standby ở site thứ hai hoặc vùng cloud thứ hai).

## 5. Đội ngũ thực hiện tham chiếu

Mô hình tổ chức theo **lane** (mỗi đội sở hữu một nhóm thư mục mã, theo IP-04 của repo). Đội phát triển dùng AI agent viết mã có kiểm soát: agent chỉ làm trong lane được giao, mọi PR do kỹ sư chịu trách nhiệm review và merge, cổng CI (Gate A/S/C) bắt buộc xanh.

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

Ghi chú: W3 và W4 chạy chồng lấn (T0+10 → T0+13); cột W3 là đội thí điểm và vận hành, cột W4 là đội phát triển đợt 2; PM và PO dùng chung giữa hai cột trong thời gian chồng lấn, và ở T0+13 → T0+15 PM, PO thuộc cột W4 (cộng thêm 2 × 2 = 4 người-tháng). **Đỉnh tải thực tế ≈ 38 FTE** trong ba tháng chồng lấn W3 + W4. Tổng nỗ lực giai đoạn thực hiện ≈ **15,5×2 + 26,5×4 + 28×4 + 18,5×3 + 19,5×5 + 17,5×3 + 4 ≈ 459 người-tháng** (chương chi phí phải tính lại chính xác và nếu lệch thì ghi rõ).

Vai trò bổ sung: **Chủ sản phẩm phía chủ đầu tư** (thuộc Ban QLDA, không tính vào FTE nhà thầu) và **Trưởng nhóm kỹ thuật** (kiêm nhiệm trong định biên kỹ sư).

Nhân sự không thuộc nhà thầu (tính vào chi phí QLDA và vận hành, không vào 459 người-tháng): Ban QLDA phía chủ đầu tư ≈ 3,5 FTE suốt giai đoạn thực hiện; đội vận hành tỉnh 6 người (≈ 5,5 FTE) từ T0+10; hỗ trợ kỹ thuật của nhà thầu sau bảo hành 2–3 FTE từ T0+30.

## 6. Quy ước tiền tệ và giá

- Đơn vị: triệu đồng (VND), làm tròn đến 1 triệu; giá trước thuế GTGT trừ khi ghi khác.
- Đơn giá người-tháng: dùng **tham số** do chủ đầu tư điền theo hướng dẫn định mức hiện hành. Để có số liệu tham khảo, dùng **kịch bản tham khảo**: đơn giá bình quân **[GĐ]** do chương chi phí đề xuất kèm lý do; mọi bảng phải ghi rõ "giá trị tham khảo".
- Giá phần cứng và cloud: ghi theo khoảng (thấp – cao) với kịch bản trung vị dùng cho TCO.
- Phần mềm nguồn mở: chi phí bản quyền 0; tính chi phí hỗ trợ thương mại tùy chọn (ví dụ Keycloak/Red Hat build, Kafka/Strimzi support, PostgreSQL support) như một kịch bản riêng.
- Lạm phát/ trượt giá: 4%/năm cho chi phí vận hành từ Năm 3 **[GĐ]**.
- Dự phòng: theo tỷ lệ quy định hiện hành của văn bản quản lý đầu tư CNTT (chương chi phí xác minh).

## 7. Phương án đánh giá trong D01-01

- **PA1** Nâng cấp, mở rộng hệ LGSP cũ (giữ kiến trúc Bus/Hub/APIM/Aita/Payment, nâng phiên bản, bổ sung chức năng).
- **PA2** Mua hoặc thuê nền tảng thương mại có sẵn (LGSP của nhà cung cấp trong nước, hoặc nền tảng tích hợp thương mại quốc tế) và tùy biến.
- **PA3 (đề xuất)** Xây mới Datahub trên nền mã nguồn mở, kiến trúc sản phẩm multi-tenant, di trú theo strangler.
- Phương án triển khai hạ tầng (đánh giá riêng, áp cho PA được chọn): **H1** on-prem K8s tại TTDL tỉnh; **H2** cloud chính phủ (IaaS/K8s quản lý); **H3** thuê dịch vụ trọn gói từ nhà cung cấp vận hành nền tảng cho nhiều tỉnh.
- Mô hình tenant (chi tiết để D03-10 quyết định): RLS trong CSDL dùng chung; schema riêng; cụm riêng cho tỉnh lớn.

## 8. Ánh xạ mã rủi ro và quy ước chung

- Rủi ro: `RSK-{nn}`, quản lý trong sổ rủi ro tại D01-02; D01-01 chỉ nêu rủi ro cấp dự án và tham chiếu mã.
- Mục tiêu nghiệp vụ `BO-{nn}`, chỉ số `KPI-{nn}`: định nghĩa chính thức ở D02-01 (BRD). D01-01 được dùng các mã BO/KPI ở dạng **đề xuất** và ghi "định nghĩa chính thức tại D02-01".
- Biện pháp ATTT `SEC-{nn}`: định nghĩa chính thức ở D03-07.
- Tham chiếu tài liệu khác theo mã D (ví dụ "xem D03-09 §4"), không chép lại nội dung.
