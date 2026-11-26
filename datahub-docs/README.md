---
ma_tai_lieu: DH-README
ten: Bộ tài liệu SDLC Datahub — điểm vào
phien_ban: 0.1
ngay: 2026-11-21
---

# Bộ tài liệu SDLC Datahub

Datahub là **nền tảng tích hợp, chia sẻ dữ liệu cấp tỉnh thế hệ mới (LGSP thế hệ mới)**, có lớp dữ liệu dùng chung, được đóng gói thành sản phẩm triển khai cho nhiều tỉnh theo mô hình đa tenant. Datahub thay thế dần hệ LGSP cũ (bộ năm khối Bus, Hub, API Management, Danh mục dùng chung, Payment) theo chiến lược chạy song song và thay thế dần (strangler).

Thư mục này là **bộ tài liệu độc lập**. Nó tham khảo nội dung trong `docs/` của repo nhưng không phụ thuộc và không sửa `docs/`. Mọi thuật ngữ, mã truy vết và quyết định kiến trúc được định nghĩa lại trong chính bộ này.

## Cách đọc

| Nếu anh/chị là | Đọc trước | Sau đó |
|---|---|---|
| Thành viên hội đồng thẩm định | [D01-01 Báo cáo nghiên cứu khả thi](01-khoi-tao/D01-01-bao-cao-nghien-cuu-kha-thi.md) | D02-01 BRD, D03-01 SAD, D00-03 RTM |
| Quản lý dự án | [D01-02 Kế hoạch dự án](01-khoi-tao/D01-02-ke-hoach-du-an.md) | D02-01 BRD, D05-01 Master Test Plan |
| Kỹ sư phát triển | [D00-01 Thuật ngữ và quy ước](00-chung/D00-01-thuat-ngu-quy-uoc.md) | D03-01 SAD → FRS và SDD của phân hệ được giao → D04-01 Coding convention |
| Kiểm thử viên | D05-01 Master Test Plan | FRS và test case của phân hệ được giao |
| Vận hành | D03-09 Hạ tầng | D06-02 Cài đặt, D06-03 HDVH |

## Danh mục tài liệu

| Mã | Tài liệu | Thư mục | Trạng thái |
|---|---|---|---|
| D00-01 | Thuật ngữ và quy ước chung | `00-chung/` | Bản 0.1 |
| D00-02 | Sổ quyết định kiến trúc (ADR) | `00-chung/`, `00-chung/adr/` | Bản 0.1 (ADR-001…013) |
| D00-03 | Ma trận truy vết (RTM), gồm kiểm kê chức năng hệ cũ | `00-chung/` | Bản 0.1 (phần kiểm kê) |
| D00-04 | [Sổ tra cứu gọn](00-chung/D00-04-so-tra-cuu-gon.md) và [khuôn rỗng bảy tập phân hệ](00-chung/khuon/README.md) | `00-chung/` | Bản 0.1 (26/11/2026) |
| D01-01 | Báo cáo nghiên cứu khả thi | `01-khoi-tao/` | Đang viết (luồng riêng) |
| D01-02 | Kế hoạch dự án | `01-khoi-tao/` | Đang viết (luồng riêng) |
| D02-01 | Tài liệu yêu cầu nghiệp vụ (BRD) | `02-yeu-cau/` | Bản 0.1 |
| D02-02 | Đặc tả yêu cầu phần mềm cấp hệ thống (SRS) | `02-yeu-cau/` | Bản 0.1 |
| D02-03 | Đặc tả chức năng (FRS), 20 tập theo phân hệ | `02-yeu-cau/frs/` | Đợt 2–4 |
| D02-04 | Đặc tả use case | `02-yeu-cau/` | Đợt 2–4 |
| D02-05 | Backlog user story | `02-yeu-cau/` | Đợt 2–4 |
| D02-06 | Sơ đồ luồng dữ liệu (DFD) và phân loại dữ liệu | `02-yeu-cau/` | Đợt 1 |
| D02-07 | Từ điển dữ liệu dùng chung | `02-yeu-cau/` | Bản 0.1 |
| D02-08 | Ma trận phân quyền | `02-yeu-cau/` | Bản 0.1 |
| D03-01 | Thiết kế kiến trúc tổng thể (SAD) | `03-thiet-ke/` | Bản 0.1 |
| D03-02 | Thiết kế chi tiết (SDD), 20 tập theo phân hệ | `03-thiet-ke/sdd/` | Đợt 2–4 |
| D03-03 | Thiết kế cơ sở dữ liệu | `03-thiet-ke/csdl/` | Đợt 2–4 |
| D03-04 | Đặc tả API và sự kiện | `03-thiet-ke/api/` | Đợt 2–4 |
| D03-05 | Design system (Liquid Glass trên antd v6) | `03-thiet-ke/uiux/` | Đang viết (luồng giao diện) |
| D03-06 | Thiết kế giao diện màn hình | `03-thiet-ke/uiux/` | Đợt 2–4 |
| D03-07 | Thiết kế an toàn thông tin | `03-thiet-ke/attt/` | Đợt 3 |
| D03-08 | Hồ sơ đề xuất cấp độ | `03-thiet-ke/attt/` | Đợt 5 |
| D03-09 | Thiết kế hạ tầng, triển khai và DR | `03-thiet-ke/ha-tang/` | Đợt 3 |
| D03-10 | Thiết kế đa tenant | `03-thiet-ke/` | Bản 0.1 |
| D04-01 | Coding convention | `04-lap-trinh/` | Đợt 3 |
| D04-02 | Quy trình kỹ thuật | `04-lap-trinh/` | Đợt 3 |
| D05-01 | Master Test Plan | `05-kiem-thu/` | Đợt 3 |
| D05-02 | Kịch bản và test case, 20 tập | `05-kiem-thu/test-case/` | Đợt 2–4 |
| D05-03 | Kế hoạch kiểm thử hiệu năng | `05-kiem-thu/` | Đợt 5 |
| D05-04 | Kế hoạch kiểm thử bảo mật | `05-kiem-thu/` | Đợt 5 |
| D05-05 | Kế hoạch UAT | `05-kiem-thu/` | Đợt 5 |
| D06-01 | Kế hoạch chuyển đổi và di trú | `06-chuyen-doi-van-hanh/` | Đợt 5 |
| D06-02 | Hướng dẫn cài đặt | `06-chuyen-doi-van-hanh/` | Đợt 5 |
| D06-03 | Hướng dẫn vận hành | `06-chuyen-doi-van-hanh/` | Đợt 5 |
| D06-04 | Hướng dẫn sử dụng | `06-chuyen-doi-van-hanh/` | Đợt 5 |
| D06-05 | Tài liệu đào tạo | `06-chuyen-doi-van-hanh/` | Đợt 5 |

