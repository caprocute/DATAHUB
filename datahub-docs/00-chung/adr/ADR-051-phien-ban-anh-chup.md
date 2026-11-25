---
ma_tai_lieu: ADR-051
ten: Phiên bản danh mục là ảnh chụp copy-on-write bất biến, hiệu lực theo khoảng ngày
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Nhóm CSDL, Hội đồng thẩm định
---

# ADR-051 · Phiên bản danh mục là ảnh chụp copy-on-write bất biến, hiệu lực theo khoảng ngày

## Bối cảnh

Danh mục dùng chung thay đổi theo văn bản pháp lý: một quyết định ban hành danh mục mới có ngày hiệu lực, có thể ban hành trước ngày hiệu lực vài tuần. Bên khai thác cần tra cứu "mã này có nghĩa gì tại ngày phát sinh hồ sơ" (FR-07-026, BR-07-008), cần lấy thay đổi kể từ phiên bản đã có (FR-07-031) và cần bảo đảm rằng dữ liệu đã phát hành không bị sửa lén (BR-07-006). Người quản lý danh mục lại cần soạn thay đổi trên bản nháp, kiểm tra, trình duyệt rồi phát hành nguyên khối (FR-07-011…017).

Hệ cũ Aita không có khái niệm phiên bản: sửa trực tiếp trên dữ liệu đang dùng. Khung mã W3 (`vn.lgsp.data.rdm`) đã thử sao chép mục từ phiên bản gần nhất khi tạo phiên bản mới, nhưng chưa sao chép định nghĩa thuộc tính và chưa có quy tắc bất biến.

Cần chọn mô hình lưu phiên bản cân bằng giữa dung lượng, tốc độ tra cứu theo thời điểm, độ đơn giản khi soạn và khả năng bảo đảm bất biến.

## Các phương án

Bảng dưới đây so sánh ba mô hình lưu lịch sử phổ biến.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Bảng temporal theo khoảng phiên bản (mỗi dòng bản ghi có `valid_from_version`, `valid_to_version`; chỉ dòng thay đổi mới sinh dòng mới) | Tiết kiệm dung lượng khi mỗi phiên bản đổi ít; chuẩn SQL:2011 có khái niệm tương tự | Tra cứu một phiên bản phải lọc khoảng trên mọi dòng; soạn nháp phải đóng mở khoảng phức tạp; định nghĩa thuộc tính cũng phải temporal; bất biến khó chứng minh vì dòng cũ bị cập nhật cột `valid_to_version`; xóa nháp phải hoàn tác nhiều dòng |
| B. Event sourcing (lưu chuỗi sự kiện thay đổi, dựng trạng thái bằng phát lại) | Lịch sử đầy đủ tới từng thao tác; tự nhiên với kiểm toán | Tra theo thời điểm phải phát lại hoặc duy trì hình chiếu; phức tạp cho đội vận hành tỉnh; nhập tệp 200.000 dòng sinh 200.000 sự kiện; không hợp với truy vấn có cấu trúc |
| C. **Ảnh chụp copy-on-write: mỗi phiên bản chứa bản sao đầy đủ `attribute_def` và `catalog_item`; tạo nháp bằng `INSERT … SELECT`; phát hành xong là bất biến** | Mỗi phiên bản tự đứng độc lập; tra cứu chỉ lọc `version_id`; bất biến dễ bảo đảm (trigger chặn sửa khi phiên bản `PUBLISHED`); hủy nháp là xóa theo `version_id`; khóa bộ đệm theo `version_id` không bao giờ cũ (ADR-053) | Dung lượng tăng tuyến tính theo số phiên bản; sao chép danh mục lớn tốn vài giây |

## Quyết định

