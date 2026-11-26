---
ma_tai_lieu: D02-03-PH{nn}
ten: Đặc tả yêu cầu chức năng phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-{nn}
---

# D02-03-PH{nn} · Đặc tả yêu cầu chức năng {Tên}

## Tóm tắt cho hội đồng thẩm định  [BB]
Mục tiêu, phạm vi, căn cứ pháp lý (`CMP-LAW-*`), số FR theo mức M/S/C, số chức năng hệ cũ được phủ.

## 1. Mục đích, phạm vi và người đọc  [BB]
Ranh giới làm và không làm; danh sách `LGC` được phủ.

## 2. Bối cảnh nghiệp vụ  [BB]
Vị trí trong kiến trúc (DU theo D00-04 §2), quy trình `BP-*` liên quan, hạn chế hệ cũ cần khắc phục.

## 3. Tác nhân, vai trò và quyền  [BB]
Bảng `ROLE-*` × `PERM-{nn}-*`. Quyền mới ghi vào "Đề nghị đồng bộ D02-08".

## 4. Khái niệm và mô hình nghiệp vụ  [BB]
Thực thể `EN-{nn}-..` ở mức logic, máy trạng thái (Mermaid `stateDiagram-v2` + thuyết minh).

## 5. Đặc tả chi tiết yêu cầu chức năng  [BB]
Mỗi FR một mục `#### FR-{nn}-nnn · {động từ + đối tượng}`, theo mẫu D00-01 §4.3.

## 6. Quy tắc nghiệp vụ  [BB]
Bảng `BR-{nn}-nnn | Quy tắc | FR áp dụng`.

## 7. Tham số và yêu cầu phi chức năng  [BB]
`NFR-{nn}-nnn` đo được (đơn vị, điều kiện đo, phân vị); tham số theo tenant.

## 8. Mã lỗi, sự kiện và danh mục API  [BB]
Bảng tóm tắt ERR, EVT, API (định nghĩa đầy đủ ở D03-04).

## 9. Truy vết  [BB]
`LGC` → FR (kết luận Giữ nguyên / Nâng cấp / Thay thế / Loại bỏ), FR → REQ.

## 10. Phụ thuộc, giả định và ràng buộc
## 11. Câu hỏi mở  [BB]
## 12. Danh sách màn hình ở mức chức năng  [BB]
Bảng `UI-{nn}-nn | Tên | Vai trò | Hành vi chính | FR`.
## 13. Tiêu chí chấp nhận cấp phân hệ  [BB]
## Lịch sử phiên bản

---

### Ví dụ ngắn (rút từ D02-03-PH07, FR-07-001)

```markdown
#### FR-07-001 · Liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng thái, phân loại

| Trường | Nội dung |
|---|---|
| Mức ưu tiên | M |
| Truy vết | REQ-07; LGC-DMDC-001 |
| Tác nhân, quyền | Mọi vai trò có `PERM-07-read`; HTTT với scope `rdm.read` |
| Tiền điều kiện | Người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004) |
| Đầu ra | `items[]`, `page`, `size`, `totalElements`, khối `facets` |
| Hậu điều kiện | Không thay đổi dữ liệu |
| Sự kiện phát ra | Không |
| Kiểm toán | Không (không có dữ liệu Nhạy cảm) |

| Tham số | Kiểu | Bắt buộc | Ràng buộc | Ví dụ |
|---|---|---|---|---|
| `q` | T-NAME | Không | Tìm không dấu trên mã và tên; 1…100 ký tự | `dan toc` |

Xử lý: 1. Kiểm tra tham số; sai miền trả `400`. 2. Truy vấn tenant hiện hành và `COMMON`…

| Điều kiện | Mã lỗi | HTTP | Hành vi |
|---|---|---|---|
| `size` > 200 | ERR-07-026 | 400 | Từ chối, gợi ý dùng phân trang |
```

### Tự soát
- [ ] Mỗi FR có đủ 12 trường của D00-01 §4.3, có `LGC` nếu thay chức năng cũ.
- [ ] Mỗi `LGC` của phân hệ có đúng một kết luận ở §9.
- [ ] Mã mới lấy số kế tiếp ở D00-04 §3.2; `kiem_tra_ma.py` sạch.
