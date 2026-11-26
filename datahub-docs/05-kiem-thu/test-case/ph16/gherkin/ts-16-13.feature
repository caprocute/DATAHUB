# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-13
Tính năng: TS-16-13 · Lập bản nháp, thuyết minh và báo cáo đột xuất

  @TC-16-054 @P1 @Dương
  Kịch bản: TC-16-054 Lập bản nháp báo cáo kỳ từ kết quả đã tính
    # Truy vết: FR-16-026 · API-16-065, 066, 070 · UI-16-10, UI-16-11 · BR-16-008, BR-16-029
    Biết T90; kỳ `M-2026-10` `CLOSED` (F-KY-1); mẫu `tc-thang-ngan`; U-T90-TO1.
    Khi `POST /reports` `{reportCode: bc-thang-2026-10, templateCode: tc-thang-ngan, reportType: PERIODIC, periodCode: M-2026-10, title: "Báo cáo chỉ tiêu tháng 10/2026"}`
    Và `GET /reports/bc-thang-2026-10`
    Và `GET /reports/bc-thang-2026-10/preview`
    Thì bước 1 `201`, `state = DRAFT`, `latestVersion = 1`, `runId` là lần tổng hợp chính thức, `completeness = PARTIAL`. Bước 2 có `requiredExplanations` (chỉ tiêu `OFF_TRACK` và chỉ tiêu bắt buộc thiếu số) và `missingExplanations` bằng với nó. Bước 3 `previewUrl`, `provisional = false`.

  @TC-16-055 @P1 @Âm
  Kịch bản: TC-16-055 Lập báo cáo khi kỳ chưa tính hoặc mã sai
    # Truy vết: FR-16-026 · API-16-065 · ERR-16-028, ERR-16-002, ERR-16-003
    Biết kỳ `M-2026-12` `OPEN` chưa có lần tổng hợp; báo cáo `bc-thang-2026-10` đã có.
    Khi `POST /reports` `periodCode = M-2026-12`
    Và `POST /reports` lại `reportCode = bc-thang-2026-10`
    Và `POST /reports` với `reportCode = "BC_Thang"`
    Thì bước 1 `422` ERR-16-028. Bước 2 `409` ERR-16-002. Bước 3 `400` ERR-16-003. Không tạo báo cáo.

  @TC-16-056 @P1 @Dương @Âm
  Kịch bản: TC-16-056 Viết thuyết minh, giải trình chỉ tiêu chệch; sửa báo cáo đã công bố
    # Truy vết: FR-16-027 · API-16-067, 068, 066 · UI-16-11 · ERR-16-032, ERR-16-003 · BR-16-029
    Biết báo cáo `bc-thang-2026-10` `DRAFT`; `missingExplanations` có 3 mã `OFF_TRACK`; U-T90-TO1.
    Khi `PATCH /reports/bc-thang-2026-10` cập nhật `sections` với `ReportSectionText` nội dung 500 ký tự, kèm `documentNumber = "125/BC-STTTT"` và `recipientsNote = "UBND tỉnh; Bộ KH&CN."` (kèm `If-Match`)
    Và `PUT /reports/bc-thang-2026-10/explanations/{mã}` `{cause, action, dueDate}` cho một mã
    Và lặp lại cho cả ba mã
    Và `GET /reports/bc-thang-2026-10`
    Và `PATCH /reports/bc-thang-2026-09` và `PUT …/explanations/mttd` khi báo cáo `PUBLISHED`
    Và `PUT` giải trình với `cause = ""`
    Thì bước 1 `200`, `documentNumber`, `recipientsNote` được lưu nguyên văn (tối đa 64 và 2.000 ký tự). Bước 2 `200`, `explanation`, `missingExplanations` còn 2. Sau bước 3 rỗng. Bước 4 `explanations[]` đủ ba. Bước 5 `409` ERR-16-032. Bước 6 `400` ERR-16-003.

  @TC-16-057 @P3 @Dương @Âm
  Kịch bản: TC-16-057 Báo cáo đột xuất theo khoảng và tập chỉ tiêu tự chọn
    # Truy vết: FR-16-032 · API-16-065, 070 · ERR-16-033 · BR-16-004
    Biết T90; U-T90-TO1; `16.report.four-eyes = true`.
    Khi `POST /reports` `{reportCode: bc-dot-xuat-q1-q3, reportType: AD_HOC, title: "Sơ kết 9 tháng", from: 2026-01-01, to: 2026-09-30, indicatorCodes: [httt-ket-noi-ty-le, mttd, api-cong-bo]}`
    Và `POST /reports` với `from = 2024-01-01`, `to = 2026-09-30` (33 tháng)
    Và `POST /reports` với `from = 2026-09-30`, `to = 2026-01-01`
    Thì bước 1 `201`, `reportType = AD_HOC`, `rangeFrom`, `rangeTo`, chỉ ba chỉ tiêu. Bước 2, 3 `422` ERR-16-033. Báo cáo đột xuất không được gửi quốc gia (xem TC-16-096).
