# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-16
Tính năng: TS-16-16 · Đính chính và rút báo cáo đã công bố

  @TC-16-067 @P1 @Dương
  Kịch bản: TC-16-067 Đính chính báo cáo đã công bố bằng phiên bản mới; rút báo cáo
    # Truy vết: FR-16-030 · API-16-075, 077, 066 · UI-16-10 · API-16-076 · EVT-16-09, EVT-16-08 · BR-16-009
    Biết `bc-thang-2026-09` `PUBLISHED` phiên bản 1, `needsCorrection = true` (per-reopen); U-T90-TA1.
    Khi `POST /reports/bc-thang-2026-09:correct` `{reason: <60 ký tự>, correctionNote: "Sửa số kết nối HTTT từ 70 thành 75"}` khóa idempotent `tc-corr-1`
    Và U-T90-TO1 duyệt lại và U-T90-TA2 công bố phiên bản 2
    Và `GET /reports/bc-thang-2026-09/versions`
    Và `POST /reports/bc-thang-2026-08:withdraw` `{reason: <40 ký tự>}` rồi `GET …/evidence`
    Thì bước 1 `201`, bản 2 `DRAFT` với `correctionOf = 1`, `correctionReason`. Sau bước 2 bản 2 `PUBLISHED`, bản 1 `SUPERSEDED` (vẫn tra được, `contentHash` bản 1 giữ nguyên); EVT: `report.state-changed` (SUPERSEDED) và `report.published`. Bước 3 liệt kê hai phiên bản, `needsCorrection` về `false`. Bước 4 `WITHDRAWN`, tệp ký và `contentHash` còn nguyên, EVT `report.state-changed`, không còn ở `/feed/reports`.

  @TC-16-068 @P2 @Âm
  Kịch bản: TC-16-068 Đính chính sai trạng thái, thiếu lý do
    # Truy vết: FR-16-030 · API-16-075, 076 · ERR-16-006, ERR-16-007, ERR-16-005
    Biết báo cáo `bc-thang-2026-10-nhap` `DRAFT`; `bc-thang-2026-09` `PUBLISHED`; U-T90-TA1.
    Khi `POST /reports/bc-thang-2026-10-nhap:correct`
    Và `POST /reports/bc-thang-2026-09:correct` với `reason` 10 ký tự
    Và `POST /reports/bc-thang-2026-10-nhap:withdraw`
    Và `POST /reports/bc-thang-2026-09:withdraw` không có `reason`
    Thì bước 1, 3 `409` ERR-16-006 (báo cáo chưa công bố). Bước 2, 4 `422` ERR-16-007 (hoặc `400` ERR-16-003 theo lược đồ). Không đổi dữ liệu.
