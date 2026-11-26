# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-42
Tính năng: TS-17-42 · Hiệu năng, quy mô và quan sát

  @TC-17-149 @P1 @Hiệu_năng
  Kịch bản: TC-17-149 Độ trễ truy hồi lai p95 ≤ 300 ms, p99 ≤ 600 ms
    # Truy vết: NFR-17-001 · FR-17-023, 018 · BR-17-034
    # Mục đích: Đo NFR-17-001.
    Biết PERF T97: 500.000 đoạn, chỉ mục HNSW cosine, 50 yêu cầu đồng thời, `top-k = 8`.
    Khi k6 gọi `POST /search` với 2.000 câu hỏi tổng hợp.
    Và đo thời gian truy hồi (không sinh văn bản).
    Thì p95 ≤ 300 ms, p99 ≤ 600 ms.

  @TC-17-150 @P1 @Hiệu_năng
  Kịch bản: TC-17-150 Token đầu tiên p95 ≤ 3 giây, hoàn tất 500 token p95 ≤ 20 giây, tốc độ ≥ 20 token mỗi giây
    # Truy vết: NFR-17-002, 003 · FR-17-026, 023 · BR-17-038
    # Mục đích: Đo NFR-17-002, 003 với mô hình giả định (8 tỷ tham số, 8 bit, GPU 48 GB, vLLM).
    Biết PERF; 20 phiên đồng thời; ngữ cảnh ≤ 4.000 token; đo lại theo cấu hình thực (Q17-01).
    Khi 20 phiên gửi `:stream` liên tục trong 10 phút.
    Và đo token đầu, thời gian hoàn tất, tốc độ phát.
    Thì token đầu p95 ≤ 3 giây; hoàn tất p95 ≤ 20 giây; tốc độ ≥ 20 token mỗi giây mỗi phiên.

  @TC-17-151 @P1 @Hiệu_năng
  Kịch bản: TC-17-151 Độ tươi chỉ mục p95 ≤ 120 giây, lập lại toàn bộ ≤ 4 giờ, xóa lan truyền theo NFR-17-011
    # Truy vết: NFR-17-010, 011 · FR-17-017, 019 · BR-17-028, 029
    # Mục đích: Đo NFR-17-010, 011 ở quy mô 500.000 đoạn.
    Biết PERF T97; mô hình nhúng nội bộ; 500.000 đoạn.
    Khi phát 200 sự kiện nguồn trải trong 10 phút; đo từ phát đến truy hồi được.
    Và chạy `POST /knowledge/index-jobs:full-reindex`.
    Và phát 100 sự kiện đổi mức và 20 sự kiện xóa nguồn; đo thời gian xóa.
    Thì bước 1 p95 ≤ 120 giây. Bước 2 ≤ 4 giờ. Bước 3 đổi mức p95 ≤ 60 giây; xóa nguồn ≤ 5 phút; truy hồi không trả đoạn đã xóa.

  @TC-17-152 @P2 @Hiệu_năng
  Kịch bản: TC-17-152 Cổng suy luận thêm ≤ 50 ms p95, khóa Idempotency-Key, vết lời gọi
    # Truy vết: NFR-17-022 · FR-17-060, 013 · BR-17-087 · ERR-17-087
    # Mục đích: Đo NFR-17-022 với mô hình giả lập trả cố định 100 ms.
    Biết PERF; S-T97-PH04; LLM-MOCK 100 ms.
    Khi 1.000 lời gọi `classify`.
    Và so thời gian qua cổng và gọi thẳng.
    Và gửi hai `POST` cùng `Idempotency-Key` nhưng khác nội dung.
    Thì thêm ≤ 50 ms p95. Bước 3 `409` ERR-17-087.

  @TC-17-153 @P3 @Hiệu_năng
  Kịch bản: TC-17-153 Dung lượng vector và nhật ký (NFR-17-025)
    # Truy vết: NFR-17-025 · FR-17-018, 055
    # Mục đích: Đo kích thước bảng bằng `pg_total_relation_size`.
    Biết PERF T97: 500.000 đoạn vector 1024 chiều 16 bit và chỉ mục HNSW; nhật ký 2.000 người dùng trong 90 ngày (mẫu).
    Khi đo `pg_total_relation_size` của bảng đoạn và chỉ mục HNSW.
    Và đo bảng nhật ký.
    Thì vector và HNSW ≤ 2,5 GB; nhật ký ≤ 20 GB.

  @TC-17-154 @P2 @Dương @Bảo_mật
  Kịch bản: TC-17-154 Chỉ số Prometheus từng chặng, vết OpenTelemetry không mang nội dung hội thoại
    # Truy vết: NFR-17-026 · FR-17-013 · UI-17-17
    # Mục đích: Chứng minh NFR-17-026.
    Biết STAGING; LGTM; canary `DH-CANARY-qs`.
    Khi chạy 100 lượt hỏi.
    Và đọc bảng chỉ số và mẫu vết.
    Thì có chỉ số độ trễ lọc vào, truy hồi, mô hình, lọc ra, tỷ lệ chặn, token vào ra, hàng đợi, cầu dao; vết mang `trace_id`, 0 canary, 0 nội dung hội thoại.

  @TC-17-155 @P1 @Hiệu_năng @Bảo_mật
  Kịch bản: TC-17-155 Tắt khẩn nền tảng cho 50 tenant giả lập ≤ 60 giây
    # Truy vết: NFR-17-004 · FR-17-006 · API-17-022 · EVT-17-03
    # Mục đích: Đo NFR-17-004 ở quy mô nhiều tenant: tắt khẩn nền tảng cùng chỉ tiêu cho mọi tenant.
    Biết PERF; 50 tenant giả lập `T97-01…50` bật, `dh-assist` 3 bản sao; 200 phiên hội thoại.
    Khi PA `POST /platform/kill-switch:activate`; ghi `t0`.
    Và với từng tenant đo thời điểm lượt gọi đầu tiên bị `403` ở từng bản sao.
    Thì p99 mọi cặp (tenant, bản sao) ≤ 60 giây tính từ `t0`.
