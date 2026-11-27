---
ma_tai_lieu: ADR-072
ten: Cấp phát topic, ACL và hạn mức Kafka bằng tài nguyên Strimzi trong kho GitOps của tenant
phien_ban: 0.2
ngay: 2026-11-27
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-integration, đội vận hành nền tảng, PH-10, PH-20
---

# ADR-072 · Cấp phát topic, ACL qua GitOps

## Bối cảnh

PH-10 phải tạo topic, ACL theo tiền tố tenant và hạn mức cho principal khi duyệt topic, publication, subscription (D03-09 §6.4, D03-10 §4). D03-09 đã ghi cấu hình topic và ACL là manifest Strimzi lưu trong Git và không sao lưu nội dung topic. ADR-068 đã có kho cấu hình theo tenant `dh-config-{tenant}`. Cần chọn đường cấp phát an toàn, có truy vết và khôi phục được.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. `dh-integration` gọi Kafka Admin API trực tiếp | Nhanh (giây) | `dh-integration` cần quyền quản trị cụm; cấu hình không nằm trong Git, khó khôi phục, dễ lệch giữa site |
| B. **`dh-integration` sinh `KafkaTopic`, `KafkaUser` vào `dh-config-{tenant}`; Argo CD đồng bộ vào namespace `dh-kafka`; Strimzi Topic Operator và User Operator áp dụng; Kyverno chặn tài nguyên có tên không mang tiền tố tenant của kho** | Git là nguồn sự thật, khôi phục và DR bằng đồng bộ lại; `dh-integration` không có quyền quản trị cụm; dùng chung mô hình với PH-05 CDC (ADR-059) | Chậm hơn (khoảng 1–3 phút); cần bộ đối soát theo dõi trạng thái `Ready` |
| C. Strimzi CR áp trực tiếp qua Kubernetes API, không qua Git | Nhanh hơn B | Mất lợi ích GitOps, trái ADR-009 |

## Quyết định

Chọn **phương án B**. `dh-integration` chỉ có quyền ghi Git và đọc trạng thái CR; ngoại lệ duy nhất là Admin API để khởi tạo, đặt lại vị trí và xóa nhóm tiêu thụ (không là manifest). Hạn mức tenant được chia thành `quotas` của từng `KafkaUser` vì Kafka chỉ hỗ trợ hạn mức theo principal. Principal nội bộ của tenant và ACL tiền tố được tạo khi khởi tạo tenant (PH-20). Lệch giữa cụm và Git được báo, không sửa tay.

Cơ chế này áp cho mọi topic của tenant, kể cả họ topic do DU nguồn phát vào các phân hệ khác: `{tenant}.obs.*` của PH-13 (kiểm toán, cảnh báo, siêu dữ liệu lượt gọi), `{tenant}.kpi.*` của PH-16 và `{tenant}.ops.*` của PH-18. Khi khởi tạo tenant, PH-20 và PH-10 cấp ACL tiền tố cho DU nguồn ghi vào `obs.audit.recorded` và cho APISIX ghi vào `obs.access.logged`. Số phân vùng và thời hạn giữ của từng topic do tập API của phân hệ phát khai báo (ví dụ PH-13 đề xuất `audit.recorded` 7 ngày, 6 phân vùng khóa `id`; `access.logged` 3 ngày, 6 phân vùng khóa `route`; các sự kiện an ninh và đứt chuỗi 30 ngày), PH-10 đăng ký chúng theo FR-10-067.

## Hệ quả

- Tích cực: mọi thay đổi cụm có commit, có người duyệt trong PH-10; site DR dựng lại topic và ACL từ cùng kho; kiểm thử rò rỉ dựa trên chính sách Kyverno.
- Tiêu cực: thời gian cấp phát tính bằng phút (NFR-10-008), PH-05 phải chấp nhận trả lời `202` rồi theo dõi; phụ thuộc Argo CD khi cấp phát.

## Truy vết

FR-10-009, 010, 031, 037, 062, 064, 066, 067; FR-13-006, 010; BR-10-029, 036; NFR-10-008; ADR-009, ADR-059, ADR-068.
