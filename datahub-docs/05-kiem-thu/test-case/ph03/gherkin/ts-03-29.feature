# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-29
Tính năng: TS-03-29 · Hiệu năng, tải và quy mô

  @TC-03-116 @P1 @Hiệu @năng
  Kịch bản: TC-03-116 Độ trễ thêm tại gateway đủ chuỗi plugin
    # Truy vết: NFR-03-001 · FR-03-005, 012, 019, 021
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 300 lượt/giây, đủ chuỗi plugin và WAF, thân ≤ 32 KB, 30 phút
    Thì đạt ngưỡng: p95 ≤ 50 ms, p99 ≤ 100 ms

  @TC-03-117 @P1 @Hiệu @năng
  Kịch bản: TC-03-117 Chi phí từng chốt
    # Truy vết: NFR-03-002 · FR-03-012, 019, 021, 005
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1.000 lượt/giây, đo từng plugin
    Thì đạt ngưỡng: JWT p99 ≤ 2 ms; hạn mức p99 ≤ 3 ms; OPA p99 ≤ 2 ms; WAF ≤ 5 ms (≤ 32 KB)

  @TC-03-118 @P1 @Hiệu @năng
  Kịch bản: TC-03-118 Thông lượng danh định
    # Truy vết: NFR-03-003 · FR-03-028, 029
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1.000 lượt/giây trên 3 bản sao 30 phút; thang tới 3.000
    Thì đạt ngưỡng: Lỗi do nền tảng < 0,1 %; đạt 3.000 lượt/giây danh định

  @TC-03-119 @P2 @Hiệu @năng
  Kịch bản: TC-03-119 Kết nối đồng thời
    # Truy vết: NFR-03-004 · FR-03-033
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 20.000 kết nối HTTP/2 giữ trên mỗi bản sao
    Thì đạt ngưỡng: Không từ chối, bộ nhớ ổn định

  @TC-03-120 @P1 @Hiệu @năng
  Kịch bản: TC-03-120 Nạp cấu hình dưới tải
    # Truy vết: NFR-03-008 · FR-03-042, 043
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 2.000 lượt/giây, phát 20 ảnh chụp liên tiếp
    Thì đạt ngưỡng: 0 lượt lỗi; lan truyền ≤ 10 s, ≤ 60 s theo yêu cầu hệ thống

  @TC-03-121 @P1 @Hiệu @năng
  Kịch bản: TC-03-121 Chống tràn tầng 7
    # Truy vết: NFR-03-013 · FR-03-003, 004
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Gấp 3 lần cao điểm (900 lượt/giây), rồi đột biến gấp 10 lần trong 30 giây từ 50 địa chỉ
    Thì đạt ngưỡng: Data plane không suy giảm; nguồn tấn công bị chặn ≤ 60 giây

  @TC-03-122 @P2 @Hiệu @năng
  Kịch bản: TC-03-122 Số route và độ trễ so khớp
    # Truy vết: NFR-03-017 · FR-03-028
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1.000 route mỗi tenant; thang tới 70.000 route nền tảng (QM-CHUNG)
    Thì đạt ngưỡng: Độ trễ so khớp tăng ≤ 10 % so với 100 route

  @TC-03-123 @P2 @Hiệu @năng
  Kịch bản: TC-03-123 Mở rộng tự động
    # Truy vết: NFR-03-018 · FR-03-028
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Tăng tải dần từ 300 tới 3.000 lượt/giây
    Thì đạt ngưỡng: HPA CPU 60 %, 3 đến 10 bản sao; gấp đôi tài nguyên ≥ 1,8 lần thông lượng

  @TC-03-124 @P1 @Hiệu @năng
  Kịch bản: TC-03-124 Cách ly hạn mức giữa hai tenant
    # Truy vết: NFR-03-019 · FR-03-023
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: T68 tải 800 lượt/giây vượt hạn mức, T01 tải nền 100 lượt/giây
    Thì đạt ngưỡng: p95 của T01 tăng ≤ 10 %, 0 lượt T01 đọc dữ liệu T68

  @TC-03-125 @P2 @Hiệu @năng
  Kịch bản: TC-03-125 Độ trễ số liệu tới bảng điều khiển
    # Truy vết: NFR-03-021 · FR-03-055
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Sự kiện đánh dấu mỗi phút trong 1 giờ
    Thì đạt ngưỡng: Chỉ số tới biểu đồ ≤ 15 giây

  @TC-03-126 @P2 @Hiệu @năng
  Kịch bản: TC-03-126 Truy vấn nhật ký lượt gọi
    # Truy vết: NFR-03-022 · FR-03-051
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: ClickHouse 5 triệu bản ghi/ngày/tenant, 31 ngày; 20 truy vấn đồng thời
    Thì đạt ngưỡng: p95 ≤ 3 giây

  @TC-03-127 @P2 @Hiệu @năng
  Kịch bản: TC-03-127 API quản trị
    # Truy vết: NFR-03-023 · FR-03-028, 046
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1.000 route, 200 consumer mỗi tenant; 50 người dùng đồng thời, 30 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms
