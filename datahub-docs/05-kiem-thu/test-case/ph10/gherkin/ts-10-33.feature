# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-33
Tính năng: TS-10-33 · Hiệu năng, tải và quy mô

  @TC-10-137 @P2 @Hiệu @năng
  Kịch bản: TC-10-137 API control plane
    # Truy vết: NFR-10-001 · FR-10-001, 006, 035
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 500 topic, 2.000 subscription mỗi tenant; 50 người dùng đồng thời, 30 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms

  @TC-10-138 @P1 @Hiệu @năng
  Kịch bản: TC-10-138 Độ trễ API phát
    # Truy vết: NFR-10-002 · FR-10-033
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 500 sự kiện/giây, 2 KB, Avro, 30 phút
    Thì đạt ngưỡng: p99 ≤ 50 ms tới `202`, gồm kiểm lược đồ và `acks=all`

  @TC-10-139 @P1 @Hiệu @năng
  Kịch bản: TC-10-139 Độ trễ đầu cuối khi đẩy
    # Truy vết: NFR-10-003 · FR-10-038
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 200 sự kiện/giây, endpoint 50 ms, không tồn đọng
    Thì đạt ngưỡng: p95 ≤ 1 giây từ ghi Kafka tới gửi

  @TC-10-140 @P2 @Hiệu @năng
  Kịch bản: TC-10-140 Thông lượng cổng sự kiện
    # Truy vết: NFR-10-004 · FR-10-033
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: Tăng dần tới bão hòa, 1, 2, 3 bản sao 1 vCPU
    Thì đạt ngưỡng: ≥ 2.000 sự kiện/giây mỗi bản sao, tuyến tính tới 3

  @TC-10-141 @P2 @Hiệu @năng
  Kịch bản: TC-10-141 Thông lượng bộ giao nhận
    # Truy vết: NFR-10-005 · FR-10-038
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 2.000 subscription đẩy, endpoint 50 ms, 3 bản sao
    Thì đạt ngưỡng: ≥ 200 lượt/giây mỗi bản sao

  @TC-10-142 @P2 @Hiệu @năng
  Kịch bản: TC-10-142 Thời gian cấp phát
    # Truy vết: NFR-10-008 · FR-10-009, 031, 037
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 50 topic, 100 subscription duyệt liên tiếp, Argo CD 30 giây
    Thì đạt ngưỡng: Topic `ACTIVE` p95 ≤ 3 phút; quan hệ ≤ 2 phút

  @TC-10-143 @P1 @Hiệu @năng
  Kịch bản: TC-10-143 Hiệu lực tạm ngừng, thu hồi
    # Truy vết: NFR-10-009 · FR-10-032, 029
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 100 lượt phát/giây, 3 bản sao cổng
    Thì đạt ngưỡng: API từ chối ≤ 60 giây; ACL ≤ 2 phút

  @TC-10-144 @P1 @Hiệu @năng
  Kịch bản: TC-10-144 Phát hiện lag
    # Truy vết: NFR-10-010 · FR-10-054, 055
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 5.000 nhóm tiêu thụ, 200 vượt ngưỡng ngẫu nhiên
    Thì đạt ngưỡng: Cảnh báo ≤ 2 phút

  @TC-10-145 @P2 @Hiệu @năng
  Kịch bản: TC-10-145 Hiệu lực tạm dừng subscription
    # Truy vết: NFR-10-011 · FR-10-041
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 100 subscription đẩy đang giao
    Thì đạt ngưỡng: Không lượt mới sau ≤ 10 giây

  @TC-10-146 @P2 @Hiệu @năng
  Kịch bản: TC-10-146 Tốc độ phát lại
    # Truy vết: NFR-10-012 · FR-10-052
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 1 triệu sự kiện, endpoint 20 ms
    Thì đạt ngưỡng: ≥ 2.000 sự kiện/giây; tôn trọng `ratePerSecond` ±5 %

  @TC-10-147 @P2 @Hiệu @năng
  Kịch bản: TC-10-147 Quy mô cụm
    # Truy vết: NFR-10-014 · FR-10-010, 054
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 1.000 topic, 10.000 phân vùng, 5.000 nhóm; 500 topic một tenant
    Thì đạt ngưỡng: Control plane, bộ thu lag, đối soát hết chu kỳ trong thời hạn

  @TC-10-148 @P2 @Hiệu @năng
  Kịch bản: TC-10-148 Hiển thị sơ đồ
    # Truy vết: NFR-10-015 · FR-10-058
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 300 nút, 600 cạnh, máy văn phòng chuẩn
    Thì đạt ngưỡng: ≤ 2 giây; kéo 60 khung hình/giây

  @TC-10-149 @P2 @Hiệu @năng
  Kịch bản: TC-10-149 Cầu nối di trú
    # Truy vết: NFR-10-018 · FR-10-073, 075
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3), tenant T97…T99
    Khi chạy tải: 200 sự kiện/giây mỗi cầu nối, 24 giờ
    Thì đạt ngưỡng: p95 ≤ 60 giây; đối chiếu chênh 0
