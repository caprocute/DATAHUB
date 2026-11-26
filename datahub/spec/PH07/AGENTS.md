# spec/PH07 · Chỉ dẫn riêng PH-07 cho tác nhân

Đọc sau `datahub/AGENTS.md`. Chỉ ghi điều khác thường của PH-07.

## Tệp trong gói

| Tệp | Vai trò | Ai sửa |
|---|---|---|
| `goi.yaml` | Bản kê: nguồn, vá, lát cắt, kiểm DDL | người viết đặc tả |
| `tom-tat.md` | Tóm tắt ≤ 300 dòng thay cho FRS/SDD/API | người viết đặc tả |
| `san-sang.md` | Mâu thuẫn và quyết định SS-07-nn (thắng nguồn) | người viết đặc tả, người duyệt chốt |
| `va-openapi.yaml` | Vá hợp đồng nguồn chờ đợt đồng bộ | người viết đặc tả |
| `features.json` | 53 tính năng, cờ `passes` | sinh bằng `tools/sinh_features.py`; `passes`, `danh_gia` do phiên đánh giá |
| `lat-cat/F-07-nnn.openapi.yaml` | Lát cắt hợp đồng của một tính năng (SINH, không sửa tay) | `tools/cat_lat_openapi.py` |
| `gherkin/F-07-nnn.feature` | Tiêu chí nghiệm thu chạy được | người viết đặc tả |
| `ddl-kiem/*.sql` | Kiểm DDL và RLS trên PostgreSQL thật | người viết đặc tả |
| `tien-do.md` | Nhật ký phiên viết mã | tác nhân viết |
| `hang-cho.md` | Câu hỏi cho người khi đặc tả sai hoặc thiếu | tác nhân viết, đánh giá |

## Điều khác thường của PH-07

- DDL dùng vai trò NOLOGIN `ph07_owner/app/readonly/worker`. Test tạo vai trò đăng nhập
  riêng (ví dụ `dh_data_app LOGIN IN ROLE ph07_app`), ứng dụng kết nối bằng vai trò đó.
  Chạy DDL bằng superuser qua `psql` (tệp có `\set`, khối `DO $$`): với Testcontainers
  chép tệp vào `/docker-entrypoint-initdb.d/` thay vì `withInitScript`.
- Seed `07-S01` tạo 9 nhóm COMMON (mã `HANH_CHINH`, `DAN_CU`, …, `KHAC`); test đừng giả
  định cây rỗng.
- `catalog` có nhiều cột NOT NULL: khi cần danh mục mẫu cho test, đọc `CREATE TABLE
  ph07_rdm.catalog` trong DDL và chèn bằng SQL trong giao dịch có tenant.
- Trigger `tg_touch` tự tăng `version` nếu ứng dụng chưa tăng; dùng `@Version` của JPA là đủ.
- `outbox.trace_id` bắt buộc 32 hex; `topic` phải bắt đầu bằng `lower(tenant_id)` của dòng.
- Màn hình nhóm danh mục là khung trái của UI-07-01 (PTN-08 "Cây + bảng"); đặc tả ở
  D03-06-PH07 §7 (thành phần dòng 3, hành động dòng 564–566, bàn phím §7 "tree" WAI-ARIA),
  ảnh tham chiếu `datahub-docs/03-thiet-ke/uiux/ph07/hifi/ui-07-01.png`. Bảng danh mục bên
  phải thuộc F-07-001, lát cắt này chỉ để khung chờ.
- Câu hiển thị lỗi: D03-06-PH07 §5.3; thông báo thành công §7.4 ("Đã thêm nhóm "{name}"."…).
