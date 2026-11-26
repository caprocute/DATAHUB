# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-17
Tính năng: TS-13-17 · Nhật ký truy cập API

  @TC-13-054 @P1 @Dương
  Kịch bản: TC-13-054 Lọc lượt gọi theo HTTT, API, mã lỗi, xem chi tiết
    # Truy vết: FR-13-030 · UC-13-19 · API-13-025, 026 · UI-13-09 · NFR-13-006 · LGC-APIM-022 · LGC-PAY-021
    Biết F-ACCESS-5M; U-T68-TO.
    Khi lọc 24 giờ, HTTT `HT-NDXP`, mã `5xx`.
    Và mở một lượt gọi.
    Thì p95 ≤ 3 giây; chi tiết có `trace_id` bấm sang UI-13-08; không thân, không `Authorization`.

  @TC-13-055 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-055 Khoảng quá 31 ngày và lượt gọi tenant khác
    # Truy vết: FR-13-030 · API-13-025, 026 · ERR-13-005, 004, 001 · BR-13-030
    Biết U-T68-TO; recordId của T01.
    Khi tra khoảng 32 ngày; không `from`.
    Và `GET /access-logs/{recordId}` của T01.
    Thì ERR-13-005 (`maxDays = 31`); ERR-13-004; bước 2 404-ẩn.
