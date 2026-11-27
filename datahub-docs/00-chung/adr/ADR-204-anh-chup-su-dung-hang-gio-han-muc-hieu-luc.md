---
ma_tai_lieu: ADR-204
ten: Ảnh chụp sử dụng hằng giờ, hạn mức hiệu lực là min của trần và max của hợp đồng, ghi đè
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-20, ATTT, Hội đồng thẩm định
---

# ADR-204 · Ảnh chụp sử dụng hằng giờ, hạn mức hiệu lực là min của trần và max của hợp đồng, ghi đè

## Bối cảnh

Theo dõi mức sử dụng của tenant để cảnh báo và áp hạn mức. Đo thời gian thực tốn kém và không cần thiết cho hầu hết chỉ tiêu.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Đo thời gian thực | Cảnh báo tức thời | Tải cao, phụ thuộc nhiều nguồn |
| B. **Ảnh chụp hằng giờ; hạn mức hiệu lực = min(trần nền tảng, max(hợp đồng, ghi đè)); thêm ThresholdProbe 5 phút cho nhóm đo bằng Mimir** | Tải thấp, đạt NFR-20-009 | Cảnh báo có độ trễ với nhóm đo hằng giờ |

## Quyết định

Chọn **phương án B**. Dòng thiếu dữ liệu không lưu; ảnh chụp ước lượng đánh dấu `is_estimate`.

## Hệ quả

Tích cực: tải thấp, rõ nguồn. Tiêu cực: độ trễ cảnh báo, thêm ThresholdProbe.

## Truy vết

D03-02-PH20 mục 13.6, L-04, L-12; NFR-20-009.
