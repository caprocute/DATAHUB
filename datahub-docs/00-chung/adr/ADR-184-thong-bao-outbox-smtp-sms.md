---
ma_tai_lieu: ADR-184
ten: Thông báo qua outbox, SMTP/TLS và SMS gateway REST, mẫu Mustache không logic có kiểm tra cấm dữ liệu Hạn chế
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-18, DBA, ATTT, Hội đồng thẩm định
---

# ADR-184 · Thông báo qua outbox và IF-09

## Bối cảnh

SRS giao PH-18 quản mẫu thư và gửi thông báo qua IF-09 (máy chủ thư, SMS gateway). Thư chỉ được chứa liên kết vào ứng dụng, không chứa dữ liệu mức Hạn chế, Nhạy cảm (FR-00-062). Nhiều phân hệ cần gửi lũy đẳng, một số cần gửi đồng bộ cho thư mang liên kết một lần.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Mỗi phân hệ tự gửi SMTP | Không phụ thuộc | Mẫu rải rác, không kiểm soát nội dung, không tùy chọn nhận chung |
| B. Dịch vụ thông báo thương mại bên ngoài | Đủ tính năng | Dữ liệu ra ngoài lãnh thổ, trái yêu cầu lưu trữ trong nước |
| C. **`NotificationApi` của PH-18: outbox trong `ph18_ops`, Spring Mail qua SMTP/TLS, SMS gateway REST, mẫu Mustache không logic có phiên bản và duyệt** | Một điểm kiểm soát nội dung, tùy chọn nhận, giờ yên lặng, nhật ký gửi | PH-18 thành phụ thuộc mềm của bên gửi |

: Các phương án được cân nhắc cho ADR-184

## Quyết định

Chọn **phương án C**. Khi duyệt mẫu, hệ thống từ chối biến thuộc trường được PH-09 phân loại Hạn chế hoặc Nhạy cảm; người nhận ghi bằng `recipientRef`, PH-18 tự phân giải địa chỉ. Kênh cảnh báo khẩn cấp của PH-13 giữ đường dự phòng riêng, không phụ thuộc PH-18.

## Hệ quả

Tích cực: thống nhất nội dung, chống lộ dữ liệu qua thư, có bằng chứng gửi. Tiêu cực: cần chế độ gửi đồng bộ có giới hạn thời gian cho thư mang liên kết (Q01-52).

## Truy vết

FR-18 nhóm E; FR-00-061, 062; IF-09; D03-02-PH18.
