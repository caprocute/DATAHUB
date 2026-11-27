---
ma_tai_lieu: ADR-203
ten: Kênh STABLE và PREVIEW, nâng cấp theo sóng, ngưỡng lỗi 2%
phien_ban: 0.1
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, nhóm PH-20, ATTT, Hội đồng thẩm định
---

# ADR-203 · Kênh STABLE và PREVIEW, nâng cấp theo sóng, ngưỡng lỗi 2%

## Bối cảnh

Nâng cấp phiên bản nền tảng cho nhiều tenant cần giảm rủi ro và dừng được khi lỗi tăng.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Nâng cấp đồng loạt | Đơn giản | Lỗi ảnh hưởng mọi tenant cùng lúc |
| B. **Hai kênh STABLE và PREVIEW, nâng cấp theo sóng, WaveGuard dừng khi tỷ lệ lỗi vượt ngưỡng (mặc định 2%)** | Giới hạn phạm vi ảnh hưởng | Cần cửa sổ bảo trì và thành phần WaveGuard |

## Quyết định

Chọn **phương án B**. Ngưỡng lỗi lấy từ tham số `20.release.wave-error-threshold-percent` (miền 0,5…10, đổi qua PH-18).

## Hệ quả

Tích cực: lỗi dừng sớm. Tiêu cực: nâng cấp kéo dài hơn, cần cửa sổ bảo trì.

## Truy vết

D03-02-PH20 mục 13.6; FR-20-061, FR-20-069.
