# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-31
Tính năng: TS-13-31 · Đẩy sang SIEM, SOC và báo cáo sự cố

  @TC-13-087 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-087 Đẩy sang SIEM đúng chuẩn, không dữ liệu cá nhân
    # Truy vết: FR-13-054 · UC-13-36 · API-13-061, 062, 063, 064 · UI-13-17 · BR-13-034
    Biết F-SIM-SIEM; F-AUD-PII; U-T68-TA.
    Khi tạo mục tiêu SIEM; gửi thử; phát cảnh báo an ninh và log mồi.
    Thì gửi thử `200`; bản tin ECS có trường chuẩn; không số định danh, thư điện tử, mồi `DH-CANARY`; điểm xuất cho cơ quan chuyên trách tắt mặc định.

  @TC-13-088 @P1 @Âm @Khả @dụng
  Kịch bản: TC-13-088 SIEM ngừng, hàng đợi đĩa và gửi bù; mục tiêu sai
    # Truy vết: FR-13-054 · API-13-062, 063, 064 · ERR-13-122, 039, 002, 037 · BR-13-034
    Biết `13.siem.queue-max-mb = 256`; ngắt F-SIM-SIEM.
    Khi ngắt SIEM; phát log; bật lại.
    Và tạo mục tiêu có địa chỉ không với tới; tạo mục tiêu trùng mã.
    Thì hàng đợi đĩa, đầy thì bỏ bản cũ nhất và cảnh báo (ERR-13-122); sau khi bật gửi bù theo thứ tự; ERR-13-039; ERR-13-002.

  @TC-13-089 @P3 @Dương @Âm
  Kịch bản: TC-13-089 Sinh báo cáo sự cố từ cảnh báo an ninh
    # Truy vết: FR-13-055 · UC-13-37 · API-13-065, 066 · ERR-13-008, 001 · UI-13-15
    Biết cảnh báo an ninh `CLOSED` sự cố thật; U-T68-SO.
    Khi `POST /incident-reports:generate` có lý do, rồi không lý do.
    Và `GET /incident-reports/{reportId}`; id của T01.
    Thì `201` báo cáo có dòng thời gian, hệ thống, phạm vi dữ liệu cá nhân (không giá trị); lần hai ERR-13-008; id T01 404-ẩn.
