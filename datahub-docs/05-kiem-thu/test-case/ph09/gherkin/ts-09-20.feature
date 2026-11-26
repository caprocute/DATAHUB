# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-20
Tính năng: TS-09-20 · Xem giá trị đầy đủ có lý do trong 60 giây

  @TC-09-068 @P1 @Dương
  Kịch bản: TC-09-068 Cấp phiếu, xác thực phiếu, giá trị tự che sau 60 giây
    # Truy vết: FR-09-029 · API-09-102, 236, 241 · UI-09-22 · BR-09-026 · NFR-09-015 · PERM-09-unmask
    # Mục đích: Chứng minh phiếu hết hạn sau `09.mask.reveal-seconds = 60` và PH-09 không thấy giá trị.
    Biết T90; U-T90-SO có `PERM-09-unmask`, U-T90-AU; trường `cccd` ở UI của PH-06 giả lập; canary `DH-CANARY-rev-grant`.
    Khi trên UI-09-22 SO nhập lý do 30 ký tự, bấm xem.
    Và DU gọi `POST /privacy/v1/reveal-grants/{gid}:verify` trong 30 giây.
    Và quan sát đồng hồ đếm ngược; gọi `:verify` lại sau 61 giây.
    Và AU `GET /reveal-grants/{grantId}`.
    Thì bước 1 `201` `{grantId, expiresAt, serverTime, remainingThisHour}` (`remainingThisHour` = 20 trừ số lần đã cấp trong giờ), KT: có ghi trước khi cấp. Bước 2 `200`. Bước 3 giá trị tự che lại; `:verify` `403` ERR-09-112. Giá trị rõ không có trong log, bảng `ph09_privacy.*`, đĩa. Bước 4 `200`, thấy người xem, trường, lý do, hết hạn, trạng thái; không có `value`.

  @TC-09-069 @P1 @Âm
  Kịch bản: TC-09-069 Thiếu quyền, lý do ngắn, trường cấm xem, vượt 20 lần mỗi giờ
    # Truy vết: FR-09-029 · API-09-102 · ERR-09-041, 007, 042, 043 · BR-09-026
    # Mục đích: Chứng minh BR-09-026 từng điều kiện.
    Biết T92 `09.mask.reveal-max-per-hour = 3`; trường `matKhau` đặt `neverReveal`; U-T90-DS1 (không quyền), U-T90-SO.
    Khi DS1 `POST /reveal-grants`.
    Và SO gửi lý do 10 ký tự.
    Và SO xin xem `matKhau`.
    Và SO xin xem 4 lần liên tiếp với lý do hợp lệ.
    Thì bước 1 `403` ERR-09-041. Bước 2 `422` ERR-09-007. Bước 3 `422` ERR-09-042. Bước 4 lần thứ 4 `429` ERR-09-043.

  @TC-09-070 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-070 Không ghi được kiểm toán thì không cấp phiếu
    # Truy vết: FR-09-029 · BR-09-057 · ERR-09-010 · API-09-102
    # Mục đích: Chứng minh ghi vết trước khi cấp, không cấp khi không ghi được.
    Biết T94; PH-13 giả lập `503`; U-T90-SO.
    Khi SO `POST /reveal-grants` khi PH-13 ngừng.
    Thì `503` ERR-09-010, không có `RevealGrant` mới; giao diện thông báo từ chối.

  @TC-09-071 @P2 @Dương @Âm
  Kịch bản: TC-09-071 Lịch sử xem đầy đủ, tách quyền xem và quyền xem lịch sử
    # Truy vết: FR-09-029 · API-09-103 · UI-09-20 · PERM-09-audit-read · EVT-09-15
    # Mục đích: Chứng minh lịch sử đủ lượt và tín hiệu bất thường.
    Biết T90; 25 lượt xem của SO trong 1 giờ ở T95; U-T90-AU, U-T90-SO.
    Khi AU `GET /reveal-grants`.
    Và SO `GET /reveal-grants`.
    Thì bước 1 `200`, đủ lượt (người, đối tượng, trường, lý do, hết hạn), EVT: `reveal.granted` khi vượt ngưỡng bất thường. Bước 2 ERR-00-403.
