# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-32
Tính năng: TS-06-32 · Hiệu năng, tải và quy mô

  @TC-06-134 @P1 @Hiệu @năng
  Kịch bản: TC-06-134 Tra bản ghi vàng p99 ≤ 50 ms
    # Truy vết: NFR-06-001 · API-06-056, 070
    # Mục đích: Đo NFR-06-001 ở 200 lượt mỗi giây qua APISIX.
    Biết T97 F-PERF; tra theo ID và khóa, tỷ lệ 70/30.
    Khi k6 200 lượt mỗi giây trong 15 phút, 5 phút khởi động.
    Thì p99 ≤ 50 ms, 0 lỗi `5xx`, không tính mạng ngoài.
    # Hậu điều kiện: Báo cáo k6.

  @TC-06-135 @P1 @Hiệu @năng
  Kịch bản: TC-06-135 Resolve xác định p99 ≤ 30 ms
    # Truy vết: NFR-06-002 · API-06-071
    # Mục đích: Đo NFR-06-002 cho resolve có CCCD.
    Biết T97.
    Khi k6 resolve 100 % có CCCD hợp lệ, 200 lượt mỗi giây, đo trong `dh-data`.
    Thì p99 ≤ 30 ms.
    # Hậu điều kiện: Báo cáo.

  @TC-06-136 @P1 @Hiệu @năng
  Kịch bản: TC-06-136 Resolve xác suất p95 ≤ 300 ms, p99 ≤ 800 ms
    # Truy vết: NFR-06-003 · API-06-071
    # Mục đích: Đo NFR-06-003 gồm gom nhóm và chấm điểm trên 1,2 triệu CITIZEN.
    Biết T97; hồ sơ không CCCD.
    Khi k6 100 lượt mỗi giây 15 phút.
    Thì p95 ≤ 300 ms, p99 ≤ 800 ms; tỷ lệ `TIMEOUT` < 1 %.
    # Hậu điều kiện: Báo cáo.

  @TC-06-137 @P1 @Hiệu @năng
  Kịch bản: TC-06-137 Thông lượng nạp 1.000 bản ghi mỗi giây
    # Truy vết: NFR-06-004, 005 · API-06-021
    # Mục đích: Đo NFR-06-004 và dung lượng NFR-06-005.
    Biết T97 nạp; T98 10 triệu bản ghi vàng.
    Khi nạp 1.000 bản ghi mỗi giây duy trì 10 phút.
    Và trên T98 lặp perf-lookup.
    Thì hàng chờ không quá 5 phút. Ở T98 tra vẫn p99 ≤ 50 ms.
    # Hậu điều kiện: Báo cáo.

  @TC-06-138 @P1 @Hiệu @năng
  Kịch bản: TC-06-138 Job lô 1,2 triệu CITIZEN ≤ 2 giờ
    # Truy vết: NFR-06-013 · FR-06-022
    # Mục đích: Đo NFR-06-013 trên Job 8 vCPU, 32 GB (giả định theo số đo công bố của Splink).
    Biết T99 1,2 triệu CITIZEN, bộ quy tắc ACTIVE.
    Khi chạy `FULL_INITIAL`, ghi thời gian từng pha.
    Thì từ `QUEUED` tới `SUCCEEDED` ≤ 2 giờ; bộ nhớ Job không quá giới hạn.
    # Hậu điều kiện: Số đo làm cơ sở GĐ.

  @TC-06-139 @P2 @Hiệu @năng
  Kịch bản: TC-06-139 Độ trễ sự kiện và đồng bộ chiều xuống
    # Truy vết: NFR-06-014, 020 · EVT-06-02 · FR-06-050, 053
    # Mục đích: Đo NFR-06-014 và NFR-06-020.
    Biết T97, T94.
    Khi cập nhật 100 bản ghi mỗi giây 10 phút, đo `mdm_event_lag_seconds`.
    Và `nat-sim` gửi 10.000 thay đổi, đo thời điểm áp.
    Thì commit tới Kafka p95 ≤ 5 giây. Áp thay đổi quốc gia p95 ≤ 15 phút.
    # Hậu điều kiện: Báo cáo.
