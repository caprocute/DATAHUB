# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-14
Tính năng: TS-12-14 · Đăng nhập OIDC Authorization Code với PKCE

  @TC-12-045 @P1 @Dương
  Kịch bản: TC-12-045 Đăng nhập PKCE, userinfo, đăng xuất
    # Truy vết: FR-12-020 · UC-12-16 · UI-12-18 · API-12-072, 073, 074, 075, 076, 078 · LGC-IAM-001 · NFR-12-007
    Biết U-T68-TA1 (WebAuthn ảo); client `dh-console` ở realm `dh-t68`.
    Khi `GET …/openid-configuration`; chạy luồng auth với `code_challenge` S256.
    Và đổi code lấy token; gọi `userinfo`; `logout`.
    Thì có `access_token` ≤ 5 phút, `refresh_token`, claim `tenant` đúng; sau logout token dùng được tới hết hạn nhưng phiên bị đóng và refresh bị từ chối; p95 đăng nhập ≤ 2 giây; SK: `auth.login`.

  @TC-12-046 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-046 PKCE sai, grant bị cấm, token sai đối tượng
    # Truy vết: FR-12-020 · BR-12-021 · API-12-073, 074, 077 · ERR-12-114, ERR-12-122, ERR-12-116 · LGC-IAM-006
    Biết C-T68-B; U-T68-VW.
    Khi đổi code với `code_verifier` sai; dùng lại `code`; `redirect_uri` lạ.
    Và `grant_type=password`; `response_type=token`.
    Và dùng token hết hạn, token của realm T01 ở API T68.
    Thì bước 1 ERR-12-114; bước 2 ERR-12-122 (`unsupported_grant_type`); bước 3 ERR-12-116 (401); không có đường lấy token bằng mật khẩu.

  @TC-12-047 @P1 @Âm
  Kịch bản: TC-12-047 Realm của tenant tạm ngừng không cấp token
    # Truy vết: FR-12-020, FR-12-043 · API-12-073, 074 · ERR-12-121
    Biết T90 realm `SUSPENDED`; một người dùng T90.
    Khi đăng nhập và `client_credentials` ở T90.
    Thì `403` ERR-12-121; T68 không bị ảnh hưởng.

  @TC-12-048 @P1 @Dương @Âm @Biên
  Kịch bản: TC-12-048 Phiên nhàn rỗi, tối đa và hạn mức đồng thời
    # Truy vết: FR-12-020, FR-12-029 · BR-12-022 · UI-12-18 · SEC-29 · API-12-016
    Biết U-T68-VW (3 phiên), U-T68-TA1 (quản trị, 1 phiên); đồng hồ điều khiển được.
    Khi mở phiên thứ 4 của VW; phiên thứ 2 của TA1.
    Và để nhàn rỗi 15 phút; để dùng liên tục 10 giờ.
    Thì phiên cũ nhất bị đóng khi vượt hạn mức (quản trị chỉ 1 phiên); nhàn rỗi 15 phút bị khóa phiên; quá 10 giờ buộc đăng nhập lại.
