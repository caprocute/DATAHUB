# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-36
Tính năng: TS-12-36 · Hiệu năng, tải và quy mô

  @TC-12-113 @P1 @Hiệu @năng
  Kịch bản: TC-12-113 Độ trễ quyết định OPA cục bộ
    # Truy vết: NFR-12-001 · FR-12-044
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 300 lượt/giây, 500 phiên bản chính sách, 30 phút
    Thì đạt ngưỡng: p50 ≤ 0,5 ms, p99 ≤ 2 ms

  @TC-12-114 @P1 @Hiệu @năng
  Kịch bản: TC-12-114 Độ trễ `/decide` qua API
    # Truy vết: NFR-12-002 · API-12-086
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Trượt bộ đệm, trong cụm, 15 phút
    Thì đạt ngưỡng: p95 ≤ 10 ms, p99 ≤ 30 ms

  @TC-12-115 @P1 @Hiệu @năng
  Kịch bản: TC-12-115 Thông lượng quyết định
    # Truy vết: NFR-12-003 · FR-12-044
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 10.000 quyết định/giây toàn cụm, 15 phút
    Thì đạt ngưỡng: Lỗi < 0,01 %

  @TC-12-116 @P1 @Hiệu @năng
  Kịch bản: TC-12-116 Hiệu lực chính sách và dữ liệu mới
    # Truy vết: NFR-12-004 · FR-12-054, 051
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 6 pod OPA, 20 lần phát hành
    Thì đạt ngưỡng: ≤ 60 giây tới mọi OPA

  @TC-12-117 @P1 @Hiệu @năng
  Kịch bản: TC-12-117 Hiệu lực thu hồi
    # Truy vết: NFR-12-005 · FR-12-040
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Client có token, gọi mỗi giây, 20 lần
    Thì đạt ngưỡng: ≤ 60 giây tại APISIX và DU

  @TC-12-118 @P1 @Hiệu @năng
  Kịch bản: TC-12-118 Độ trễ cấp token máy
    # Truy vết: NFR-12-006 · FR-12-035
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 100 yêu cầu/giây, 500 client, 15 phút
    Thì đạt ngưỡng: p95 ≤ 150 ms, p99 ≤ 300 ms

  @TC-12-119 @P1 @Hiệu @năng
  Kịch bản: TC-12-119 Thời gian đăng nhập
    # Truy vết: NFR-12-007 · FR-12-020
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 200 đăng nhập đồng thời
    Thì đạt ngưỡng: p95 ≤ 2 giây (không tính yếu tố thứ hai)

  @TC-12-120 @P1 @Hiệu @năng
  Kịch bản: TC-12-120 API quản trị ở quy mô tenant
    # Truy vết: NFR-12-008 · FR-12-001, 030
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 10.000 người dùng, 1.000 client, 30 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms

  @TC-12-121 @P1 @Hiệu @năng
  Kịch bản: TC-12-121 Tỷ lệ trúng bộ đệm quyết định
    # Truy vết: NFR-12-009 · FR-12-050
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Lưu lượng mô phỏng 1 giờ
    Thì đạt ngưỡng: ≥ 60 %

  @TC-12-122 @P2 @Hiệu @năng
  Kịch bản: TC-12-122 Quy mô chính sách
    # Truy vết: NFR-12-024 · FR-12-052
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 500 phiên bản `PUBLISHED`, gói 20 MiB
    Thì đạt ngưỡng: Độ trễ tăng ≤ 20 %

  @TC-12-123 @P2 @Hiệu @năng
  Kịch bản: TC-12-123 Quy mô định danh và phiên
    # Truy vết: NFR-12-023, 025 · FR-12-041
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 34 realm; 2.000 phiên mỗi tenant; 20.000 phiên toàn cụm
    Thì đạt ngưỡng: Đăng nhập và quyết định đạt ngưỡng trên
