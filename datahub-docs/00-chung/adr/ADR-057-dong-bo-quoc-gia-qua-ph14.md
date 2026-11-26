---
ma_tai_lieu: ADR-057
ten: Đồng bộ danh mục quốc gia qua adapter PH-14, đối chiếu khác biệt và tự áp dụng có điều kiện
phien_ban: 0.1
ngay: 2026-11-21
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, Trưởng nhóm PH-07, Trưởng nhóm PH-14, Hội đồng thẩm định
---

# ADR-057 · Đồng bộ danh mục quốc gia qua adapter PH-14, đối chiếu khác biệt và tự áp dụng có điều kiện

## Bối cảnh

Danh mục dùng chung quốc gia được công bố qua Nền tảng trao đổi dữ liệu quốc gia (NDXP, trước đây là NGSP) với các dịch vụ: liệt kê danh mục, lấy cấu trúc (metadata), lấy dữ liệu và đề xuất bổ sung. Hệ cũ Aita gọi trực tiếp NGSP, ghi đè dữ liệu và đánh dấu `is_update = 1`; khóa ứng dụng NGSP nằm trong cấu hình của Aita. KPI-11 và NFR-07-013 yêu cầu phát hiện thay đổi quốc gia trong vòng 24 giờ. Thay đổi phá vỡ (xóa mã, đổi mã cha, đổi kiểu thuộc tính) có thể làm hỏng dữ liệu nghiệp vụ của tỉnh nếu áp dụng tự động (BR-07-017).

D03-01 giao PH-14 là điểm duy nhất kết nối các nền tảng quốc gia (quản lý thông tin xác thực, chứng thư, giới hạn tần suất, nhật ký). PH-07 nằm ở `dh-data`, PH-14 có phần data plane ở `dh-runtime` và phần control ở `dh-integration`.

## Các phương án

Bảng dưới đây so sánh các cách đồng bộ.

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. PH-07 gọi trực tiếp NDXP như Aita | Ít bước | Nhân đôi quản lý khóa và chứng thư; vi phạm vai trò điểm kết nối duy nhất của PH-14; khóa nằm trong cấu hình DU dữ liệu |
| B. PH-14 đẩy dữ liệu (push) vào PH-07 qua sự kiện khi phát hiện thay đổi | PH-07 thụ động | PH-14 phải hiểu ngữ nghĩa danh mục và lịch; khó chạy theo yêu cầu; khó tính khác biệt có ngữ cảnh phiên bản |
| C. **PH-07 kéo (pull) qua API của adapter PH-14 theo lịch và theo yêu cầu; PH-07 chuẩn hóa, tính khác biệt với phiên bản hiện hành, phân loại phá vỡ; không phá vỡ và `auto_apply = true` thì tự tạo và phát hành phiên bản; có phá vỡ thì chờ xác nhận** | PH-14 chỉ lo giao thức và bảo mật; PH-07 giữ toàn bộ ngữ nghĩa; kiểm soát được thay đổi phá vỡ | Phụ thuộc thời gian chạy vào PH-14; cần chống chạy trùng khi nhiều pod |

## Quyết định

Chọn **phương án C**.

PH-14 công bố cho PH-07 bốn thao tác REST nội bộ (qua mesh, mTLS, token dịch vụ): liệt kê danh mục NDXP, lấy cấu trúc một danh mục, lấy dữ liệu một danh mục (phân trang hoặc luồng), gửi đề xuất bổ sung. Hợp đồng chi tiết thuộc tài liệu PH-14; PH-07 dùng client `NdxpCatalogClient` sinh từ OpenAPI của PH-14, có thời gian chờ kết nối 5 giây, đọc 60 giây, thử lại 3 lần lùi theo hàm mũ có nhiễu với lỗi mạng và 5xx, và bộ ngắt mạch Resilience4j. Lỗi sau khi hết thử lại trả ERR-07-028 cho lần chạy theo yêu cầu và ghi `sync_run.status = FAILED`.

Mỗi `sync_source` có lịch cron (mặc định `0 0 1 * * *` giờ Việt Nam, tham số `07.rdm.sync-default-cron`). Bộ lập lịch chạy ở mọi pod nhưng mỗi nguồn chỉ được một pod xử lý nhờ ShedLock (bảng `ph07_rdm.shedlock`) cho tác vụ quét và khóa tư vấn PostgreSQL `pg_try_advisory_xact_lock` theo `source_id` cho từng lần chạy. Dữ liệu NDXP được chuẩn hóa theo `field_mapping` (ánh xạ trường NDXP sang `code`, `name`, `parent_code`, thuộc tính) và chuẩn hóa mã theo T-CODE; sau đó tính khác biệt với phiên bản hiện hành bằng cùng thuật toán so sánh của FR-07-014, ghi `sync_change`.

Quyết định áp dụng: không có khác biệt thì `NO_CHANGE`; không phá vỡ và `auto_apply = true` thì tạo phiên bản `origin = SYNC`, phát hành ngay với `effective_from` theo ngày hiệu lực NDXP cung cấp hoặc ngày chạy (cho phép hồi tố theo BR-07-027) và đặt `APPLIED`; có phá vỡ hoặc `auto_apply = false` thì `PENDING_CONFIRMATION`, phát EVT-07-09 để tạo việc trong hộp "Việc của tôi". Người có `PERM-07-sync` xác nhận (API-07-061) thì phiên bản được tạo và chuyển theo luồng duyệt thường của danh mục; từ chối (API-07-062) thì `REJECTED` và lần chạy sau vẫn so với phiên bản hiện hành nên thay đổi sẽ xuất hiện lại cho tới khi được xử lý. Danh mục NATIONAL chỉ ghi qua đường này (BR-07-009). Danh mục quốc gia dùng cho mọi tỉnh được cấu hình đồng bộ ở tenant COMMON bởi PLATFORM.

Chỉ số `rdm_sync_last_success_timestamp` có cảnh báo khi quá 26 giờ để bảo đảm NFR-07-013.

## Hệ quả

Tích cực: không khóa NDXP nào nằm trong PH-07; một cơ chế khác biệt dùng chung cho so sánh phiên bản, đồng bộ và nhập tệp; thay đổi phá vỡ luôn có người xác nhận.

Tiêu cực: phụ thuộc vào khả năng sẵn sàng của PH-14 và NDXP; lần chạy thất bại được lặp lại theo lịch tiếp theo và có thể chạy tay. Danh mục lớn tải về tốn băng thông; PH-14 nên hỗ trợ tham số phiên bản hoặc dấu thời gian để PH-07 bỏ qua khi `remote_version` không đổi (Câu hỏi mở Q07-40 trong D03-02-PH07).

## Trạng thái

Đề xuất.

## Truy vết

FR-07-035, FR-07-036, FR-07-037, FR-07-038, FR-07-039; BR-07-009, BR-07-017, BR-07-027; NFR-07-013; KPI-11; ERR-07-028, ERR-07-029; EVT-07-09; LGC-DMDC-019, LGC-NGSP-006. Liên quan ADR-013, ADR-051. Thiết kế chi tiết: D03-02-PH07 §4.11, §5.6.
