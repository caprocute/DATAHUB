---
ma_tai_lieu: ADR-022
ten: Lucide làm bộ biểu tượng ứng dụng
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Trưởng nhóm giao diện, Nhà thiết kế
nguoi_lap: Luồng giao diện
---

# ADR-022 · Lucide làm bộ biểu tượng ứng dụng

## Bối cảnh

Liquid Glass dùng biểu tượng nét mảnh, đầu nét tròn, cùng độ dày với chữ (SF Symbols). SF Symbols chỉ được cấp phép trên nền tảng Apple. Bộ biểu tượng mặc định của antd (`@ant-design/icons`) có hai phong cách viền và đặc, nét vuông và mảnh không đồng đều, cho cảm giác "giao diện Ant" mà ADR-020 muốn tránh. Ứng dụng cần vài trăm biểu tượng cho hành động, đối tượng nghiệp vụ (API, luồng, topic, danh mục, giao dịch) và nút EIP trên canvas.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. `@ant-design/icons` | Đồng bộ với biểu tượng nội bộ của antd | Phong cách lệch Liquid Glass |
| B. **Lucide (`lucide-react`)** | Hơn 1.500 biểu tượng nét tròn đồng nhất, độ dày nét chỉnh được, nhập từng biểu tượng (tree-shaking), giấy phép ISC | Biểu tượng nội bộ của antd (mũi tên của Select, nút đóng) vẫn là của antd |
| C. Phosphor | Nhiều trọng số | Gói lớn hơn, ít phổ biến trong hệ React quản trị |
| D. Tự vẽ | Khớp tuyệt đối | Chi phí lớn |

## Quyết định

Chọn **Lucide** cho mọi biểu tượng do ứng dụng đặt (nút, menu, trạng thái rỗng, nút canvas), độ dày nét mặc định 1,75 ở cỡ 16px và 20px, bọc trong `CMP-Icon` để cố định kích thước và `aria-hidden`. Biểu tượng nội bộ của antd được giữ, trừ các vị trí antd cho phép thay qua thuộc tính (ví dụ `suffixIcon`, `closeIcon`, `expandIcon`), khi đó `@datahub/ui` truyền biểu tượng Lucide tương ứng. Biểu tượng nghiệp vụ không có trong Lucide được vẽ thêm theo lưới 24px, nét 1,75, đầu nét tròn, lưu trong `@datahub/ui/icons`.

## Hệ quả

Tích cực: phong cách đồng nhất, gần SF Symbols; chỉ tải biểu tượng được dùng. Tiêu cực: một số biểu tượng nhỏ bên trong thành phần antd vẫn mang dáng antd; cần danh mục ánh xạ hành động sang biểu tượng (D03-05-03, `CMP-Icon`) để các phân hệ dùng thống nhất.

## Trạng thái

Đề xuất.

## Truy vết

ADR-020; NFR-00-045; D03-05-03 `CMP-Icon`.
