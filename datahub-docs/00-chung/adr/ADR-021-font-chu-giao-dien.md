---
ma_tai_lieu: ADR-021
ten: Inter và JetBrains Mono làm phông chữ giao diện, tự lưu trữ
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Trưởng nhóm giao diện, Nhà thiết kế, Hội đồng thẩm định
nguoi_lap: Luồng giao diện
---

# ADR-021 · Inter và JetBrains Mono làm phông chữ giao diện, tự lưu trữ

## Bối cảnh

Liquid Glass của Apple dùng họ chữ SF Pro, nhưng giấy phép của SF Pro chỉ cho phép dùng để thiết kế giao diện chạy trên nền tảng Apple; phần lớn máy văn phòng của cơ quan nhà nước chạy Windows, nên không thể nhúng SF Pro vào ứng dụng web. Phông chữ cho Datahub phải: hiển thị đúng và đẹp toàn bộ dấu tiếng Việt kể cả dấu chồng hai tầng; có chữ số đều độ rộng cho bảng số liệu, thời gian, tiền; có giấy phép mở cho phép nhúng; tự lưu trữ được vì ứng dụng có thể chạy trong trung tâm dữ liệu không ra Internet; và có cảm giác gần với SF Pro để giữ tinh thần Liquid Glass. Ngoài ra cần một phông đơn cách cho mã, YAML, log và mã định danh.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Ngăn xếp phông hệ thống (`system-ui`) | Không tải thêm byte nào; trên máy Apple ra đúng SF Pro | Trên Windows ra Segoe UI, trên Linux tùy bản phân phối; giao diện khác nhau giữa các máy, khó nghiệm thu hình ảnh |
| B. **Inter (bản biến thiên)** | Thiết kế cho màn hình, dáng gần SF Pro, hỗ trợ tiếng Việt đầy đủ, có `tnum` và các biến thể ký tự dễ đọc, giấy phép SIL OFL 1.1 | Thêm khoảng 100–150 KB WOFF2 cho tập con cần thiết |
| C. Be Vietnam Pro | Thiết kế bởi người Việt, dấu đẹp | Chữ rộng, tốn chỗ trong bảng dày; ít trục biến thiên |
| D. Roboto | Phổ biến, sẵn trên Android | Cảm giác Material, lệch tinh thần Liquid Glass |

Cho phông đơn cách, các ứng viên là JetBrains Mono (OFL, hỗ trợ tiếng Việt, phân biệt rõ 0/O, 1/l/I), Fira Code và Source Code Pro.

## Quyết định

Chọn **Inter** (bản biến thiên, trục độ đậm 100–900) cho toàn bộ giao diện và **JetBrains Mono** (bản biến thiên) cho mã, log, định danh. Cả hai được **tự lưu trữ** trong gói `@datahub/tokens`, định dạng WOFF2, cắt tập con Latin, Latin Extended và Vietnamese, khai báo `font-display: swap`. Không tải từ Google Fonts hay CDN. Ngăn xếp dự phòng là `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`. Bật `font-feature-settings: "cv11", "ss01"` cho giao diện và `"tnum"` cho cột số. Chiều cao dòng tối thiểu 1,4 vì dấu tiếng Việt.

## Hệ quả

Tích cực: giao diện đồng nhất trên Windows, macOS, Linux; nghiệm thu hình ảnh ổn định; không phụ thuộc mạng ngoài; không có rủi ro giấy phép. Tiêu cực: thêm dung lượng tải lần đầu (được bộ nhớ đệm trình duyệt giữ lâu dài, nằm trong ngân sách LCP của NFR-00-005); phải cập nhật tập con khi nâng phiên bản phông.

## Trạng thái

Đề xuất.

## Truy vết

RB-03, NFR-00-005, NFR-00-040; D03-05-02 §10, §14. Không có ADR tương ứng trong repo gốc.
