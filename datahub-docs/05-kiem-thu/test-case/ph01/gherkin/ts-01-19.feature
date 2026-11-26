# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-19
Tính năng: TS-01-19 · Danh sách, thu hồi, nhắc hạn, tự vô hiệu định danh

  @TC-01-073 @P1 @Dương @Âm @Bảomật
  Kịch bản: TC-01-073 Danh sách, chi tiết định danh: không bí mật, tenant khác ẩn
    # Truy vết: FR-01-028 · UC-01-19 · API-01-049, 050 · UI-01-04, 08 · BR-01-007 · ERR-01-001.
    Biết U-T68-TA1; U-T68-OR2; U-T01-TA; định danh của `HT-QLVB`.
    Khi TA1 `GET /systems/HT-QLVB/credentials`; `GET /credentials/{id}`.
    Và OR2 gọi chi tiết định danh của `HT-QLVB`; U-T01-TA gọi cùng id.
    Thì bước 1: có loại, trạng thái, hạn, vân tay, `secret_ref` dạng ẩn; không có giá trị bí mật. Bước 2: `404-ẩn`. Mồi sạch.

  @TC-01-074 @P1 @Dương @Âm
  Kịch bản: TC-01-074 Thu hồi định danh, hiệu lực trong 60 giây
    # Truy vết: FR-01-026 · UC-01-19 · API-01-047 · UI-01-11 · BR-01-009, 023 · ERR-01-030, 033, 034, 035 · EVT-01-07 · NFR-01-008.
    Biết định danh `ACTIVE` của `HT-DVC`; TA1 có MFA mới; giả lập PH-03 đo thời gian.
    Khi `POST /credentials/{id}:revoke` kèm lý do.
    Và gọi API cổng bằng định danh đó mỗi giây.
    Và thu hồi lần hai; thu hồi thiếu lý do; thiếu MFA.
    Thì bước 1: `200`, `REVOKED`; cổng từ chối trong ≤ 60 giây kể từ lệnh (chặn ở cổng trước, gọi PH-12 và PH-03 sau, thử lại tới khi xong). EVT: `EVT-01-07` một lần. Bước 3: `409` ERR-01-030; `400` ERR-01-033; `403` ERR-01-035. KT: có.

  @TC-01-075 @P1 @Biên @Âm
  Kịch bản: TC-01-075 Nhắc hạn 30, 14, 7 ngày và tự hết hạn
    # Truy vết: FR-01-027 · UC-01-19 · API-01-048 · BR-01-020 · EVT-01-07, 08.
    Biết định danh chuỗi bí mật hạn 31 ngày; `credential.expiryReminderDays = [30,14,7]`; đồng hồ giả.
    Khi chạy tác vụ hằng ngày ở các ngày còn 30, 14, 7, 0; `GET /credentials:expiring`.
    Và chạy cùng tác vụ với một định danh đã `REVOKED` và một định danh đã `EXPIRED`; dùng định danh hết hạn gọi cổng.
    Thì mỗi mốc đúng một `EVT-01-08` và thư nhắc tới đầu mối kỹ thuật, TA; sang ngày hết hạn: `EXPIRED`, `EVT-01-07`, cổng từ chối. Định danh đã thu hồi, đã hết hạn không bị nhắc lại, không phát sự kiện thứ hai; định danh hết hạn gọi cổng bị `401`. Định danh tạo mới có hạn ≤ 365 ngày, chuỗi bí mật ≤ 180 ngày.

  @TC-01-076 @P3 @Dương @Âm
  Kịch bản: TC-01-076 Tự vô hiệu định danh không dùng 90 ngày, bật lại (Đợt 2)
    # Truy vết: FR-01-036 · UC-01-25 · API-01-061 · UI-01-04 · BR-01-022 · ERR-01-030 · EVT-01-07.
    Biết định danh PRODUCTION `tc-ngu`; PH-13 trả 0 lượt gọi trong 90 ngày; `inactivity.autoSuspendDays = 90`.
    Khi chạy tác vụ ngày thứ 91; xem nhãn ở UI-01-04.
    Và TA1 `POST /credentials/{id}:enable`; gọi `:enable` lần hai.
    Thì bước 1: vô hiệu với `reversible = true`, `EVT-01-07`. Bước 2: lần một `200`, lần hai `409` ERR-01-030.
