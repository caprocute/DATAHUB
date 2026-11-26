# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-22
Tính năng: TS-01-22 · Thu hồi, tạm ngừng khẩn cấp bởi Cán bộ ATTT

  @TC-01-086 @P1 @Dương @Bảomật
  Kịch bản: TC-01-086 SO tạm ngừng khẩn, TA xác nhận
    # Truy vết: FR-01-032 · UC-01-22 · API-01-054, 055 · UI-01-11 · BR-01-010, 023 · EVT-01-15, 03, 07 · NFR-01-008.
    Biết `HT-DVC` ACTIVE đang gọi API; U-T68-SO có MFA mới; TA1.
    Khi SO `POST /systems/HT-DVC:emergency-action` với `mode = SUSPEND`, lý do, `incidentRef`.
    Và đo thời gian cổng từ chối.
    Và TA1 `POST /emergency-actions/{actionId}:confirm`.
    Thì bước 1: `200` ngay, không chờ TA; `SUSPENDED` lý do `SECURITY_SUSPECT`. Bước 2: ≤ 60 giây. Bước 3: `200`, ghi nhận xác nhận. EVT: `EVT-01-15` hai lần (thực hiện, xác nhận), `EVT-01-03`, `EVT-01-07`. KT: có.

  @TC-01-087 @P1 @Âm
  Kịch bản: TC-01-087 Thao tác khẩn sai điều kiện
    # Truy vết: FR-01-032 · API-01-054, 055 · ERR-01-033, 035, 036.
    Biết `HT-DVC`; thao tác khẩn đã xác nhận; U-T68-SO, TA1, OR1.
    Khi SO gọi không lý do; rồi thiếu MFA mới.
    Và TA1 xác nhận lần hai thao tác đã xử lý.
    Và OR1 gọi `:emergency-action`.
    Thì `400` ERR-01-033; `403` ERR-01-035; `409` ERR-01-036; `403-PQ`.

  @TC-01-088 @P2 @Biên
  Kịch bản: TC-01-088 Quá 24 giờ chưa xác nhận: cảnh báo, không hoàn tác
    # Truy vết: FR-01-032 · BR-01-010 · EVT-01-15.
    Biết thao tác khẩn chưa xác nhận; `emergency.confirmHours = 24`; đồng hồ giả.
    Khi tua 25 giờ; chạy tác vụ.
    Thì `EVT-01-15` loại "quá hạn", cảnh báo mức cao tới TA, PO; HTTT vẫn `SUSPENDED`, không tự khôi phục.
