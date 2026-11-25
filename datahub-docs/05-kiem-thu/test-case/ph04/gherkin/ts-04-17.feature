# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-17
Tính năng: TS-04-17 · Quay lui

  @TC-04-104 @P1 @Dương
  Kịch bản: TC-04-104 Quay lui PROD về phiên bản trước
    # Truy vết: FR-04-044 · API-04-055 · UC-04-13 · EVT-04-06
    Biết v4 chạy PROD, v3 `SUPERSEDED`; IA1.
    Khi gọi `POST /flows/tra-cuu-ho-tich/deployments:rollback` với `{"environment":"PROD","targetVersionNo":3,"reason":"Tỷ lệ lỗi tăng sau phát hành v4"}`.
    Thì `202`; triển khai `kind = ROLLBACK` không cần duyệt lại và không cần qua STAGING (BR-04-019 trừ quay lui); PROD `SYNCED` với v3; v4 thành `ROLLED_BACK`. KT: có (`INT_ROLLBACK` có lý do).

  @TC-04-105 @P2 @Dương
  Kịch bản: TC-04-105 Quay lui trong khoảng đóng băng
    # Truy vết: FR-04-044, 084 · BR-04-022
    Biết khoảng đóng băng đang hiệu lực.
    Khi quay lui PROD về v3.
    Thì `202` (quay lui được phép khi đóng băng).

  @TC-04-106 @P1 @Âm
  Kịch bản: TC-04-106 Quay lui về phiên bản dùng thành phần nay bị cấm, thiếu lý do
    # Truy vết: FR-04-044 · ERR-04-040, 025, 004
    Biết F-HT v2 dùng `ftp`, nay T68 cấm `ftp`.
    Khi quay lui về v2.
    Và quay lui về v3 với `reason = "lỗi"`.
    Và quay lui về v9.
    Thì lần lượt `409` ERR-04-040 (gợi ý tạm dừng khẩn), `400` ERR-04-025, `404` ERR-04-004.

  @TC-04-107 @P3 @Dương
  Kịch bản: TC-04-107 Gợi ý quay lui khi tỷ lệ lỗi tăng
    # Truy vết: FR-04-044, 051 · UI-04-15
    Biết `04.deploy.rollback-suggest-error-ratio = 2`; sau phát hành v4, đích trả 500 cho 30% lượt (v3 trước đó 5%).
    Khi mở UI-04-02 sau 5 phút.
    Thì banner "Tỷ lệ lỗi gấp 6 lần phiên bản trước. Cân nhắc quay lui về v3." với nút "Quay lui". Hệ thống không tự quay lui.
