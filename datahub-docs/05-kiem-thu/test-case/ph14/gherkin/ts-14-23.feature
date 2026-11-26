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
