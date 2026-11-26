# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-17
Tính năng: TS-12-17 · Đặt lại yếu tố thứ hai khi mất thiết bị

  @TC-12-053 @P1 @Dương
  Kịch bản: TC-12-053 Đặt lại yếu tố thứ hai đúng quy trình
    # Truy vết: FR-12-024 · UC-12-18 · UI-12-02, 17 · API-12-015 · BR-12-034 · LGC-IAM-003
    Biết U-T68-VW mất thiết bị; U-T68-TA1; TA2 là người cần đặt lại (quản trị) và U-T68-SO duyệt.
    Khi TA1 `:reset-mfa` cho VW kèm mã xác minh qua điện thoại.
    Và PA đặt lại cho TA2, SO duyệt.
    Thì phiên của người bị đặt lại bị thu; lần đăng nhập kế buộc đăng ký lại; KT: có (user.reset-mfa).

  @TC-12-054 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-054 Đặt lại sai cấp, thiếu xác minh, tự đặt lại
    # Truy vết: FR-12-024 · BR-12-033, BR-12-034 · API-12-015 · ERR-12-017 · ERR-12-014 · ERR-12-013
    Biết U-T68-TA1, U-T68-TA2, U-T68-VW.
    Khi TA1 đặt lại cho TA2 (cùng cấp).
    Và TA1 đặt lại cho VW không có thông tin xác minh.
    Và TA1 đặt lại cho chính mình.
    Thì bước 1 `403` ERR-12-017; bước 2 `400` ERR-12-014; bước 3 `403` ERR-12-013.