## Lộ trình viết tập phân hệ

Các tài liệu D02-03, D02-04, D03-02, D03-03, D03-04, D03-06, D05-02 được viết theo từng phân hệ. Mỗi phân hệ có bảy tập theo khuôn của PH-07 (phân hệ mẫu, Q10). Thứ tự dưới đây ưu tiên phân hệ MVP có nhiều nghiệp vụ hệ cũ nhất.

| Thứ tự | Phân hệ | Đợt | Lý do ưu tiên | Tình trạng (25/11/2026) |
|---|---|---|---|---|
| 1 | PH-07 Danh mục dùng chung | Đợt 2 (mẫu) | Mẫu để duyệt độ sâu; nhiều nghiệp vụ Aita | Xong bản 0.2 đủ bảy tập (xem mục dưới), chờ duyệt tổng thể |
| 2 | PH-04 Lõi tích hợp và trình thiết kế luồng | Đợt 2 | Thay Bus và Tooling (70 chức năng cũ); trình thiết kế là màn phức tạp nhất của console; mã repo đã có phần lớn nhưng lệch thiết kế ở 13 điểm (GAP-04-01…13) | Xong bản 0.1 đủ bảy tập (xem mục dưới) và ADR-060…069, chờ duyệt tổng thể |
| 3 | PH-19 Thanh toán | Đợt 2 | Nghiệp vụ mới hoàn toàn (Q3): đối soát, hoàn tiền, đa kênh | Xong bản 0.1 đủ bảy tập cộng BRD, khung truy vết, ADR-040…049 (26/11/2026), chờ duyệt tổng thể |
| 4 | PH-05 Bộ điều hợp và kết nối | Đợt 3 | PH-04 phụ thuộc trực tiếp (kết nối, Kamelet, tài khoản CSDL chỉ đọc theo Q359) | Xong bản 0.1 đủ bảy tập (xem mục dưới) và ADR-059, chờ duyệt tổng thể |
| 5 | PH-10 Sự kiện | Đợt 3 | Thay Hub Pulsar | Chưa bắt đầu |
| 6 | PH-02, PH-03, PH-01 | Đợt 3 | Thay API Management | Chưa bắt đầu |
| 7 | PH-14, PH-18, PH-13, PH-12, PH-20 | Đợt 3–4 | MVP còn lại | Chưa bắt đầu |
| 8 | PH-06, 08, 09, 11, 15, 16, 17 | Đợt 4 | Sau MVP | Chưa bắt đầu |

## Phân hệ mẫu PH-07 Danh mục dùng chung

