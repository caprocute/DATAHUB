# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-19
Tính năng: TS-13-19 · Data plane: đơn vị triển khai, luồng, route, endpoint

  @TC-13-058 @P1 @Dương
  Kịch bản: TC-13-058 Đơn vị triển khai, luồng, route và thống kê endpoint
    # Truy vết: FR-13-032, 033, 034 · UC-13-21 · API-13-003, 004, 005, 006, 007, 008 · UI-13-02 · LGC-BUS-007, 015, 016, 017, 019, 027
    Biết F-DU-SIM; luồng `luong-chung` chạy 100 bản tin/phút; U-T68-TO.
    Khi mở UI-13-02; xem histogram bản tin thành công và thất bại, đồ thị CPU, bộ nhớ của đơn vị triển khai.
    Và bấm luồng, bấm route; mở thống kê endpoint 24 giờ.
    Thì số liệu khớp bộ phát; có thời gian trung bình, lỗi, bản tin gần nhất, API gọi nhiều nhất; chỉ luồng của T68.

  @TC-13-059 @P2 @Âm @Biên
  Kịch bản: TC-13-059 Luồng không có dữ liệu, khoảng thống kê quá hạn
    # Truy vết: FR-13-032, 033, 034 · API-13-004, 006, 007, 008 · ERR-13-001, 005 · BR-13-016
    Biết luồng mới chưa chạy; luồng của T01.
    Khi gọi `GET /deployments/khong-co`; gọi chỉ số luồng mới; luồng `luong-chung` của T01 qua token T68.
    Và thống kê endpoint 32 ngày.
    Thì luồng mới trả `200` với "Chưa có dữ liệu"; luồng T01 404-ẩn; ERR-13-005 (`maxDays = 31`).
