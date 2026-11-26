# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-09
Tính năng: TS-14-09 · Gọi dịch vụ quốc gia qua điểm gọi chung

  @TC-14-023 @P1 @Dương
  Kịch bản: TC-14-023 Gọi thành công, có mã giao dịch và nhật ký khai thác
    # Truy vết: FR-14-010, 014, 026, 027 · API-14-075 · UC-14-09 · BR-14-007, 020, 037 · NFR-14-013, 020.
    Biết S-HT-MC; V-LLTP đã cung cấp lại cho `HT-MOTCUA`; `sim-ndxp` `OK`.
    Khi `POST /internal/national/v1/invocations` `{serviceCode: lltp-tra-trang-thai, params: {dossierCode: LLTP-2026-000123}, purposeCode: GIAI_QUYET_TTHC}`; thân có thêm `systemCode: HT-KHAC`.
    Và tra giao dịch ở UI-14-12 theo `transactionCode`.
    Thì `200` JSON chuẩn, `transactionCode`, `traceId`; mã HTTT lấy từ `azp` (bỏ qua `systemCode` trong thân); bản tin gửi đi có chữ ký, phản hồi đã xác minh; giao dịch `SUCCEEDED`; có dòng nhật ký khai thác đủ HTTT, mục đích.

  @TC-14-024 @P1 @Âm
  Kịch bản: TC-14-024 Lỗi từ quốc gia được phân loại và che nội dung kỹ thuật
    # Truy vết: FR-14-015 · API-14-075 · ERR-14-101, 102, 115, 127, 128 · UI-14-12 · NFR-14-009.
    Biết S-HT-MC; `sim-ndxp` lần lượt `BIZ404`, `DOWN`, `SLOW` quá 15 giây, phản hồi sai cấu trúc; tiêm lỗi nội bộ bằng cờ kiểm thử.
    Khi gọi khi `BIZ404`.
    Và gọi khi `DOWN`; gọi khi trễ quá `14.timeout.default-ms`.
    Và gọi khi phản hồi thiếu trường bắt buộc.
    Và gọi khi bật cờ lỗi nội bộ.
    Thì bước 1 `404` hoặc `422` ERR-14-102, không có chuỗi lỗi của trung ương trong `detail`; bước 2 `502` ERR-14-101 và `504` ERR-14-115; bước 3 `502` ERR-14-128; bước 4 `500` ERR-14-127 kèm mã truy vết. Mọi giao dịch có trạng thái `FAILED` hoặc `TIMEOUT`.

  @TC-14-025 @P1 @Âm @Biên
  Kịch bản: TC-14-025 Thao tác ghi: Idempotency-Key và kết quả chưa rõ
    # Truy vết: FR-14-010 · API-14-075 · ERR-14-003, 116, 108, 105, 117 · BR-14-030, 031 · UC-14-09.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` `SLOW` rồi mất kết nối sau khi nhận; dịch vụ `tc-khong-luat` chưa có luật định tuyến.
    Khi `POST` ghi thiếu `Idempotency-Key`.
    Và `POST` cùng khóa hai lần, lần hai khác `params`.
    Và `POST` ghi khi quốc gia nhận nhưng không phản hồi; đếm số lần Datahub gửi.
    Và `POST` với `params` sai lược đồ; gọi `tc-khong-luat`.
    Thì bước 1 `400` ERR-14-003; bước 2 lần hai `409` ERR-14-116; bước 3 giao dịch `UNKNOWN_RESULT`, gửi đúng một lần, không thử lại tự động, chỉ đối soát trạng thái; bước 4 `422` ERR-14-108 và ERR-14-105.

  @TC-14-026 @P1 @Âm
  Kịch bản: TC-14-026 Bộ điều hợp và chuyển đổi từ chối đầu vào sai, không có luật, lỗi không thử lại
    # Truy vết: FR-14-012, 014, 017, 019, 020, 021, 022 · API-14-075 · ERR-14-102, 105, 108 · BR-14-037.
    Biết S-HT-MC; V-LLTP, V-BHXH, V-DVQHNS, V-DKKD, V-VBQPPL; `sim-ndxp` `BIZ404`; dịch vụ `tc-khong-luat`.
    Khi gọi từng dịch vụ với `params` sai kiểu hoặc thiếu trường bắt buộc.
    Và gọi `tc-khong-luat`.
    Và gọi V-LLTP khi `BIZ404`, xem trường `retryable`.
    Thì bước 1 `422` ERR-14-108 cho từng bộ điều hợp, không gọi ra quốc gia; bước 2 `422` ERR-14-105; bước 3 `404` ERR-14-102, `retryable = false`, không thử lại. Bộ điều hợp chỉ đổi giao thức, phong bì, lược đồ, không đổi ngữ nghĩa (BR-14-037).

  @TC-14-027 @P1 @Dương
  Kịch bản: TC-14-027 Phân loại lỗi có thể thử lại và thử lại thành công
    # Truy vết: FR-14-015, 038 · API-14-075 · BR-14-031 · UC-14-09.
    Biết S-HT-MC; V-HT; `sim-ndxp` trả `503` một lần rồi `OK`; `14.retry.max-attempts = 2`.
    Khi gọi thao tác đọc V-HT, đếm số lần gửi.
    Và xem giao dịch ở UI-14-12.
    Thì lỗi `503` của quốc gia phân loại `retryable = true`; thử lại một lần thì thành công, bên gọi nhận `200`; giao dịch ghi số lần thử và mã lỗi gốc đã che.
