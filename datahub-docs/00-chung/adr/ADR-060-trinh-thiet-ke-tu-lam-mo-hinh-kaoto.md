---
ma_tai_lieu: ADR-060
ten: Trình thiết kế luồng tự làm lại mô hình Kaoto bằng React 19 và XYFlow, dùng catalog Kaoto đã vendor
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, trưởng nhóm giao diện, Hội đồng thẩm định
---

# ADR-060 · Trình thiết kế luồng tự làm lại mô hình Kaoto bằng React 19 và XYFlow

## Bối cảnh

PH-04 cần trình thiết kế luồng Camel trực quan, đồng bộ hai chiều với YAML DSL (ADR-010), theo phong cách Liquid Glass trên antd v6 (Q8) và tích hợp chặt với kết nối PH-05, ánh xạ mã PH-07, chính sách thành phần của tenant. Kaoto là trình thiết kế mã nguồn mở chính thức của cộng đồng Camel, viết bằng React và PatternFly. Repo hiện đã tự làm lại mô hình hoạt động của Kaoto trong `apps/console/src/flows` (cây tài nguyên, bảng thành phần, Kamelet, Pipe, Test, bean, DataMapper) bằng React 19, antd 6 và `@xyflow/react` 12, với catalog sinh từ `@kaoto/camel-catalog` (kế hoạch IP-07 của repo).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Nhúng nguyên Kaoto (iframe hoặc gói `@kaoto/kaoto`) | Ít công; theo kịp Camel | PatternFly xung đột design system; khó chèn chọn kết nối PH-05, chính sách thành phần, duyệt bốn mắt; khó đạt WCAG 2.2 AA theo chuẩn riêng |
| B. **Tự làm lại mô hình Kaoto, dùng catalog Kaoto đã vendor** | Giao diện thống nhất; kiểm soát toàn bộ quy tắc nghiệp vụ và ATTT; tận dụng phần đã làm ở repo | Phải tự duy trì phần biểu diễn sơ đồ, quay vòng YAML |
| C. Trình thiết kế tự làm từ đầu, không dùng catalog Kaoto | Không phụ thuộc | Phải tự sinh lược đồ cho hàng trăm thành phần |

## Quyết định

Chọn **phương án B**. Dữ liệu catalog (chỉ mục và lược đồ JSON từng thành phần) vendor vào mã nguồn, ghi rõ nguồn, phiên bản và giấy phép Apache-2.0 trên màn danh mục thành phần. Phần biểu diễn sơ đồ dùng `@xyflow/react`, sắp xếp tự động bằng dagre. Bộ kiểm thử quay vòng YAML (BR-04-006) là điều kiện bắt buộc của CI.

## Hệ quả

Tích cực: một design system cho toàn console; quy tắc ATTT nằm ngay trong trình thiết kế. Tiêu cực: phải theo dõi thay đổi cú pháp YAML DSL mỗi khi nâng Camel; cần bộ kiểm thử quay vòng lớn.

## Truy vết

REQ-04; FR-04-010…027; LGC-TOOL-*. Tương ứng ADR-015, ADR-017 và IP-07 của repo.
