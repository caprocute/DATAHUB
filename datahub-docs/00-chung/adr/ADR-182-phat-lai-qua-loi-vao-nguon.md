---
ma_tai_lieu: ADR-182
ten: Phát lại bản tin lỗi luôn qua lối vào của nguồn, khóa lũy đẳng theo bản sửa, loạt lớn duyệt bốn mắt
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-18, DBA, ATTT, Hội đồng thẩm định
---

# ADR-182 · Phát lại qua lối vào của nguồn

## Bối cảnh

Phát lại sai có thể gửi trùng hồ sơ, trùng giao dịch thanh toán sang hệ đích. Nếu PH-18 gọi thẳng hệ đích thì bỏ qua các bước kiểm soát của luồng (quyền, chuẩn hóa, che dữ liệu, ký số).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. PH-18 gọi thẳng hệ đích | Đơn giản | Bỏ qua kiểm soát của luồng, cần thông tin xác thực của mọi đích, không lũy đẳng |
| B. **PH-18 trả bản tin về lối vào của nguồn qua `ReplayPort` (PH-04 runtime, PH-10 qua `event:replay`, phân hệ khác qua API phát lại đã đăng ký), khóa lũy đẳng `dlqId:revision`** | Mọi bước kiểm soát chạy lại; nguồn tự chống trùng | Phụ thuộc nguồn khả dụng; kết quả về bất đồng bộ |

: Các phương án được cân nhắc cho ADR-182

## Quyết định

Chọn **phương án B**. Lượt phát lại loạt vượt ngưỡng `18.dlq.replay.approval-threshold` cần người thứ hai có `PERM-18-approve` duyệt; tốc độ giới hạn theo nguồn; có tạm dừng, hủy. Kết quả về qua callback `ops:replay-callback` hoặc sự kiện của nguồn.

## Hệ quả

Tích cực: phát lại an toàn, lặp lại không tạo bản trùng. Tiêu cực: nguồn mới phải đăng ký cổng phát lại trước khi được phát lại từ PH-18; nguồn chưa đăng ký chỉ xem và bỏ qua được.

## Truy vết

FR-18 nhóm D; BR-04-008; D05-01 tiêu chí xử lý lại lũy đẳng; D03-02-PH18.
