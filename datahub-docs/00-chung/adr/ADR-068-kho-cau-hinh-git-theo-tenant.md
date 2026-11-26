---
ma_tai_lieu: ADR-068
ten: Kho cấu hình luồng tách theo tenant, nhánh theo môi trường, commit ký và yêu cầu gộp cho PROD
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, vận hành, ATTT
---

# ADR-068 · Kho cấu hình Git theo tenant

## Bối cảnh

`GitOpsPublisher` hiện ghi YAML vào thư mục `routes/` của chính repo mã. Trộn cấu hình vận hành của các tỉnh vào repo mã làm lộ cấu hình tỉnh này cho tỉnh khác và cho đội phát triển, và không bảo vệ được nhánh theo môi trường.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Một kho chung, thư mục theo tenant | Ít kho | Quyền đọc khó tách; một lỗi lộ mọi tỉnh |
| B. **Một kho mỗi tenant `dh-flows-{tenant}`, nhánh `env/test`, `env/staging`, `env/prod`** | Tách quyền rõ; xóa tenant là xóa kho | Nhiều kho; ApplicationSet theo tenant |
| C. Lưu trong CSDL, Argo CD đọc qua plugin | Không cần Git | Mất lịch sử Git, mất mô hình GitOps chuẩn |

## Quyết định

Chọn **phương án B**. `dh-integration` ghi bằng tài khoản máy có quyền ghi nhánh `env/test` trực tiếp; nhánh `env/prod` được bảo vệ, chỉ nhận yêu cầu gộp đã qua CI kho cấu hình (kiểm tra lại, ca kiểm thử) và tự gộp khi đạt. Mọi commit ký bằng khóa của dịch vụ. PH-20 tạo kho khi khởi tạo tenant.

## Hệ quả

Argo CD có quyền đọc mọi kho tenant; kỹ sư tỉnh không cần quyền Git trực tiếp. Kho cấu hình là đối tượng sao lưu và DR (D03-09).

## Truy vết

FR-04-042; GAP-04-03; ADR-009, ADR-037.
