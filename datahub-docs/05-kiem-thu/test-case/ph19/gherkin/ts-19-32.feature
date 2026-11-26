# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-32
Tính năng: TS-19-32 · Hiệu năng, tải và dung lượng

  @TC-19-776 @P1 @Hiệu @năng
  Kịch bản: TC-19-776 Tạo giao dịch ở tải thường
    # Truy vết: NFR-19-001 · API-19-101 · LGC-PAY-001
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: k6, 200 giao dịch/giây một tenant, 15 phút
    Thì đạt ngưỡng: p95 ≤ 300 ms, p99 ≤ 800 ms

  @TC-19-777 @P1 @Hiệu @năng
  Kịch bản: TC-19-777 Tải đỉnh một tenant và toàn cụm
    # Truy vết: NFR-19-002 · API-19-101
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: k6, 200 giao dịch/giây mỗi tenant × 3 tenant, 15 phút
    Thì đạt ngưỡng: Lỗi do PH-19 < 0,1%; tổng 600 giao dịch/giây

  @TC-19-778 @P1 @Hiệu @năng
  Kịch bản: TC-19-778 Nhận và xử lý IPN
    # Truy vết: NFR-19-003 · API-19-201 · LGC-PAY-010
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: k6, 200 IPN/giây
    Thì đạt ngưỡng: Trả lời p95 ≤ 200 ms; xử lý p95 ≤ 2 s

  @TC-19-779 @P1 @Hiệu @năng
  Kịch bản: TC-19-779 Truy vấn trạng thái của đối tác
    # Truy vết: NFR-19-004 · API-19-102, 103
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: k6, 300 yêu cầu/giây một tenant
    Thì đạt ngưỡng: p95 ≤ 150 ms

  @TC-19-780 @P2 @Hiệu @năng
  Kịch bản: TC-19-780 Webhook đầu tiên và tỷ lệ giao
    # Truy vết: NFR-19-005 · FR-19-060
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: 10.000 giao dịch kết thúc trong 10 phút; `WHSINK` trả `200` trong 50 ms
    Thì đạt ngưỡng: Bắt đầu p95 ≤ 5 s; ≥ 99% `DELIVERED` trong 60 s

  @TC-19-781 @P2 @Hiệu @năng
  Kịch bản: TC-19-781 Dashboard trễ và tải trang
    # Truy vết: NFR-19-006 · UI-19-01, 02 · LGC-PAY-026
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: 50 người dùng ảo mở UI-19-01, 02 khi đang chạy TC-19-776
    Thì đạt ngưỡng: Trễ số liệu ≤ 60 s; tải trang p95 ≤ 2 s

  @TC-19-782 @P2 @Hiệu @năng
  Kịch bản: TC-19-782 Tra cứu giao dịch 10 triệu dòng
    # Truy vết: NFR-19-007 · API-19-051 · LGC-PAY-014
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: k6, 200 người dùng đồng thời một tenant, lọc ngẫu nhiên
    Thì đạt ngưỡng: Trang đầu p95 ≤ 1,5 s; tra theo mã p95 ≤ 300 ms

  @TC-19-783 @P2 @Hiệu @năng
  Kịch bản: TC-19-783 Đối soát 100.000 dòng mỗi phía
    # Truy vết: NFR-19-008 · FR-19-044
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: Tệp đối soát sinh tổng hợp 100.000 dòng, 1% lệch
    Thì đạt ngưỡng: So khớp ≤ 10 phút; phiên sẵn trước 08:00

  @TC-19-784 @P2 @Hiệu @năng
  Kịch bản: TC-19-784 Xuất 1.000.000 dòng
    # Truy vết: NFR-19-009 · FR-19-052
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: Một tác vụ xuất trên dữ liệu 10 triệu dòng
    Thì đạt ngưỡng: ≤ 10 phút; đường tải hết hạn 24 giờ

  @TC-19-785 @P2 @Hiệu @năng
  Kịch bản: TC-19-785 Bulkhead khi một NCC chậm
    # Truy vết: NFR-19-012 · FR-19-011
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: `PGSIM` trễ 9 s cho PV-PG; 50 yêu cầu/giây PV-PG và 100 yêu cầu/giây NCC thứ hai
    Thì đạt ngưỡng: Lời gọi đồng thời tới PV-PG ≤ 50; p95 của NCC thứ hai không đổi quá 10%

  @TC-19-786 @P1 @Hiệu @năng
  Kịch bản: TC-19-786 Ngâm tải 8 giờ
    # Truy vết: NFR-19-002, 013
    Biết bộ dữ liệu quy mô theo GĐ-01 ở PERF (mục 1.3)
    Khi chạy tải: 50 giao dịch/giây kèm IPN, truy vấn, webhook
    Thì đạt ngưỡng: Không rò bộ nhớ (heap ổn định ±10%); outbox, inbox không tồn đọng
