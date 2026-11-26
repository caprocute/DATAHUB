# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-29
Tính năng: TS-11-29 · Bền trạng thái, sống sót khởi động lại, mất một bản sao

  @TC-11-146 @P1 @Chịu @lỗi
  Kịch bản: TC-11-146 Tắt cứng pod ngay sau hoàn thành bước
    # Truy vết: NFR-11-011 · FR-11-038, 028 · BR-11-023
    # Mục đích: Chứng minh chuyển bước đã trả thành công đều có trong CSDL, phiên tiếp tục đúng bước ở bản sao khác.
    Biết PERF 4 bản sao; 100 phiên `LT_KHAI_SINH` đang chạy; `kubectl delete pod --grace-period=0`.
    Khi CB hoàn thành 100 việc, ngay khi nhận `200` tắt cứng pod phục vụ
    Và đợi bản sao khác nhận
    Và so `current_elements` và lệnh PH-04 đã gửi với danh sách mong đợi
    Thì 100 % bước đã trả `200` có trong CSDL; không bước nào chạy lại; không lệnh PH-04 trùng; không phiên mất.

  @TC-11-147 @P1 @Chịu @lỗi
  Kịch bản: TC-11-147 Mất một bản sao đang giữ khóa job, mở rộng ngang
    # Truy vết: NFR-11-008, 009 · FR-11-031, 047 · BR-11-022
    # Mục đích: Chứng minh job được bản khác nhận trong 5 phút, chạy một lần; mở rộng 2 đến 6 bản sao không xử lý trùng.
    Biết PERF 4 bản sao; 2.000 job hẹn giờ đến hạn; một pod giữ khóa 200 job.
    Khi tắt cứng pod giữ khóa
    Và đo thời gian đến khi 200 job được nhận
    Và tăng từ 2 lên 6 bản sao khi hàng đợi job sâu
    Và đếm số lần thực thi từng job
    Thì job được nhận ≤ 5 phút (hết hạn khóa); mỗi job chạy đúng một lần; mở rộng ngang không chạy trùng.

  @TC-11-148 @P1 @Chịu @lỗi
  Kịch bản: TC-11-148 Khởi động lại toàn bộ bản sao với 50.000 phiên
    # Truy vết: NFR-11-012, 005 · FR-11-018, 031 · tiêu chí chấp nhận 4
    # Mục đích: Chứng minh 100 % phiên tiếp tục đúng bước sau khi khởi động lại toàn bộ bản sao.
    Biết T98 `F-PERF`: 50.000 phiên `RUNNING`, 5.000 việc mở, 1.000 hẹn giờ chờ.
    Khi ghi ảnh chụp `waitState`, `current_elements`, việc mở
    Và `kubectl rollout restart` toàn bộ
    Và so ảnh chụp trước và sau
    Và cho CLK qua hạn của 1.000 hẹn giờ
    Thì 100 % phiên giữ đúng bước và `waitState`; 5.000 việc còn nguyên ở hộp việc; 1.000 hẹn giờ nổ đúng giờ một lần.

  @TC-11-149 @P2 @Chịu @lỗi
  Kịch bản: TC-11-149 Phục hồi từ sao lưu
    # Truy vết: NFR-11-010 · BR-11-022, 023
    # Mục đích: Chứng minh RPO ≤ 5 phút, RTO ≤ 30 phút, sau phục hồi không phát lại sự kiện đã gửi.
    Biết PERF `pg-core` có sao lưu liên tục; tải nền 50 phiên/s.
    Khi ghi mốc giao dịch cuối
    Và phá hủy phiên bản chính, phục hồi
    Và đo thời gian và mất mát
    Và quan sát outbox và `inbox_message`
    Thì mất dữ liệu ≤ 5 phút giao dịch; dịch vụ hoạt động lại ≤ 30 phút; không bản tin tiến độ trùng với `id` cũ; job và hẹn giờ tiếp tục.
