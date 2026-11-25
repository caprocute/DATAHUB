---
ma_tai_lieu: ADR-069
ten: Máy trạng thái phiên bản luồng với duyệt bốn mắt chốt ở máy chủ, bỏ trạng thái TESTING
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-integration
---

# ADR-069 · Máy trạng thái phiên bản và bốn mắt

## Bối cảnh

Repo cho phép `publish()` từ `DRAFT` (bỏ qua duyệt) và chỉ so người duyệt với người tạo phiên bản (GAP-04-05, 06). Trạng thái `TESTING` trộn khái niệm "đã chạy thử" với vòng đời.

## Quyết định

Máy trạng thái: `DRAFT → PENDING_REVIEW → APPROVED → SUPERSEDED | ROLLED_BACK`, nhánh `CHANGES_REQUESTED`, `DISCARDED` (FRS §4.10). Chỉ `APPROVED` được triển khai. Bốn mắt so người duyệt với người tạo, mọi người đóng góp và người gửi duyệt. "Đã chạy thử đạt" là điều kiện gắn với băm định nghĩa, không phải trạng thái. Chuyển trạng thái nằm trong thực thể miền (D04-01 CC-…), có khóa lạc quan.

## Hệ quả

Cần thay đổi dữ liệu: bỏ `TESTING`, thêm bảng người đóng góp và cột băm (D03-03-PH04).

## Truy vết

FR-04-040, 041; BR-04-004, 005, 016.
