# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-33
Tính năng: TS-08-33 · Hiệu năng đo lô, hồ sơ, bảng điều khiển và báo cáo

  @TC-08-146 @P1 @Hiệu @năng
  Kịch bản: TC-08-146 Đo FULL 1 triệu bản ghi, SAMPLE, hồ sơ
    # Truy vết: NFR-08-003 · NFR-08-004 · NFR-08-013 · NFR-08-014 · FR-08-026 · FR-08-008 · FR-08-044
    Biết T99; nguồn PostgreSQL bản sao chỉ đọc 1 triệu dòng, 30 quy tắc; bốn bộ thực thi.
    Khi đo `FULL`
    Và đo `SAMPLE` 10.000 bản ghi
    Và hồ sơ 1 triệu dòng 50 cột
    Và đo kiểm chứng 10.000 khóa
    Thì `FULL` ≤ 60 phút. `SAMPLE` ≤ 3 phút. Hồ sơ ≤ 15 phút, sai số HLL ≤ 2 %. Đo kiểm chứng ≤ 5 phút từ lúc báo đã sửa (không gồm chờ PH-06).

  @TC-08-147 @P2 @Hiệu @năng
  Kịch bản: TC-08-147 Mở rộng gần tuyến tính theo số bộ thực thi
    # Truy vết: NFR-08-019 · NFR-08-003
    Biết T99 như perf-scan.
    Khi đo `FULL` với 1, 2, 4, 8 bộ thực thi, ghi thông lượng
    Thì thông lượng với n bộ ≥ 0,8 × n × thông lượng 1 bộ, tới n = 8.

  @TC-08-148 @P2 @Hiệu @năng
  Kịch bản: TC-08-148 Bảng điều khiển, tra cứu lỗi và báo cáo
    # Truy vết: NFR-08-010 · NFR-08-011 · NFR-08-012 · FR-08-050 · FR-08-037 · FR-08-052 · FR-08-055 · API-08-104, 073
    Biết T98: 200 đối tượng, 13 tháng ảnh chụp, 10 triệu dòng lỗi phân vùng tháng.
    Khi k6 `GET /dashboard` 50 người dùng đồng thời
    Và `GET /findings` lọc theo đối tượng và trạng thái
    Và sinh báo cáo kỳ cho 200 đối tượng
    Và xuất PDF 100 trang
    Thì dashboard p95 ≤ 2 giây. Tra cứu lỗi p95 ≤ 1,5 giây. Báo cáo kỳ ≤ 5 phút. PDF 100 trang ≤ 2 phút.
