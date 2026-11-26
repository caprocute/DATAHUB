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

  @TC-14-143 @P2 @Hiệu @năng
  Kịch bản: TC-14-143 Từ chối chiều vào không chạm backend
    # Truy vết: NFR-14-016, NFR-14-014
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 2.000 yêu cầu/giây từ nguồn không hợp lệ (chứng thư mTLS sai, nguồn ngoài danh sách), 10 phút, 3 bản sao
    Thì đạt ngưỡng: từ chối p99 ≤ 50 ms; 0 lượt tới PH-04

  @TC-14-144 @P1 @Hiệu @năng
  Kịch bản: TC-14-144 Thông lượng toàn cụm và 34 tenant
    # Truy vết: NFR-14-006, NFR-14-019, NFR-14-012
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: 500 lượt/giây toàn cụm 30 phút, 34 tenant (một tenant tỉnh vừa 300 lượt/giây), KEDA mở rộng
    Thì đạt ngưỡng: ≥ 500 lượt/giây, không suy giảm, 0 lỗi do PH-14, tenant nhỏ không chậm hơn

  @TC-14-145 @P1 @Hiệu @năng
  Kịch bản: TC-14-145 Dữ liệu quá hạn sau khi ngắt mạch mở
    # Truy vết: NFR-14-009
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: `sim-ndxp` `DOWN` giữa tải 300 lượt/giây, dịch vụ `staleAllowed`
    Thì đạt ngưỡng: ≤ 1 giây sau khi ngắt mạch mở, trả dữ liệu đệm quá hạn có cờ hoặc lỗi thân thiện

  @TC-14-146 @P2 @Hiệu @năng
  Kịch bản: TC-14-146 Hiệu lực tạm ngừng và nạp nóng
    # Truy vết: NFR-14-017, NFR-14-026
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: Tạm ngừng nền tảng, đổi luật, hạn mức, chứng thư, tham số khi tải 300 lượt/giây, 3 bản sao
    Thì đạt ngưỡng: từ chối lượt mới ≤ 30 giây; lượt đang chạy kết thúc ≤ 30 giây; cấu hình mới hiệu lực ≤ 30 giây, không khởi động lại

  @TC-14-147 @P1 @Hiệu @năng
  Kịch bản: TC-14-147 Cảnh báo kịp thời
    # Truy vết: NFR-14-018, NFR-14-007
    Biết bộ dữ liệu quy mô tỉnh vừa theo GĐ-07 (mục 1.3), NDXP giả lập
    Khi chạy tải: Gây chữ ký sai, hạn mức 70, 85, 95 %, mất kết nối quá 5 phút, đo từ lúc xảy ra tới lúc thông báo
    Thì đạt ngưỡng: chữ ký sai ≤ 1 phút; hạn mức ≤ 2 phút; mất kết nối ≤ 1 phút sau mốc
