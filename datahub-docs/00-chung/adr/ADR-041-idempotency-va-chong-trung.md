---
ma_tai_lieu: ADR-041
ten: Idempotency hai tầng và bảng chống trùng mã đơn hàng
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-041 · Idempotency hai tầng và bảng chống trùng mã đơn hàng

## Bối cảnh

HTTT đối tác gọi tạo giao dịch qua mạng không tin cậy và thường gửi lại khi hết thời gian chờ. Nếu tạo trùng, người nộp có thể trả tiền hai lần cho một hồ sơ. Bảng giao dịch phân vùng theo tháng (ADR-047) nên không đặt được ràng buộc duy nhất toàn bảng cho mã đơn hàng. Valkey nhanh nhưng có thể mất dữ liệu khi sự cố.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ dùng Valkey `SET NX` | Nhanh | Mất khóa khi Valkey sự cố là tạo trùng |
| B. Chỉ dùng bảng PostgreSQL | Bền | Thêm một lần ghi đồng bộ cho mọi yêu cầu, tranh chấp khóa khi gửi lại dồn dập |
| C. **Hai tầng: Valkey chặn nhanh, PostgreSQL `idempotency_record` là chuẩn; thêm bảng không phân vùng `transaction_order_guard` cho mã đơn hàng** | Nhanh ở đường thường, đúng khi Valkey mất dữ liệu; chặn trùng theo nghiệp vụ, không chỉ theo khóa | Hai cấu trúc phải đồng bộ; có tác vụ dọn |

## Quyết định

Chọn **phương án C**. `Idempotency-Key` bắt buộc với API ghi của đối tác (BR-19-006), phạm vi (tenant, client, method, path), băm nội dung chuẩn hóa JCS. Valkey giữ trạng thái `IN_PROGRESS` hoặc phản hồi đã lưu 24 giờ; `idempotency_record` có khóa duy nhất ghi trong cùng giao dịch CSDL với bản ghi `CREATED`. Cùng khóa khác nội dung trả ERR-19-003; đang xử lý trả ERR-19-004. `transaction_order_guard` giữ (tenant, đối tác, mã đơn hàng) cho giao dịch chưa thất bại; giao dịch về `FAILED`, `EXPIRED`, `CANCELLED` thì nhả guard để tạo lượt mới (BR-19-007). Giao dịch CSDL đầu tiên cam kết trước khi gọi NCC, để pod chết giữa chừng vẫn còn dấu vết cho truy vấn bù.

## Hệ quả

Tích cực: gửi lại bao nhiêu lần cũng ra một giao dịch; chịu được mất Valkey. Tiêu cực: đối tác phải sinh và giữ khóa; thanh toán muộn khi guard đã bị lượt khác giữ sinh chênh lệch `DUPLICATE` cần kế toán xử lý.

## Truy vết

FR-19-022, 023, 033, 034; BR-19-006, 007, 018; ERR-19-002…004, 015; D03-02-PH19 §5.2, §5.3; TS-19-11.
