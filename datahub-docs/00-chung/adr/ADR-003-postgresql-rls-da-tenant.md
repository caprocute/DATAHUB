---
ma_tai_lieu: ADR-003
ten: PostgreSQL với Row-Level Security làm cơ chế cách ly tenant mặc định
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-003 · PostgreSQL với Row-Level Security làm cơ chế cách ly tenant mặc định

## Bối cảnh

Datahub phục vụ nhiều tỉnh (Q2). Dữ liệu của tỉnh này tuyệt đối không được lộ sang tỉnh khác. Đồng thời, một số tỉnh (hoặc yêu cầu cấp độ 4) có thể đòi hỏi cách ly vật lý. Cần một mô hình cách ly vừa rẻ cho đa số, vừa nâng cấp được cho trường hợp đặc biệt.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Một CSDL riêng cho mỗi tenant | Cách ly mạnh nhất | Chi phí vận hành tăng tuyến tính theo số tỉnh; khó nâng cấp schema đồng loạt |
| B. Một schema riêng cho mỗi tenant | Cách ly khá | Số schema bùng nổ (20 phân hệ × 34 tỉnh) |
| C. **Bảng chung, cột `tenant_id` và PostgreSQL Row-Level Security (RLS)** | Rẻ, một lần migrate; RLS chặn ở tầng CSDL kể cả khi mã ứng dụng có lỗi | Cần kỷ luật đặt biến phiên; truy vấn quản trị liên tenant phải đi qua vai trò riêng |
| D. **Kết hợp: C mặc định, A cho tenant yêu cầu cách ly vật lý** | Đáp ứng cả hai nhu cầu | Phải hỗ trợ hai chế độ trong vận hành |

## Quyết định

Chọn **phương án D**. Mặc định mọi bảng nghiệp vụ có cột `tenant_id` (kiểu T-TENANT, D00-01 §5) và chính sách RLS `USING (tenant_id = current_setting('app.tenant_id'))`. Ứng dụng kết nối bằng vai trò không có quyền `BYPASSRLS`; biến `app.tenant_id` được đặt ở đầu mỗi giao dịch từ ngữ cảnh đã xác thực. Tenant có yêu cầu cách ly vật lý được cấp cụm CloudNativePG riêng; định tuyến kết nối theo bảng cấu hình tenant của PH-20. Chi tiết tại D03-10.

PostgreSQL phiên bản 18 trên CloudNativePG, có PITR. Kafka, kho đối tượng và Keycloak cách ly theo cơ chế tương ứng (tiền tố topic, bucket, realm) mô tả tại D03-10.

## Hệ quả

Tích cực: chi phí thấp; lỗ hổng quên điều kiện `WHERE tenant_id` trong mã không làm lộ dữ liệu. Tiêu cực: mọi kiểm thử tích hợp phải có ca kiểm tra rò rỉ chéo tenant (bắt buộc trong D05-01); thao tác thống kê toàn nền tảng phải dùng vai trò riêng có nhật ký.

## Truy vết

REQ-20, BO-06; D03-10. Mở rộng ADR-008 của repo.
