---
ma_tai_lieu: ADR-004
ten: Kafka và Apicurio Registry thay Apache Pulsar cho trao đổi sự kiện
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Chấp nhận
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-004 · Kafka và Apicurio Registry thay Apache Pulsar cho trao đổi sự kiện

## Bối cảnh

Khối Hub của hệ cũ dùng Apache Pulsar. Datahub cần trao đổi sự kiện giữa HTTT (PH-10), sự kiện nội bộ giữa phân hệ, và thu thay đổi dữ liệu (CDC). Cần chọn một nền sự kiện duy nhất.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Giữ Pulsar | Không phải di trú khái niệm | Hệ sinh thái nhỏ hơn; ít kỹ sư vận hành tại Việt Nam; tích hợp Debezium, Strimzi kém hơn |
| B. **Kafka (vận hành bằng Strimzi, chế độ KRaft) + Apicurio Registry** | Hệ sinh thái lớn nhất; Debezium cho CDC; Strimzi vận hành trên K8s; schema registry mở | Không có multi-tenant gốc như Pulsar; phải tự cách ly bằng tiền tố topic và ACL |
| C. RabbitMQ | Đơn giản | Không phù hợp lưu giữ và phát lại sự kiện |

## Quyết định

Chọn **phương án B**. Topic đặt tên theo D00-01 §6 với tiền tố tenant. Mọi topic phải có schema đăng ký ở Apicurio (Avro hoặc JSON Schema) và quy tắc tương thích `BACKWARD`. ACL Kafka cấp theo publisher/subscriber đã đăng ký ở PH-10. Khái niệm dự án tích hợp, publisher, subscriber, publication, subscription của hệ cũ được giữ nguyên ở tầng nghiệp vụ PH-10.

## Hệ quả

Tích cực: thống nhất một nền sự kiện cho cả ba nhu cầu. Tiêu cực: di trú topic Pulsar sang Kafka trong giai đoạn chạy song song cần cầu nối tạm (Camel route đọc Pulsar ghi Kafka), mô tả ở D06-01.

## Truy vết

REQ-10; LGC-HUB-*. Tương ứng ADR-005 của repo.
