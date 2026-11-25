---
ma_tai_lieu: ADR-055
ten: Mô hình đơn vị hành chính theo phiên bản, quan hệ kế thừa nhiều-nhiều và bảng chiếu admin_unit
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Trưởng nhóm PH-20, Trưởng nhóm PH-06, Hội đồng thẩm định
---

# ADR-055 · Mô hình đơn vị hành chính theo phiên bản, quan hệ kế thừa nhiều-nhiều và bảng chiếu admin_unit

## Bối cảnh

Năm 2025, Việt Nam sắp xếp lại đơn vị hành chính (ĐVHC) quy mô lớn: Nghị quyết 202/2025/QH15 sắp xếp cấp tỉnh còn 34 tỉnh, thành phố (28 tỉnh, 6 thành phố trực thuộc trung ương); các nghị quyết của Ủy ban Thường vụ Quốc hội năm 2025 sắp xếp cấp xã; chính quyền địa phương hai cấp (tỉnh, xã) vận hành từ 01/7/2025, cấp huyện chấm dứt. Quyết định 19/2025/QĐ-TTg ban hành Bảng danh mục và mã số ĐVHC Việt Nam với 3.321 đơn vị cấp xã, mã tỉnh 2 chữ số, mã xã 5 chữ số, hiệu lực 01/7/2025.

Dữ liệu nghiệp vụ phát sinh trước 01/7/2025 vẫn mang mã ba cấp cũ; HTTT cần chuyển đổi mã cũ sang mới và ngược lại (FR-07-046), xem dòng lịch sử (FR-07-047). Một xã cũ có thể được chia về nhiều xã mới (BR-07-022), nhiều xã cũ gộp thành một xã mới. Đồng thời D02-07 định nghĩa thực thể dùng chung DD-07 `ph07_rdm.admin_unit` có định danh ổn định, để PH-20 (tenant gắn với tỉnh) và DD-02 (tổ chức) tham chiếu khóa ngoại.

## Các phương án

Bảng dưới đây so sánh ba cách mô hình hóa ĐVHC.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Bảng ĐVHC riêng ngoài cơ chế danh mục, mỗi dòng một đơn vị có `effective_from/to` và `successor_ids` (đúng nguyên dạng DD-07) | Đơn giản cho phân hệ tham chiếu | Trùng lặp cơ chế phiên bản, duyệt, phát hành, đồng bộ quốc gia, bộ đệm đã có ở PH-07; `successor_ids` một chiều không biểu diễn được chia tách có căn cứ pháp lý |
| B. Chỉ dùng danh mục có phiên bản `DVHC`, không có bảng chiếu | Một nguồn sự thật | `catalog_item.id` đổi theo mỗi phiên bản (copy-on-write, ADR-051) nên phân hệ khác không có khóa ổn định để tham chiếu |
| C. **Danh mục `DVHC` có phiên bản là nguồn sự thật; bảng `item_succession` ghi sự kiện sắp xếp nhiều-nhiều; bảng chiếu `admin_unit` (EN-07-18, đúng cột DD-07) có định danh ổn định, làm mới trong cùng giao dịch phát hành** | Tận dụng toàn bộ cơ chế danh mục; quan hệ kế thừa đủ ngữ nghĩa; phân hệ khác có khóa ổn định | Hai biểu diễn phải đồng nhất; logic làm mới bảng chiếu phải đúng |

## Quyết định

Chọn **phương án C**.

Danh mục `DVHC` thuộc tenant COMMON, phân cấp (`is_hierarchical = true`, `max_depth = 3`), thuộc tính bắt buộc `level` (ENUM `PROVINCE`, `COMMUNE`, `DISTRICT`) và `unit_type` (ENUM tỉnh, thành phố, xã, phường, đặc khu). Phiên bản hiệu lực từ 01/7/2025 chỉ có `PROVINCE` và `COMMUNE`, `level_names = ["Tỉnh","Xã"]`; các phiên bản trước giữ ba cấp có `DISTRICT`.

Bảng `item_succession` ghi mỗi sự kiện sắp xếp với `event_type` ∈ {`MERGE`, `SPLIT`, `RENAME`, `ABOLISH`, `ESTABLISH`, `RECODE`}, `from_codes text[]`, `to_codes text[]`, `effective_date`, `legal_basis` bắt buộc (BR-07-021, ERR-07-035). Sự kiện gắn với phiên bản ghi nhận và chỉ sửa được khi phiên bản là nháp. Chuyển mã cũ sang mới tại ngày đích duyệt đồ thị kế thừa có hướng theo thứ tự `effective_date`, xử lý chuỗi nhiều bước, trả `AMBIGUOUS` kèm ứng viên khi gặp `SPLIT` (BR-07-022); thuật toán chi tiết ở D03-02-PH07 §4.13.

Bảng chiếu `ph07_rdm.admin_unit` có `id` ổn định theo đơn vị: một đơn vị được nhận diện bởi (`code`, khoảng hiệu lực liên tục không bị sự kiện `RECODE`/`ABOLISH` cắt). Khi phát hành phiên bản `DVHC`, `AdminUnitProjector` chạy trong cùng giao dịch: đơn vị có mã tồn tại và vẫn hiệu lực giữ nguyên `id`, cập nhật `name`, `unit_type`, `parent_id`; đơn vị mới được thêm; đơn vị bị giải thể, sáp nhập, đổi mã được đóng `effective_to` và ghi `successor_ids` từ `item_succession`; `source_version` nhận số phiên bản. Mã giữ nguyên nhưng đổi sang đơn vị khác về bản chất không được phép trong cùng khoảng thời gian (BR-07-021).

Các số hiệu văn bản và số lượng đơn vị nêu ở Bối cảnh phải được đối chiếu Công báo trước khi nạp dữ liệu sản xuất (Câu hỏi mở Q07-38 trong D03-02-PH07).

## Hệ quả

Tích cực: ĐVHC hưởng đủ phiên bản, duyệt bốn mắt, đồng bộ NDXP, bộ đệm và ảnh chụp như mọi danh mục. Phân hệ khác tham chiếu `admin_unit.id` ổn định mà không phụ thuộc cơ chế phiên bản. Dữ liệu lịch sử ba cấp vẫn tra được theo thời điểm.

Tiêu cực: thêm một bảng phải giữ đồng nhất; có kiểm thử bất biến "mọi dòng `admin_unit` hiệu lực tại ngày `d` tương ứng đúng một `catalog_item` của phiên bản `DVHC` hiệu lực tại `d`". Phát hành phiên bản `DVHC` phát thêm EVT-07-10 khi có sự kiện sắp xếp.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-044, FR-07-045, FR-07-046, FR-07-047; BR-07-021, BR-07-022; ERR-07-035; DD-07 (D02-07); EVT-07-10. Liên quan ADR-051, ADR-052, ADR-057, D03-10 §5.4. Thiết kế chi tiết: D03-02-PH07 §4.13.
