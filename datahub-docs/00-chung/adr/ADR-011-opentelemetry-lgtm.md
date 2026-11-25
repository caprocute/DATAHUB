---
ma_tai_lieu: ADR-011
ten: OpenTelemetry và bộ LGTM cho giám sát xuyên suốt
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-011 · OpenTelemetry và bộ LGTM cho giám sát xuyên suốt

## Bối cảnh

Hệ cũ đọc số liệu qua JMX/Jolokia và ghi log một dòng phân tách bằng dấu `|`. Không truy được một giao dịch qua nhiều thành phần. Datahub cần MTTD ≤ 5 phút (KPI-15) và truy vết theo `trace_id`.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Giữ JMX | Quen | Không có trace; mở JMX ra mạng là rủi ro |
| B. **OpenTelemetry (SDK + Collector) với Prometheus/Mimir, Loki, Tempo, Grafana** | Chuẩn mở; một mã truy vết xuyên APISIX, Spring, Camel, Kafka | Phải vận hành bốn kho dữ liệu giám sát |
| C. Elastic stack | Tìm kiếm log mạnh | Tốn tài nguyên; giấy phép |

## Quyết định

Chọn **phương án B**. Mọi thành phần phát trace theo W3C Trace Context; log ở dạng JSON có `trace_id`, `tenant_id`; dữ liệu cá nhân bị che trước khi ghi. Nhật ký kiểm toán là dòng riêng, không dùng Loki, mà ghi vào bảng chỉ-thêm và kho WORM (ADR-008).

## Hệ quả

Tích cực: thay thế toàn bộ màn giám sát Bus, Hub, APIM của hệ cũ bằng một nền. Tiêu cực: dung lượng lưu trữ giám sát đáng kể; chính sách lưu giữ tại D03-09.

## Truy vết

REQ-13; LGC-BUS-007, 014…019, 027, 029, 030; LGC-NFR-004. Tương ứng ADR-007 của repo.
