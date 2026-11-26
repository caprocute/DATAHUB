# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-34
Tính năng: TS-08-34 · Tái lập, chịu lỗi và giao sự kiện

  @TC-08-149 @P1 @Dương
  Kịch bản: TC-08-149 Tái lập điểm và mẫu
    # Truy vết: NFR-08-007 · NFR-08-008 · FR-08-028 · BR-08-019
    Biết dữ liệu đóng băng F-SCORE; cùng phiên bản quy tắc và cấu hình trọng số.
    Khi đo `FULL` hai lần liên tiếp
    Và đo `SAMPLE` seed 7 hai lần
    Và so điểm và tập `recordKey`
    Thì điểm chênh ≤ 0,01; tập `recordKey` mẫu giống hệt.

  @TC-08-150 @P1 @Chịu @lỗi
  Kịch bản: TC-08-150 Mất pod, mất Kafka, lịch không chạy trùng
    # Truy vết: NFR-08-009 · NFR-08-018 · NFR-08-015 · FR-08-023 · FR-08-026 · EVT-08-02
    Biết T95; `dh-data` 2 bản sao; lần đo 200.000 bản ghi đang `RUNNING`.
    Khi xóa pod đang chạy tác vụ
    Và dừng Kafka 10 phút rồi bật lại
    Và để hai bản sao cùng chạm giờ lịch 02:00
    Và đo `dq_outbox_lag_seconds`
    Thì tác vụ tiếp tục từ chỗ dừng, không đo hai lần cùng khóa; sự kiện không mất, giao ít nhất một lần, consumer xử lý idempotent, trễ p95 ≤ 5 giây khi Kafka bình thường; lịch chỉ bắn một lần (ShedLock); API sẵn sàng ≥ 99,5 % trong tháng thử.
