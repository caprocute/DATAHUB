# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-10
Tính năng: TS-05-10 · Sức khỏe kết nối và bộ điều hợp

  @TC-05-038 @P1 @Dương
  Kịch bản: TC-05-038 Phát hiện mất kết nối trong 3 phút
    # Truy vết: FR-05-019, 021 · API-05-034 · EVT-05-06 · NFR-05-005 · UC-05-12
    Biết U-T68-TO; C-NDXP PROD `HEALTHY`.
    Khi ngắt SIM-HTTP lúc t0.
    Và theo dõi `GET …/ndxp-ho-tich/health?env=PROD`.
    Và bật lại SIM-HTTP.
    Thì trạng thái `UNHEALTHY` ≤ t0 + 3 phút; EVT: `health.changed` một lần mỗi lần đổi mức (không lặp mỗi chu kỳ); TO nhận cảnh báo PH-13. Bước 3 về `HEALTHY` sau ba chu kỳ đạt (FR-05-021), EVT lần nữa.

  @TC-05-039 @P2 @Dương
  Kịch bản: TC-05-039 Suy giảm thụ động theo p95 so với nền
    # Truy vết: FR-05-020 · API-05-034
    Biết C-NDXP có `health_baseline` p95 = 400 ms; luồng mẫu 10 lượt/giây.
    Thì sức khỏe `DEGRADED` với lý do "p95 gấp 2,5 lần nền"; hết chậm thì về `HEALTHY`.

  @TC-05-040 @P2 @Dương
  Kịch bản: TC-05-040 Tổng quan sức khỏe và lưới nhiệt
    # Truy vết: FR-05-022 · API-05-033 · UI-05-07
    Biết U-T68-TO; sau TC-05-038.
    Thì thẻ chỉ số khớp `GET /health/overview`; danh sách chú ý có C-NDXP đứng đầu; lưới nhiệt có bảng thay thế đọc được bằng trình đọc màn hình; tự làm mới dừng khi tab ẩn.

  @TC-05-041 @P2 @Dương @Âm
  Kịch bản: TC-05-041 PH-04 đọc trạng thái sức khỏe qua API nội bộ
    # Truy vết: FR-05-021 · API-05-093 · ERR-05-012
    Biết S-INT; U-T68-IE1.
    Khi S-INT `GET /internal/health/states?tenant=T68`.
    Và U-T68-IE1 gọi cùng đường.
    Thì bước 1 `200`, mỗi mục `kind`, `code`, `env`, `level`, `since`. Bước 2 403-PQ (thiếu scope `adapter:health-read`).

  @TC-05-148 @P2 @Âm
  Kịch bản: TC-05-148 Không đánh giá sai sức khỏe khi tắt hoặc ít lưu lượng
    # Truy vết: FR-05-019, 020, 022 · API-05-033, 034 · ERR-05-003
    Biết U-T68-TO; `tc-e6` TEST `DISABLED`; C-NDXP PROD có 3 lượt gọi chậm trong 10 phút (dưới ngưỡng mẫu tối thiểu).
    Khi chờ 3 chu kỳ thăm dò; `GET …/tc-e6/health?env=TEST`.
    Và `GET …/ndxp-ho-tich/health?env=PROD`.
    Và `GET /health/overview?env=DEV`.
    Thì bước 1 `UNKNOWN`, không có lần thăm dò nào tới hệ đích của môi trường đã tắt. Bước 2 giữ `HEALTHY` (không đủ mẫu để kết luận suy giảm). Bước 3 `400` ERR-05-003.
