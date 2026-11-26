# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-25
Tính năng: TS-08-25 · Báo cáo kỳ, duyệt, công bố và báo cáo chính thức hằng năm

  @TC-08-115 @P1 @Dương @Âm
  Kịch bản: TC-08-115 Sinh báo cáo kỳ và báo cáo thiếu lần đo trong kỳ
    # Truy vết: FR-08-052 · API-08-107, 108, 109 · UI-08-18 · PERM-08-report · ERR-08-056, 112
    Biết T90 có 3 đối tượng đo thành công trong 2026-11, một đối tượng không; T95 không có lần đo nào; DS1.
    Khi DS1 `POST /reports` `{reportType: PERIODIC, periodCode: 2026-11}`
    Và `GET /reports/{code}`
    Và `GET /reports?type=PERIODIC&page=0&size=10`
    Và T95 `POST /reports` `{reportType: PERIODIC, periodCode: 2026-11}`
    Và tắt kho tệp rồi `POST /reports`
    Thì bước 1 `201`, `reportCode = BC-DQ-2026-11-T90`, `DRAFT`, `summary` nêu đối tượng chưa đo, khuyến nghị gợi ý. Bước 3 danh sách có báo cáo vừa tạo. Bước 4 `422` ERR-08-056. Bước 5 thông báo ERR-08-112 trong ứng dụng, không có báo cáo dở dang.

  @TC-08-116 @P1 @Dương
  Kịch bản: TC-08-116 Gửi duyệt, duyệt và công bố báo cáo
    # Truy vết: FR-08-053 · API-08-110, 111, 112 · UI-08-18 · BR-08-007, 009 · EVT-08-11 · PERM-08-approve
    Biết báo cáo `DRAFT` (rep-periodic); DS1, DA1.
    Khi DS1 `PATCH /reports/{code}` thêm khuyến nghị
    Và DS1 `:submit`
    Và DA1 `:approve`
    Và `GET /reports/{code}`
    Thì `IN_REVIEW` rồi `PUBLISHED` với `contentSha256`, `publishedAt`, `publishedBy = DA1`; nội dung bất biến. EVT: `report.published` (EVT-08-11). KT: có (report.publish).

  @TC-08-117 @P1 @Âm
  Kịch bản: TC-08-117 Thiếu khuyến nghị, tự duyệt, sửa báo cáo đã công bố, thu hồi
    # Truy vết: FR-08-053 · API-08-111, 112, 113, 114, 110 · BR-08-009, 011 · ERR-08-039, 005, 040, 007
    Biết báo cáo `DRAFT` không khuyến nghị; báo cáo `PUBLISHED`.
    Khi DS1 `:submit` báo cáo không khuyến nghị
    Và DS1 `:approve` báo cáo do mình gửi
    Và `PATCH` báo cáo `PUBLISHED`
    Và DA1 `:withdraw` lý do 10 ký tự
    Và DA1 `:withdraw` lý do 30 ký tự, lập báo cáo thay thế
    Và DA1 `POST /reports/{code}:reject` báo cáo `IN_REVIEW` kèm lý do 30 ký tự
    Thì bước 1 `422` ERR-08-039. Bước 2 `403` ERR-08-005. Bước 3 `409` ERR-08-040. Bước 4 `422` ERR-08-007. Bước 5 `WITHDRAWN`, EVT-08-11 `WITHDRAWN`, báo cáo gốc không bị sửa. Bước 6 báo cáo về `DRAFT` kèm lý do.

  @TC-08-118 @P1 @Dương
  Kịch bản: TC-08-118 Báo cáo chính thức năm khi đủ điều kiện
    # Truy vết: FR-08-054 · API-08-115, 107, 111, 112 · UI-08-18 · BR-08-010 · EVT-08-11 · EVT-08-14
    Biết T96 có mọi đối tượng với lần đo `FULL` `SUCCEEDED` trong 2026, ảnh chụp không `INCOMPLETE_DIMENSIONS`; DS1, DA1.
    Khi `POST /reports:check-annual-readiness` `{year: 2026}`
    Và `POST /reports` `{reportType: ANNUAL, periodCode: 2026-12, annualMethod: FULL_DECEMBER}`
    Và thêm khuyến nghị, `:submit`, DA1 `:approve`
    Thì bước 1 `ready = true`, `blockers[]` trống. Bước 2 `201`, `BC-DQ-2026-NAM-T96`, ảnh chụp theo `FULL_DECEMBER`; đối tượng `FLOW_MESSAGE` không đo theo lô nên được loại khỏi điều kiện và báo cáo trình bày bằng thống kê trực tuyến cả năm. Bước 3 `PUBLISHED`; EVT-08-11 và EVT-08-14.

  @TC-08-119 @P1 @Âm @Biên
  Kịch bản: TC-08-119 Báo cáo năm bị chặn khi thiếu FULL, thiếu chiều, chỉ có mẫu
    # Truy vết: FR-08-054 · FR-08-024 · API-08-115, 107, 059 · BR-08-010 · ERR-08-038 · ERR-08-030
    Biết T90: A chỉ có lần đo `SAMPLE`; B có ảnh chụp `INCOMPLETE_DIMENSIONS`; C không có lần `FULL` trong năm.
    Khi `POST /reports:check-annual-readiness`
    Và `POST /reports` `{reportType: ANNUAL, periodCode: 2026-12}`
    Và `POST /scans` `{assetCode: A, scanTrigger: ANNUAL, scanMode: SAMPLE, periodCode: 2026-12}`
    Và `POST /scans` `{assetCode: A, scanTrigger: ANNUAL, scanMode: FULL, periodCode: 2026-12}` cho A, B, C, kiểm lại
    Thì bước 1 `ready = false`, `blockers[]` có C (thiếu lần đo `FULL`), B (thiếu chiều), A (chỉ có lần đo mẫu). Bước 2 `422` ERR-08-038. Bước 3 `422` ERR-08-030. Bước 4 sau khi đủ ba lần `FULL` sạch, `ready = true`.
