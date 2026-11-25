---
ma_tai_lieu: ADR-058
ten: Luồng duyệt phiên bản danh mục dùng máy trạng thái nội bộ thay cho Flowable
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Trưởng nhóm PH-11, Hội đồng thẩm định
---

# ADR-058 · Luồng duyệt phiên bản danh mục dùng máy trạng thái nội bộ thay cho Flowable

## Bối cảnh

Phiên bản danh mục đi qua các trạng thái `DRAFT`, `IN_REVIEW`, `APPROVED`, `PUBLISHED`, `DISCARDED` với nguyên tắc bốn mắt: người trình không được tự duyệt (BR-07-011), và người có `PERM-07-publish` không được duyệt hoặc phát hành phiên bản do chính mình trình hoặc sửa lần cuối (D02-08). ADR-007 chọn Flowable cho quy trình có từ hai bước duyệt trở lên, có hạn xử lý hoặc liên cơ quan, còn luồng duyệt ngắn trong một phân hệ dùng máy trạng thái trong mã. Luồng duyệt danh mục có đúng một bước duyệt, không có hạn xử lý bắt buộc và nằm trọn trong PH-07. Việc chờ duyệt vẫn phải hiện trong hộp "Việc của tôi" (FR-00-070).

## Các phương án

Bảng dưới đây so sánh ba cách hiện thực.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Khởi tạo quy trình Flowable ở PH-11 cho mỗi lần trình | Giao diện theo dõi chung; mở rộng nhiều bước dễ | Gọi chéo DU (`dh-data` sang `dh-platform`) cho mọi lần trình; trạng thái nằm ở hai nơi phải đồng bộ; PH-11 thuộc Đợt 2 trong khi PH-07 thuộc MVP |
| B. Spring State Machine | Khung có sẵn | Phụ thuộc thêm cho bảng chuyển trạng thái năm trạng thái; khó đọc; ADR-007 đã khuyên không cần |
| C. **Enum trạng thái + bảng chuyển trạng thái khai báo trong mã + bảng `version_review` ghi từng hành động; đăng việc chờ duyệt qua sự kiện EVT-07-04** | Nhẹ; trạng thái một nơi; kiểm thử bảng chuyển dễ; không phụ thuộc PH-11 | Không có giao diện BPM; muốn duyệt nhiều cấp phải mở rộng mã |

## Quyết định

Chọn **phương án C**, đúng định hướng ADR-007 cho luồng ngắn. Bảng chuyển trạng thái được khai báo một lần trong `VersionStateMachine` dưới dạng danh sách bất biến (từ, sự kiện, điều kiện bảo vệ, hành động, đến) và là nguồn duy nhất cho dịch vụ, giao diện (danh sách hành động khả dụng trả kèm phiên bản) và kiểm thử. Mỗi chuyển trạng thái ghi một dòng `version_review` và một sự kiện outbox trong cùng giao dịch. Hộp "Việc của tôi" tạo việc khi nhận EVT-07-04 và đóng việc khi nhận EVT-07-05 hoặc EVT-07-06.

Nếu sau này có yêu cầu duyệt nhiều cấp hoặc liên cơ quan cho một nhóm danh mục, PH-07 thêm chính sách `approval_mode = BPMN` và giao cho PH-11 qua API mà không đổi trạng thái lưu của phiên bản.

## Hệ quả

Tích cực: PH-07 phát hành được ở MVP độc lập với tiến độ PH-11; bốn mắt kiểm soát tập trung trong một lớp. Tiêu cực: báo cáo hạn xử lý duyệt phải tự tính từ `version_review`.

## Trạng thái

Đề xuất.

## Truy vết

FR-07-015, FR-07-016, FR-07-017; BR-07-011, BR-07-012, BR-07-026; EVT-07-04, EVT-07-05, EVT-07-06; FR-00-070; D02-08 §3.1. Liên quan ADR-007. Thiết kế chi tiết: D03-02-PH07 §4.4.
