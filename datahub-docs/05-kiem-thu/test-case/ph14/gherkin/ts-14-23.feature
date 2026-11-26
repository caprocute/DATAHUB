# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-23
Tính năng: TS-14-23 · Ngắt mạch và thử lại

  @TC-14-058 @P1 @Dương @Âm @Biên
  Kịch bản: TC-14-058 Mở, thăm dò, đóng ngắt mạch
    # Truy vết: FR-14-038 · UC-14-25 · UI-14-01 · ERR-14-103 · BR-14-031 · NFR-14-009.
    Biết `14.breaker.min-calls = 20`, `failure-ratio = 0,5`, `open-seconds = 30`; `sim-ndxp` `ERR5XX`.
    Khi gọi 20 lượt lỗi liên tiếp.
    Và gọi tiếp khi ngắt mạch mở.
    Và sau 30 giây đặt `OK`, gọi.
    Thì ngắt mạch mở; lượt tiếp theo trả ≤ 1 giây `503` ERR-14-103 hoặc dữ liệu đệm quá hạn; thăm dò thành công thì đóng; UI-14-01 hiển thị trạng thái.

  @TC-14-059 @P2 @Dương @Biên
  Kịch bản: TC-14-059 Ép ngắt mạch tay; thử lại đọc, không thử lại ghi
    # Truy vết: FR-14-038 · API-14-086, 075 · BR-14-030, 031 · ERR-14-004, 103.
    Biết U-T68-TO; `14.retry.max-attempts = 2`; `sim-ndxp` lỗi 503 hai lần rồi `OK`.
    Khi gọi thao tác đọc; đếm số lần gửi.
    Và gọi thao tác ghi, cùng điều kiện.
    Và `POST /platforms/ndxp/breaker:set` `OPEN` kèm lý do rồi `CLOSED`.
    Thì đọc thành công sau tối đa 3 lần gửi; ghi chỉ gửi một lần; ép `OPEN` có hiệu lực ≤ 30 giây; đặt trạng thái không đổi trả `409` ERR-14-004.

  @TC-14-126 @P1 @Âm @Biên
  Kịch bản: TC-14-126 Ngắt mạch: ngoài đệm và dự phòng, thử lại bị chặn, ép tay thiếu lý do
    # Truy vết: FR-14-038 · API-14-086, 075 · ERR-14-003, 103, 104 · BR-14-030, 031 · NFR-14-009 · EVT-14-10.
    Biết U-T68-TO, S-HT-MC; V-LLTP (không đệm, không dự phòng), V-HT-DK (ghi không idempotent); `14.breaker.min-calls = 20`, `14.breaker.failure-ratio = 0,5`, `14.retry.max-attempts = 2`; `sim-ndxp` `ERR5XX`; mức dùng hạn mức ở bước 4 là 95 %.
    Khi gọi V-LLTP 19 lượt lỗi rồi 1 lượt nữa; ngay sau đó gọi lượt tiếp theo.
    Và gọi V-HT-DK thao tác ghi không idempotent khi `sim-ndxp` `ERR5XX`; đếm số lần gửi.
    Và `POST /platforms/ndxp/breaker:set` đặt `OPEN` không có `reason`.
    Và khi mức dùng 95 %, gọi V-HT thao tác đọc gặp lỗi có thể thử lại.
    Thì bước 1 sau lượt thứ 20 ngắt mạch `OPEN`, lượt kế tiếp `503` ERR-14-103 "Nền tảng quốc gia tạm thời không phản hồi. Hệ thống sẽ thử lại tự động, hãy gọi lại sau ít phút." tức thì, không gọi ra; phát EVT-14-10. Bước 2 gửi đúng một lần, không thử lại. Bước 3 `400` ERR-14-003. Bước 4 lượt thử lại bị bỏ qua vì mức dùng đã chạm ngưỡng chỉ dành cho dịch vụ thiết yếu, không tiêu thêm hạn mức; mỗi lần thử lại hợp lệ ở các ca khác đều bị tính một lượt.
