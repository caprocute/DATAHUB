# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-11
Tính năng: TS-09-11 · Gia hạn, sửa, tạm dừng, thu hồi và tự hết hạn chấp thuận

  @TC-09-035 @P1 @Dương @Âm
  Kịch bản: TC-09-035 Gia hạn và sửa chấp thuận, tối đa ba lần
    # Truy vết: FR-09-017 · API-09-069, 070 · ERR-09-031, 030 · BR-09-015 · EVT-09-06
    # Mục đích: Chứng minh giới hạn `09.grant.renew-max = 3` và gia hạn không vượt trần.
    Biết T90; chấp thuận G1 đã gia hạn 2 lần; U-T90-DO1.
    Khi DO1 `:renew` G1 thêm 180 ngày (lần 3).
    Và DO1 `:renew` G1 lần 4.
    Và DO1 `:amend` G1 bớt 1 trường, hạ hạn ngạch.
    Thì bước 1 `200`, `renewCount = 3`. Bước 2 `422` ERR-09-031 "Chấp thuận đã gia hạn tối đa 3 lần. Lập yêu cầu mới." Bước 3 `200`, EVT: `purpose-grant.approved` (loại sửa), KT: có (grant-amend).

  @TC-09-036 @P1 @Dương @Âm
  Kịch bản: TC-09-036 Tạm dừng và khôi phục, lý do bắt buộc
    # Truy vết: FR-09-017 · API-09-071, 072 · ERR-09-007, 006 · EVT-09-07
    # Mục đích: Chứng minh `ACTIVE → SUSPENDED → ACTIVE` và thao tác sai trạng thái bị chặn.
    Biết T90; G1 `ACTIVE`; U-T90-DO1.
    Khi DO1 `:suspend` G1 lý do 5 ký tự.
    Và DO1 `:suspend` lý do 25 ký tự.
    Và DO1 `:suspend` lần hai.
    Và DO1 `:resume`.
    Thì bước 1 `422` ERR-09-007. Bước 2 `200`, EVT: `purpose-grant.suspended`. Bước 3 `409` ERR-09-006. Bước 4 `200`, `ACTIVE`, EVT: `purpose-grant.suspended` loại khôi phục.

  @TC-09-037 @P1 @Dương @Bảo @mật
  Kịch bản: TC-09-037 Thu hồi chấp thuận, quyết định mục đích chuyển sang từ chối
    # Truy vết: FR-09-017, 019 · API-09-073, 227 · EVT-09-08 · BR-09-017 · ERR-09-102
    # Mục đích: Chứng minh thu hồi có hiệu lực ở điểm thực thi trong 15 giây (BR-09-017); đo chi tiết ở TC-09-135.
    Biết T90; G1 `ACTIVE`; S-T90-PEP-04 gọi `purpose:decide` 5 lượt mỗi giây; U-T90-DO1.
    Khi PEP gọi liên tục `POST /privacy/v1/purpose:decide` cho G1.
    Và DO1 `:revoke` G1 lý do 30 ký tự.
    Và ghi thời điểm lượt `deny` đầu tiên.
    Thì bước 2 `200`, `REVOKED`, EVT: `purpose-grant.revoked` có trên `t90.privacy.purpose-grant.revoked.v1`, KT: có (grant-revoke). Bước 3 mọi lượt sau 15 giây là `403` ERR-09-102; chấp thuận không `ACTIVE` lại được (thử `:resume` `409` ERR-09-006).

  @TC-09-038 @P1 @Dương
  Kịch bản: TC-09-038 Tự hết hạn, báo trước 30 ngày, không gia hạn ngầm
    # Truy vết: FR-09-017 · EVT-09-09, 10 · BR-09-015 · API-09-068
    # Mục đích: Chứng minh `EXPIRED` tự động và báo trước đúng hạn.
    Biết T95 đồng hồ giả; chấp thuận G2 hạn sau 31 ngày, `09.grant.expiring-notice-days = 30`.
    Khi tiến đồng hồ 1 ngày.
    Và tiến đến sau `validTo` 1 phút.
    Và gọi `purpose:decide` cho G2.
    Thì bước 1 EVT: `purpose-grant.expiring` đúng một lần. Bước 2 `GrantStatus = EXPIRED`, EVT: `purpose-grant.expired`. Bước 3 `403` ERR-09-102; không gia hạn tự động.
