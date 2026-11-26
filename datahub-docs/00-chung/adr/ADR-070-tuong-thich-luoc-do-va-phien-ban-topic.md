---
ma_tai_lieu: ADR-070
ten: Chiến lược tương thích lược đồ sự kiện và phiên bản chính của topic
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-integration và dh-runtime, PH-04, PH-05, PH-10
---

# ADR-070 · Tương thích lược đồ và phiên bản chính của topic

## Bối cảnh

ADR-004 đã chọn Kafka và Apicurio Registry, yêu cầu mọi topic có lược đồ và quy tắc `BACKWARD`. Còn phải quyết: lược đồ gắn với topic thế nào, ai được đăng ký, định dạng trên dây, và xử lý thế nào khi cần thay đổi phá vỡ. Hub Pulsar cũ chỉ có "cấu trúc" mô tả, bên phát đổi định dạng âm thầm làm vỡ bên nhận. HTTT của tỉnh dùng nhiều ngôn ngữ, một số đã có thư viện serde của Confluent.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Bên phát tự đăng ký lược đồ (`auto.register`), tương thích kiểm ở Apicurio | Đơn giản cho bên phát | Không có duyệt; bên phát có quyền ghi registry; khó truy vết ai đổi gì |
| B. **PH-10 là bên duy nhất ghi Apicurio; một artifact mỗi topic (`groupId = tenant`, `artifactId = topicName`); phiên bản qua duyệt bốn mắt, kiểm tra bằng `dryRun`; thay đổi phá vỡ tạo topic `.v{n+1}`** | Có duyệt, truy vết; bên nhận không bị vỡ; lịch sử tương thích theo topic rõ | Bên phát phải chờ duyệt khi đổi lược đồ; thay đổi phá vỡ cần thời gian chạy song song |
| C. Cho phép phá vỡ trong cùng topic với mức `NONE` và số phiên bản trong tiêu đề | Không phải tạo topic mới | Bên nhận cũ vỡ ngay; phát lại dữ liệu cũ phức tạp |

## Quyết định

Chọn **phương án B**. Mức mặc định `BACKWARD`; được chọn các mức `FORWARD`, `FULL` và biến thể `_TRANSITIVE` qua duyệt; `NONE` chỉ cho topic chưa từng hoạt động. Phiên bản nháp không ghi vào Apicurio, chỉ kiểm tra bằng chế độ chạy thử; khi duyệt mới tạo phiên bản `ENABLED`. Trạng thái phiên bản ở PH-10 dùng đúng tên trạng thái của Apicurio 3 (`ENABLED`, `DEPRECATED`, `DISABLED`). Định dạng trên dây: phong bì CloudEvents 1.0 chế độ nhị phân (tiêu đề `ce_*`), giá trị có tiền tố định danh lược đồ kiểu Confluent (byte 0 và 4 byte `contentId`) để serde của Apicurio và Confluent cùng đọc được; Apicurio mở API `ccompat/v7` chỉ đọc cho HTTT qua APISIX. Avro là định dạng khuyến nghị, JSON Schema được phép. Thay đổi phá vỡ tạo topic mới `…v{n+1}` với artifact mới, topic cũ `DEPRECATED` có `sunsetAt`; bên phát chịu trách nhiệm phát song song trong giai đoạn chuyển.

## Hệ quả

- Tích cực: bên nhận không bao giờ gặp bản tin không đọc được theo lược đồ đã biết; mọi thay đổi lược đồ có người duyệt; PH-05 CDC đi cùng cơ chế (thay đổi phá vỡ thành `.v2`).
- Tiêu cực: bên phát Kafka trực tiếp vẫn có thể ghi sai vì Kafka mã nguồn mở không kiểm ở broker; bù bằng giám sát tuân thủ lấy mẫu (FR-10-023). Thời gian chạy song song hai topic làm tăng dung lượng.

## Truy vết

FR-10-008, 009, 013, 015, 017…024, 066, 068; BR-10-011…015; ADR-004. Tương ứng một phần ADR-005 của repo.
