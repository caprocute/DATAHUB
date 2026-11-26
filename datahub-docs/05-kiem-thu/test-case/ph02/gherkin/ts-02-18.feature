# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-18
Tính năng: TS-02-18 · Tạm ngừng, tiếp tục, thu hồi, hủy, gia hạn đăng ký

  @TC-02-058 @P1 @Dương @Âm
  Kịch bản: TC-02-058 Tạm ngừng, tiếp tục, thu hồi, hủy: quyền, lý do và hiệu lực gateway
    # Truy vết: FR-02-051 · API-02-061, 062, 063, 064 · UI-02-08 · UC-02-27 · BR-02-028, 034 · ERR-02-041, 014, 011 · EVT-02-11 · GW: gỡ consumer · KT: có (subscription.revoke).
    Biết SUB-ACTIVE; U-T68-SO, U-T68-OR1, U-T68-CA.
    Khi U-T68-SO `:suspend` kèm lý do; thiếu lý do; `:resume`.
    Và U-T68-CA `:revoke`; OR1 `:cancel` đăng ký đã thu hồi.
    Và OR1 `:cancel` đăng ký `ACTIVE` khác.
    Thì `200` kèm GW gỡ rồi nạp consumer; thiếu lý do `400` ERR-02-041; thu hồi `REVOKED` ≤ 30 giây, hủy lại `409` ERR-02-011; hủy `CANCELLED`, EVT: `subscription.state-changed`.

  @TC-02-059 @P3 @Dương @Biên
  Kịch bản: TC-02-059 Gia hạn và rà soát định kỳ: quá hạn thành `EXPIRED`
    # Truy vết: FR-02-052 · API-02-065, 066 · UC-02-28 · BR-02-012 · ERR-02-011.
    Biết `02.subscription.review-months` = 12, đẩy đồng hồ 12 tháng (Đợt 2).
    Khi `:renew` kèm mục đích mới; `:confirm-review`.
    Và không làm gì quá hạn thêm 30 ngày.
    Thì gia hạn cập nhật hạn; không phản hồi thì `EXPIRED`, gỡ consumer; `:renew` đăng ký `REVOKED` `409` ERR-02-011.

  @TC-02-129 @P1 @Âm
  Kịch bản: TC-02-129 Vòng đời đăng ký: sai quyền, sai trạng thái, thiếu lý do
    # Truy vết: FR-02-051 · API-02-061, 062, 063, 064 · UI-02-08 · UC-02-27 · BR-02-028, 034 · ERR-02-014, 011, 041.
    Biết SUB-ACTIVE; đăng ký `REVOKED`; đăng ký `CANCELLED`; U-T68-OR1, U-T68-SV1, U-T68-CA, U-T68-SO.
    Khi OR1 `:revoke` SUB-ACTIVE.
    Và U-T68-TO `:suspend` SUB-ACTIVE không lý do.
    Và CA `:resume` đăng ký `ACTIVE`; OR1 `:cancel` đăng ký `REVOKED`; SO `:resume` đăng ký `CANCELLED`.
    Và SV1 `:cancel` thay cho OR1.
    Thì bước 1: `403` ERR-02-014 (thu hồi cần `PERM-02-approve-subscription`). Bước 2: `400` ERR-02-041. Bước 3: `409` ERR-02-011 cả ba. Bước 4: `403`. SUB-ACTIVE không đổi trạng thái.

  @TC-02-130 @P2 @Âm @Biên
  Kịch bản: TC-02-130 Gia hạn và rà soát: sai trạng thái, sai quyền, hạn rà soát
    # Truy vết: FR-02-052 · API-02-065, 066 · UI-02-08 · UC-02-28 · BR-02-012, 026 · ERR-02-011, 014, 029.
    Biết SUB-ACTIVE sắp tới hạn rà soát (`02.subscription.review-months`); đăng ký `CANCELLED`; U-T68-OR1, U-T68-VW; đồng hồ giả.
    Khi OR1 `:renew` đăng ký `CANCELLED`.
    Và U-T68-VW `:confirm-review`; OR1 `:confirm-review`.
    Và OR1 `:renew` SUB-ACTIVE thiếu mục đích cập nhật.
    Và tới hạn rà soát không ai xác nhận: chạy bộ rà soát; rồi OR1 gia hạn đúng.
    Thì bước 1: `409` ERR-02-011. Bước 2: `403` ERR-02-014 cả hai. Bước 3: `422` ERR-02-029. Bước 4: quá hạn rà soát chuyển `EXPIRED` và thu hồi phạm vi; gia hạn đúng khi còn hiệu lực giữ `ACTIVE`.
