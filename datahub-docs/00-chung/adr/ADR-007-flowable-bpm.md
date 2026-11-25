---
ma_tai_lieu: ADR-007
ten: Flowable cho quy trình nghiệp vụ và luồng duyệt
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-007 · Flowable cho quy trình nghiệp vụ và luồng duyệt

## Bối cảnh

Nhiều nghiệp vụ có bước duyệt của người (kết nạp HTTT, chấp thuận khai thác dữ liệu, phát hành danh mục, kích hoạt nhà cung cấp thanh toán), và PH-11 cần điều phối quy trình liên thông nhiều cơ quan.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Tự viết máy trạng thái trong từng phân hệ | Nhẹ | Lặp lại; không có giao diện theo dõi |
| B. Camunda 8 | Mạnh | Bản tự triển khai yêu cầu giấy phép cho môi trường sản xuất |
| C. **Flowable (BPMN 2.0, nhúng vào Spring Boot)** | Apache 2.0; nhúng được; BPMN chuẩn | Giao diện modeler cần tích hợp lại |

## Quyết định

Chọn **phương án C**. Luồng duyệt ngắn trong một phân hệ dùng máy trạng thái trong mã (Spring State Machine không cần thiết, dùng enum và bảng chuyển trạng thái). Quy trình có từ hai bước duyệt trở lên, có hạn xử lý hoặc liên cơ quan dùng Flowable nhúng trong DU của PH-11; các phân hệ khác khởi tạo quy trình qua API của PH-11.

## Hệ quả

Tích cực: một chỗ theo dõi mọi việc chờ duyệt. Tiêu cực: phải định nghĩa ranh giới rõ giữa máy trạng thái cục bộ và quy trình Flowable để tránh dùng BPM cho việc đơn giản.

## Truy vết

REQ-11, BP-01, BP-03. Tương ứng ADR-009 của repo.
