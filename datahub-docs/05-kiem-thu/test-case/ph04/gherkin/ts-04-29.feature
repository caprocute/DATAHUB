# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-29
Tính năng: TS-04-29 · Hiệu năng

  @TC-04-159 @P2 @Hiệu @năng
  Kịch bản: TC-04-159 Mở bảng thành phần với toàn bộ catalog
    # Truy vết: NFR-04-001 · UI-04-04
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Lighthouse trên máy văn phòng chuẩn D05-03, catalog đã ở bộ đệm
    Thì đạt ngưỡng: < 300 ms

  @TC-04-160 @P2 @Hiệu @năng
  Kịch bản: TC-04-160 Gõ tìm trong bảng thành phần
    # Truy vết: NFR-04-002 · FR-04-012
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 50 lần gõ, `performance.now`
    Thì đạt ngưỡng: < 50 ms mỗi lần

  @TC-04-161 @P2 @Hiệu @năng
  Kịch bản: TC-04-161 Kéo chặng trên sơ đồ 200 chặng
    # Truy vết: NFR-04-003 · FR-04-013
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: YAML-200, Chrome DevTools trace 10 giây kéo liên tục
    Thì đạt ngưỡng: ≥ 50 khung hình/giây; tối thiểu 30

  @TC-04-162 @P2 @Hiệu @năng
  Kịch bản: TC-04-162 Mở trình thiết kế với luồng 200 chặng
    # Truy vết: NFR-04-004 · UI-04-04
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: YAML-200, Lighthouse TTI
    Thì đạt ngưỡng: < 2 s

  @TC-04-163 @P2 @Hiệu @năng
  Kịch bản: TC-04-163 Sinh lại YAML sau một thay đổi
    # Truy vết: NFR-04-005 · FR-04-017
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: UT đo 1.000 thay đổi ngẫu nhiên trên YAML-200
    Thì đạt ngưỡng: p99 < 100 ms

  @TC-04-164 @P2 @Hiệu @năng
  Kịch bản: TC-04-164 Mở cửa sổ cấu hình chặng 154 thuộc tính
    # Truy vết: NFR-04-006 · FR-04-014
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Thành phần `kafka`
    Thì đạt ngưỡng: < 400 ms

  @TC-04-165 @P1 @Hiệu @năng
  Kịch bản: TC-04-165 Kiểm tra hợp lệ mức SUBMIT
    # Truy vết: NFR-04-007 · API-04-030
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: k6, 20 người dùng ảo, YAML-200
    Thì đạt ngưỡng: p95 < 2 s

  @TC-04-166 @P1 @Hiệu @năng
  Kịch bản: TC-04-166 Chạy thử MOCK luồng chín chặng
    # Truy vết: NFR-04-008 · API-04-040
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: k6, 5 lần đồng thời mỗi tenant × 3 tenant, 30 phút
    Thì đạt ngưỡng: p95 < 5 s

  @TC-04-167 @P1 @Hiệu @năng
  Kịch bản: TC-04-167 Từ nâng PROD tới SYNCED
    # Truy vết: NFR-04-009 · API-04-056
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 30 lần nâng trên STAGING của PERF
    Thì đạt ngưỡng: p95 < 3 phút

  @TC-04-168 @P1 @Hiệu @năng
  Kịch bản: TC-04-168 Lệnh tạm dừng tới đủ xác nhận
    # Truy vết: NFR-04-010 · API-04-061
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 4 bản sao, 50 lệnh thường, 20 lệnh khẩn
    Thì đạt ngưỡng: p95 < 10 s; khẩn < 5 s

  @TC-04-169 @P1 @Hiệu @năng
  Kịch bản: TC-04-169 Độ trễ thêm của khung chín chặng
    # Truy vết: NFR-04-011 · FR-04-060
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: k6 200 yêu cầu/giây, JSON 10 KiB, đích WireMock 20 ms; so với luồng chỉ có `from` và `to`
    Thì đạt ngưỡng: p95 thêm < 15 ms

  @TC-04-170 @P1 @Hiệu @năng
  Kịch bản: TC-04-170 Thông lượng một vCPU runtime native
    # Truy vết: NFR-04-012 · FR-04-075
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: k6 tăng dần tới bão hòa, luồng chuyển đổi JSON chuẩn, 1 vCPU
    Thì đạt ngưỡng: ≥ 400 bản tin/giây, lỗi < 0,1%

  @TC-04-171 @P1 @Hiệu @năng
  Kịch bản: TC-04-171 Khởi động pod runtime native
    # Truy vết: NFR-04-013 · FR-04-075
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 20 lần khởi động, có và không có 50 luồng
    Thì đạt ngưỡng: < 1 s; < 5 s với 50 luồng

  @TC-04-172 @P2 @Hiệu @năng
  Kịch bản: TC-04-172 Danh sách luồng với 300 luồng mỗi tenant
    # Truy vết: FR-04-001 · API-04-010
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: k6 50 người dùng ảo, lọc và tìm ngẫu nhiên
    Thì đạt ngưỡng: p95 < 500 ms
