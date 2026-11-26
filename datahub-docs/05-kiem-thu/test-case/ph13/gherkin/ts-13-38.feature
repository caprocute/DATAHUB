# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-38
Tính năng: TS-13-38 · Hiệu năng, tải và quy mô

  @TC-13-104 @P2 @Hiệu @năng
  Kịch bản: TC-13-104 Độ trễ chỉ số tới bảng điều khiển
    # Truy vết: NFR-13-001 · FR-13-001
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 250.000 chuỗi, chu kỳ 15 giây, 30 phút
    Thì đạt ngưỡng: p95 ≤ 30 giây, p99 ≤ 60 giây

  @TC-13-105 @P2 @Hiệu @năng
  Kịch bản: TC-13-105 Độ trễ log và trace tới tra cứu
    # Truy vết: NFR-13-002, 003, 007 · FR-13-002, 003
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 20.000 dòng log/giây, 5.000 span/giây
    Thì đạt ngưỡng: Log p95 ≤ 30 giây; trace p95 ≤ 60 giây

  @TC-13-106 @P2 @Hiệu @năng
  Kịch bản: TC-13-106 Tải bảng điều khiển chuẩn
    # Truy vết: NFR-13-004 · FR-13-031
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 12 panel, 50 người xem đồng thời
    Thì đạt ngưỡng: p95 ≤ 3 giây

  @TC-13-107 @P2 @Hiệu @năng
  Kịch bản: TC-13-107 Truy vấn trace và log
    # Truy vết: NFR-13-005 · FR-13-026, 028
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Log 90 ngày khoảng 50 GB
    Thì đạt ngưỡng: Trace p95 ≤ 2 giây; log 1 giờ p95 ≤ 5 giây, 24 giờ ≤ 15 giây

  @TC-13-108 @P2 @Hiệu @năng
  Kịch bản: TC-13-108 Tra lượt gọi API
    # Truy vết: NFR-13-006, 018 · FR-13-030
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: F-ACCESS-5M nhân 365 ngày ngày (1,8 tỷ bản ghi)
    Thì đạt ngưỡng: Lọc 24 giờ, HTTT p95 ≤ 3 giây

  @TC-13-109 @P1 @Hiệu @năng
  Kịch bản: TC-13-109 Ghi bản ghi kiểm toán
    # Truy vết: NFR-13-008, 011 · FR-13-010, 011
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1.000 bản ghi/giây toàn nền tảng, 34 tenant, bản ghi 1,5 KB, 30 phút
    Thì đạt ngưỡng: p95 ≤ 2 giây, p99 ≤ 5 giây; 0 mất

  @TC-13-110 @P1 @Hiệu @năng
  Kịch bản: TC-13-110 Truy vấn kiểm toán
    # Truy vết: NFR-13-009, 017 · FR-13-020
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 36,5 triệu bản ghi mỗi tenant
    Thì đạt ngưỡng: 31 ngày, 10.000 kết quả p95 ≤ 3 giây; 12 tháng p95 ≤ 10 giây

  @TC-13-111 @P1 @Hiệu @năng
  Kịch bản: TC-13-111 Kiểm tra toàn vẹn
    # Truy vết: NFR-13-010 · FR-13-014
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: Chuỗi 12 tháng, 36,5 triệu bản ghi
    Thì đạt ngưỡng: Tới đầu chuỗi từ neo gần nhất ≤ 2 phút; toàn chuỗi ≤ 60 phút; độ trễ ghi tăng ≤ 10 %

  @TC-13-112 @P2 @Hiệu @năng
  Kịch bản: TC-13-112 Xuất 1 triệu bản ghi
    # Truy vết: NFR-13-031 · FR-13-024
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 1 triệu bản ghi, gói khoảng 200 MB
    Thì đạt ngưỡng: ≤ 15 phút; script ngoại tuyến xác minh được

  @TC-13-113 @P1 @Hiệu @năng
  Kịch bản: TC-13-113 Thông lượng thu thập toàn nền tảng
    # Truy vết: NFR-13-007, 003 · FR-13-001
    Biết bộ dữ liệu quy mô theo GĐ ở PERF (mục 1.3)
    Khi chạy tải: 34 tenant mỗi tenant 250.000 chuỗi, 20.000 dòng/giây
    Thì đạt ngưỡng: Không mất mẫu có độ ưu tiên cao, collector đệm theo ERR-13-115
