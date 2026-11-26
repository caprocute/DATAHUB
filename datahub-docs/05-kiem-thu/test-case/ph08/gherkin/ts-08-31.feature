# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-31
Tính năng: TS-08-31 · Kiểm toán và truy vết xuyên suốt

  @TC-08-141 @P1 @Dương @Bảo @mật
  Kịch bản: TC-08-141 Mọi hành động thay đổi đều có kiểm toán
    # Truy vết: FR-08-060 · FR-08-001 · FR-08-018 · FR-08-021 · FR-08-040 · FR-08-044 · FR-08-053 · FR-08-058 · API-08-127 · UI-08-04
    Biết T90; chuỗi hành động từ các ca TS-08-01…27.
    Khi thực hiện: tạo miền, kích hoạt bộ quy tắc, duyệt trọng số, duyệt ngoại lệ, xác nhận phiếu, xuất lỗi, công bố báo cáo, đổi tham số
    Và `GET /audit-events` theo từng hành động
    Và mở tab "Lịch sử" của `mdm-citizen` ở UI-08-04
    Thì mỗi hành động có một bản ghi với người thao tác, tenant, hành động, đối tượng, giá trị trước và sau, `traceId`, thời điểm; không có giá trị thuộc tính Nhạy cảm; tab "Lịch sử" hiển thị cùng bản ghi.

  @TC-08-142 @P2 @Dương
  Kịch bản: TC-08-142 traceId xuyên lần đo, tác vụ và lời gọi phụ thuộc
    # Truy vết: FR-08-060 · NFR-08-020 · NFR-08-015 · API-08-061
    Biết lần đo `FULL` của `mdm-citizen` có lời gọi tới `mdm-sim`, `rdm-sim`, `conn-sim`; Tempo, Prometheus.
    Khi chạy lần đo, lấy `traceId`
    Và tìm trong Tempo
    Và đọc `/metrics`
    Thì một cây vết gồm lần đo, các tác vụ, lời gọi PH-05, PH-06, PH-07 cùng `traceId`. Có đủ chỉ số `dq_scan_jobs_total`, `dq_scan_duration_seconds`, `dq_score_gauge`, `dq_findings_total`, `dq_check_total`, `dq_check_duration_seconds`, `dq_issues_overdue`, `dq_outbox_lag_seconds`.
