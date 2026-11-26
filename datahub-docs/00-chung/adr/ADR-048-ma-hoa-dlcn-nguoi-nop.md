---
ma_tai_lieu: ADR-048
ten: Mã hóa dữ liệu cá nhân người nộp và tìm kiếm bằng băm HMAC
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm PH-19, nhóm ATTT, Hội đồng thẩm định
---

# ADR-048 · Mã hóa dữ liệu cá nhân người nộp và tìm kiếm bằng băm HMAC

## Bối cảnh

Giao dịch chứa họ tên, số định danh, điện thoại, thư điện tử, địa chỉ của người nộp. Ở QM-VUA mỗi năm khoảng 7 triệu giao dịch, vượt ngưỡng 100.000 chủ thể của NĐ 331/2026 cho cấp độ 3 và chịu Luật BVDLCN 91/2025. Cán bộ vẫn cần tìm giao dịch theo người nộp (LGC-PAY-015). ADR-032 đã chọn envelope encryption qua OpenBao transit ở mức hệ thống; ADR này chi tiết hóa cho PH-19.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ mã hóa đĩa (TDE) | Không đổi mã | Không bảo vệ trước người có quyền đọc CSDL, bản sao lưu đã khôi phục |
| B. **Envelope theo giao dịch: DEK AES-256-GCM sinh tại chỗ, bọc bằng khóa của tenant ở OpenBao transit; bản che tính sẵn; tìm kiếm qua HMAC của giá trị chuẩn hóa** | Bản rõ chỉ có trong bộ nhớ khi được phép; tìm đúng giá trị đầy đủ; xóa bằng hủy DEK | Không tìm được theo một phần họ tên |
| C. Mã hóa tất định để tìm kiếm | Tìm được trực tiếp | Lộ tần suất; cùng giá trị ra cùng bản mã |

## Quyết định

Chọn **phương án B**. Cột `payer_*_enc` mã hóa envelope; `payer_dek_wrapped` lưu cùng dòng. `payer_search_hash`, `payer_phone_hash`, `payer_id_no_hash` là HMAC-SHA256 bằng khóa transit `payer-search` của tenant trên giá trị chuẩn hóa (không dấu, chữ thường; điện thoại E.164). Bản che `payer_name_masked`, `payer_phone_masked` tính lúc ghi theo BR-19-031. Xem bản rõ cần `PERM-19-transaction-read-pii` và lý do, mỗi lần xem ghi kiểm toán (khung §13.4 quy tắc 6). Sau thời hạn lưu, hủy DEK để dữ liệu không giải mã được (crypto-shredding), giữ bản che và số liệu. Không lưu số thẻ, số tài khoản đầy đủ, CVV, OTP ở bất kỳ đâu (BR-19-032).

## Hệ quả

Tích cực: bản sao lưu, bản sao CSDL không lộ dữ liệu cá nhân; đáp ứng yêu cầu mã hóa của TCVN 14423:2026 cấp độ 3. Tiêu cực: tìm theo một phần họ tên không còn (khác hệ cũ, có ghi chú trên màn UI-19-14); mỗi lần hiện bản rõ thêm một lời gọi OpenBao.

## Truy vết

FR-19-049, 050, 051, 052; NFR-19-024; BR-19-031, 032; D03-02-PH19 §9.5; ADR-032; LGC-PAY-015; TS-19-22, 23, 34.
