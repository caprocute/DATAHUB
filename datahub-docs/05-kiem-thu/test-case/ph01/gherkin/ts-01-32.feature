# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-32
Tính năng: TS-01-32 · Hiệu năng, tải và quy mô

  @TC-01-125 @P2 @Hiệunăng
  Kịch bản: TC-01-125 Độ trễ API điều khiển
    # Truy vết: NFR-01-001 · FR-01-001, 002
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: 1.000 HTTT, 5.000 định danh; 50 người dùng đồng thời, 30 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms

  @TC-01-126 @P2 @Hiệunăng
  Kịch bản: TC-01-126 Tải danh sách HTTT
    # Truy vết: NFR-01-003 · FR-01-001
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: 500 HTTT, trang 50 dòng kèm facets, 20 luồng
    Thì đạt ngưỡng: p99 ≤ 1 giây

  @TC-01-127 @P1 @Hiệunăng
  Kịch bản: TC-01-127 Cấp định danh SANDBOX sau phê duyệt
    # Truy vết: NFR-01-004 · FR-01-020
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: 100 phê duyệt liên tiếp, PH-12, PH-03, OpenBao khỏe
    Thì đạt ngưỡng: p95 ≤ 5 phút từ phê duyệt tới có bàn giao hoặc chờ khóa

  @TC-01-128 @P1 @Hiệunăng
  Kịch bản: TC-01-128 Hiệu lực cắt quyền
    # Truy vết: NFR-01-008 · FR-01-029, 032
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: Ba bản sao APISIX, 100 lượt gọi/giây; 20 lệnh tạm ngừng, thu hồi, khẩn
    Thì đạt ngưỡng: Cổng từ chối ≤ 60 giây; ACL Kafka ≤ 2 phút

  @TC-01-129 @P2 @Hiệunăng
  Kịch bản: TC-01-129 Độ trễ sự kiện trạng thái
    # Truy vết: NFR-01-021 · FR-01-037
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: 100 chuyển trạng thái/giây, 10 phút
    Thì đạt ngưỡng: p95 ≤ 5 giây từ commit tới Kafka, không mất

  @TC-01-130 @P2 @Hiệunăng
  Kịch bản: TC-01-130 Quy mô tối đa của tenant
    # Truy vết: NFR-01-017 · FR-01-001, 045
    Biết bộ dữ liệu quy mô tỉnh vừa GĐ-07 (mục 2.6)
    Khi chạy tải: 1.000 HTTT, 5.000 định danh, 20.000 đầu mối, 50.000 mục trần phạm vi
    Thì đạt ngưỡng: Các chỉ tiêu độ trễ ở trên vẫn đạt