Chọn **phương án C**. Mỗi `catalog_version` sở hữu bản sao đầy đủ của định nghĩa thuộc tính (`attribute_def.version_id`) và bản ghi (`catalog_item.version_id`). Thao tác tạo bản nháp (API-07-012) chạy trong một giao dịch hai câu `INSERT … SELECT` sao chép từ phiên bản hiện hành, sinh `id` mới bằng UUID v7 và giữ nguyên `code`. Phiên bản ở trạng thái `PUBLISHED` là bất biến: tầng ứng dụng chặn mọi thao tác ghi, và CSDL có trigger `BEFORE UPDATE OR DELETE` trên `catalog_item`, `attribute_def`, `item_succession` từ chối khi phiên bản cha đã phát hành (trừ vai trò bảo trì có kiểm toán).

Hiệu lực được biểu diễn bằng khoảng nửa mở `[effective_from, effective_to)` kiểu `date` trên `catalog_version`. Ràng buộc loại trừ `EXCLUDE USING gist (catalog_id WITH =, daterange(effective_from, effective_to, '[)') WITH &&) WHERE (status = 'PUBLISHED')` bảo đảm không chồng lấn (BR-07-007). Khi phát hành phiên bản mới, `effective_to` của phiên bản trước được đặt bằng `effective_from` của phiên bản mới trong cùng giao dịch; đây là cập nhật duy nhất được phép trên phiên bản đã phát hành và chỉ do `PublishService` thực hiện.

Nhãn "Đang hiệu lực", "Sắp hiệu lực", "Hết hiệu lực" được tính từ khoảng hiệu lực so với ngày hiện tại theo giờ Việt Nam, không lưu thành trạng thái. Con trỏ `catalog.current_version_id` trỏ tới phiên bản đang hiệu lực và được một tác vụ lịch chuyển sang phiên bản sắp hiệu lực khi đến ngày (D03-02-PH07 §4.6).

Để giảm dung lượng, phiên bản đã hết hiệu lực quá thời hạn lưu giữ trực tuyến (mặc định 5 năm, cấu hình `07.rdm.version-online-retention-years`) được chuyển sang lưu trữ: bản ghi được xóa khỏi `catalog_item` sau khi ảnh chụp JSON.gz trên Garage được xác minh tổng kiểm tra; tra cứu theo thời điểm quá khứ xa đọc từ ảnh chụp.

## Hệ quả

Tích cực: mô hình đơn giản cho người soạn (nháp là một bản sao để sửa thoải mái) và cho bên khai thác (một phiên bản là một tập đóng). So sánh hai phiên bản (FR-07-014) là phép nối đầy đủ theo `code` giữa hai tập. Ảnh chụp trên Garage và bộ đệm theo `version_id` không cần cơ chế vô hiệu hóa vì nội dung không bao giờ đổi.

Tiêu cực: dung lượng. Với danh mục ĐVHC khoảng 3.400 bản ghi hiện hành và 10.000 bản ghi lịch sử, mỗi phiên bản vài MB, không đáng kể. Với danh mục 200.000 bản ghi phát hành hằng tháng, mỗi năm thêm khoảng 2,4 triệu dòng; chấp nhận được nhờ chính sách lưu trữ ở trên. Sao chép 200.000 dòng ước tính 2–4 giây trên PostgreSQL 18 với cấu hình chuẩn; thao tác được chạy đồng bộ nhưng có giới hạn thời gian 30 giây.

Ràng buộc: mỗi danh mục tối đa một phiên bản mở (BR-07-005), bảo đảm bằng chỉ mục duy nhất từng phần `UNIQUE (catalog_id) WHERE status IN ('DRAFT','IN_REVIEW','APPROVED')`.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-011, FR-07-014, FR-07-016, FR-07-017, FR-07-026, FR-07-031; BR-07-005, BR-07-006, BR-07-007, BR-07-008, BR-07-027; NFR-07-007, NFR-07-011; LGC-DMDC-011. Liên quan ADR-050, ADR-053, ADR-055. Thiết kế chi tiết: D03-02-PH07 §4.2, §4.5, §4.6.
