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
    Và mở `/ca-nhan/viec`, lọc loại `ph18.approve-param`.
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
    Và mở liên kết `/ca-nhan/viec/TASK-DONE-01`.
    Thì bước 1 `404` ERR-18-001. Bước 2 màn hiện câu thông báo ERR-18-048 và nút về danh sách.
