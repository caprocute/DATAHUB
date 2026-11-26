# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-29
Tính năng: TS-13-29 · Luật phát hiện UC-SEC

  @TC-13-082 @P1 @Dương
  Kịch bản: TC-13-082 Tinh chỉnh ngưỡng trong biên có lý do
    # Truy vết: FR-13-051 · UC-13-33 · API-13-054, 055 · UI-13-15 · BR-13-025 · EVT-13-10
    Biết U-T68-SO xác thực lại; luật đăng nhập thất bại ngưỡng mặc định 5.
    Khi `GET /detection-rules`; nới ngưỡng thành 8; siết thành 3.
    Thì `200`; KT: có (`OBS.DETRULE.TUNE`) kèm `reason`; EVT: `rule.changed`.

  @TC-13-083 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-083 Nới quá 2 lần, tắt luật Nghiêm trọng, thiếu lý do
    # Truy vết: FR-13-051 · API-13-055 · ERR-13-024, 008, 028, 009 · BR-13-025
    Biết U-T68-SO; U-T68-TO.
    Khi nới ngưỡng 11 (hơn 2 lần mặc định 5).
    Và tắt luật Nghiêm trọng kiểu "mọi sự kiện".
    Và sửa không lý do; phiên chưa xác thực lại; U-T68-TO sửa.
    Thì ERR-13-024; ERR-13-024; ERR-13-008; ERR-13-028; 403-PQ.
