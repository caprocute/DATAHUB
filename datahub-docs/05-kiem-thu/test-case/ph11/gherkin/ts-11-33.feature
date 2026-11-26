# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-33
Tính năng: TS-11-33 · Chịu lỗi tích hợp: CSDL, PH-04, PH-12

  @TC-11-159 @P1 @Chịu @lỗi
  Kịch bản: TC-11-159 CSDL ngừng
    # Truy vết: FR-11-018 · ERR-11-046 · NFR-11-007, 010
    # Mục đích: Chứng minh CSDL ngừng thì API `503`, phiên đã cam kết còn nguyên, hệ thống tự phục hồi.
    Biết T95; ngừng `pg-core` 2 phút.
    Khi ngừng CSDL, S-DVC `POST /instances`
    Và đọc kiểm tra sẵn sàng
    Và phục hồi, đếm phiên và job
    Thì `503` ERR-11-046; bộ cân bằng tải loại pod khỏi dịch vụ; sau phục hồi job chạy tiếp, phiên đã cam kết còn đủ, không phiên nửa vời.

  @TC-11-160 @P1 @Chịu @lỗi
  Kịch bản: TC-11-160 PH-04 ngừng một giờ
    # Truy vết: FR-11-028, 029 · ERR-11-102 · EVT-11-17 · BR-11-022
    # Mục đích: Chứng minh lệnh chờ trong Kafka, phiên giữ `WAITING_SERVICE`, xử lý đúng khi PH-04 hồi phục.
    Biết T95; `ph04-sim` ngừng 60 phút; 100 phiên đến `guiTuPhap`.
    Khi ngừng `ph04-sim`
    Và chạy 100 phiên tới bước tự động
    Và đợi qua `timeoutAt` của 20 phiên
    Và phục hồi `ph04-sim`
    Thì lệnh tồn trong Kafka; phiên `WAITING_SERVICE`; 20 phiên quá hạn mở sự cố ERR-11-102; sau phục hồi kết quả tương quan đúng, không lệnh trùng.

  @TC-11-161 @P2 @Chịu @lỗi
  Kịch bản: TC-11-161 PH-12 ngừng
    # Truy vết: FR-11-034, 035 · ERR-11-113 · NFR-11-020
    # Mục đích: Chứng minh việc không mất khi PH-12 ngừng và xác thực vẫn đúng trong thời hạn đệm khóa.
    Biết T95; PH-12 giả ngừng; token còn hạn.
    Khi tạo việc `ORG_UNIT` khi PH-12 ngừng
    Và gọi API bằng token còn hạn
    Và phục hồi PH-12
    Thì việc vào `11.task.fallbackGroup` kèm ERR-11-113; API vẫn xác thực được bằng khóa đã đệm; sau phục hồi việc được giao lại đúng ứng viên.
