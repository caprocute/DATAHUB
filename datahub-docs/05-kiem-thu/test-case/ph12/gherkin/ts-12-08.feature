# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-08
Tính năng: TS-12-08 · Tách nhiệm vụ và ngoại lệ có thời hạn

  @TC-12-032 @P1 @Âm
  Kịch bản: TC-12-032 Gán cặp vai trò xung đột bị chặn
    # Truy vết: FR-12-013 · UC-12-10 · API-12-026, 028 · ERR-12-009 · BR-12-030 · UI-12-06
    Biết U-T68-IE đang có `INTEGRATION_ENGINEER`; U-T68-TA1.
    Khi `GET /sod-rules` lấy cặp IE–IA.
    Và gán `INTEGRATION_APPROVER` cho IE.
    Thì bước 2 `409` ERR-12-009, thân nêu cặp xung đột; UI-12-06 hiện cảnh báo và lối đề nghị ngoại lệ.

  @TC-12-033 @P1 @Dương
  Kịch bản: TC-12-033 Ngoại lệ tách nhiệm vụ: đề nghị, duyệt, tự hết hạn
    # Truy vết: FR-12-013 · UC-12-10 · UI-12-17 · API-12-029, 030, 031 · BR-12-030 · SEC-27
    Biết U-T68-TA1, U-T68-SO, U-T68-IE; đồng hồ điều khiển được.
    Khi TA1 `POST /sod-exceptions` có lý do, hạn 30 ngày.
    Và SO `:decide` chấp thuận; gán vai trò xung đột thành công.
    Và nhảy 31 ngày; xem gán vai trò.
    Thì sau bước 2 gán được; bước 3 vai trò xung đột tự gỡ; KT: có; thu hồi tay bằng `:revoke` cũng gỡ.

  @TC-12-034 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-034 Ngoại lệ vi phạm bốn mắt, vượt hạn hoặc thiếu lý do
    # Truy vết: FR-12-013 · BR-12-030, BR-12-033 · API-12-029, 030 · ERR-12-008 · ERR-12-014
    Biết U-T68-TA1 vừa là người đề nghị; cặp vai trò "cấm tuyệt đối" ở D02-08 §4.
    Khi TA1 tự `:decide` ngoại lệ mình đề nghị.
    Và đề nghị thiếu lý do; đề nghị hạn 120 ngày.
    Và đề nghị ngoại lệ cho cặp cấm tuyệt đối.
    Thì bước 1 `403` ERR-12-008; bước 2 `400` ERR-12-014 (thiếu lý do) và `422` (vượt 90 ngày); bước 3 bị từ chối.
