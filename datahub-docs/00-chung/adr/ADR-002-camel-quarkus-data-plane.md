---
ma_tai_lieu: ADR-002
ten: Camel Quarkus native cho lõi tích hợp, bộ điều hợp và kết nối quốc gia
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-002 · Camel Quarkus native cho lõi tích hợp, bộ điều hợp và kết nối quốc gia

## Bối cảnh

PH-04 (lõi tích hợp), PH-05 (bộ điều hợp) và PH-14 (kết nối quốc gia) là data plane: chạy các luồng do người dùng thiết kế, cần khởi động nhanh, ít bộ nhớ, mở rộng theo tải. Hệ cũ dùng Apache Camel trên Spring XML, đóng gói theo agent gắn máy chủ. Chủ đầu tư đã quyết định giữ Camel Quarkus cho PH-04 (Q9).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Camel trên Spring Boot, cùng nền backend | Một nền công nghệ | Khởi động chậm, bộ nhớ lớn khi chạy nhiều luồng; khó scale-to-zero |
| B. **Camel Quarkus biên dịch native (GraalVM / Mandrel)** | Khởi động dưới 0,1 giây, bộ nhớ thấp; hỗ trợ Camel YAML DSL, Kamelet | Biên dịch native lâu; một số component không hỗ trợ native |
| C. Nền tích hợp thương mại | Đầy đủ công cụ | Phụ thuộc nhà cung cấp, chi phí bản quyền |

## Quyết định

Chọn **phương án B** cho PH-04, PH-05, PH-14. Luồng được viết bằng Camel YAML DSL (ADR-010). Chỉ những component nằm trong danh mục được duyệt và có hỗ trợ native mới được dùng; component không hỗ trợ native chạy ở chế độ JVM trong một nhóm triển khai riêng. Data plane không truy cập CSDL của control plane; cấu hình được đẩy xuống qua GitOps.

## Hệ quả

Tích cực: chi phí tài nguyên thấp khi có hàng trăm luồng; tách biệt data plane khỏi control plane giúp sự cố ở giao diện quản trị không ảnh hưởng luồng đang chạy. Tiêu cực: hai nền công nghệ Java (Spring và Quarkus) trong một sản phẩm; CI phải có bước biên dịch native và kiểm thử native.

## Truy vết

REQ-04, REQ-05, REQ-14; LGC-BUS-*, LGC-NGSP-*. Tương ứng ADR-001, ADR-002 của repo.
