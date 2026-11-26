---
ma_tai_lieu: D03-03-PH{nn}
ten: Thiết kế cơ sở dữ liệu phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, DBA, hội đồng thẩm định
phan_he: PH-{nn}
---

# D03-03-PH{nn} · Thiết kế CSDL {Tên}

## Tóm tắt cho hội đồng thẩm định  [BB]
## 1. Chiến lược lưu trữ  [BB]
Schema `ph{nn}_{tên}`, cụm PostgreSQL, vai trò `*_owner`, `*_app`, `*_migrator`, `*_readonly`, RLS theo `tenant_id`.
## 2. Sơ đồ thực thể – quan hệ  [BB]
Mermaid `erDiagram` theo schema, kèm thuyết minh.
## 3. Đặc tả bảng  [BB]
Mỗi bảng: cột, kiểu chuẩn (`T-*`), ràng buộc, khóa, index, partition, retention. Nên sinh bảng từ DDL bằng script (như `csdl/ph04/tools/gen_tables_md.py`).
## 4. DDL và changelog Liquibase  [BB]
Tệp DDL tại `03-thiet-ke/csdl/ph{nn}/ddl/`, đã chạy thử trên PostgreSQL sạch.
## 5. Dữ liệu khởi tạo  [BB]
## 6. Kho lưu trữ ngoài PostgreSQL  [BB]
Topic Kafka, khóa Valkey, kho đối tượng (Ceph RGW), ClickHouse nếu có.
## 7. Sao lưu, khôi phục, mã hóa và lưu giữ  [BB]
## 8. Ánh xạ CSDL hệ cũ sang thiết kế mới  [BB]
Bảng/cột cũ → bảng/cột mới, chuyển đổi kiểu (ví dụ `int(10)` → `T-MONEY`); đầu vào cho D06-01.
## 9. Câu hỏi mở  [BB]
## Lịch sử phiên bản

---

### Ví dụ ngắn (một bảng)

```markdown
#### `catalog_item` — bản ghi danh mục (minh họa)

| Cột | Kiểu | Null | Mặc định | Ràng buộc, ghi chú |
|---|---|---|---|---|
| `id` | `uuid` | Không | | PK, UUID v7 |
| `tenant_id` | `varchar(16)` | Không | | RLS; FK kèm `tenant_id` |
| `code` | `varchar(64)` | Không | | UNIQUE (`tenant_id`, `catalog_version_id`, `code`) |
| `attributes` | `jsonb` | Không | `'{}'` | JSON Schema theo lược đồ phiên bản (ADR-050) |
| `created_at` … `version` | | | | Cột ngữ cảnh D00-01 §5.1 |

Index: `ix_catalog_item_parent (tenant_id, parent_id)`. Retention: theo phiên bản, không xóa cứng.
```

### Tự soát
- [ ] Mọi bảng nghiệp vụ có cột ngữ cảnh và `FORCE ROW LEVEL SECURITY`.
- [ ] DDL chạy thử được; kiểm tra tenant A không đọc được dữ liệu tenant B.
- [ ] Có ánh xạ hệ cũ cho mọi bảng hệ cũ thuộc phân hệ.