Đợt 2 viết trọn vẹn PH-07 làm mẫu độ sâu cho 19 phân hệ còn lại. Các tài liệu dưới đây đã đủ mục theo dàn ý và qua kiểm tra hoàn thành (không còn TBD ngoài câu hỏi mở, liên kết sạch, hợp đồng API kiểm tra ví dụ, xuất thử .docx).

| Mã | Tài liệu | Tệp đi kèm |
|---|---|---|
| D02-03-PH07 | [Đặc tả yêu cầu chức năng](02-yeu-cau/frs/D02-03-PH07-frs-danh-muc.md) | — |
| D02-04-PH07 | [Đặc tả use case](02-yeu-cau/use-case/D02-04-PH07-use-case-danh-muc.md) | — |
| D03-02-PH07 | [Thiết kế chi tiết phần mềm](03-thiet-ke/sdd/D03-02-PH07-sdd-danh-muc.md) | — |
| D03-03-PH07 | [Thiết kế CSDL](03-thiet-ke/csdl/D03-03-PH07-csdl-danh-muc.md) | DDL, changelog Liquibase, dữ liệu mồi, công cụ sinh tại `03-thiet-ke/csdl/ph07/` |
| D03-04-PH07 | [Đặc tả API và sự kiện](03-thiet-ke/api/D03-04-PH07-api-danh-muc.md) | `openapi-rdm.yaml`, `asyncapi-rdm.yaml` tại `03-thiet-ke/api/ph07/` |
| D03-06-PH07 | [Thiết kế giao diện màn hình](03-thiet-ke/uiux/D03-06-PH07-man-hinh-danh-muc.md) | Bản hi-fi 12 màn (HTML, PNG) tại `03-thiet-ke/uiux/ph07/hifi/` |
| D05-02-PH07 | [Kịch bản và test case](05-kiem-thu/test-case/D05-02-PH07-test-case.md) | Bảng tính `.xlsx`, tệp Gherkin, công cụ sinh ma trận tại `05-kiem-thu/test-case/ph07/` |

## Phân hệ PH-04 Lõi tích hợp và trình thiết kế luồng

Viết theo khuôn và độ sâu của PH-07. Trình thiết kế (UI-04-04…10) được đặc tả tới từng thành phần Liquid Glass trên antd v6. Hai hợp đồng API được sinh bằng script và đã qua bộ kiểm tra (OpenAPI 3.1, AsyncAPI 3.0). DDL đã chạy thử trên PostgreSQL, gồm RLS và changeset di trú từ bảng W2.

| Mã | Tài liệu | Tệp đi kèm |
|---|---|---|
| D02-03-PH04 | [Đặc tả yêu cầu chức năng](02-yeu-cau/frs/D02-03-PH04-frs-tich-hop.md) | — |
| D02-04-PH04 | [Đặc tả use case](02-yeu-cau/use-case/D02-04-PH04-use-case-tich-hop.md) | — |
| D03-02-PH04 | [Thiết kế chi tiết phần mềm](03-thiet-ke/sdd/D03-02-PH04-sdd-tich-hop.md) | — |
| D03-03-PH04 | [Thiết kế CSDL](03-thiet-ke/csdl/D03-03-PH04-csdl-tich-hop.md) | DDL `ph04_int.sql` và công cụ sinh bảng tại `03-thiet-ke/csdl/ph04/` |
| D03-04-PH04 | [Đặc tả API và sự kiện](03-thiet-ke/api/D03-04-PH04-api-tich-hop.md) | `openapi-integration.yaml` (70 operation), `asyncapi-integration.yaml` (14 sự kiện), script sinh tại `03-thiet-ke/api/ph04/` |
| D03-06-PH04 | [Thiết kế giao diện màn hình](03-thiet-ke/uiux/D03-06-PH04-man-hinh-tich-hop.md) | — |
| D05-02-PH04 | [Kịch bản và test case](05-kiem-thu/test-case/D05-02-PH04-test-case.md) | 186 ca; bảng tính `.xlsx`, Gherkin, công cụ sinh ma trận tại `05-kiem-thu/test-case/ph04/` |

## Phân hệ PH-05 Bộ điều hợp và kết nối

Bộ đầu tiên viết theo cách tối ưu token (D00-04): khuôn ở `00-chung/khuon/`, một phiên mỗi tập, commit theo chương, soát mã bằng `kiem_tra_ma.py`, một lượt rà chéo cuối. Phạm vi: kết nối nguồn có bí mật ghi một chiều ở OpenBao, kiểm tra kết nối theo bước, tài khoản CSDL động theo luồng (Q359), bộ điều hợp tám giao thức, CDC Debezium trên Strimzi Kafka Connect (ADR-059), danh mục Kamelet có kiểm tra tĩnh KR-01…14. Trình cấu hình bộ điều hợp (UI-05-10) viết siêu chi tiết.

