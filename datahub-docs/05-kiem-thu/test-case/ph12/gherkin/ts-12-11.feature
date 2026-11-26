# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-11
Tính năng: TS-12-11 · Quyền có thời hạn và truy cập liên tenant

  @TC-12-039 @P1 @Dương
  Kịch bản: TC-12-039 Xin, duyệt, dùng và tự hết quyền vào tenant khác
    # Truy vết: FR-12-017 · UC-12-13 · UI-12-08, 17 · API-12-036, 037, 038, 040 · BR-12-032 · SEC-28
    Biết U-PO xin vào T68 4 giờ, phiếu `HT-1001`; U-T68-SO duyệt.
    Khi U-PO `POST /privileged-grants`; SO `:approve`.
    Và U-PO truy cập API của T68; sau 4 giờ (đồng hồ nhảy) thử lại.
    Và lần khác, SO `:revoke` giữa chừng.
    Thì bước 2 dùng được rồi bị từ chối khi hết hạn; thu hồi có hiệu lực ≤ 60 giây; thông báo tới TA T68; KT: có (grant.request, approve, expire, revoke).

  @TC-12-040 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-040 Quyền thời hạn vượt 4 giờ, thiếu phiếu, tự duyệt, bị từ chối
    # Truy vết: FR-12-017 · BR-12-032, BR-12-031, BR-12-033 · API-12-036, 038, 039 · ERR-12-030 · ERR-12-008
    Biết U-PO, U-PA.
    Khi xin 5 giờ; xin không có mã phiếu.
    Và U-PO tự `:approve` yêu cầu của mình.
    Và SO `:reject` một yêu cầu rồi thử dùng.
    Thì bước 1 `422` ERR-12-030; bước 2 `403` ERR-12-008; bước 3 không có quyền nào được cấp.
