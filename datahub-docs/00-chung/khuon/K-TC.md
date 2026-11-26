---
ma_tai_lieu: D05-02-PH{nn}
ten: Kịch bản và test case phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Kiểm thử viên, kỹ sư, chủ đầu tư (UAT)
phan_he: PH-{nn}
---

# D05-02-PH{nn} · Kịch bản và test case {Tên}

## Tóm tắt cho hội đồng thẩm định  [BB]
Số kịch bản, số ca theo loại, độ phủ FR mức M.
## 1. Phạm vi, chiến lược và tổ chức kiểm thử  [BB]
Theo D05-01; tenant kiểm thử `T90…T99` hoặc `T68`/`T01` cho ca liên tenant.
## 2. Dữ liệu kiểm thử  [BB]
Bộ dữ liệu có tên (ví dụ `F-HT`, `U-T68-VW`), giả lập rõ ràng.
## 3. Tổng quan kịch bản kiểm thử  [BB]
Bảng `TS-{nn}-nn | Mục tiêu | UC | Số ca`.
## 4. Kịch bản và test case chức năng  [BB]
Mỗi kịch bản `### TS-{nn}-nn`, mỗi ca `#### TC-{nn}-### · {tên} <!--k:khóa-->`.
## 5. Kịch bản kiểm thử phi chức năng  [BB]
## 6. Thủ tục kiểm thử thủ công
## 7. Nghiệm thu người dùng tương đương hệ cũ  [BB]
`UAT-nn` theo màn hệ cũ được giữ.
## 8. Ma trận truy vết  [BB]
FR → TC (dương, âm), `LGC` → TC, UAT; sinh bằng script `gen_matrix.py`.
## 9. Tự động hóa và tệp đi kèm  [BB]
`.xlsx` theo mẫu nghiệm thu, tệp Gherkin; công cụ tại `05-kiem-thu/test-case/ph{nn}/tools/` (chép từ `ph04/tools/`).
## Lịch sử phiên bản

Viết ca với `TC-{nn}-###` kèm khóa `<!--k:…-->`, rồi chạy `number_tcs.py` để cấp số liên tục; tham chiếu chéo bằng `[[tc:khóa]]`.

---

### Ví dụ ngắn (rút từ D05-02-PH04)

```markdown
#### TC-04-011 · Chi tiết luồng không tồn tại hoặc ở tenant khác <!--k:flow-404-->
- **Loại** Âm, Bảo mật · **Ưu tiên** P1 · **Tự động** API
- **Truy vết** FR-04-002 · API-04-012 · ERR-04-001
- **Tiền điều kiện / dữ liệu** U-T68-VW; F-T01 chỉ có ở T01.
- **Bước**
  1. Gọi `GET /flows/khong-co`.
  2. U-T01-IE tạo luồng `tc-chi-t01`; U-T68-VW gọi `GET /flows/tc-chi-t01`.
- **Mong đợi** Cả hai trả `404` ERR-04-001, thân giống nhau trừ `traceId`.
```

### Tự soát
- [ ] Mỗi FR mức M có ít nhất một ca dương và một ca âm.
- [ ] Mỗi ca ghi loại, dữ liệu, FR, `LGC` (nếu có), khả năng tự động hóa.
- [ ] Có ca rò rỉ chéo tenant cho mọi API đọc.
