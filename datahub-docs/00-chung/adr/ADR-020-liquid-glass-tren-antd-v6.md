---
ma_tai_lieu: ADR-020
ten: Phong cách Liquid Glass trên Ant Design v6 làm ngôn ngữ thị giác của giao diện
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm giao diện, Nhà thiết kế, Hội đồng thẩm định
nguoi_lap: Luồng giao diện
---

# ADR-020 · Phong cách Liquid Glass trên Ant Design v6 làm ngôn ngữ thị giác của giao diện

## Bối cảnh

Datahub có một ứng dụng quản trị duy nhất (`dh-console`) phục vụ hai mươi phân hệ và một cổng nhà phát triển (`dh-portal`). Màn hình chủ yếu là bảng dữ liệu dày, biểu mẫu nhiều trường, sơ đồ thiết kế luồng và bảng điều khiển giám sát trực ca. Người dùng gồm cán bộ kỹ thuật dùng hằng ngày, cán bộ nghiệp vụ dùng hằng tuần và lãnh đạo dùng hằng tháng (D02-02 §2.1). Ràng buộc RB-03 của SRS đã chốt React và Ant Design v6.

ADR-016 của repo gốc chọn Ant Design v6 và tinh chỉnh token theo phong cách shadcn (thang xám zinc, viền mảnh, bóng rất nhẹ). Chủ đầu tư đã yêu cầu đổi sang phong cách **Liquid Glass của Apple** (quyết định Q8 ngày 21/11/2026), với điều kiện glass chỉ dùng cho lớp điều hướng và lớp nổi, còn nội dung dày dùng nền đặc để đạt WCAG 2.2 AA. Quyết định cần trả lời ba câu hỏi: giữ hay đổi bộ thành phần nền, hiện thực vật liệu kính bằng cách nào, và làm thế nào để thẩm mỹ không phá vỡ khả năng truy cập và hiệu năng trên máy văn phòng.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Giữ ADR-016: antd v6 + phong cách shadcn | Đã có mockup, chi phí thấp nhất | Không đáp ứng yêu cầu Q8 của chủ đầu tư |
| B. Liquid Glass phủ toàn bộ: mọi bề mặt kể cả bảng, thẻ, biểu mẫu đều là kính | Gần ảnh minh họa của Apple nhất | Chữ dày trên nền thay đổi không đạt 4,5:1 ổn định; nhiều lớp `backdrop-filter` làm cuộn bảng giật trên máy yếu; mất phân biệt khung và nội dung |
| C. **Liquid Glass phân lớp trên antd v6**: kính cho lớp chức năng (topbar, sidebar, khung Modal/Drawer, popover, dropdown), nền đặc cho lớp nội dung; vật liệu đặt qua token và `classNames` ngữ nghĩa của antd v6; có chế độ Giảm/Tắt và tự hạ cấp | Đúng tinh thần Apple (kính thuộc về lớp chức năng), giữ được bộ thành phần quản trị mạnh nhất của React, kiểm soát được tương phản và hiệu năng | Phải tự viết lớp vật liệu và cơ chế hạ cấp; một vài hình khối thành phần vẫn mang dáng antd |
| D. Đổi sang bộ thành phần khác có sẵn phong cách kính (tự dựng trên Radix hoặc thư viện cộng đồng) | Tự do thẩm mỹ | Thiếu Table cấp quản trị, Tree, Transfer, DatePicker tiếng Việt; trái RB-03; chi phí lớn |

## Quyết định

Chọn **phương án C**. Cụ thể:

1. Bộ thành phần nền vẫn là **Ant Design v6** (cố định phiên bản 6.x trong `@datahub/ui`, đã kiểm tra trên 6.7.1), chạy chế độ CSS variables, `hashed: false`.
2. Ngôn ngữ thị giác là **Liquid Glass phân lớp** với bốn vật liệu `glass-chrome`, `glass-chrome-scrolled`, `glass-modal`, `glass-overlay` (D03-05-01, D03-05-02 §5). Độ đục của từng vật liệu được chọn bằng phép tính tương phản trong trường hợp xấu nhất.
3. Bảng, biểu mẫu, log, mô tả chi tiết, biểu đồ, nút trên canvas thiết kế luôn dùng nền đặc. Tooltip và Toast dùng nền đảo đặc.
4. Có ba chế độ kính `full`, `lite`, `off`; mặc định "Tự động" phân giải theo tín hiệu truy cập của hệ điều hành và hạng hiệu năng máy, kể cả phát hiện kết xuất phần mềm trên máy trạm ảo.
5. Mọi tùy biến đi theo thứ tự: token toàn cục, token thành phần, `classNames`/`styles` ngữ nghĩa, rồi mới đến CSS của `@datahub/ui` chỉ tham chiếu biến. Không ghi đè lớp nội bộ `.ant-*`.
6. Tắt hiệu ứng gợn sóng (`wave`) của antd; phản hồi nhấn kiểu Liquid Glass (sáng bề mặt, thu nhỏ 2%).
7. Màu chủ đạo `#0A66D8`, sẫm hơn màu hệ thống của Apple để chữ trắng đạt 5,38:1.

## Hệ quả

Tích cực: giao diện hiện đại, phân biệt rõ khung ứng dụng và nội dung; giữ nguyên năng lực bảng, cây, biểu mẫu của antd; tương phản được chứng minh bằng tính toán và kiểm tra tự động trong CI; người dùng trên máy yếu không phải tự tắt hiệu ứng.

Tiêu cực: phải viết và bảo trì `CMP-GlassSurface`, cơ chế phân giải chế độ kính và bộ kiểm thử TS-00-UI-01…06; `backdrop-filter` vẫn tốn GPU nên phải giữ trần bốn lớp kính cùng lúc; trình duyệt chưa hỗ trợ `prefers-reduced-transparency` phải dựa vào công tắc thủ công; mockup cũ trong `mockup/` theo phong cách shadcn cần làm lại trước khi dùng làm tham chiếu.

Rủi ro liên quan RSK-A05 (SAD) được giảm bằng cơ chế hạ cấp ở D03-05-01 §7.

## Trạng thái

Đề xuất. Thay thế ADR-016 của repo gốc (`docs/05-adr`).

## Truy vết

RB-03, Q8; NFR-00-005, NFR-00-040…045; RSK-A05; D03-05, D03-05-01, D03-05-02. Tương ứng và thay thế ADR-016 của repo.
