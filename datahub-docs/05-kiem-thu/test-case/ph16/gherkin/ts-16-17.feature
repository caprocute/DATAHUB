# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-17
Tính năng: TS-16-17 · Tra cứu báo cáo và tải bằng chứng công bố

  @TC-16-069 @P1 @Dương @Âm
  Kịch bản: TC-16-069 Liệt kê, tìm, xem báo cáo và lịch sử phiên bản theo quyền
    # Truy vết: FR-16-031 · API-16-064, 066, 077 · UI-16-10 · ERR-16-057, ERR-16-001
    Biết T90: `bc-thang-2026-09` `PUBLISHED`, `bc-thang-2026-10` `DRAFT`; T91 có `bc-thang-2026-10`; U-T90-VW, U-T90-TO1.
    Khi U-T90-TO1 `GET /reports?state=DRAFT&reportType=PERIODIC&periodCode=M-2026-10`
    Và U-T90-VW `GET /reports`
    Và U-T90-VW `GET /reports/bc-thang-2026-10`
    Và U-T90-TO1 `GET /reports?state=XYZ`
    Và U-T91-TO1 `GET /reports/bc-thang-2026-10` của T90
    Thì bước 1 trả bản nháp kèm người lập, `latestVersion`. Bước 2 VW chỉ thấy báo cáo đã công bố (`PUBLISHED`, `SUPERSEDED`, `WITHDRAWN`), kèm `needsCorrection`. Bước 3 `404` ERR-16-001 (VW không thấy bản nháp, 404-ẩn). Bước 4 `400` ERR-16-057. Bước 5 `404` ERR-16-001 theo tenant.

  @TC-16-070 @P1 @Dương
  Kịch bản: TC-16-070 Tải bằng chứng công bố và kiểm chứng ngoài hệ thống
    # Truy vết: FR-16-036 · API-16-088, 077 · UI-16-10 · BR-16-010
    Biết `bc-thang-2026-09` `PUBLISHED`; U-T90-AU.
    Khi `GET /reports/bc-thang-2026-09/evidence?version=1`
    Và tải `downloadUrl`, tính SHA-256 và kiểm chữ ký bằng công cụ ngoài
    Và `GET /reports/bc-thang-2026-10/evidence` (bản nháp)
    Thì bước 1 `200`, `verified = true`, `contentHash`, `signature`, `downloadUrl`, `expiresAt`. Bước 2 SHA-256 khớp `contentHash`, chữ ký hợp lệ. Bước 3 `404` ERR-16-001 hoặc không có bằng chứng (báo cáo chưa công bố). KT: có (report.evidence.read) vì là truy cập bằng chứng.
