---
ma_tai_lieu: ADR-010
ten: Camel YAML DSL thay Camel XML làm định dạng luồng tích hợp
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm kỹ thuật, Hội đồng thẩm định
---

# ADR-010 · Camel YAML DSL thay Camel XML làm định dạng luồng tích hợp

## Bối cảnh

Hệ cũ sinh Camel XML từ công cụ kéo thả, kèm file pom. Datahub cần định dạng luồng dễ đọc khi so sánh phiên bản, ánh xạ được hai chiều với sơ đồ, và không cho phép người dùng tự thêm thư viện.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Giữ Camel XML | Di trú dễ | Khó đọc khi so sánh; công cụ hiện đại ưu tiên YAML |
| B. **Camel YAML DSL, thành phần qua Kamelet được duyệt** | Dễ so sánh, là định dạng của Kaoto và Camel JBang; Kamelet đóng gói cấu hình an toàn | Phải chuyển đổi luồng XML cũ |
| C. DSL riêng | Kiểm soát hoàn toàn | Tự gánh toàn bộ công cụ |

## Quyết định

Chọn **phương án B**. Trình thiết kế luồng ở PH-04 đọc và ghi YAML DSL, dùng mô hình cây tài nguyên Camel; ánh xạ dữ liệu sinh biểu thức JQ. Không cho nhập JAR hay sửa pom (LGC-TOOL-022, LGC-TOOL-027 loại bỏ). Công cụ di trú tự động chuyển XML cũ sang YAML, phần không chuyển được đánh dấu để kỹ sư xử lý (D06-01).

## Hệ quả

Tích cực: an toàn chuỗi cung ứng; xem khác biệt phiên bản dễ. Tiêu cực: cần công cụ chuyển đổi XML sang YAML và kiểm thử đối chiếu khi di trú.

## Truy vết

REQ-04; LGC-TOOL-*, LGC-BUS-033, LGC-BUS-034. Tương ứng ADR-015, ADR-021, ADR-022 của repo.
