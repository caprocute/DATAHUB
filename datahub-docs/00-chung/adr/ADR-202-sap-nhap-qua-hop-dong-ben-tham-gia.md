---
ma_tai_lieu: ADR-202
ten: Sáp nhập tenant qua hợp đồng bên tham gia, PH-18 chạy chuyển dữ liệu
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-20, ATTT, Hội đồng thẩm định
---

# ADR-202 · Sáp nhập tenant qua hợp đồng bên tham gia, PH-18 chạy chuyển dữ liệu

## Bối cảnh

Sáp nhập hai tenant cần chuyển dữ liệu của nhiều phân hệ. PH-20 không nên biết cấu trúc dữ liệu của từng phân hệ khác.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. PH-20 chạm trực tiếp dữ liệu từng phân hệ | Một nơi điều khiển | Vi phạm ranh giới schema, phụ thuộc cấu trúc của mọi phân hệ |
| B. **Mỗi phân hệ khai báo hợp đồng bên tham gia; PH-20 lập kế hoạch, PH-18 chạy chuyển qua API-18-150** | PH-20 không biết schema phân hệ khác | Mỗi phân hệ phải khai báo và kiểm thử hợp đồng |

## Quyết định

Chọn **phương án B**. Mỗi kế hoạch có một tenant nguồn; nhiều kế hoạch có thể cùng đích.

## Hệ quả

Tích cực: giữ ranh giới phân hệ. Tiêu cực: chi phí khai báo hợp đồng ở từng phân hệ.

## Truy vết

D03-02-PH20 mục 13.6 và L-11; D03-02-PH18 mục chuyển sáp nhập.
