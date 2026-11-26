---
ma_tai_lieu: ADR-071
ten: Giao nhận sự kiện đẩy qua bộ giao nhận webhook và kéo qua cổng sự kiện, chạy trong dh-runtime
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-runtime, đội vận hành nền tảng, PH-10, PH-03
---

# ADR-071 · Giao nhận đẩy và kéo qua dh-runtime

## Bối cảnh

Đa số HTTT của tỉnh chỉ nói được HTTP; ít HTTT dùng được Kafka client. Hub cũ đẩy bản tin về URI của subscriber, không ký, không DLQ. Datahub cần hai chế độ: ĐẨY (webhook có ký tới URI của HTTT) và KÉO (HTTT tự lấy có xác thực), bảo đảm ít nhất một lần, không phụ thuộc control plane (NFR-00-012), không thêm nhiều thành phần vận hành.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Strimzi Kafka Bridge (HTTP sang Kafka) cho cả phát và kéo; webhook bằng luồng PH-04 | Có sẵn | Bridge không hiểu scope, lược đồ, tenant; không có webhook ký; mỗi subscription một luồng PH-04 làm phình số luồng |
| B. **Hai mô-đun trong `dh-runtime`: cổng sự kiện (API phát, API kéo, kiểm lược đồ) sau APISIX, và bộ giao nhận webhook (mỗi subscription một nhóm tiêu thụ, ký HMAC theo ADR-044, thử lại giãn dần, DLQ, phát lại)** | Dùng lại runtime đã có (Camel Quarkus native, KEDA theo lag, mTLS mesh); chung cơ chế ký với PH-19; data plane độc lập control plane | `dh-runtime` thêm trách nhiệm; phải định cỡ riêng cho bộ giao nhận |
| C. Dịch vụ giao nhận riêng (DU mới) | Tách biệt tải | Thêm một DU phải vận hành, sao lưu, kiểm thử; trái mục tiêu giữ số DU ít |

## Quyết định

Chọn **phương án B**. Cổng sự kiện nhận `POST /event/v1/topics/{topicName}/events` và API kéo có lease và cursor ký; APISIX và OPA kiểm token, scope `topic:{tên}:publish|subscribe` và quan hệ còn hiệu lực ở từng lượt. Bộ giao nhận đọc cấu hình subscription từ `dh-integration` (đệm cục bộ, chạy tiếp khi control plane ngừng), đọc khóa ký thẳng từ OpenBao, gửi qua egress gateway; xác minh endpoint bằng bắt tay CloudEvents HTTP Webhook. Kết quả giao thất bại cuối cùng ghi lên topic `{topicName}.dlq`, `dh-integration` lưu bền thành mục DLQ trong `ph10_event` tới khi xử lý. HTTT lưu lượng lớn có thể dùng Kafka listener `external` (SASL OAUTHBEARER hoặc mTLS) khi tenant bật.

## Hệ quả

- Tích cực: HTTT nhỏ tham gia trục chỉ bằng HTTP; một cơ chế ký chung cho PH-10 và PH-19; DLQ bền, phát lại không phụ thuộc lưu giữ của topic.
- Tiêu cực: mỗi subscription đẩy giữ kết nối consumer, cần giới hạn tổng worker theo tenant; D03-09 phải bổ sung định cỡ mô-đun mới (đề nghị ở D02-03-PH10 §10.4).

## Truy vết

FR-10-033, 036…044, 049…053; BR-10-009, 020, 024…027; NFR-10-002…007, 013; ADR-002, ADR-013, ADR-044.