| Mã | Tài liệu | Tệp đi kèm |
|---|---|---|
| D02-03-PH05 | [Đặc tả yêu cầu chức năng](02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md) | — |
| D02-04-PH05 | [Đặc tả use case](02-yeu-cau/use-case/D02-04-PH05-use-case-bo-dieu-hop.md) | — |
| D03-02-PH05 | [Thiết kế chi tiết phần mềm](03-thiet-ke/sdd/D03-02-PH05-sdd-bo-dieu-hop.md) | — |
| D03-03-PH05 | [Thiết kế CSDL](03-thiet-ke/csdl/D03-03-PH05-csdl-bo-dieu-hop.md) | DDL `ph05_adapter.sql` (23 bảng), bài kiểm cô lập 23 khối, công cụ sinh bảng tại `03-thiet-ke/csdl/ph05/` |
| D03-04-PH05 | [Đặc tả API và sự kiện](03-thiet-ke/api/D03-04-PH05-api-bo-dieu-hop.md) | `openapi-adapter.yaml` (92 operation), `asyncapi-adapter.yaml` (17 kênh), script sinh tại `03-thiet-ke/api/ph05/` |
| D03-06-PH05 | [Thiết kế giao diện màn hình](03-thiet-ke/uiux/D03-06-PH05-man-hinh-bo-dieu-hop.md) | — |
| D05-02-PH05 | [Kịch bản và test case](05-kiem-thu/test-case/D05-02-PH05-test-case.md) | 155 ca; bảng tính `.xlsx`, Gherkin, công cụ sinh ma trận tại `05-kiem-thu/test-case/ph05/` |

## Phân hệ PH-19 Thanh toán

Viết theo khuôn và độ sâu của PH-07, phạm vi Q3: nhà cung cấp (PayGov là kênh đầu tiên, qua adapter chống nhiễm), dịch vụ, đối tác, giao dịch, hoàn tiền, đối soát, dashboard, di trú strangler theo đối tác. CSDL riêng `pg-payment` (Q340), trạng thái nội bộ kèm bảng ánh xạ sang PayGov (GĐ-03). Đặc tả PayGov chưa có nên mọi chỗ phụ thuộc PayGov đều ghi giả định và câu hỏi mở OQ-19-01…07. Phạm vi MVP và Đ2b ghi ở từng FR và từng màn.

| Mã | Tài liệu | Tệp đi kèm |
|---|---|---|
| D02-01-PH19 | [Yêu cầu nghiệp vụ phân hệ](02-yeu-cau/brd/D02-01-PH19-brd-thanh-toan.md) | — |
| D02-03-PH19-00 | [Khung truy vết, mã, quyền, máy trạng thái](02-yeu-cau/frs/D02-03-PH19-00-khung-truy-vet.md) | — |
| D02-03-PH19 | [Đặc tả yêu cầu chức năng](02-yeu-cau/frs/D02-03-PH19-frs-thanh-toan.md) | Công cụ sinh bảng tại `02-yeu-cau/frs/ph19/` |
| D02-04-PH19 | [Đặc tả use case](02-yeu-cau/use-case/D02-04-PH19-use-case-thanh-toan.md) | — |
| D03-02-PH19 | [Thiết kế chi tiết phần mềm](03-thiet-ke/sdd/D03-02-PH19-sdd-thanh-toan.md) | — |
| D03-03-PH19 | [Thiết kế CSDL](03-thiet-ke/csdl/D03-03-PH19-csdl-thanh-toan.md) | DDL `ph19_payment.sql`, ca kiểm thử cách ly tenant, công cụ sinh tại `03-thiet-ke/csdl/ph19/` |
| D03-04-PH19 | [Đặc tả API và sự kiện](03-thiet-ke/api/D03-04-PH19-api-thanh-toan.md) | Ba hợp đồng OpenAPI (quản trị 92, đối tác 10, callback 5 operation) và `asyncapi-payment.yaml` (18 sự kiện), script sinh tại `03-thiet-ke/api/ph19/` |
| D03-06-PH19 | [Thiết kế giao diện màn hình](03-thiet-ke/uiux/D03-06-PH19-man-hinh-thanh-toan.md) | 28 màn UI-19-01…28 |
| D05-02-PH19 | [Kịch bản và test case](05-kiem-thu/test-case/D05-02-PH19-test-case.md) | 34 kịch bản, 187 ca, 12 UAT; bảng tính `.xlsx`, Gherkin, công cụ sinh ma trận tại `05-kiem-thu/test-case/ph19/` |

## Xuất bản .docx

Nguồn là Markdown. Bản .docx theo mẫu hồ sơ nhà nước được sinh bằng `build/build-docx.sh` (xem [build/README.md](build/README.md)). Mỗi tài liệu có khối metadata YAML ở đầu file làm nguồn cho trang bìa và bảng ghi nhận thay đổi.
