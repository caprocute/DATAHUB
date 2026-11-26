---
ma_tai_lieu: D03-06-PH{nn}
ten: Thiết kế giao diện màn hình phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
trang_thai: Dự thảo
nguoi_doc: Kỹ sư giao diện, kiểm thử viên, hội đồng thẩm định
phan_he: PH-{nn}
---

# D03-06-PH{nn} · Thiết kế giao diện màn hình {Tên}

Tập màn **không tự đặt** token, `CMP-*` hay `PTN-*`; dùng tên chuẩn ở D03-05 và D03-06-00. Thiếu thành phần thì ghi Phụ lục A.

## Tóm tắt cho hội đồng thẩm định  [BB]
## 1. Mục đích, phạm vi và tài liệu liên quan  [BB]
Bảng danh sách `UI-{nn}-nn | Tên | PTN | Mức chi tiết | FR`.
## 2. Nguyên tắc thiết kế áp dụng cho phân hệ
Bản đồ vật liệu (kính chỉ cho lớp điều hướng và lớp nổi, nội dung dày nền đặc), mật độ, ngôn ngữ.
## 3. Màn hệ cũ được giữ lại thành gì  [BB]
`LGC` màn cũ → `UI` mới, giữ hay thiết kế lại.
## 4. Điều hướng  [BB]
Sơ đồ điều hướng, bảng route (theo D03-06-00 §2.3, §2.4), menu theo quyền, breadcrumb, tiêu đề tab.
## 5. Quy ước hiển thị dùng chung  [BB]
Nhãn trạng thái, thông điệp `ERR-{nn}` sang câu hiển thị.
## 6. Trạng thái màn hình dùng chung  [BB]
Tham chiếu `ST-*` của D03-06-00 §4.2.
## 7… Đặc tả từng màn `UI-{nn}-nn`  [BB]
Mỗi màn có: **Mục đích**, **Đường dẫn**, **Mẫu**, **Quyền**, **API**; wireframe; bảng thành phần; bảng trường hoặc cột (nhãn, kiểu, bắt buộc, kiểm tra, ánh xạ API); hành động; trạng thái (rỗng, đang tải, lỗi, không có quyền); thông điệp; tương tác bàn phím; bản hi-fi.
## Mẫu truy cập, kiến trúc mã giao diện, luồng người dùng chính
## Ma trận màn hình theo vai trò  [BB]
## Kiểm thử giao diện và bản hi-fi  [BB]
## Phụ lục A. Đề nghị bổ sung cho D03-05 · Phụ lục B. Đề nghị bổ sung API
## Câu hỏi mở · Lịch sử phiên bản

> Màn designer, canvas hoặc màn phức tạp nhất của phân hệ viết ở mức "siêu chi tiết" như UI-04-04: lưới bố cục và kích thước, từng vùng đánh số, giải phẫu từng phần tử, mọi trạng thái, tương tác chuột và bàn phím, khả năng truy cập.

---

### Ví dụ ngắn (rút từ D03-06-PH04 §7, UI-04-01)

```markdown
## 7. UI-04-01 Danh sách luồng

**Mục đích.** Tìm luồng, xem tình trạng ở từng môi trường, mở chi tiết hoặc trình thiết kế. Thay LGC-BUS-001, LGC-TOOL-001.
**Đường dẫn.** `/tich-hop/luong`. **Mẫu.** PTN-01. **Quyền.** `PERM-04-read`. **API.** API-04-010.

### 7.2. Thành phần
| # | Thành phần | `CMP-*` | Nội dung, kiểm tra | Nguồn | Ghi chú |
|---|---|---|---|---|---|
| 1 | Tiêu đề trang | `CMP-PageHeader` | Cố định | — | |
| 2 | Nút "Tạo luồng" | `CMP-Button` primary + `CMP-DropdownMenu` | Luồng trống, Từ khuôn mẫu… | — | Hiện khi `PERM-04-create` |

### 7.4. Trạng thái màn
| Trạng thái | Hiển thị |
|---|---|
| Đang tải | Skeleton 8 dòng |
| Rỗng lần đầu | "Chưa có luồng tích hợp nào…" kèm nút "Tạo luồng" |
```

### Tự soát
- [ ] Mọi `UI` ở FRS §12 có mục đặc tả; mọi route khớp D03-06-00 §2.3.
- [ ] Mọi `CMP-*`, token dùng tên có thật (`kiem_tra_ma.py` báo `CMP` thiếu).
- [ ] Đủ bốn trạng thái rỗng, đang tải, lỗi, không có quyền cho mỗi màn.
