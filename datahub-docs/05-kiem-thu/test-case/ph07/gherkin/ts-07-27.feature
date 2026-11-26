# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-27
Tính năng: TS-07-27 · Hiệu năng (k6)

  @TC-07-293 @P1 @Hiệu @năng
  Kịch bản: TC-07-293 Tra một mã, bộ đệm ấm
    # Truy vết: NFR-07-001 · FR-07-026
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 5.000 lượt/giây/tenant, 15 phút
    Thì đạt ngưỡng: p95 ≤ 20 ms, p99 ≤ 50 ms, lỗi < 0,1%

  @TC-07-294 @P2 @Hiệu @năng
  Kịch bản: TC-07-294 Tra lô 500 mã
    # Truy vết: NFR-07-002 · FR-07-027
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 200 lượt/giây
    Thì đạt ngưỡng: p95 ≤ 150 ms

  @TC-07-295 @P2 @Hiệu @năng
  Kịch bản: TC-07-295 Chuyển mã lô 500 qua ánh xạ
    # Truy vết: NFR-07-002 · FR-07-042
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 200 lượt/giây
    Thì đạt ngưỡng: p95 ≤ 150 ms

  @TC-07-296 @P2 @Hiệu @năng
  Kịch bản: TC-07-296 Lấy trang 1.000 bản ghi
    # Truy vết: NFR-07-003 · FR-07-028
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 100 lượt/giây
    Thì đạt ngưỡng: p95 ≤ 300 ms

  @TC-07-297 @P1 @Hiệu @năng
  Kịch bản: TC-07-297 Truy vấn DSL trên CAT-BIG (5 mẫu truy vấn)
    # Truy vết: NFR-07-004 · FR-07-032
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 50 lượt/giây
    Thì đạt ngưỡng: p95 ≤ 500 ms; truy vấn quá 2 giây bị ngắt

  @TC-07-298 @P1 @Hiệu @năng
  Kịch bản: TC-07-298 Nhập F-100K
    # Truy vết: NFR-07-005 · FR-07-021
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 1 tác vụ, lặp 5 lần
    Thì đạt ngưỡng: Xem trước ≤ 2 phút; commit ≤ 60 giây

  @TC-07-299 @P2 @Hiệu @năng
  Kịch bản: TC-07-299 Xuất 100.000 dòng xlsx; xuất đồng bộ 10.000 dòng
    # Truy vết: NFR-07-006 · FR-07-024
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 1 tác vụ; 10 lượt/phút
    Thì đạt ngưỡng: ≤ 60 giây; ≤ 5 giây

  @TC-07-300 @P1 @Hiệu @năng
  Kịch bản: TC-07-300 Phát hành 50.000 bản ghi kể cả ảnh chụp
    # Truy vết: NFR-07-007 · FR-07-016
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 1 lần, lặp 5 lần
    Thì đạt ngưỡng: ≤ 30 giây; sự kiện ≤ 5 giây

  @TC-07-301 @P1 @Hiệu @năng
  Kịch bản: TC-07-301 Thông lượng toàn cụm trên dữ liệu quy mô đầy đủ
    # Truy vết: NFR-07-008, 011
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 20.000 lượt/giây, 3 pod, 1 giờ, 34 tenant × 1.000 danh mục
    Thì đạt ngưỡng: Không suy giảm p95 quá 20% so với 15 phút đầu

  @TC-07-302 @P2 @Hiệu @năng
  Kịch bản: TC-07-302 Thời lượng (soak)
    # Truy vết: NFR-07-008, 012
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 30% tải đỉnh, 8 giờ
    Thì đạt ngưỡng: Không rò bộ nhớ (heap sau GC tăng < 5%), không tăng lỗi

  @TC-07-303 @P2 @Hiệu @năng
  Kịch bản: TC-07-303 Chuyển mã ĐVHC lô 1.000
    # Truy vết: FR-07-046
    Biết bộ dữ liệu quy mô NFR-07-011 ở PERF
    Khi chạy tải: 50 lượt/giây
    Thì đạt ngưỡng: p95 ≤ 300 ms
