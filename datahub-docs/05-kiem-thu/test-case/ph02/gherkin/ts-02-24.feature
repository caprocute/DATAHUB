# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-24
Tính năng: TS-02-24 · Hiệu năng và quy mô

  @TC-02-070 @P1 @Hiệu @năng
  Kịch bản: TC-02-070 Tra cứu danh mục
    # Truy vết: NFR-02-001, 006 · API-02-001, 004
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: 2.000 API, 200 người dùng đồng thời, 10 phút, API-02-001, 002, 004
    Thì đạt ngưỡng: p95 ≤ 300 ms, p99 ≤ 500 ms, `304` khi chưa đổi

  @TC-02-071 @P1 @Hiệu @năng
  Kịch bản: TC-02-071 Tìm kiếm toàn văn
    # Truy vết: NFR-02-002 · API-02-003
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: 2.000 API, 10.000 phiên bản, 100 yêu cầu/giây
    Thì đạt ngưỡng: p95 ≤ 500 ms

  @TC-02-072 @P1 @Hiệu @năng
  Kịch bản: TC-02-072 Kiểm tra đặc tả 5.000 dòng và 10 MiB
    # Truy vết: NFR-02-003, 011 · API-02-022
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: 20 lần song song F-SPEC-5K, 5 lần F-SPEC-10M
    Thì đạt ngưỡng: ≤ 5 giây; ≤ 20 giây

  @TC-02-073 @P1 @Hiệu @năng
  Kịch bản: TC-02-073 Báo cáo khác biệt hai phiên bản
    # Truy vết: NFR-02-004 · API-02-055
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: Hai đặc tả 5.000 dòng, 20 lần
    Thì đạt ngưỡng: ≤ 3 giây

  @TC-02-074 @P1 @Hiệu @năng
  Kịch bản: TC-02-074 Hiệu lực cấu hình ở gateway
    # Truy vết: NFR-02-005 · API-02-047, 048, 063
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: 100 lệnh công bố, tạm ngừng, cấp, thu hồi; ba bản sao APISIX
    Thì đạt ngưỡng: p95 ≤ 30 giây từ quyết định tới áp dụng

  @TC-02-075 @P1 @Hiệu @năng
  Kịch bản: TC-02-075 Quy mô tối đa mỗi tenant
    # Truy vết: NFR-02-006, 010 · API-02-001, 059
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 2)
    Khi chạy tải: 2.000 API, 50 phiên bản mỗi API, 20.000 đăng ký, 5.000 thao tác mỗi đặc tả
    Thì đạt ngưỡng: Đọc p95 ≤ 300 ms, ghi p95 ≤ 600 ms

  @TC-02-076 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-076 Đặc tả độc hại: bom YAML, `$ref` sâu, quá nhiều thao tác
    # Truy vết: FR-02-011, 016 · API-02-015, 022 · NFR-02-011 · ERR-02-009, 005, 006.
    Biết F-SPEC-BOMB; đặc tả 5.001 thao tác.
    Khi nạp F-SPEC-BOMB và `POST /spec-lint`; theo dõi bộ nhớ, CPU của `dh-connect`.
    Và nạp đặc tả 5.001 thao tác.
    Thì bị từ chối `422` hoặc `413` trong ≤ 20 giây, tiến trình không quá bộ nhớ, các yêu cầu khác không chậm quá 2 lần.

  @TC-02-142 @P2 @Hiệu @năng
  Kịch bản: TC-02-142 Đồng bộ lô lớn lên Nền tảng quốc gia trong 15 phút
    # Truy vết: FR-02-053 · API-02-069 · UI-02-12 · UC-02-29 · NFR-02-014 · BR-02-009.
    Biết 180 API công bố `NATIONAL` (hồ sơ tỉnh vừa, GĐ-02-01); M-NSP trả sau 100 ms; `02.sync.batch-size` mặc định.
    Khi đặt toàn bộ 180 API ở trạng thái đủ điều kiện cùng lúc.
    Và đo từ lúc đủ điều kiện tới khi mọi bản ghi `SYNCED`.
    Và lặp lại với M-NSP lỗi 5 % bản ghi.
    Thì bước 2: ≤ 15 phút. Bước 3: 5 % bản ghi vào `RETRY` rồi `SYNCED` ở lần thử kế tiếp, không bản ghi nào bị gửi trùng.

  @TC-02-143 @P3 @Hiệu @năng
  Kịch bản: TC-02-143 Chạy bền 8 giờ ở nửa tải: không rò bộ nhớ, không lệch hiệu năng
    # Truy vết: NFR-02-006, 007 · API-02-001, 002, 059 · FR-02-001.
    Biết môi trường PERF; 1.000 API, 100 người dùng đồng thời; hỗn hợp 90 % đọc, 10 % ghi.
    Khi chạy 8 giờ liên tục.
    Và so sánh p95 giờ đầu với giờ cuối; theo dõi bộ nhớ, số kết nối DB, độ trễ bộ đệm.
    Thì p95 giờ cuối không quá 1,2 lần giờ đầu; bộ nhớ tiến trình không tăng đơn điệu quá 10 %; không lỗi 5xx do cạn kết nối; sẵn sàng đo được ≥ 99,5 % (NFR-02-007).
