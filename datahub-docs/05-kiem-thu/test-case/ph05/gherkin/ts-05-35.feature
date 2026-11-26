# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-35
Tính năng: TS-05-35 · Chịu lỗi và phục hồi

  @TC-05-140 @P1 @Khả @dụng
  Kịch bản: TC-05-140 Outbox không mất sự kiện khi Kafka mất
    # Truy vết: FR-05-007, 021 · EVT-05-01, 06
    Biết U-T68-IA1; Kafka dừng 10 phút.
    Thì API trả `200` (sự kiện ở outbox); sau khi Kafka có lại, đúng 5 bản tin `connection.enabled`, đúng thứ tự theo khóa; outbox sạch.

  @TC-05-141 @P2 @Khả @dụng
  Kịch bản: TC-05-141 Kafka mất làm CDC tự tạm dừng và tự tiếp tục
    # Truy vết: FR-05-050 · EVT-05-12 · NFR-05-010
    Biết CDC `STREAMING`.
    Thì CDC `PAUSED`, banner ở UI-05-12; có lại thì `STREAMING`, không mất thay đổi; WAL giữ lại ở nguồn hiện trên thẻ chỉ số.

  @TC-05-142 @P3 @Khả @dụng
  Kịch bản: TC-05-142 PH-10 hoặc PH-01 mất khi khai báo
    # Truy vết: FR-05-004, 048 · ERR-05-029
    Biết U-T68-IE1; PH-01 dừng.
    Thì `503` ERR-05-029 có `retryAfterSeconds`; không có kết nối nửa vời trong CSDL.
