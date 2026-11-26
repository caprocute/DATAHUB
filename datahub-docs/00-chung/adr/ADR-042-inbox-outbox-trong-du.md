---
ma_tai_lieu: ADR-042
ten: Hộp nhận, hộp gửi trong DU thanh toán; webhook không phụ thuộc Kafka
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-042 · Hộp nhận, hộp gửi trong DU thanh toán; webhook không phụ thuộc Kafka

## Bối cảnh

Kết quả thanh toán đến từ PayGov qua IPN, có thể lặp, đến muộn, đến trước phản hồi khởi tạo. Kết quả phải được báo lại cho đối tác và cho các phân hệ khác. Nếu ghi CSDL và phát Kafka là hai thao tác rời, sự cố giữa hai bước làm mất hoặc nhân đôi sự kiện. Kafka là hạ tầng dùng chung (ADR-004) và có thể ngừng; việc báo cho đối tác không được dừng theo.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Xử lý IPN ngay trong lời gọi, phát Kafka trực tiếp | Đơn giản | Trả lời PayGov chậm; mất sự kiện khi Kafka lỗi; IPN đồng thời tranh chấp |
| B. **`callback_inbox` ghi nguyên văn rồi xử lý bất đồng bộ; `outbox_event` ghi cùng giao dịch CSDL với thay đổi trạng thái; webhook đọc outbox trực tiếp** | Trả lời PayGov ≤ 200 ms; đúng một lần; không mất sự kiện; webhook chạy khi Kafka ngừng | Thêm bảng, tác vụ nền, cần theo dõi tồn đọng |
| C. Dùng Kafka làm nơi nhận IPN | Mở rộng tốt | Phụ thuộc Kafka ngay ở cửa vào tiền; khó giữ nguyên văn bất biến để làm chứng cứ |

## Quyết định

Chọn **phương án B**. Cửa nhận IPN chỉ xác minh và chèn một dòng vào `callback_inbox` (nguyên văn, băm, kết quả xác minh) rồi trả xác nhận. `InboxProcessor` ở vai trò `worker` lấy việc bằng `FOR UPDATE SKIP LOCKED`, khóa hàng giao dịch, áp máy trạng thái (ADR-043), ghi `transaction_event` và `outbox_event` trong cùng giao dịch CSDL. Phát Kafka bằng Debezium Outbox Event Router (QM-VUA, QM-LON) hoặc `OutboxRelay` quét lô (QM-NHO, dự phòng). `WebhookFanout` đọc bảng outbox, không đọc Kafka, nên webhook và kéo thông báo (API-19-109) vẫn chạy khi Kafka ngừng. Bản ghi kiểm toán cũng đi qua outbox (BR-19-029).

## Hệ quả

Tích cực: không mất sự kiện khi Kafka ngừng, phát bù ≤ 5 phút sau khi phục hồi (NFR-19-013); IPN lặp chỉ xử lý một lần. Tiêu cực: dung lượng `callback_inbox` lớn (khoảng 17 GB mỗi năm ở QM-VUA); cần cảnh báo tồn đọng inbox, outbox.

## Truy vết

FR-19-028…032, 053, 060…062; NFR-19-003, 005, 013; BR-19-014, 015, 021, 029; D03-02-PH19 §6; TS-19-13, 27, 34.
