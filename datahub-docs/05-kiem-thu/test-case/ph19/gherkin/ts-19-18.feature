# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-18
Tính năng: TS-19-18 · Phê duyệt và thực thi hoàn tiền

  @TC-19-426 @P1 @Dương
  Kịch bản: TC-19-426 Duyệt một cấp dưới ngưỡng
    # Truy vết: FR-19-039 · BR-19-023 · API-19-050
    Biết yêu cầu từ TC-19-401 (50.000 ₫); U-APR1.
    Khi U-APR1 duyệt.
    Thì yêu cầu `APPROVED` rồi `AWAITING_MANUAL` (chế độ `MANUAL`). WH: `refund.decided`. U-ACC1 thấy yêu cầu trong "Việc của tôi" ở UI-19-17.

  @TC-19-427 @P1 @Dương @Âm
  Kịch bản: TC-19-427 Duyệt hai cấp trên ngưỡng, ba người khác nhau
    # Truy vết: FR-19-039 · BR-19-023, 011 · API-19-050 · ERR-19-033 · UI-19-13
    Biết U-ACC1 lập yêu cầu hoàn 7.500.000 ₫ cho TX-BIG; U-APR1, U-APR2.
    Khi U-APR1 duyệt.
    Và U-APR1 duyệt lần nữa (cấp 2).
    Và U-APR2 duyệt.
    Thì bước 1: `PENDING_SECOND_APPROVAL`; UI-19-13 hiện "Hoàn tiền (cấp 2)". Bước 2 trả `403` ERR-19-033 "đã duyệt cấp trước". Bước 3: `APPROVED`.

  @TC-19-428 @P1 @Dương
  Kịch bản: TC-19-428 Ghi nhận đã hoàn thủ công có chứng từ
    # Truy vết: FR-19-040, 041 · BR-19-024 · API-19-062 · UI-19-18
    Biết yêu cầu `AWAITING_MANUAL` từ TC-19-426; U-ACC2 (không duyệt yêu cầu này); F-VOUCHER.
    Khi U-ACC2 bấm "Ghi nhận đã hoàn", nhập số chứng từ, ngày, tải tệp, gõ lại mã yêu cầu.
    Thì `POST /refunds/{id}/executions` `RECORD_MANUAL` trả `200`; yêu cầu `SUCCEEDED`; ST: `SUCCEEDED` → `REFUNDED` (nguồn `REFUND`). WH: `refund.succeeded`. Tệp chứng từ lưu ở `dh-t68-payment-worm`. KT: có.

  @TC-19-429 @P2 @Dương
  Kịch bản: TC-19-429 Hoàn một phần nhiều lần tới toàn phần
    # Truy vết: FR-19-041 · BR-19-022 · API-19-059, 062
    Biết giao dịch `SUCCEEDED` 1.000.000 ₫.
    Khi hoàn 300.000 ₫ (đi hết duyệt, ghi nhận).
    Và hoàn 700.000 ₫.
    Thì bước 1: ST: `SUCCEEDED` → `PARTIALLY_REFUNDED`, `refundedAmount = 300000`. Bước 2: ST: `PARTIALLY_REFUNDED` → `REFUNDED`.

  @TC-19-430 @P2 @Dương
  Kịch bản: TC-19-430 Thực thi hoàn qua NCC và thực hiện lại
    # Truy vết: FR-19-040, 041 · BR-19-024 · API-19-203, 062
    Biết cờ `payment.refund-api` bật; `PGSIM` khai năng lực hoàn; yêu cầu `APPROVED` 50.000 ₫.
    Khi hệ thống gửi lệnh hoàn; `PGSIM` gửi `C: POST /paygov/{connectionKey}/refund-ipn` thành công.
    Thì yêu cầu `PROCESSING` → `SUCCEEDED`; `providerRefundRef` có giá trị. Phát hành Đ2b.

  @TC-19-431 @P2 @Âm
  Kịch bản: TC-19-431 Hoàn qua NCC lỗi, thực hiện lại, chuyển thủ công
    # Truy vết: FR-19-040, 041 · API-19-062 · ERR-19-021
    Biết như TC-19-430; `PGSIM` báo lỗi hoàn.
    Khi yêu cầu chuyển `FAILED`; U-ACC1 `RETRY` ba lần, `PGSIM` lỗi cả ba.
    Và `RETRY` lần thứ tư.
    Và `SWITCH_MANUAL`.
    Thì bước 1: `executionCount = 3`, `FAILED`. Bước 2 trả `409` ERR-19-021. Bước 3: `AWAITING_MANUAL`. Phát hành Đ2b.

  @TC-19-432 @P3 @Dương
  Kịch bản: TC-19-432 Người lập rút yêu cầu hoàn
    # Truy vết: FR-19-038 · API-19-050
    Biết yêu cầu `PENDING_APPROVAL` của U-ACC1.
    Khi U-ACC1 rút; U-ACC2 thử rút.
    Thì U-ACC2 trả `403` ERR-19-033 (không phải người lập); U-ACC1: `CANCELLED`, số còn được hoàn trở lại như trước.

  @TC-19-433 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-433 Ghi nhận thủ công vi phạm tách nhiệm, thiếu chứng từ
    # Truy vết: FR-19-040 · BR-19-024 · API-19-062 · ERR-19-033, 001, 021
    Biết yêu cầu `AWAITING_MANUAL` do U-APR1 duyệt; U-AA1 có thêm `refund-execute` qua vai trò thử; yêu cầu `PENDING_APPROVAL`.
    Khi người đã duyệt (U-APR1 được gán tạm `refund-execute`) ghi nhận đã hoàn.
    Và U-ACC2 ghi nhận thiếu `voucherFileId`.
    Và U-ACC2 ghi nhận cho yêu cầu còn `PENDING_APPROVAL`.
    Thì bước 1 trả `403` ERR-19-033; nút vô hiệu với lý do tách nhiệm. Bước 2 trả `400` ERR-19-001. Bước 3 trả `409` ERR-19-021.
