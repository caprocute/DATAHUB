# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-35
Tính năng: TS-14-35 · Hiệu năng, tải và quy mô

  @TC-14-088 @P1 @Hiệu @năng
  Kịch bản: TC-14-088 Chi phí xử lý thêm của PH-14
    # Truy vết: NFR-14-001, NFR-14-006
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 500 lượt/giây, 30 phút, 3 bản sao, `sim-ndxp` trả ngay
    Thì đạt ngưỡng: p99 ≤ 80 ms

  @TC-14-089 @P1 @Hiệu @năng
  Kịch bản: TC-14-089 Ký số và xác minh
    # Truy vết: NFR-14-002, NFR-14-003
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: Gatling từng chặng, OpenBao 3 nút
    Thì đạt ngưỡng: ký p99 ≤ 50 ms; xác minh p99 ≤ 30 ms

  @TC-14-090 @P2 @Hiệu @năng
  Kịch bản: TC-14-090 Trúng đệm
    # Truy vết: NFR-14-004, NFR-14-005
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 300 lượt/giây, mẫu truy vấn phân bố thực
    Thì đạt ngưỡng: p99 ≤ 15 ms; tỷ lệ trúng ≥ 60 %

  @TC-14-091 @P1 @Hiệu @năng
  Kịch bản: TC-14-091 Thông lượng một tenant ở cao điểm
    # Truy vết: NFR-14-006
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 300 lượt/giây, hạn mức đủ, tuân thủ ưu tiên
    Thì đạt ngưỡng: không suy giảm, 0 lỗi do PH-14

  @TC-14-092 @P2 @Hiệu @năng
  Kịch bản: TC-14-092 Quy mô mỗi tenant
    # Truy vết: NFR-14-019, NFR-14-025, FR-14-004, FR-14-013
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 10 nền tảng, 300 dịch vụ, 1.000 luật, 20 chứng thư, 50 điểm cuối; API điều khiển
    Thì đạt ngưỡng: đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms
