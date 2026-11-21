---
ma_tai_lieu: ADR-001
ten: Spring Boot 4 và Spring Modulith làm nền backend chung
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-001 · Spring Boot 4 và Spring Modulith làm nền backend chung

## Bối cảnh

Datahub có khoảng 15 phân hệ thuần nghiệp vụ (quản lý hồ sơ, danh mục, quyền, thanh toán, báo cáo). Chủ đầu tư yêu cầu backend chung dùng Java Spring Boot. Đội phát triển ở các tỉnh phổ biến nhất với Spring. Câu hỏi cần quyết định là tổ chức các phân hệ này thành microservice riêng từ đầu, hay thành một số ít đơn vị triển khai lớn có ranh giới module chặt.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Mỗi phân hệ một microservice | Triển khai độc lập, mở rộng riêng | 15+ dịch vụ, chi phí vận hành lớn cho TTDL tỉnh; giao dịch phân tán; đội nhỏ khó gánh |
| B. Một monolith không ranh giới | Đơn giản lúc đầu | Mã dính chùm, không tách được về sau |
| C. **Đơn vị triển khai (DU) dạng modular monolith với Spring Modulith**, gom phân hệ theo miền | Ít đơn vị vận hành; ranh giới module được kiểm tra tự động; tách thành dịch vụ riêng khi cần | Cần kỷ luật ranh giới; một DU lỗi ảnh hưởng nhiều phân hệ cùng DU |

## Quyết định

Chọn **phương án C**. Backend chung dùng **Java 21, Spring Boot 4.x, Spring Modulith**. Các phân hệ được gom vào bốn đến năm DU theo miền (danh sách DU tại D03-01 §5). Mỗi phân hệ là một module Modulith với ba package con `api`, `internal`, `events`; module khác chỉ được gọi qua `api` hoặc qua sự kiện. Kiểm thử `ApplicationModules.verify()` chạy trong CI và chặn merge khi vi phạm ranh giới. Mỗi phân hệ sở hữu schema PostgreSQL riêng, không truy vấn chéo schema.

Chọn Java 21 thay vì 25 vì toàn bộ thành phần đi kèm (Camel Quarkus, thư viện ký số, driver) đã được kiểm chứng trên 21; sẽ rà soát nâng cấp theo chính sách vòng đời phiên bản tại D04-02.

## Hệ quả

Tích cực: số đơn vị vận hành giảm từ 15+ xuống 4–5, phù hợp năng lực TTDL tỉnh; giao dịch trong một phân hệ là giao dịch cục bộ. Tiêu cực: phải có quy tắc chống phụ thuộc chéo và kiểm tra tự động; khi một phân hệ cần mở rộng riêng (ví dụ PH-19 lúc cao điểm) thì phải tách DU. Điều kiện tách DU được ghi ở D03-01.

## Truy vết

REQ-01…22; NFR khả năng bảo trì (D02-02). Tương ứng ADR-019 trong `docs/05-adr` của repo.
