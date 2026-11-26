# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-32
Tính năng: TS-11-32 · Nhất quán giao dịch, outbox và Saga

  @TC-11-157 @P1 @Chịu @lỗi
  Kịch bản: TC-11-157 Chèn lỗi ở mọi điểm của giao dịch chuyển bước
    # Truy vết: BR-11-023 · FR-11-056, 038, 018 · EVT-11-04, 10 · NFR-11-011
    # Mục đích: Chứng minh không có bản tin mà trạng thái chưa cam kết và không có trạng thái cam kết mà thiếu bản tin.
    Biết bộ chèn lỗi ngẫu nhiên 1.000 lần ở điểm: trước ghi biến, sau engine, sau ghi `instance_index`, trước `commit`; T97.
    Khi chạy 1.000 lần hoàn thành việc có chèn lỗi ngẫu nhiên
    Và với mỗi lần so trạng thái `task_index`, `instance_index`, `outbox_event` và bản tin Kafka
    Thì mọi lần: `task_index`, `instance_index`, `outbox_event` cùng một giao dịch `ph11_bpm` (cùng đổi hoặc không đổi); lỗi sau cam kết engine được đối soát dựng lại, đúng một bản tin; 0 bản tin cho thay đổi chưa cam kết.

  @TC-11-158 @P1 @Hiệu @năng
  Kịch bản: TC-11-158 Khởi động bù trừ và không giao dịch phân tán
    # Truy vết: NFR-11-017 · BR-11-010, 011 · FR-11-051 · EVT-11-13
    # Mục đích: Chứng minh Saga bắt đầu ≤ 30 giây sau lỗi bước (p95) và cấu hình không dùng giao dịch XA, theo ADR 113.
    Biết T97; 100 phiên cùng lỗi `capTheBHYT`; cấu hình nguồn dữ liệu và Flowable.
    Khi gây lỗi 100 phiên đồng thời
    Và đo `saga_log.startedAt` trừ thời điểm nhận lỗi
    Và kiểm cấu hình không có `XADataSource`, không `JTA`
    Thì p95 ≤ 30 giây; không có thành phần giao dịch phân tán; nhất quán đạt bằng bù trừ.
