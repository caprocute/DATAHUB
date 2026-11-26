# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-22
Tính năng: TS-16-22 · Theo dõi vận hành thu thập và tính toán

  @TC-16-080 @P2 @Dương
  Kịch bản: TC-16-080 Tổng quan vận hành và chỉ số vận hành của chính PH-16
    # Truy vết: FR-16-042, FR-16-058 · API-16-093, 049 · UI-16-08 · NFR-16-019
    Biết T90 có 12 nguồn `ACTIVE`, 2 `STALE`, 1 `FAILED`, 1 `PAUSED`; 1 xuất đang chạy; 1 gói quốc gia `FAILED`.
    Khi U-T90-TO1 `GET /ops/overview`
    Và `GET /runs?state=FAILED&from=2026-11-01`
    Và U-PO xem tổng hợp toàn nền tảng
    Và `GET /actuator/prometheus` rồi quét chuỗi mồi `DH-CANARY-ops`
    Thì bước 1 `sources` = {ACTIVE 12, STALE 2, FAILED 1, PAUSED 1}, `runs[]` các lần gần nhất, `exports.running = 1`, `national.failed = 1`, `outboxLagSeconds` số nguyên ≥ 0. Bước 2 lọc đúng. Bước 3 PO thấy theo từng tenant, không thấy nội dung báo cáo. Bước 4 có đủ `kpi_observations_total{source,result}`, `kpi_source_state{source}`, `kpi_run_duration_seconds`, `kpi_run_completeness`, `kpi_indicator_status{group,status}`, `kpi_report_publish_total{result}`, `kpi_national_submission_total{type,state}`, `kpi_outbox_lag_seconds`, khớp dữ liệu; không nhãn nào chứa định danh người dùng hay chuỗi mồi.
