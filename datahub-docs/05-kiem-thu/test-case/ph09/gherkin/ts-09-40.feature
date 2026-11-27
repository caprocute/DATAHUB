# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-40
Tính năng: TS-09-40 · Hiệu năng, quy mô và quan sát

  @TC-09-139 @P1 @Hiệu @năng
  Kịch bản: TC-09-139 Kế hoạch che p95 ≤ 50 ms với 200 trường
    # Truy vết: NFR-09-002 · API-09-228
    # Mục đích: Đo NFR-09-002.
    Biết T97; 3 bản sao; kế hoạch 200 trường.
    Khi k6 1.000 lượt mỗi giây 15 phút `mask-plans:resolve`, 30 % trúng `304`.
    Thì p95 ≤ 50 ms khi gọi trực tiếp, trúng đệm ≤ 2 ms, 0 lỗi `5xx`.

  @TC-09-140 @P1 @Hiệu @năng
  Kịch bản: TC-09-140 Ghi kiểm toán ≤ 100 ms, phủ 100 % thao tác ghi và đặc quyền
    # Truy vết: NFR-09-013 · FR-09-061 · API-09-215
    # Mục đích: Chứng minh số lượt ở cổng bằng số bản ghi PH-13.
    Biết T99; 10.000 thao tác ghi và 500 thao tác đặc quyền.
    Khi chạy các thao tác; đối chiếu số lượt APISIX với số bản ghi PH-13.
    Thì 100 % có bản ghi; ghi p95 ≤ 100 ms; không thao tác nào thiếu.

  @TC-09-141 @P2 @Hiệu @năng
  Kịch bản: TC-09-141 Ẩn danh hóa 1 triệu bản ghi, 10 thuộc tính ≤ 15 phút
    # Truy vết: NFR-09-012 · FR-09-036 · API-09-130
    # Mục đích: Đo NFR-09-012.
    Biết T98 F-ANON-1M; Job 8 vCPU, 32 GB (giả định theo Q09-44).
    Khi chạy job ẩn danh hóa k = 10.
    Thì `COMPLETED` ≤ 15 phút; k thực tế ≥ 10; rủi ro không `HIGH`.

  @TC-09-142 @P2 @Hiệu @năng
  Kịch bản: TC-09-142 Danh sách 50.000 phần tử p95 ≤ 1 giây, quy mô 200 HTTT
    # Truy vết: NFR-09-023, 020 · API-09-010 · UI-09-02
    # Mục đích: Đo NFR-09-023 và NFR-09-020.
    Biết T98; 50.000 phần tử; 3.000 chấp thuận; 2 triệu bản ghi kiểm toán.
    Khi k6 `GET /data-elements` có lọc; tải UI-09-02 bằng Playwright.
    Thì p95 ≤ 1 giây; bảng cuộn ảo không treo; truy vấn có chỉ mục.

  @TC-09-143 @P2 @Hiệu @năng
  Kịch bản: TC-09-143 Khả dụng data plane ≥ 99,95 % trong 24 giờ thử và chỉ số quan sát
    # Truy vết: NFR-09-006, 022 · API-09-227
    # Mục đích: Đo khả dụng và sự có mặt đủ tám chỉ số của NFR-09-022.
    Biết PERF; 3 bản sao; thăm dò 1 lượt mỗi giây; chỉ số Prometheus.
    Khi chạy thăm dò 24 giờ, kèm một lần khởi động cuốn chiếu.
    Và đọc `privacy_decide_total`, `privacy_mask_total`, `privacy_blocked_total`, `privacy_bundle_age_seconds`…
    Thì khả dụng ≥ 99,95 % (suy ra tháng); đủ tám chỉ số có nhãn đúng; cảnh báo hiện ở UI-09-01.

  @TC-09-144 @P3 @Hiệu @năng
  Kịch bản: TC-09-144 98 % yêu cầu chủ thể đóng trong hạn
    # Truy vết: NFR-09-016 · FR-09-049 · API-09-181
    # Mục đích: Chứng minh cách tính chỉ số tuân thủ hạn (theo quý).
    Biết T95 đồng hồ giả; 500 yêu cầu mô phỏng với phân bố xử lý giả định.
    Khi chạy mô phỏng; `GET /subject-request-reports`.
    Thì tỷ lệ báo cáo khớp số tính độc lập; nhắc trước 3 ngày làm việc đạt 100 %.

  @TC-09-158 @P1 @Hiệu @năng
  Kịch bản: TC-09-158 Kiểm cấm gửi ra ngoài tỉnh và ropaActivityId p95 ≤ 200 ms
    # Truy vết: NFR-09-027 · BR-09-063 · API-09-231, 227
    # Mục đích: Đo NFR-09-027: `classification:check` với `egressScope = OUT_OF_PROVINCE` (lô 200 trường) và `purpose:decide` khi trả `ropaActivityId`.
    Biết T97; 3 bản sao data plane; hợp đồng 200 trường, 40 trường bật `noEgress`; 3.000 chấp thuận, 500 hợp đồng thuộc hoạt động `ACTIVE`; S-T90-PEP-04 tương đương ở T97.
    Khi k6 1.000 lượt mỗi giây 15 phút `classification:check` 200 trường với `egressScope = OUT_OF_PROVINCE`.
    Và k6 1.000 lượt mỗi giây 15 phút `purpose:decide` cho hợp đồng có `ropaActivityId`.
    Và lặp hai bước ở 3.000 lượt mỗi giây 10 phút.
    Thì bước 1 và 2: p95 ≤ 200 ms, `egressBlockedFields` đúng 40 trường ở mọi lượt, 0 lỗi `5xx`. Bước 3: p95 vẫn ≤ 200 ms. Kiểm bằng cách so kết quả với kết quả tính độc lập.
