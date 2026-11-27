# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-07
Tính năng: TS-18-07 · Ghi tham số mặc định khi khởi tạo tenant

  @TC-18-022 @P1 @Dương
  Kịch bản: TC-18-022 Sự kiện tenant mới ghi tham số, lịch mặc định; chạy lại không đổi
    # Truy vết: FR-18-011, 045 · API-18-030 · BR-18-010 · EVT-18-15 · UI-18-08
    # Mục đích: Chứng minh BR-18-010: lần đầu ghi đủ mặc định của mọi không gian tên đã đăng ký và lịch `COMMON`, lần hai và gọi API trực tiếp không tạo phiên bản mới.
    Biết T93 mới, chưa có giá trị; S-PH20 (`ops:param-write`); WireMock PH-20 phát `platform.tenant.created.v1` cho T93.
    Khi phát `platform.tenant.created.v1` cho T93.
    Và S-PH20 `POST /ops/internal/v1/tenants/T93/params:seed-defaults`.
    Và U-T93-TA1 sửa `04.retry.max-attempts` thành 5; phát lại sự kiện lần hai (cùng `eventId`) và một sự kiện mới `eventId` khác.
    Thì bước 1 mọi khóa mức `TENANT` có giá trị `source = DEFAULT`, lịch năm hiện tại tạo từ `COMMON`, EVT-18-15 phát một lần. Bước 2 `200`, `added = 0`. Bước 3 inbox bỏ sự kiện trùng; sự kiện mới không ghi đè giá trị 5, `added = 0`.

  @TC-18-023 @P2 @Âm @Chịu_lỗi
  Kịch bản: TC-18-023 Tenant không tồn tại, chế độ chỉ đọc và sự kiện lỗi năm lần vào DLQ PH-18
    # Truy vết: FR-18-011, 072 · API-18-030 · BR-18-010 · ERR-18-001, 071, 124 · UI-18-24
    # Mục đích: Chứng minh lỗi khi ghi mặc định được báo rõ và sự kiện tiêu thụ lỗi đi vào DLQ của PH-18 thay vì mất (LP-18-06).
    Biết T93; `18.degraded.read-only = true` ở bước 2; WireMock registry PH-20 không trả T99X.
    Khi S-PH20 `POST /ops/internal/v1/tenants/T99X/params:seed-defaults`.
    Và bật chế độ chỉ đọc, gọi lại cho T93.
    Và phát sự kiện `platform.tenant.created.v1` có thân hỏng làm bộ xử lý lỗi năm lần.
    Thì bước 1 `404` ERR-18-001. Bước 2 `503` ERR-18-071. Bước 3 inbox `FAILED`, ghi ERR-18-124, có mục DLQ nguồn `PH18_INBOX` hiện ở UI-18-24 và phát lại được như mục DLQ thường.
