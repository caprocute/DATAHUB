# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-29
Tính năng: TS-05-29 · Runtime phân giải kết nối và PH-04 xác minh tham chiếu

  @TC-05-113 @P1 @Dương @Bảo @mật
  Kịch bản: TC-05-113 Runtime nhận cấu hình kết nối không có bí mật
    # Truy vết: FR-05-015 · API-05-032 · BR-05-003 · UC-05-24
    Biết S-RT-T68.
    Thì `200`, mỗi kết nối `ENABLED` có tham số, `secretPath`, `secretVersion`, hạn mức đồng thời mỗi bản sao; không có giá trị bí mật; mồi sạch; có `ETag` để hỏi lại có điều kiện.

  @TC-05-114 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-114 Runtime T01 không đọc được cấu hình T68
    # Truy vết: FR-05-015 · API-05-032 · BR-05-002 · ERR-05-012
    Biết S-RT-T01; U-T68-IE1.
    Thì S-RT-T01 nhận cấu hình T01 (tham số `tenant` bị bỏ qua, tenant lấy từ token) với `baseUrl` của T01 cho mã `ndxp-ho-tich`; IE1 403-PQ.

  @TC-05-115 @P1 @Dương @Âm
  Kịch bản: TC-05-115 PH-04 xác minh tham chiếu khi phát hành
    # Truy vết: FR-05-014 · API-05-031 · ERR-05-013, 014, 118 · UC-05-25
    Biết S-INT; luồng ở không gian `ho-tich` tham chiếu `ndxp-ho-tich` (đã cấp), `tc-chua-cap` (chưa cấp), `tc-e1` (PROD chưa có giá trị), `tc-tam-ngung` (`SUSPENDED`).
    Thì trả từng mục: `ndxp-ho-tich` OK; `tc-chua-cap` ERR-05-013; `tc-e1` ERR-05-014; `tc-tam-ngung` ERR-05-118. Chỉ mục `usage_ref` được ghi khi PH-04 phát hành thành công.

  @TC-05-116 @P1 @Hiệu @năng @Khả
  Kịch bản: TC-05-116 Phân giải kết nối nhanh khi có đệm; OpenBao mất
    # Truy vết: FR-05-015 · NFR-05-002, 012 · ERR-05-101
    Biết luồng mẫu gọi C-NDXP liên tục.
    Khi đo thời gian phân giải `{{conn:ndxp-ho-tich}}` 10.000 lần.
    Và dừng OpenBao 10 phút; rồi tới khi hết đệm 5 phút với kết nối chưa có trong đệm.
    Và dừng `dh-integration` 24 giờ (đồng hồ giả).
    Thì bước 1 p99 ≤ 2 ms khi có đệm. Bước 2 kết nối đã đệm vẫn chạy; kết nối chưa đệm trả ERR-05-101. Bước 3 luồng đang chạy tiếp tục.
