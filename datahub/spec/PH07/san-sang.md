# PH-07 · Báo cáo kiểm sẵn sàng trước khi viết mã

> Bước "kiểm sẵn sàng" của K-GOI-DAC-TA §4.6: đối chiếu chéo FRS ↔ OpenAPI ↔ DDL ↔ TC
> ↔ D02-08 cho các tính năng sắp làm, ghi mâu thuẫn và quyết định tạm. Mỗi quyết định
> SS-07-nn có hiệu lực cho tới đợt đồng bộ cuối, khi người duyệt chốt và chép về tài
> liệu nguồn. Tác nhân viết mã làm theo cột "Quyết định", không tự chọn cách khác.
> Ngày kiểm: 26/11/2026, main `82ad789`. Phạm vi: toàn bộ OpenAPI (máy) + F-07-010 (đọc tay).

## 1. Kết quả kiểm bằng máy

| Kiểm | Kết quả trên nguồn | Sau vá |
|---|---|---|
| YAML OpenAPI đọc được (Redocly) | **Hỏng**: khóa trùng `retroactiveReason` (dòng 4086) | Đạt |
| Redocly `struct` | **5 lỗi**: mô tả dạng flow `{ description: a, b }` chứa dấu phẩy không đặt trong ngoặc kép, bị đọc thành khóa lạ | 0 lỗi |
| Redocly cảnh báo | 16 (ví dụ không khớp lược đồ 6, `required` không có trong `properties` 6, …) | 15 (giữ, ghi nhận) |
| DDL `ph07_rdm.sql` + 3 seed trên PostgreSQL 18.7 | Chạy được, 25 bảng | — |
| Kiểm RLS `catalog_group` (`ddl-kiem/10-*.sql`) | Đạt, kèm phát hiện SS-07-07 | — |
| Gherkin nguồn `ts-07-02.feature` | Phân tích được nhưng **không chạy được**: bước là văn xuôi ("Biết như chung.") | Viết lại `gherkin/F-07-010.feature` |

## 2. Quyết định

