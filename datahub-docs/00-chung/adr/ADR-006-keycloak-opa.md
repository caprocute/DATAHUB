---
ma_tai_lieu: ADR-006
ten: Keycloak cho định danh và OPA cho ủy quyền
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-006 · Keycloak cho định danh và OPA cho ủy quyền

## Bối cảnh

Hệ cũ đã dùng Keycloak cho SSO. Datahub cần thêm: realm theo tenant, MFA bắt buộc cho quản trị, ủy quyền chi tiết theo vai trò, tenant, mục đích khai thác dữ liệu, và khả năng kết nối VNeID khi có yêu cầu.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Keycloak, phân quyền viết trong mã | Đơn giản | Quy tắc rải rác, khó kiểm toán |
| B. **Keycloak cho xác thực, OPA cho quyết định ủy quyền, chính sách Rego trong Git** | Chính sách tập trung, kiểm thử được, có phiên bản | Thêm một thành phần |
| C. IAM thương mại | Đầy đủ | Bản quyền, phụ thuộc |

## Quyết định

Chọn **phương án B**. Keycloak phát hành token OIDC; mỗi tenant một realm (tạo tự động bởi PH-20). Grant `password` bị tắt; người dùng dùng Authorization Code + PKCE, máy dùng `client_credentials` hoặc mTLS. OPA là điểm quyết định (PDP); điểm thực thi (PEP) đặt ở APISIX và ở từng DU. Ma trận vai trò và quyền tại D02-08.

## Hệ quả

Tích cực: kiểm toán được ai có quyền gì; thay đổi chính sách không cần phát hành lại ứng dụng. Tiêu cực: độ trễ thêm cho mỗi quyết định; giảm bằng OPA chạy cạnh ứng dụng và bộ nhớ đệm quyết định ngắn hạn.

## Truy vết

REQ-12; LGC-IAM-*. Tương ứng ADR-004 của repo.
