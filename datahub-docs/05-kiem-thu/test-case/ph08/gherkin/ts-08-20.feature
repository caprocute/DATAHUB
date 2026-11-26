# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-20
Tính năng: TS-08-20 · Nhận, xử lý và cập nhật tiến độ phiếu khắc phục

  @TC-08-099 @P1 @Dương
  Kịch bản: TC-08-099 Bắt đầu xử lý và trao đổi trên phiếu
    # Truy vết: FR-08-043 · API-08-085, 086, 088, 089, 097 · UI-08-15, 16 · EVT-08-08 · PERM-08-remediate
    Biết phiếu `DQ-2026-000001` `ASSIGNED` cho ORG-CA; DO1.
    Khi DO1 `GET /issues?scope=MINE`
    Và `POST /issues/DQ-2026-000001:start`
    Và `POST /issues/DQ-2026-000001/activities` `{activityType: COMMENT, comment: "@DS1 đã sửa 8/12"}` kèm tệp 1 MB
    Và `GET /issues/DQ-2026-000001/activities`
    Thì `IN_PROGRESS`; hoạt động `COMMENT`, `ATTACHMENT` có dòng thời gian; nhắc `@DS1` gửi thông báo riêng; EVT: `issue.status-changed` (EVT-08-08) khi đổi trạng thái.

  @TC-08-100 @P2 @Âm
  Kịch bản: TC-08-100 Phiếu đã hủy, tệp quá lớn, DO khác tổ chức
    # Truy vết: FR-08-043 · API-08-089, 086 · BR-08-026 · ERR-08-006, 046, 032
    Biết phiếu `CANCELLED`; phiếu của ORG-CA; DO2 thuộc ORG-TC.
    Khi DO1 `POST …/activities` trên phiếu `CANCELLED`
    Và DO1 đính tệp 26 MB
    Và DO2 `GET /issues/DQ-2026-000001`
    Thì bước 1 `409` ERR-08-006. Bước 2 `413` ERR-08-046. Bước 3 `403` ERR-08-032.
