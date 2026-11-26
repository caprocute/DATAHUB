# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-27
Tính năng: TS-06-27 · Yêu cầu của chủ thể dữ liệu

  @TC-06-115 @P1 @Dương
  Kịch bản: TC-06-115 Yêu cầu biết (ACCESS)
    # Truy vết: FR-06-058 · BR-06-030 · API-06-090, 091, 092 · UI-06-16 · PERM-06-dsr
    # Mục đích: Chứng minh báo cáo dữ liệu đang giữ cho chính chủ thể, theo FR-06-058.
    Biết SO tiếp nhận; DS1 xác nhận; bản ghi vàng Bình.
    Khi `POST /subject-requests` `DsrType = ACCESS`, đã xác minh danh tính, CC-03.
    Và DS1 xác nhận đúng người, `:complete`.
    Thì yêu cầu `RECEIVED` → `IN_PROGRESS` → `COMPLETED`; báo cáo có thuộc tính (giá trị rõ cho chính chủ thể), nguồn từng thuộc tính, danh sách HTTT và mục đích truy cập 12 tháng; hạn theo `06.dsr.sla-days`. KT: có (dsr-complete).
    # Hậu điều kiện: Một yêu cầu COMPLETED.

  @TC-06-116 @P1 @Dương
  Kịch bản: TC-06-116 Yêu cầu sửa (RECTIFICATION)
    # Truy vết: FR-06-058 · BR-06-014, 025 · API-06-092 · EVT-06-15
    # Mục đích: Chứng minh sửa tại nguồn, không sửa ở bản ghi vàng, theo BR-06-014.
    Biết hai yêu cầu: thuộc tính `phone` (nguồn `HT-YTE`) và `dateOfBirth` (thẩm quyền quốc gia).
    Khi `POST /subject-requests` cho `phone`; `:forward`.
    Và `POST` cho `dateOfBirth`; `:complete`.
    Thì bước 1 `FORWARDED_TO_SOURCE`, EVT-06-15 tới `HT-YTE`, bản ghi vàng chưa đổi tới khi nguồn gửi. Bước 2 `COMPLETED` kèm hướng dẫn liên hệ cơ quan đăng ký.
    # Hậu điều kiện: Một yêu cầu FORWARDED.

  @TC-06-117 @P2 @Dương
  Kịch bản: TC-06-117 Yêu cầu hạn chế xử lý (RESTRICTION)
    # Truy vết: FR-06-058 · API-06-092 · BR-06-026
    # Mục đích: Chứng minh hạn chế đưa bản ghi vàng sang `LOCKED` có cờ `restricted`, theo FR-06-058.
    Biết bản ghi vàng Bình; DS1.
    Khi `POST` `RESTRICTION`; `:complete`.
    Và gọi `lookup` mục đích tra cứu thường.
    Thì bản ghi `LOCKED` `restricted`, PH-09 nhận cập nhật chính sách; tra cứu mục đích không bắt buộc theo luật bị từ chối. Việc gỡ hạn chế chưa có API (ĐN-UC-05).
    # Hậu điều kiện: Bình LOCKED restricted.

  @TC-06-118 @P1 @Âm
  Kịch bản: TC-06-118 Chưa xác minh, yêu cầu xóa, từ chối, quá hạn
    # Truy vết: FR-06-058 · BR-06-030 · API-06-090, 092 · ERR-06-007, 046
    # Mục đích: Chứng minh các nhánh chặn và cảnh báo hạn của yêu cầu chủ thể, theo FR-06-058.
    Biết SO; `06.dsr.sla-days = 10`; đồng hồ giả lập.
    Khi gửi yêu cầu chưa xác minh danh tính.
    Và gửi yêu cầu xóa dữ liệu.
    Và `:reject` thiếu lý do.
    Và tiến 8 rồi 11 ngày làm việc.
    Thì bước 1 `422` ERR-06-046. Bước 2 từ chối có căn cứ pháp lý giữ dữ liệu có nguồn thẩm quyền, chuyển PH-09. Bước 3 `422` ERR-06-007. Bước 4 cảnh báo SO trước hạn 2 ngày, đánh dấu quá hạn.
    # Hậu điều kiện: Ba yêu cầu ở trạng thái cuối.
