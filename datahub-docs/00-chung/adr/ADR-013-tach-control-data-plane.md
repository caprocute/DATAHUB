---
ma_tai_lieu: ADR-013
ten: Tách control plane và data plane
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-013 · Tách control plane và data plane

## Bối cảnh

Sự cố ở giao diện quản trị hoặc CSDL quản trị không được làm gián đoạn luồng dữ liệu đang phục vụ dịch vụ công (KPI-03 99,9%). Hệ cũ cho giao diện điều khiển trực tiếp agent qua JMX.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Một khối chung | Đơn giản | Lỗi quản trị lan sang luồng dữ liệu |
| B. **Tách hai mặt: control plane (Spring DU, giao diện, CSDL quản trị) và data plane (APISIX, Camel Quarkus, Kafka)** | Data plane tiếp tục chạy với cấu hình đã nạp khi control plane hỏng | Đồng bộ cấu hình phải có cơ chế phát hiện lệch |

## Quyết định

Chọn **phương án B**. Mục tiêu sẵn sàng tách riêng: data plane 99,9%/tháng, control plane 99,5%/tháng. Data plane không gọi đồng bộ tới control plane trên đường xử lý bản tin; cấu hình được đẩy xuống qua GitOps (luồng) và Admin API (gateway). Mạng giữa hai mặt chỉ mở các cổng cần thiết, mTLS qua Istio ambient.

## Hệ quả

Tích cực: cô lập lỗi, đáp ứng LGC-NFR-006. Tiêu cực: thay đổi cấu hình có độ trễ lan truyền vài giây; giao diện phải hiển thị trạng thái đồng bộ.

## Truy vết

BO-02, KPI-03; REQ-03, REQ-04. Tương ứng ADR-014 của repo.
