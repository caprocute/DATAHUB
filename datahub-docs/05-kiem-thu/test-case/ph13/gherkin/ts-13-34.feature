# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-34
Tính năng: TS-13-34 · Tham số và hạn mức quan sát theo tenant

  @TC-13-095 @P2 @Dương
  Kịch bản: TC-13-095 Đổi tham số trong biên có hiệu lực ≤ 60 giây
    # Truy vết: FR-13-061 · UC-13-42 · API-13-070, 071 · UI-13-17 · NFR-13-019, 030
    Biết U-T68-TA.
    Khi `PATCH /settings` đặt `13.alert.silence-max-days = 3`, `13.audit.worm-retention-years = 7`.
    Thì `200`; tạm ẩn quá 3 ngày bị từ chối sau ≤ 60 giây; lô WORM mới có thời hạn 7 năm, lô cũ không rút ngắn; KT: có kèm `reason`.

  @TC-13-096 @P2 @Âm @Biên
  Kịch bản: TC-13-096 Hạn mức vượt trần, tham số ngoài miền, thiếu lý do
    # Truy vết: FR-13-061 · API-13-071 · ERR-13-041, 040, 007, 008, 009
    Biết U-T68-TA; U-T68-TO.
    Khi đặt `13.series.max-active = 3.000.000`.
    Và đặt `13.alert.escalate-minutes = 2`; không `reason`.
    Và U-T68-TO sửa.
    Thì `422` ERR-13-041; ERR-13-040; ERR-13-008; 403-PQ; không giá trị nào được lưu.

  @TC-13-126 @P2 @Âm @Biên
  Kịch bản: TC-13-126 Dữ liệu vào sai kiểu và `size` quá giới hạn ở API danh sách, tạo mới
    # Truy vết: API-13-030, 036, 035 · ERR-13-003, 038 · FR-13-042, 047
    Biết U-T68-TA.
    Khi `GET /alerts?size=201`.
    Và `POST /alert-rules` với `severity = BAT_KY`.
    Thì `400` ERR-13-038; `400` ERR-13-003 với `errors[]` nêu `path = severity`, thông điệp "Trường `severity` phải là một trong CRITICAL, WARNING, INFO."
