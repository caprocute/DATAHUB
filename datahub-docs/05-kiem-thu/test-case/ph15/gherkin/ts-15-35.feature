# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-35
Tính năng: TS-15-35 · Hiệu năng, tải và quy mô

  @TC-15-188 @P1 @Hiệu @năng
  Kịch bản: TC-15-188 Tải trang đầu
    # Truy vết: NFR-15-001 · UI-15-01, 02, 05
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Trang chủ, danh mục, tài liệu; máy 4 nhân, 8 GB, 20 Mbps; 30 lượt
    Thì đạt ngưỡng: LCP ≤ 2,5 giây, INP ≤ 200 ms

  @TC-15-189 @P1 @Hiệu @năng
  Kịch bản: TC-15-189 API danh mục và tìm kiếm
    # Truy vết: NFR-15-002, 012 · FR-15-004, 005
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 500 API, 3.000 phiên bản; 100 người đồng thời, 15 phút
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms; tìm p95 ≤ 300 ms; gợi ý p95 ≤ 200 ms

  @TC-15-190 @P1 @Hiệu @năng
  Kịch bản: TC-15-190 Hiển thị tài liệu
    # Truy vết: NFR-15-003 · FR-15-009
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Đặc tả 300 thao tác; 50 người đồng thời
    Thì đạt ngưỡng: `operations` p95 ≤ 500 ms; dựng trang ≤ 2 giây

  @TC-15-191 @P1 @Hiệu @năng
  Kịch bản: TC-15-191 Độ trễ đồng bộ
    # Truy vết: NFR-15-004 · FR-15-001
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 50 thay đổi mỗi phút, 10 phút; sau đó mất sự kiện
    Thì đạt ngưỡng: Sự kiện → hiển thị p95 ≤ 30 giây; kéo bù ≤ 5 phút

  @TC-15-192 @P1 @Hiệu @năng
  Kịch bản: TC-15-192 Độ trễ thêm của đường thử
    # Truy vết: NFR-15-005 · FR-15-035, 036
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 50 lượt thử đồng thời, MOCK và BACKEND, 10 phút
    Thì đạt ngưỡng: Ngoài thời gian backend p95 ≤ 100 ms; MOCK p95 ≤ 150 ms

  @TC-15-193 @P1 @Hiệu @năng
  Kịch bản: TC-15-193 Cấp credential
    # Truy vết: NFR-15-006 · FR-15-027
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 20 yêu cầu cấp đồng thời kể cả Keycloak
    Thì đạt ngưỡng: p95 ≤ 3 giây

  @TC-15-194 @P1 @Hiệu @năng
  Kịch bản: TC-15-194 Hiệu lực thu hồi, khóa
    # Truy vết: NFR-15-007 · FR-15-031, 059
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 100 lượt/giây; thu hồi 50 credential, khóa 10 ứng dụng
    Thì đạt ngưỡng: Chặn ≤ 60 giây; ≤ 5 giây khi nhận EVT-15-05

  @TC-15-195 @P2 @Hiệu @năng
  Kịch bản: TC-15-195 Thông lượng thử toàn tenant
    # Truy vết: NFR-15-013 · FR-15-039
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: ≥ 100 lượt/giây, 10 phút, hạn mức tenant 100
    Thì đạt ngưỡng: Giữ NFR-15-005; vượt thì 429 chứ không lỗi 5xx

  @TC-15-196 @P1 @Hiệu @năng
  Kịch bản: TC-15-196 Truy cập ẩn danh chịu tải
    # Truy vết: NFR-15-018 · FR-15-008
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 300 lượt/giây trang `PUBLIC`; một IP vượt trần
    Thì đạt ngưỡng: Phục vụ nhờ bộ đệm, p95 ≤ 300 ms; IP vượt trần bị 429

  @TC-15-197 @P2 @Hiệu @năng
  Kịch bản: TC-15-197 Quy mô tenant vừa
    # Truy vết: NFR-15-012 · FR-15-001, 025, 058
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 500 API, 3.000 phiên bản, 2.000 tài khoản dh-dev, 2.000 ứng dụng, 300 trang, 100 người đồng thời, 1 giờ
    Thì đạt ngưỡng: Mọi ngưỡng trên giữ; 0 lỗi 5xx
