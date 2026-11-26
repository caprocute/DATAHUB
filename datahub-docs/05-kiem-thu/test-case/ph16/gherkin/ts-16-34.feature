# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-34
Tính năng: TS-16-34 · Hiệu năng

  @TC-16-114 @P1 @Hiệu @năng
  Kịch bản: TC-16-114 Tổng hợp kỳ tháng 24 chỉ tiêu trên 10 triệu quan sát
    # Truy vết: NFR-16-001, NFR-16-022 · FR-16-018 · API-16-050, 051
    Biết T97 (F-PERF): 10 triệu quan sát trong phân vùng tháng, 36 kỳ, 24 chỉ tiêu.
    Khi `POST /periods/{kỳ}/runs`
    Và đo thời gian từ `QUEUED` tới `SUCCEEDED`
    Và lặp 5 lần
    Và đồng thời chạy tải đọc nền 50 yêu cầu/giây
    Thì mỗi lần ≤ 5 phút (NFR-16-001); `completeness` và giá trị đúng như dữ liệu chuẩn; không lỗi `5xx`.

  @TC-16-115 @P1 @Hiệu @năng
  Kịch bản: TC-16-115 API đẩy quan sát và tiêu thụ sự kiện
    # Truy vết: NFR-16-003, NFR-16-004 · FR-16-010, FR-16-012 · API-16-030
    Biết T97; S-T90-PH01; bộ phát Kafka 50 sự kiện/giây.
    Khi k6 15 phút `POST /ingest/observations` lô 100, tối thiểu 200 quan sát/giây
    Và song song phát 50 sự kiện/giây
    Và đo trễ từ phát tới ghi quan sát
    Thì API đẩy p95 ≤ 300 ms, p99 ≤ 500 ms mỗi lô 100; thông lượng ≥ 200 quan sát/giây; trễ sự kiện p95 ≤ 60 giây; 0 quan sát mất, 0 trùng.

  @TC-16-116 @P1 @Hiệu @năng
  Kịch bản: TC-16-116 Bảng điều khiển, API đọc, danh sách
    # Truy vết: NFR-16-005, NFR-16-006, NFR-16-007 · FR-16-038, FR-16-035, FR-16-031, FR-16-043 · API-16-090, 086, 064, 094
    Biết T98: 24 chỉ tiêu, 13 kỳ, 1.000 báo cáo, 10.000 thành phần; 200 người dùng đồng thời; S-T90-PH17.
    Khi 200 người dùng mở `GET /dashboard`
    Và 50 lượt/giây `GET /feed/indicator-values`
    Và `GET /reports` và `GET /arch/components` phân trang
    Và `GET /reports/{reportCode}` và chi tiết thành phần
    Và đo LCP của UI-16-01 bằng Playwright
    Thì `/dashboard` p95 ≤ 2 giây, LCP ≤ 2,5 giây; `/feed/*` p99 ≤ 300 ms; danh sách p95 ≤ 1,5 giây; chi tiết ≤ 1 giây.

  @TC-16-117 @P1 @Hiệu @năng
  Kịch bản: TC-16-117 Công bố 50 trang, xuất 100.000 dòng, tự đăng ký và gói sổ kiến trúc
    # Truy vết: NFR-16-009, NFR-16-010, NFR-16-015, NFR-16-016 · FR-16-029, FR-16-033, FR-16-044, FR-16-052 · API-16-074, 079, 101, 118
    Biết T99: báo cáo 50 trang đã `APPROVED`; 100.000 dòng quan sát; `sign-sim` và `worm-sim` sẵn sàng.
    Khi công bố báo cáo 50 trang, đo từ yêu cầu tới `PUBLISHED` (20 lần)
    Và xuất 100.000 dòng XLSX
    Và xuất 100.000 dòng CSV
    Và Ở T98 phát 10 sự kiện/giây và lập gói `ARCH_REGISTRY` `FULL` 1.000 thành phần
    Thì công bố p95 ≤ 2 phút (gồm dựng PDF, ký, lưu WORM); XLSX ≤ 3 phút; CSV ≤ 1 phút; tệp hợp lệ, `sha256` khớp. Thành phần tự đăng ký xuất hiện ≤ 60 giây p95; dựng và giao gói sổ kiến trúc ≤ 5 phút (không kể trễ hệ quốc gia).
