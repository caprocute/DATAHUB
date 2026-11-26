# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-30
Tính năng: TS-14-30 · Tham số phân hệ theo tenant

  @TC-14-077 @P1 @Dương
  Kịch bản: TC-14-077 Đổi tham số thường và tham số bảo mật
    # Truy vết: FR-14-054 · API-14-070, 071 · UI-14-16, 17 · UC-14-36 · BR-14-022 · NFR-14-026.
    Biết U-T68-TA, U-T68-IA.
    Khi `PUT /settings` đổi `14.retry.max-attempts` thành 3.
    Và `PUT /settings` đổi `14.sign.max-skew-seconds` (★) thành 120; IA duyệt.
    Thì bước 1 hiệu lực ≤ 30 giây không khởi động lại; bước 2 chờ duyệt rồi hiệu lực; có nhãn bảo mật ở UI-14-16.

  @TC-14-078 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-078 Tham số ngoài miền, không có quyền, tự duyệt
    # Truy vết: FR-14-054 · API-14-071 · ERR-14-003, 007, 036 · BR-14-022.
    Biết U-T68-TA; U-T68-IA2; U-T68-VW.
    Khi `PUT /settings` `14.timeout.default-ms = 90000`.
    Và `PUT /settings` `14.cache.max-ttl-seconds` vượt trần.
    Và U-T68-IA2 tự duyệt thay đổi tham số ★ mình đề nghị; U-T68-VW đổi tham số.
    Thì `400` ERR-14-003; `422` ERR-14-036; `403` ERR-14-007; `403`.
