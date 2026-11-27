# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-24
Tính năng: TS-18-24 · Xử lý thư trả lại, danh sách chặn và tra nhật ký gửi

  @TC-18-080 @P1 @Dương
  Kịch bản: TC-18-080 Thư trả lại cứng và ba lần trả lại mềm đưa vào danh sách chặn
    # Truy vết: FR-18-040 · API-18-104, 106 · BR-18-031 · ERR-18-112 · EVT-18-12
    # Mục đích: Chứng minh BR-18-031: trả lại cứng chặn ngay, trả lại mềm quá `18.notify.bounce.soft-limit` trong 30 ngày thì chặn, mỗi lần chặn phát EVT-18-12.
    Biết T90; MOCK-SMTP gọi `POST /ops/internal/v1/notifications/bounces` (scope `ops:notify`); người nhận R1, R2.
    Khi báo trả lại `HARD` cho R1.
    Và báo trả lại `SOFT` cho R2 ba lần trong 10 ngày.
    Và `GET /suppressions`.
    Thì lần gửi của R1 `BOUNCED` ghi ERR-18-112, R1 vào danh sách chặn, EVT-18-12 `bounceType = HARD`. R2 sau lần thứ ba vào danh sách chặn. Danh sách hiện địa chỉ đã che dạng `t*@*.vn`.

  @TC-18-081 @P1 @Âm @Dương
  Kịch bản: TC-18-081 Gửi tới người bị chặn, gỡ chặn có lý do và gửi lại
    # Truy vết: FR-18-040, 041 · API-18-091, 092, 103, 105 · ERR-18-006, 043, 113 · EVT-18-13
    # Mục đích: Chứng minh người bị chặn không nhận thư (bất đồng bộ ghi ERR-18-113, đồng bộ trả ERR-18-043), gỡ chặn cần lý do, gửi lại thông báo `BOUNCED` sau khi sửa.
    Biết T90; R1 bị chặn; lần gửi `DLV-01` `BOUNCED`, `DLV-02` `DELIVERED`; U-T90-TA1 (`PERM-18-template`).
    Khi S-PH01 gửi bất đồng bộ cho R1.
    Và S-PH01 gửi đồng bộ cho R1.
    Và TA1 `DELETE /suppressions/{id}` kèm lý do.
    Và TA1 `POST /notification-deliveries/DLV-01:resend`; rồi `:resend` cho `DLV-02`.
    Thì bước 1 lần gửi `SUPPRESSED` ghi ERR-18-113. Bước 2 `409` ERR-18-043. Bước 3 `204`, KT: có. Bước 4 `DLV-01` gửi lại `202`; `DLV-02` `409` ERR-18-006.

  @TC-18-082 @P2 @Dương @Âm
  Kịch bản: TC-18-082 Tra nhật ký gửi theo kênh, trạng thái, nguồn; địa chỉ đã che; kênh cho PH-13
    # Truy vết: FR-18-041, 036 · API-18-102, 093 · BR-18-029 · ERR-18-003 · UI-18-13
    # Mục đích: Chứng minh FR-18-041: nhật ký lọc được, chỉ hiện địa chỉ đã che kể cả với AU, bộ lọc sai bị chặn; PH-13 gửi thư theo lịch trực qua cùng API.
    Biết T90; 500 lần gửi mẫu; U-T90-AU; S-PH13 (`ops:notify`).
    Khi AU mở `/van-hanh/thong-bao/nhat-ky`, lọc kênh `EMAIL`, trạng thái `BOUNCED`.
    Và `GET /notification-deliveries?trangThai=XYZ`.
    Và S-PH13 gửi thư mức `URGENT` tới `ON_CALL:SO` rồi tra trạng thái.
    Thì bước 1 danh sách đúng, cột người nhận đã che. Bước 2 `400` ERR-18-003. Bước 3 `202` rồi `DELIVERED` trong ≤ 30 giây; nhật ký ghi `callerPh = PH-13`.
