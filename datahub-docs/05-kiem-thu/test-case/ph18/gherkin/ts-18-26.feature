# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-26
Tính năng: TS-18-26 · Xử lý Việc của tôi, nhắc và quá hạn

  @TC-18-086 @P1 @Dương
  Kịch bản: TC-18-086 Danh sách Việc của tôi, thẻ tóm tắt và mở màn của phân hệ nguồn
    # Truy vết: FR-18-044 · API-18-111, 112 · UI-18-15
    # Mục đích: Chứng minh FR-18-044: danh sách sắp theo hạn, `?summary=true` cho thẻ trang chủ, chi tiết có liên kết sang màn của phân hệ nguồn.
    Biết T90; U-T90-TA2 có 12 việc mở thuộc 4 loại, 2 quá hạn.
    Khi `GET /me/tasks?summary=true`.
    Và mở `/viec-cua-toi`, lọc loại `ph18.approve-param`.
    Và bấm một việc.
    Thì bước 1 `200` `open = 12`, `overdue = 2`, theo loại. Bước 2 đúng việc, cột hạn và người giao. Bước 3 chuyển sang màn của phân hệ nguồn qua liên kết đã đăng ký.

  @TC-18-087 @P2 @Biên
  Kịch bản: TC-18-087 Nhắc trước hạn 24 giờ và báo quá hạn sau 48 giờ
    # Truy vết: FR-18-044, 036 · BR-18-032 · EVT-18-14
    # Mục đích: Chứng minh `18.task.reminder.before-hours` và `18.task.overdue.escalate-hours`: nhắc đúng một lần, quá hạn chuyển cấp theo loại việc.
    Biết T95 (đồng hồ giả); việc hạn sau 30 giờ.
    Khi tua 7 giờ, chạy tác vụ nhắc hai lần.
    Và tua tới quá hạn 49 giờ.
    Thì bước 1 đúng một thông báo nhắc, bản ghi `task_reminder` có thời điểm. Bước 2 việc có cờ quá hạn, người giao ở cấp trên nhận thông báo chuyển cấp; EVT-18-14 không phát vì trạng thái không đổi.

  @TC-18-088 @P2 @Âm
  Kịch bản: TC-18-088 Mở việc không tồn tại và việc đã đóng từ liên kết cũ
    # Truy vết: FR-18-044 · API-18-112 · ERR-18-001, 048
    # Mục đích: Chứng minh liên kết cũ trong thư nhắc không mở được việc đã đóng.
    Biết T90; việc `TASK-DONE-01` đã `DONE`.
    Khi `GET /me/tasks/TASK-KHONG-CO`.
    Và mở liên kết `/viec-cua-toi/TASK-DONE-01`.
    Thì bước 1 `404` ERR-18-001. Bước 2 màn hiện câu thông báo ERR-18-048 và nút về danh sách.

  @TC-18-166 @P2 @Dương @Âm @Lũy_đẳng
  Kịch bản: TC-18-166 Nhận việc chuyển IN_PROGRESS, gọi lại không đổi, việc đã đóng bị từ chối
    # Truy vết: FR-18-044 · API-18-181, 112 · EVT-18-14 · ERR-18-048, 001 · ERR-00-428 · UI-18-15
    # Mục đích: Chứng minh FR-18-044 bước 3 qua API-18-181: nhận việc ghi người nhận, phát EVT-18-14, lũy đẳng khi gọi lại và từ chối việc đã đóng.
    Biết T90; U-T90-TA2 có việc `TASK-OPEN-01` `OPEN` cùng nhóm nhận với U-T90-TA1; việc `TASK-DONE-01` đã `DONE`.
    Khi TA2 `POST /me/tasks/TASK-OPEN-01:claim` kèm `If-Match`.
    Và TA2 gửi lại bước 1 với ETag mới.
    Và TA2 `POST /me/tasks/TASK-OPEN-01:claim` không có `If-Match`.
    Và TA2 `POST /me/tasks/TASK-DONE-01:claim`.
    Và TA1 mở UI-18-15.
    Thì bước 1 `200` việc `IN_PROGRESS`, `claimedBy = U-T90-TA2`, EVT-18-14 phát một lần. Bước 2 `200` không đổi, không phát sự kiện mới. Bước 3 `428` ERR-00-428. Bước 4 `409` ERR-18-048. Bước 5 TA1 thấy việc ghi "TA2 đã nhận".
