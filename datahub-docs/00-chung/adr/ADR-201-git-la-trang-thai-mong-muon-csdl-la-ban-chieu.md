---
ma_tai_lieu: ADR-201
ten: Git là trạng thái mong muốn của tenant, CSDL là bản chiếu
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-20, ATTT, Hội đồng thẩm định
---

# ADR-201 · Git là trạng thái mong muốn của tenant, CSDL là bản chiếu

## Bối cảnh

Cấu hình tenant cần lịch sử có chữ ký, xem lại được và so khớp với thực tế. Đồng thời cần truy vấn nhanh cho giao diện quản trị.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Chỉ CSDL | Truy vấn đơn giản | Không có lịch sử ký, khó đối chiếu |
| B. Chỉ Git | Có lịch sử ký | Truy vấn chậm, không có RLS |
| C. **Git là trạng thái mong muốn, CSDL là bản chiếu, có DriftDetector so khớp** | Có lịch sử ký, truy vấn nhanh | Cần bộ phát hiện lệch và quy trình xử lý lệch |

## Quyết định

Chọn **phương án C**. Chế độ `DEDICATED_DB` thêm tệp `database.yaml` vào bản khai báo của tenant.

## Hệ quả

Tích cực: lịch sử ký, phát hiện lệch. Tiêu cực: thêm thành phần DriftDetector và quy trình xử lý lệch.

## Truy vết

D03-02-PH20 mục 13.6 và L-15; D03-03-PH20.
