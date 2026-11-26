---
ma_tai_lieu: D03-02-PH{nn}
ten: Thiết kế chi tiết phần mềm phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Kỹ sư, kiến trúc sư, hội đồng thẩm định
phan_he: PH-{nn}
---

# D03-02-PH{nn} · Thiết kế chi tiết {Tên}

## Tóm tắt cho hội đồng thẩm định  [BB]
## 1. Phạm vi và cách đọc
## 2. Vị trí trong kiến trúc  [BB]
DU, vùng mạng `Z*`, phụ thuộc PH khác; sơ đồ C4 mức thành phần.
## 3. Cấu trúc mã nguồn  [BB]
Gói `vn.datahub.{du}.{module}.{api|internal|events}`, quy tắc phụ thuộc (Modulith, ArchUnit).
## 4. Thiết kế chi tiết từng thành phần  [BB]
Class diagram domain, aggregate và invariant.
## 5. Biểu đồ tuần tự  [BB]
Một sequence cho mỗi FR phức tạp (không dùng `;` trong thông điệp Mermaid).
## 6. Đa tenant trong mã nguồn
`tenant_id`, RLS, ngữ cảnh tenant theo D03-10.
## 7. Bảo mật
Tham chiếu `SEC-*` đã có (không tạo mới), kiểm tra quyền ở máy chủ.
## 8. Máy trạng thái, xử lý lỗi, thử lại và tính nhất quán  [BB]
Outbox, saga, idempotency, retry, timeout, circuit breaker; mã ERR.
## 9. Cấu hình và cờ tính năng theo tenant  [BB]
## 10. Quan sát  [BB]
Chỉ số, log, trace mà phân hệ phát ra (tên metric, nhãn).
## 11. Hiệu năng và vận hành  [BB]
## 12. Kiểm thử
## 13. Lộ trình hiện thực, rủi ro và câu hỏi mở  [BB]
## Lịch sử phiên bản

---

### Ví dụ ngắn (cấu trúc gói, theo D03-02-PH07 §3)

```text
vn.datahub.data.rdm
├── api/            # DTO, interface công khai cho PH khác (chỉ gói này được import từ ngoài)
├── internal/       # domain, service, repository; không lộ ra ngoài module
│   ├── catalog/    # aggregate Catalog, invariant: mã duy nhất trong tenant (BR-07-001)
│   └── importing/  # tác vụ nhập hai pha (ADR-056)
└── events/         # sự kiện EVT-07-*, phát qua outbox
```

### Tự soát
- [ ] Mỗi FR phức tạp (nhiều bước, giao dịch, tác vụ nền) có sequence.
- [ ] Mỗi máy trạng thái ở FRS có bảng chuyển trạng thái và chỗ kiểm tra ở máy chủ.
- [ ] Quyết định mới có ADR trong dải của nhóm (D00-04 §3.1).
