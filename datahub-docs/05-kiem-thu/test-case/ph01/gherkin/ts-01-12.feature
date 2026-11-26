# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-12
Tính năng: TS-01-12 · Phê duyệt hoặc từ chối kết nạp

  @TC-01-049 @P1 @Dương
  Kịch bản: TC-01-049 Phê duyệt bởi TA không liên quan, trần bằng phạm vi duyệt
    # Truy vết: FR-01-018 · UC-01-12 · API-01-032 · UI-01-07 · BR-01-003, 017, 031 · EVT-01-02, 03, 11.
    Biết `HT-HOTICH-OK`; người lập OR1, người nộp OR1, người thẩm định gồm IE, SO, TA2; U-T68-TA1 (khác tất cả); phạm vi bước pháp lý đã thu hẹp.
    Khi TA1 xác thực lại MFA; mở UI-01-07; `POST …:approve` kèm lý do.
    Và `GET …/data-demands`.
    Thì `200`, `APPROVED`, `provisionStage = PROVISIONING`; trần phạm vi bằng đúng phạm vi được chấp thuận, không có phạm vi bị từ chối. EVT: `EVT-01-02`, `EVT-01-03`, `EVT-01-11`, cùng giao dịch. KT: có.

  @TC-01-050 @P1 @Âm @Bảomật
  Kịch bản: TC-01-050 Bốn mắt, MFA, thiếu lý do, thiếu kết luận
    # Truy vết: FR-01-018 · API-01-032, 033 · BR-01-009, 017 · ERR-01-017, 020, 033, 035.
    Biết `HT-HOTICH-OK`; `HT-HOTICH-SS`; U-T68-TA2 (đã thẩm định), U-T68-X1, U-T68-TA1.
    Khi TA2 `:approve` (đã thẩm định bước pháp lý).
    Và X1 (người lập) `:approve`.
    Và TA1 `:approve` khi phiên chưa có MFA mới.
    Và TA1 (MFA mới) `:reject` không lý do.
    Và TA1 (MFA mới) `:approve` `HT-HOTICH-SS` (còn bước chưa xong).
    Thì `403` ERR-01-017; `403` ERR-01-017; `403` ERR-01-035; `400` ERR-01-033; `409` ERR-01-020. Trạng thái hồ sơ không đổi sau mọi lần lỗi.

  @TC-01-051 @P2 @Dương
  Kịch bản: TC-01-051 Từ chối kết nạp, mã vẫn giữ
    # Truy vết: FR-01-018 · API-01-033 · UI-01-07 · BR-01-011, 018 · EVT-01-03.
    Biết `HT-HOTICH-OK` bản sao `tc-rj`; TA1 có MFA mới.
    Khi `:reject` kèm lý do; tạo lại hồ sơ cùng mã.
    Thì `REJECTED`, hồ sơ và bước thẩm định được giữ; thông báo cho người nộp; tạo lại mã `409` ERR-01-002. EVT: `EVT-01-03`.
