---
ma_tai_lieu: D02-03-PH{nn}
ten: Đặc tả yêu cầu chức năng phân hệ PH-{nn} {Tên}
phien_ban: 0.1
ngay: yyyy-MM-dd
mo_ta: Một câu nói tài liệu đặc tả gì, dùng làm gì
tai_lieu_lien_quan: D02-02 SRS; D02-04-PH{nn}; D03-02-PH{nn}; D03-04-PH{nn}; D03-06-PH{nn}
trang_thai: Dự thảo
nguoi_doc: Hội đồng thẩm định, kỹ sư, kiểm thử viên
phan_he: PH-{nn}
---

# D02-03-PH{nn} · Đặc tả yêu cầu chức năng {Tên}

> Trình bày, văn phong, khối đặc tả và mức sàn theo [K-TRINH-BAY](K-TRINH-BAY.md). Tài liệu mẫu theo khuôn này: `02-yeu-cau/frs/D02-03-PH05-frs-bo-dieu-hop.md` bản 0.2 (chương 1–6.3).

## Tóm tắt cho hội đồng thẩm định  [BB]
Mục tiêu, phạm vi, căn cứ pháp lý (`CMP-LAW-*`), những điểm hội đồng cần lưu ý (3–5 ý), bảng con số chính (số FR theo M/S/C, BR, NFR, UI, API, LGC được phủ).

## 1. Giới thiệu  [BB]
### 1.1. Mục đích của tài liệu — ai dùng để làm gì; khung đặc tả mỗi chức năng.
### 1.2. Phạm vi — bảng trách nhiệm theo nhóm FR; bảng việc ngoài phạm vi và phân hệ chịu trách nhiệm.
### 1.3. Đối tượng sử dụng và cách đọc — bảng Người đọc | Đọc phần | Mục đích.
### 1.4. Thuật ngữ và chữ viết tắt — chỉ thuật ngữ dùng trong tập này, kể cả viết tắt vai trò.
### 1.5. Tài liệu tham chiếu — văn bản pháp lý `CMP-LAW-*`, tài liệu dự án, ADR liên quan.
### 1.6. Cấu trúc tài liệu — một đoạn nêu nội dung từng chương.

## 2. Tổng quan phân hệ  [BB]
### 2.1. Bối cảnh và vấn đề cần giải quyết — đoạn mở + bảng hạn chế hệ cũ | hệ quả | cách khắc phục.
### 2.2. Mục tiêu của phân hệ — 3–5 mục tiêu đo được (gắn NFR).
### 2.3. Vị trí trong kiến trúc — sơ đồ Mermaid (DU theo D00-04 §2, vùng mạng) + thuyết minh.
### 2.4. Kiến trúc thành phần và công nghệ — các thành phần, công nghệ, sơ đồ trình tự luồng chính.
### 2.5. Quy trình nghiệp vụ liên quan — bảng `BP-*` | bước có phân hệ; sơ đồ vòng đời điển hình.
### 2.6. Chức năng hệ cũ được phủ — bảng `LGC` | chức năng | vai trò của phân hệ.

## 3. Tác nhân, vai trò và quyền  [BB]
### 3.1. Tác nhân — bảng Tác nhân | Loại | Mô tả | Tương tác chính.
### 3.2. Ma trận quyền — `PERM-{nn}-*` × `ROLE-*`. Quyền mới ghi vào "Đề nghị đồng bộ D02-08".
### 3.3. Tách nhiệm vụ và tài khoản máy — bốn mắt, cặp loại trừ, scope dịch vụ.

## 4. Khái niệm và mô hình nghiệp vụ  [BB]
Khái niệm nghiệp vụ; thực thể `EN-{nn}-..` mức logic; máy trạng thái (Mermaid `stateDiagram-v2` có `caption` + thuyết minh từng trạng thái).

## 5. Danh sách chức năng  [BB]
Bảng Mã | Nhóm | Chức năng | Mức | Đợt | Màn hình, chú thích "Danh sách chức năng của PH-{nn}".

## 6. Đặc tả chi tiết chức năng  [BB]
6.1 Cách đọc bảng đặc tả (bảng 14 mục). Mỗi nhóm một mục `### 6.k. Nhóm X · Tên`, mở bằng đoạn văn và sơ đồ quan hệ chức năng trong nhóm. Mỗi FR: `#### FR-{nn}-nnn · {động từ + đối tượng}` + khối `::: dac-ta` đủ 14 mục + bảng "Dữ liệu vào" khi ≥ 5 trường + sơ đồ trình tự khi có ≥ 3 thành phần hoặc duyệt bốn mắt.

## 7. Quy tắc nghiệp vụ  [BB]
Bảng `BR-{nn}-nnn | Quy tắc | FR áp dụng`.

## 8. Tham số và yêu cầu phi chức năng  [BB]
`NFR-{nn}-nnn` đo được (đơn vị, điều kiện đo, phân vị); tham số theo tenant (khóa, mặc định, miền, ý nghĩa).

## 9. Mã lỗi, thông báo, sự kiện và API  [BB]
9.1 Mã lỗi (mã, HTTP, ý nghĩa). 9.2 Thông báo hiển thị cho người dùng (mã, câu hiển thị, vị trí). 9.3 Sự kiện. 9.4 Danh mục API (định nghĩa đầy đủ ở D03-04).

## 10. Giao diện  [BB]
10.1 Danh sách màn hình `UI-{nn}-nn | Tên | Vai trò | Hành vi chính | FR`. 10.2 Giao diện tiêu biểu: ít nhất hai ảnh hi-fi (`03-thiet-ke/uiux/ph{nn}/hifi/`), mỗi ảnh một đoạn thuyết minh.

## 11. Truy vết  [BB]
`LGC` → FR (kết luận Giữ nguyên / Nâng cấp / Thay thế / Loại bỏ), FR → REQ.

## 12. Phụ thuộc, giả định và ràng buộc
## 13. Câu hỏi mở  [BB]
## 14. Tiêu chí chấp nhận cấp phân hệ  [BB]
## Lịch sử phiên bản

---

### Ví dụ ngắn (định dạng cũ, chỉ để tra trường; định dạng chuẩn là khối `::: dac-ta` ở K-TRINH-BAY §4)

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
- [ ] Mỗi FR dùng khối `::: dac-ta` đủ 14 mục (K-TRINH-BAY §4), có `LGC` nếu thay chức năng cũ; ngoại lệ có câu thông báo hiển thị.
- [ ] Mọi bảng có chú thích, mọi sơ đồ có `caption`; có ít nhất hai ảnh giao diện tiêu biểu.
- [ ] Mỗi `LGC` của phân hệ có đúng một kết luận ở §9.
- [ ] Mã mới lấy số kế tiếp ở D00-04 §3.2; `kiem_tra_ma.py` sạch.
