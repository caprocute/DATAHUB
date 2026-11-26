# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-32
Tính năng: TS-08-32 · Hiệu năng kiểm tra trực tuyến

  @TC-08-143 @P1 @Hiệu @năng
  Kịch bản: TC-08-143 p95 kiểm tra trực tuyến ≤ 50 ms
    # Truy vết: NFR-08-001 · FR-08-032 · API-08-068
    Biết T97; `dh-data` 2 bản sao 4 vCPU, 8 GB; bộ quy tắc 50 quy tắc không `UNIQUE_*`; bộ đệm đã nóng; bản ghi trung bình 2 KB.
    Khi k6 500 lượt mỗi giây gọi `POST /checks:evaluate` trong 15 phút, bỏ 5 phút khởi động; đo ở máy chủ
    Thì p95 ≤ 50 ms, p99 ≤ 100 ms, 0 lỗi `5xx`.

  @TC-08-144 @P1 @Hiệu @năng
  Kịch bản: TC-08-144 Thông lượng ≥ 2.000 bản ghi mỗi giây
    # Truy vết: NFR-08-002 · FR-08-032 · API-08-068, 069
    Biết như perf-inline; dùng `evaluate-batch` 20 bản ghi mỗi lần.
    Khi k6 tăng dần đến tải đều 2.000 bản ghi mỗi giây trong 15 phút
    Thì duy trì ≥ 2.000 bản ghi mỗi giây, tỷ lệ lỗi < 0,1 %.

  @TC-08-145 @P2 @Hiệu @năng @Chịu
  Kịch bản: TC-08-145 Bộ đệm quy tắc và tra PH-07
    # Truy vết: NFR-08-005 · NFR-08-006 · FR-08-027 · EVT-08-01
    Biết `dq_inline_rule_cache_hit_ratio`; `rdm-sim` có độ trễ 40 ms mỗi lô 500 mã.
    Khi chạy tải perf-inline và đọc tỷ lệ trúng
    Và kích hoạt phiên bản mới, đo thời gian đến lúc `ruleSetVersion` mới xuất hiện
    Và tra PH-07 lô 500 mã
    Và ép `rdm-sim` lỗi 5 lần liên tiếp rồi chờ 30 giây
    Thì tỷ lệ trúng ≥ 95 %; phiên bản mới có hiệu lực ≤ 30 giây sau EVT-08-01; tra lô 500 mã p95 ≤ 100 ms; ngắt mạch sau 5 lỗi liên tiếp và thử lại sau 30 giây.
