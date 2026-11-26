# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-17
Tính năng: TS-01-17 · Kích hoạt môi trường thật (PRODUCTION)

  @TC-01-067 @P1 @Dương
  Kịch bản: TC-01-067 Kích hoạt hợp lệ
    # Truy vết: FR-01-024 · UC-01-17 · API-01-044 · UI-01-10 · BR-01-003, 008, 017 · EVT-01-03, 05.
    Biết `HT-HOTICH-SB` (kiểm thử đạt, có đầu mối kỹ thuật); người nộp OR1; U-T68-TA2 có MFA mới.
    Khi TA2 `POST /systems/HT-HOTICH-SB:activate`.
    Và `GET …/credentials`; `GET /internal/systems/HT-HOTICH-SB` bằng S-INT.
    Thì `200` hoặc `202`; `ACTIVE`; có định danh PRODUCTION không có scope dữ liệu (scope chỉ phát sinh sau đăng ký sử dụng ở PH-02); PH-10, PH-03 nhận `EVT-01-03`, `EVT-01-05`. KT: có.

  @TC-01-068 @P1 @Âm @Bảomật
  Kịch bản: TC-01-068 Kích hoạt khi chưa đủ điều kiện hoặc sai người
    # Truy vết: FR-01-024 · API-01-044 · BR-01-008, 013, 017, 026 · ERR-01-017, 021, 031, 032, 035.
    Biết `HT-HOTICH-AP` (chưa kiểm thử đạt); `HT-HOTICH-SB` có hai biến thể: thiếu đầu mối kỹ thuật, cấp độ hạ xuống `L2`; U-T68-X1 là người nộp.
    Khi TA2 kích hoạt `HT-HOTICH-AP`.
    Và TA2 kích hoạt biến thể thiếu đầu mối; biến thể cấp độ thấp.
    Và X1 (người nộp) kích hoạt.
    Và TA2 kích hoạt khi phiên chưa có MFA mới.
    Và PH-12 `fail`; TA2 kích hoạt.
    Thì `422` ERR-01-031; `422` ERR-01-032 (danh sách điều kiện thiếu); `403` ERR-01-017; `403` ERR-01-035; `503` ERR-01-021 và HTTT giữ `APPROVED`.

  @TC-01-069 @P2 @Biên
  Kịch bản: TC-01-069 HTTT chỉ cung cấp API (PROVIDER)
    # Truy vết: FR-01-024 · UC-01-17 · API-01-044 · BR-01-003.
    Biết `tc-provider` vai trò `PROVIDER`, đã kiểm thử đạt.
    Khi TA2 kích hoạt.
    Thì `ACTIVE` với scope dữ liệu rỗng để PH-02 công bố API của HTTT.
