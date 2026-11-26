# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-26
Tính năng: TS-13-26 · Xử lý cảnh báo

  @TC-13-076 @P1 @Dương
  Kịch bản: TC-13-076 Xác nhận, tạm ẩn rồi đóng cảnh báo
    # Truy vết: FR-13-047 · UC-13-29 · API-13-031, 032, 033, 034 · UI-13-10 · BR-13-021, 023 · EVT-13-02
    Biết cảnh báo Nghiêm trọng `FIRING`; U-T68-TO.
    Khi xác nhận; tạm ẩn 12 giờ với lý do; đóng với nguyên nhân, hành động, kết quả `FIXED`.
    Thì trạng thái `ACKNOWLEDGED` → `SILENCED` → `RESOLVED` (`MANUAL`); EVT: `alert.resolved`; KT: có từng bước; hết hạn tạm ẩn mà điều kiện còn thì quay về `FIRING`.

  @TC-13-077 @P1 @Âm @Biên
  Kịch bản: TC-13-077 Tạm ẩn quá hạn, đóng thiếu nguyên nhân, thao tác sai trạng thái
    # Truy vết: FR-13-047 · API-13-032, 033, 034 · ERR-13-021, 022, 020, 007, 009 · BR-13-021, 023
    Biết cảnh báo Nghiêm trọng; cảnh báo `RESOLVED`; U-T68-VW.
    Khi tạm ẩn Nghiêm trọng 25 giờ; tạm ẩn thiếu lý do.
    Và đóng không có nguyên nhân.
    Và xác nhận cảnh báo đã `RESOLVED`; U-T68-VW xác nhận.
    Thì ERR-13-021 (`maxDays` nêu 24 giờ); ERR-13-022; `409` ERR-13-020; 403-PQ.
