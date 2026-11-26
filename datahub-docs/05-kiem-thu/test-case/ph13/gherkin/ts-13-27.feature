# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-27
Tính năng: TS-13-27 · Lịch trực, nhóm nhận, kênh thông báo

  @TC-13-078 @P1 @Dương
  Kịch bản: TC-13-078 Tạo lịch trực, nhóm, kênh và gửi thử
    # Truy vết: FR-13-048 · UC-13-30 · API-13-045, 046, 047, 048, 049, 050, 051 · UI-13-12
    Biết U-T68-TA; F-SIM-CHAN.
    Khi tạo kênh thư điện tử, SMS, webhook; gửi thử từng kênh.
    Và tạo lịch trực 24/7 hai ca; sửa.
    Thì `201`; thử gửi `200`, kênh giả nhận; KT: có.

  @TC-13-079 @P1 @Âm
  Kịch bản: TC-13-079 Lịch hở khoảng, chồng ca, kênh thử thất bại
    # Truy vết: FR-13-048 · API-13-046, 047, 049, 051 · ERR-13-034, 033, 002, 037 · BR-13-022
    Biết U-T68-TA; kênh ngắt.
    Khi lịch thiếu Thứ Bảy 00:00–07:30; lịch hai ca chồng nhau.
    Và nhóm Nghiêm trọng chỉ có một đường.
    Và gửi thử tới kênh ngắt; tạo kênh trùng mã.
    Thì ERR-13-034 nêu khoảng hở (ví dụ "Thứ Bảy 00:00–07:30 chưa có người nhận"); ERR-13-033; ERR-13-002.
