# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-16
Tính năng: TS-12-16 · Yếu tố thứ hai và xác thực lại bước lên

  @TC-12-051 @P1 @Dương @Âm
  Kịch bản: TC-12-051 Đăng ký TOTP và WebAuthn, quản trị chỉ nhận WebAuthn
    # Truy vết: FR-12-022 · UC-12-17 · UI-12-18, UI-12-02 · BR-12-015 · LGC-IAM-003 · SEC-23
    Biết U-T68-NEW (nhóm `mfa-required`); U-T68-TA1 mới.
    Khi người thường đăng ký TOTP; nhập mã sai, rồi đúng.
    Và TA1 thử đăng ký TOTP; sau đó đăng ký WebAuthn ảo.
    Thì TOTP đúng mới kích hoạt; mã sai ERR-12-111; quản trị bị từ chối TOTP, chỉ WebAuthn được nhận; UI-12-02 hiện loại yếu tố, không hiện bí mật.

  @TC-12-052 @P1 @Dương @Âm
  Kịch bản: TC-12-052 Bước lên khi lần xác thực cuối quá 5 phút
    # Truy vết: FR-12-023 · UC-12-17 · UI-12-18 · API-12-073, 074 · BR-12-016 · ERR-12-120
    Biết U-T68-TA1 đăng nhập 6 phút trước; thao tác `:revoke-access`.
    Khi gọi thao tác nhạy cảm bằng token cũ.
    Và xác thực lại bằng WebAuthn; gọi lại.
    Thì bước 1 `401` ERR-12-120 (`insufficient_user_authentication`); bước 2 thành công; mức yêu cầu lấy từ OPA, đổi chính sách thì đổi mức mà không sửa mã.
