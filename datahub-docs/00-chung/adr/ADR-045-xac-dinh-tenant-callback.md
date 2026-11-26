---
ma_tai_lieu: ADR-045
ten: Xác định tenant của callback bằng connectionKey trong đường dẫn
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-045 · Xác định tenant của callback bằng connectionKey trong đường dẫn

## Bối cảnh

Datahub đa tenant (Q2, ADR-003): mọi truy cập dữ liệu phải có tenant trước. Lời gọi của đối tác mang tenant trong token. IPN và lượt quay về từ PayGov không có token của Datahub; nhiều tỉnh có thể dùng chung một địa chỉ đăng ký với PayGov ở HT-B. Nếu đoán tenant từ nội dung trước khi xác minh, kẻ tấn công có thể dò hoặc chạm dữ liệu của tỉnh khác.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Tên miền con theo tenant | Rõ ràng | Mỗi tỉnh phải đăng ký địa chỉ riêng với PayGov; khó ở cụm dùng chung |
| B. **`connectionKey` 160 bit ngẫu nhiên trong đường dẫn, gắn một NCC của một tenant; kiểm tra chéo với mã đơn vị trong nội dung đã ký** | Xác định tenant trước khi đọc nội dung; không đoán được; không lộ tồn tại | Phải xoay khóa có chuyển tiếp khi lộ |
| C. Tra tenant theo tiền tố mã giao dịch trong nội dung | Không cần khóa | Đọc nội dung chưa xác minh để chọn tenant; dò được |

## Quyết định

Chọn **phương án B**. Đường dẫn `/api/payment-callback/v1/{adapter}/{connectionKey}/…`. CSDL chỉ lưu `sha256(connectionKey)`; khóa đầy đủ ở OpenBao. Khóa không tồn tại trả ERR-19-027 với thân giống hệt lỗi nguồn không được phép. Sau khi xác định NCC, `TenantSession` đặt tenant cho RLS rồi mới xác minh; mã đơn vị trong nội dung đã ký phải khớp `merchant_ref` của NCC, không khớp thì `REJECTED` lý do `TENANT_MISMATCH` và cảnh báo khẩn. Đổi `connectionKey` cho phép hai khóa cùng hợp lệ 7 ngày.

## Hệ quả

Tích cực: không có đường đọc chéo tenant ở cửa callback (TS-19-31). Tiêu cực: đăng ký địa chỉ với PayGov phải kèm khóa; khi PayGov chỉ cho một địa chỉ cho cả hệ thống (A-19-07), PH-03 định tuyến theo tiền tố mã giao dịch tới đúng đường dẫn có khóa.

## Truy vết

FR-19-029; NFR-19-020, 025; ERR-19-027; D03-02-PH19 §6.2; D03-10; ADR-003; TS-19-30, 31.
