---
ma_tai_lieu: ADR-073
ten: Di trú Hub Pulsar theo cách thay dần bằng cầu nối hai chiều tạm thời chạy trên dh-runtime
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-runtime, đơn vị vận hành hệ cũ, PH-10, PH-18
---

# ADR-073 · Cầu nối di trú Pulsar

## Bối cảnh

Datahub thay hệ cũ bằng chạy song song và thay dần (D00-04 §5). ADR-004 ghi hệ quả cần cầu nối tạm đọc Pulsar ghi Kafka. Bên phát và bên nhận của Hub cũ không chuyển cùng lúc: có HTTT nhận chuyển trước bên phát, có HTTT phát chuyển trước bên nhận. Cần quyết định hướng cầu nối, nơi chạy, cách đối chiếu và điều kiện tắt Hub.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chuyển một lần (big bang) | Không có cầu nối | Rủi ro cao, mọi HTTT phải sửa cùng ngày |
| B. Chỉ cầu nối Pulsar sang Kafka | Đơn giản | Bên phát đã chuyển thì bên nhận cũ mất dữ liệu |
| C. **Cầu nối hai chiều theo từng topic, không bao giờ hai chiều cùng lúc trên một cặp; chạy như luồng Camel trên `dh-runtime` (thành phần `pulsar`), có hạn dùng; đối chiếu số lượng mỗi giờ; chuyển hẳn có duyệt và cửa sổ quay lui** | Mỗi HTTT chuyển theo lịch riêng; đối chiếu được; không thêm thành phần | Cần theo dõi nhiều cầu nối trong giai đoạn chuyển; chuyển đổi nội dung theo lược đồ đích có thể lỗi |

## Quyết định

Chọn **phương án C**. Chiều `PULSAR_TO_KAFKA` dùng khi bên phát còn ở Pulsar; chiều `KAFKA_TO_PULSAR` dùng khi bên phát đã chuyển mà còn bên nhận cũ. Cầu nối dùng subscription Pulsar `Failover` riêng (không ảnh hưởng subscriber cũ), dựng phong bì CloudEvents với `id` lấy từ `messageId`, xác nhận Pulsar sau khi Kafka xác nhận, chống trùng theo `id`. Không di trú backlog lịch sử trừ khi có yêu cầu (Q10-03). Thông tin xác thực cũ không di trú. Hub cũ tắt khi mọi ánh xạ `CUT_OVER` qua cửa sổ quay lui.

## Hệ quả

- Tích cực: không có ngày chuyển chung; mọi bước có đối chiếu và quay lui.
- Tiêu cực: giai đoạn song song tốn tài nguyên ở cả hai hệ; PH-05 phải có loại kết nối Pulsar chỉ dùng cho di trú.

## Truy vết

FR-10-072…076; BR-10-032…034; NFR-10-018; ADR-004; REQ-22.
