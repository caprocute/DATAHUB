---
ma_tai_lieu: ADR-012
ten: OpenBao (hoặc Vault) làm kho bí mật, cấm bí mật trong mã và tài liệu
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-012 · OpenBao (hoặc Vault) làm kho bí mật, cấm bí mật trong mã và tài liệu

## Bối cảnh

Tài liệu hệ cũ chứa Consumer Key/Secret dạng văn bản. Hệ cũ mã hóa thông tin kết nối bằng thư viện riêng. Datahub giữ thông tin xác thực tới NDXP, PayGov, CSDL nguồn của hàng trăm HTTT.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Kubernetes Secret thuần | Có sẵn | Chỉ mã hóa base64 nếu không cấu hình thêm; không xoay vòng |
| B. **OpenBao (nhánh mở của Vault) hoặc HashiCorp Vault, đồng bộ qua External Secrets Operator** | Xoay vòng, kiểm toán truy cập, bí mật động cho CSDL | Thêm thành phần quan trọng phải HA |

## Quyết định

Chọn **phương án B**, mặc định OpenBao vì giấy phép MPL 2.0; tỉnh đã có Vault thì dùng Vault. Mọi trường bí mật trong CSDL của Datahub có kiểu T-SECRET-REF (chỉ lưu đường dẫn tới kho bí mật). Khóa ký callback thanh toán và khóa ký nhật ký dùng engine transit, không rời kho. Quét bí mật (gitleaks) chạy trong CI và chặn merge.

## Hệ quả

Tích cực: đạt KPI-09. Tiêu cực: kho bí mật trở thành phụ thuộc khởi động của mọi DU; phải có quy trình mở niêm phong (unseal) tự động an toàn, mô tả ở D03-09.

## Truy vết

REQ-14, BO-04, KPI-09; LGC-NFR-007, LGC-NGSP-008. Tương ứng ADR-012 của repo.
