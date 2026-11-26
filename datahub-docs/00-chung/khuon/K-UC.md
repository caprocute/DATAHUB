---
ma_tai_lieu: D02-04-PH{nn}
ten: Đặc tả use case phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-{nn}
---

# D02-04-PH{nn} · Đặc tả use case {Tên}

## 1. Giới thiệu  [BB]
Mục đích và phạm vi, người đọc, thuật ngữ (dẫn FRS §1.4), tài liệu tham chiếu.
## 2. Quy ước đọc đặc tả
Cách đánh số luồng chính (1, 2…), thay thế (A1…), ngoại lệ (E1…).
## 3. Tác nhân  [BB]
Tác nhân chính (`ROLE-*`), tác nhân phụ (HTTT, PH khác, dịch vụ ngoài).
## 4. Sơ đồ use case tổng  [BB]
Mermaid `flowchart LR` tác nhân → UC có `caption`, kèm thuyết minh; quá 15 UC thì chia nhiều hình theo nhóm để đọc được trên A4.
## 5. Bảng tổng hợp use case và truy vết  [BB]
`UC-{nn}-nn | Tên | Tác nhân chính | Mức | FR` ; `UC | UI | API` ; `UC | REQ | BP | LGC`.
## 6. Đặc tả chi tiết use case  [BB]
Mỗi UC một mục `### 6.x. UC-{nn}-nn · {Tên}` gồm một khối `::: dac-ta` 15 mục đúng thứ tự: Mục tiêu · Tác nhân chính · Tác nhân phụ · Mức ưu tiên · FR hiện thực · Truy vết (REQ, quy trình, LGC) · Tiền điều kiện · Kích hoạt · Đảm bảo tối thiểu · Đảm bảo thành công · Luồng chính · Luồng thay thế · Luồng ngoại lệ (mã ERR kèm câu thông báo lấy từ FRS §9.2) · Quy tắc áp dụng · Màn hình, API. Trình bày theo K-TRINH-BAY; mẫu: D02-04-PH05 bản 0.2.
## 7. Luồng phụ dùng chung
## 8. Tổng hợp mã mới và đối chiếu
## 9. Câu hỏi mở  [BB]
## Lịch sử phiên bản

---

### Ví dụ ngắn (rút từ D02-04-PH07, UC-07-03)

```markdown
### 6.3. UC-07-03 · Nhập bản ghi từ tệp Excel/CSV

| Mục | Nội dung |
|---|---|
| Mục tiêu | Cán bộ đưa lượng lớn bản ghi từ tệp vào bản nháp an toàn, sửa lỗi theo dòng |
| Tác nhân chính | ROLE-DATA_STEWARD |
| Tác nhân phụ | Kho đối tượng, dịch vụ quét mã độc (DD-12), dịch vụ thông báo (FR-00-060) |
| Mức ưu tiên | M |
| FR hiện thực | FR-07-020, FR-07-021, FR-07-025 |
| Tiền điều kiện | Có `PERM-07-update`; danh mục `LOCAL` hoặc `HYBRID`, không `RETIRED` |
| Điều kiện kích hoạt | Chọn "Nhập từ tệp" trên UI-07-02 |
| Đảm bảo tối thiểu | Bản nháp không đổi nếu tác vụ thất bại (BR-07-015) |
| Đảm bảo thành công | `import_job.status = COMMITTED` |

**Luồng chính**
1. Người dùng chọn "Tải tệp mẫu". Hệ thống gọi API-07-032 …
5. Hệ thống lưu tệp, tạo `import_job` (`UPLOADED`) và trả 202 kèm `jobId`.

**Luồng ngoại lệ**
- **E2. Tệp nhiễm mã độc (bước 6).** Tác vụ sang `FAILED`, xóa tệp, ghi sự kiện an ninh.
```

### Tự soát
- [ ] Mỗi FR mức M thuộc ít nhất một UC; mỗi UC có FR, UI, API.
- [ ] Mỗi bước kiểm chứng được, có ví dụ dữ liệu giả lập rõ ràng (tenant `T68`).
- [ ] Luồng ngoại lệ dẫn mã `ERR-{nn}-nnn` có thật.
