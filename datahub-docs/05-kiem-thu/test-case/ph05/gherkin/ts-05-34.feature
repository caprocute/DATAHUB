# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-34
Tính năng: TS-05-34 · Hiệu năng, tải và quy mô

  @TC-05-130 @P2 @Hiệu @năng
  Kịch bản: TC-05-130 Độ trễ thêm của Kamelet giao thức
    # Truy vết: NFR-05-001 · FR-05-033, 034
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 200 lượt/giây qua `dh-http-sink` và gọi thẳng SIM-HTTP, 15 phút
    Thì đạt ngưỡng: p95 chênh ≤ 5 ms (HTTP), ≤ 15 ms (SOAP có WS-Security)

  @TC-05-131 @P2 @Hiệu @năng
  Kịch bản: TC-05-131 Phân giải kết nối và bí mật
    # Truy vết: NFR-05-002 · FR-05-015
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 10.000 lần phân giải có đệm, 1.000 lần không đệm
    Thì đạt ngưỡng: p99 ≤ 2 ms có đệm, ≤ 50 ms không đệm

  @TC-05-132 @P2 @Hiệu @năng
  Kịch bản: TC-05-132 API control plane
    # Truy vết: NFR-05-003, 013 · FR-05-002, 029
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 5.000 kết nối, 2.000 bộ điều hợp; 50 người dùng đồng thời, 30 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms

  @TC-05-133 @P2 @Hiệu @năng
  Kịch bản: TC-05-133 Thời gian kiểm tra kết nối
    # Truy vết: NFR-05-004 · FR-05-010
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 100 lần mỗi loại kết nối
    Thì đạt ngưỡng: ≤ 15 giây khi đích phản hồi; ≤ chờ + 5 giây khi không

  @TC-05-134 @P2 @Hiệu @năng
  Kịch bản: TC-05-134 Phát hiện mất kết nối
    # Truy vết: NFR-05-005 · FR-05-019
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 50 kết nối PROD, ngắt ngẫu nhiên 10
    Thì đạt ngưỡng: ≤ 3 phút tới `UNHEALTHY`

  @TC-05-135 @P2 @Hiệu @năng
  Kịch bản: TC-05-135 Hiệu lực tạm ngừng
    # Truy vết: NFR-05-006 · FR-05-008
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Ba bản sao, 100 lượt/giây
    Thì đạt ngưỡng: Từ chối lượt mới ≤ 30 giây

  @TC-05-136 @P1 @Hiệu @năng
  Kịch bản: TC-05-136 Thu hồi tài khoản động
    # Truy vết: NFR-05-007 · FR-05-028
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 20 tài khoản PostgreSQL, 20 MySQL
    Thì đạt ngưỡng: ≤ 60 giây

  @TC-05-137 @P1 @Hiệu @năng
  Kịch bản: TC-05-137 Thông lượng tệp CSV
    # Truy vết: NFR-05-008 · FR-05-036
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: F-CSV-1M, một bản sao, heap 512 MiB
    Thì đạt ngưỡng: ≥ 20.000 bản ghi/giây; heap không tăng theo cỡ tệp

  @TC-05-138 @P1 @Hiệu @năng
  Kịch bản: TC-05-138 Độ trễ CDC
    # Truy vết: NFR-05-009 · FR-05-052
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 500 thay đổi/giây, PostgreSQL 16, một connector, 30 phút
    Thì đạt ngưỡng: p95 ≤ 5 giây

  @TC-05-139 @P1 @Hiệu @năng
  Kịch bản: TC-05-139 Không mất thay đổi CDC khi khởi động lại
    # Truy vết: NFR-05-010 · FR-05-050
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 500 thay đổi/giây, xóa pod Connect 5 lần
    Thì đạt ngưỡng: 0 mất
