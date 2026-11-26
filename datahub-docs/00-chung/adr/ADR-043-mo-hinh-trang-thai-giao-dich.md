---
ma_tai_lieu: ADR-043
ten: Máy trạng thái giao dịch nội bộ, ánh xạ trạng thái NCC qua bảng
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-043 · Máy trạng thái giao dịch nội bộ, ánh xạ trạng thái NCC qua bảng

## Bối cảnh

Hệ cũ lưu trạng thái giao dịch bằng mã số của PayGov và có ba trạng thái hoàn trả chưa có chức năng (LGC-PAY-025). Thiếu một định nghĩa duy nhất về chuyển trạng thái hợp lệ dẫn tới giao dịch "thành công" từ nguồn không xác thực (lượt quay về của trình duyệt). Giả định GĐ-03 chọn trạng thái nội bộ kèm bảng ánh xạ sang PayGov.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Dùng nguyên mã trạng thái của PayGov | Không cần ánh xạ | Lõi phụ thuộc PayGov; không có hoàn tiền, đối soát |
| B. **Tám trạng thái nội bộ, bảng chuyển trạng thái cố định trong mã theo cặp (trạng thái, nguồn), ánh xạ mã NCC qua bảng có phiên bản** | Một nguồn sự thật; nguồn không xác thực không thể đổi trạng thái về kiểu dữ liệu; đổi PayGov không đổi lõi | Phải duy trì bảng ánh xạ cho mỗi NCC |
| C. Dùng công cụ quy trình (Flowable) cho vòng đời giao dịch | Trực quan | Quá nặng cho tải 200 giao dịch/giây; khó đúng một lần |

## Quyết định

Chọn **phương án B**. Trạng thái: `CREATED`, `PENDING`, `SUCCEEDED`, `FAILED`, `EXPIRED`, `CANCELLED`, `PARTIALLY_REFUNDED`, `REFUNDED`. Nguồn chuyển: `PARTNER_API`, `PROVIDER_INIT`, `IPN`, `POLL`, `MANUAL_SYNC`, `USER`, `EXPIRY_JOB`, `REFUND`, `DISCREPANCY_RESOLUTION`, `MIGRATION`. Lượt quay về của người nộp không có trong tập nguồn (BR-19-014). Trạng thái cuối chỉ đảo qua xử lý chênh lệch có phê duyệt; thanh toán muộn cho phép `EXPIRED`/`CANCELLED` → `SUCCEEDED` (BR-19-018). Mỗi chuyển ghi `transaction_event` chỉ-thêm, tăng `sequence`, ghi `mapping_version`. Bảng ánh xạ hệ cũ → nội bộ cho di trú nằm ở khung §7.4.

## Hệ quả

Tích cực: kiểm thử được từng ô của bảng chuyển (D05-02-PH19 §3.2); hội đồng thấy rõ không có đường tắt. Tiêu cực: mỗi NCC mới cần bảng ánh xạ được duyệt trước khi kích hoạt.

## Truy vết

FR-19-024…031, 036, 046, 069; BR-19-014…019; ERR-19-021; khung D02-03-PH19-00 §7.4; D03-02-PH19 §5.4, §7; LGC-PAY-019, 025.
