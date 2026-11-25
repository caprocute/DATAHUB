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

## Xuất bản .docx

Nguồn là Markdown. Bản .docx theo mẫu hồ sơ nhà nước được sinh bằng `build/build-docx.sh` (xem [build/README.md](build/README.md)). Mỗi tài liệu có khối metadata YAML ở đầu file làm nguồn cho trang bìa và bảng ghi nhận thay đổi.