| Mã | Mâu thuẫn | Nguồn A | Nguồn B | Quyết định | Áp ở |
|---|---|---|---|---|---|
| SS-07-01 | (Đã sửa ở nguồn, PR #37) Mô tả flow có dấu phẩy làm hỏng cấu trúc (5 chỗ) | OpenAPI | Redocly | Đặt mô tả trong ngoặc kép | `va-openapi.yaml` |
| SS-07-02 | (Đã sửa ở nguồn, PR #37) Khóa trùng `PublishRequest.retroactiveReason` | OpenAPI dòng 4081 | dòng 4086 | Giữ bản đầy đủ (`minLength: 10`, có mô tả) | `va-openapi.yaml` |
| SS-07-03 | Quyền tạo/sửa/xóa nhóm | FRS, D02-08: `PERM-07-create` / `update` | OpenAPI: `PERM-07-configure` (đề xuất, chưa có ở D02-08) | Theo D02-08: POST cần `PERM-07-create`; PATCH, DELETE cần `PERM-07-update`; thêm điều kiện vai trò TA hoặc PA (DS bị từ chối dù có quyền) | `va-openapi.yaml`, mã |
| SS-07-04 | Đổi nhóm cha tạo vòng | FRS, TC-07-020: 409 ERR-07-039 | OpenAPI PATCH: ERR-07-010 (422) | 409 ERR-07-039, `errors[].code = CYCLE`; vượt độ sâu: ERR-07-039 `DEPTH`; trùng mã: ERR-07-039 `UNIQUE` | `va-openapi.yaml`, Gherkin |
| SS-07-05 | Xóa nhóm | FRS hậu điều kiện: "xóa mềm" | DDL: không có `deleted_at` | Xóa hẳn. Chặn xóa khi còn BẤT KỲ dòng `catalog` tham chiếu (kể cả `RETIRED` và đã xóa mềm, vì khóa ngoại); `detail` nêu số danh mục chưa xóa mềm | `va-openapi.yaml`, mã |
| SS-07-06 | Lỗi kiểm tra trường khi tạo nhóm | OpenAPI POST: chỉ 400 | Bảng lỗi: ERR-07-009 là 422 | 422 ERR-07-009 kèm `errors[]`; thân JSON hỏng cũng 422 ERR-07-009 (`errors[].code = TYPE`) | `va-openapi.yaml`, mã |
| SS-07-07 | "Quên đặt biến phiên thì lỗi" | DDL chú thích dòng 163, D03-10 | Chạy thật: chỉ đúng với kết nối mới; kết nối đã dùng có `app.tenant_id = ''` và vẫn thấy dòng `COMMON` | Không dựa vào lỗi CSDL. Ứng dụng luôn đặt tenant đầu giao dịch; kiểm thử rò rỉ chéo tenant bắt buộc (CC-TEST-03). Đề nghị sửa chú thích DDL ở đợt đồng bộ | `ddl-kiem/10-*.sql`, mã |
| SS-07-08 | Kiểm toán ghi thế nào | SDD §4.16: `AuditRecorder` của thư viện chung → outbox → PH-13 | Thư viện chung chưa có; outbox CHECK `event_type ~ vn.datahub.rdm.x.y.vN` | Lát cắt mẫu tự có `AuditRecorder` trong `shared` của `dh-data`, ghi outbox `event_type = vn.datahub.rdm.audit.recorded.v1`, topic `{tenant thường}.rdm.audit.recorded.v1`, `aggregate_type = catalog_group`, payload: `action` (`RDM_GROUP_CREATE/UPDATE/DELETE`), `actor`, `objectRef`, `before`, `after` (chỉ trường đổi), `ip`, `traceId`, `at`. Ghi PLATFORM vào COMMON thì outbox `tenant_id = COMMON`. Đề nghị đưa vào `vn.datahub.common.audit` khi có thư viện chung | mã |
| SS-07-09 | Nguồn quyền | ADR-006: Keycloak + OPA | Chưa có realm, chưa có chính sách OPA cho PH-07 | Lát cắt mẫu đọc claim `perms` (mảng `PERM-*`) và `roles` (mảng `ROLE-*`) trong JWT đã xác minh chữ ký (RS256, khóa công khai cấu hình). Nối OPA ở lát cắt sau | mã |
| SS-07-10 | Cây nhóm của tenant tỉnh | Ví dụ OpenAPI: nút gốc của tenant và `COMMON` lẫn nhau | DDL: nhóm con phải cùng tenant với cha | Trả rừng: mọi nhóm gốc (tenant và `COMMON`) ở cấp 1, sắp theo `sortOrder` rồi `code`; con sắp như vậy. `catalogCount` = số `catalog` chưa xóa mềm thấy được (RLS) có `group_id` = nhóm, không cộng nhóm con | mã |
| SS-07-11 | Tiền điều kiện TC-07-019 | TC: "T68 có nhóm HANH_CHINH" | Seed: `HANH_CHINH` là nhóm COMMON | Gherkin tạo nhóm `HANH_CHINH` riêng của T68 trong bối cảnh (mã trùng giữa tenant và COMMON là hợp lệ vì UNIQUE theo `(tenant_id, code)`) | Gherkin |
| SS-07-12 | `createdBy` | OpenAPI: chuỗi, có thể `client:{id}` | DDL: `uuid NOT NULL` | Lát cắt chỉ cho người dùng (claim `sub` là UUID); HTTT không ghi nhóm. Trả `createdBy` = UUID dạng chuỗi | mã |
| SS-07-13 | Trường lạ trong PATCH (ví dụ `code`) | OpenAPI: không có `additionalProperties: false` | D04-01 CC-SEC-21 | 422 ERR-07-009 `errors[].code = UNKNOWN_FIELD` | mã, Gherkin |

## 3. Kịch bản bổ sung (chờ chép về D05-02-PH07)

`gherkin/F-07-010.feature` thêm 10 kịch bản gắn `@bo-sung`: độ sâu, rò rỉ chéo tenant, COMMON chỉ đọc, thiếu quyền, không token, ETag lệch, thiếu `If-Match`, sửa thành công và không đổi mã, `Idempotency-Key`, PA tạo nhóm COMMON. Đề nghị cấp mã TC-07 mới ở đợt đồng bộ.

## 4. Câu hỏi mở cho người duyệt (không chặn lát cắt mẫu)

| Mã | Câu hỏi |
|---|---|
| SS-07-Q1 | ERR-07-039 gộp ba nghĩa (trùng, vòng, độ sâu) khác cách các phân hệ khác dùng ERR riêng; có tách không? |
| SS-07-Q2 | Có cần `PERM-07-configure` riêng cho cấu hình (nhóm, tham số) như OpenAPI đề xuất không? |
| SS-07-Q3 | Nhóm có cần xóa mềm để giữ lịch sử phân loại không (FRS ghi xóa mềm)? |
