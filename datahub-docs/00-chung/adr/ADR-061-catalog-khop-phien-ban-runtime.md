---
ma_tai_lieu: ADR-061
ten: Catalog của trình thiết kế khớp đúng phiên bản Camel Quarkus của runtime, kiểm bằng tệp kê khai
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Chấp nhận (25/11/2026)
nguoi_doc: Kiến trúc sư, trưởng nhóm kỹ thuật
---

# ADR-061 · Catalog khớp đúng phiên bản runtime

## Bối cảnh

Runtime `camel/dancu`, `camel/datdai` dùng Camel Quarkus 3.33.2 (Camel 4.18 LTS), còn catalog của trình thiết kế được sinh cho camel-quarkus 3.35.0. Lệch phiên bản làm trình thiết kế cho cấu hình thuộc tính hoặc thành phần mà runtime không có, lỗi chỉ lộ ra khi nạp luồng ở vận hành. Ngày 25/11/2026 chủ đầu tư chốt catalog phải khớp đúng phiên bản runtime.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Catalog mới nhất, cảnh báo khi lệch | Có tính năng mới sớm | Vẫn sinh luồng không chạy được |
| B. **Catalog sinh từ tệp kê khai runtime, CI chặn khi lệch** | Một nguồn sự thật | Phải sinh lại mỗi lần nâng runtime |

## Quyết định

Chọn **phương án B**. Thực hiện bước đầu ở PR #5 (25/11/2026): catalog hạ về camel-quarkus 3.33.1 (Camel 4.18.2) vì Kaoto không phát hành nhánh 3.33.2; phiên bản đọc từ `camel/*/pom.xml`; `npm run catalog:check` trong cổng CI chặn lệch. Lệch bản vá chỉ được chấp nhận khi công cụ so khớp xác nhận danh sách thành phần và lược đồ giống nhau. Về lâu dài, mỗi hồ sơ runtime có `runtime-manifest.json` (Quarkus, Camel Quarkus, Camel, extension, băm ảnh). Công cụ `scripts/build-catalog` đọc tệp kê khai, sinh chỉ mục catalog có trường `runtimeVersion`, `camelVersion`. CI của `dh-console` và `dh-integration` so khớp và chặn khi lệch. Nâng runtime và nâng catalog nằm trong cùng một thay đổi.

## Hệ quả

Lệch 3.35.0 so với 3.33.2 (GAP-04-01) đã xử lý ở PR #5. Khi nâng runtime, mọi luồng phải kiểm tra lại theo VR-17.

## Truy vết

FR-04-081; BR-04-020; D00-02 §5 (25/11/2026).
