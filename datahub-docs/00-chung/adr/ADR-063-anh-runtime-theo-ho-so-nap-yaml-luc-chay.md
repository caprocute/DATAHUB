---
ma_tai_lieu: ADR-063
ten: Ảnh dh-runtime dựng theo hồ sơ thành phần, luồng YAML nạp lúc chạy từ kho cấu hình qua Argo CD
phien_ban: 0.1
ngay: 2026-11-25
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-runtime, vận hành
---

# ADR-063 · Ảnh runtime theo hồ sơ, nạp YAML lúc chạy

## Bối cảnh

Camel Quarkus native biên dịch trước toàn bộ thành phần; biên dịch native mất 5–15 phút mỗi ảnh. Một tỉnh có hàng trăm luồng thay đổi thường xuyên. Repo hiện chưa có cơ chế đưa luồng đã phát hành vào runtime (GAP-04-03).

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Biên dịch native riêng cho mỗi luồng | Cô lập tối đa | Hàng trăm ảnh; phát hành chậm; tốn tài nguyên CI |
| B. **Ảnh dùng chung theo hồ sơ thành phần; YAML nạp lúc chạy từ ConfigMap do Argo CD đồng bộ** | Phát hành trong vài phút; số ảnh ít; YAML DSL được thông dịch lúc chạy cả ở native | Mọi thành phần của hồ sơ có trong ảnh; cô lập theo namespace chứ không theo luồng |
| C. Camel K Operator | Có sẵn mô hình `Integration` | Thêm operator lớn; mô hình build riêng, không khớp quy trình ký ảnh của Datahub |

## Quyết định

Chọn **phương án B**. Hồ sơ `core-native`, `files-native`, `soap-jvm`, `legacy-jvm` (FR-04-075). Kho cấu hình `dh-flows-{tenant}` có thư mục theo môi trường; ApplicationSet sinh ConfigMap và tài nguyên `FlowDeployment` cho namespace `dh-runtime` hoặc `dh-rt-{tenant}`. `dh-runtime` có bộ điều khiển nhỏ theo dõi ConfigMap theo nhãn, nạp, nạp lại, gỡ route bằng `RoutesLoader` của Camel mà không khởi động lại pod, và phát nhịp tim kèm băm đã nạp.

## Hệ quả

Tích cực: phát hành nhanh, ít ảnh, ký ảnh một lần. Tiêu cực: lỗi nạp một luồng không được làm hỏng luồng khác (nạp riêng từng tệp, cô lập lỗi); cần kiểm soát tài nguyên khi một namespace chạy nhiều luồng (ngưỡng 50 luồng tách namespace ở D03-10).

## Truy vết

FR-04-042, 075; GAP-04-03; ADR-002, ADR-009.
