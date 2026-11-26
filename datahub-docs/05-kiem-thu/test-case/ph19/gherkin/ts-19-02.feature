# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-02
Tính năng: TS-19-02 · Kiểm tra kết nối và giao dịch thử

  @TC-19-026 @P1 @Dương
  Kịch bản: TC-19-026 Kiểm tra kết nối đạt, ghi từng bước con
    # Truy vết: FR-19-003 · API-19-009, 011 · UI-19-06 · LGC-PAY-007
    Biết U-ADM1; `PGSIM` trả lời bình thường.
    Khi `POST /providers/{id}/connection-tests` với `{"environment":"SANDBOX"}` và `Idempotency-Key`.
    Và thăm dò `GET /providers/{id}/check-runs` tới khi kết quả khác `RUNNING`.
    Thì bước 1 trả `202`, `Location` tới lần chạy. Bước 2 có lần chạy `CONNECTION`, `PASSED`, bốn bước con (DNS, TLS 1.3, xác thực, gọi API kiểm tra) đều đạt kèm thời lượng; `integration_log` có lượt `OUT_PROVIDER`/`HEALTH`. KT: có (`PROVIDER_CONNECTION_TEST`).

  @TC-19-027 @P1 @Âm
  Kịch bản: TC-19-027 Kiểm tra kết nối thất bại ở từng bước
    # Truy vết: FR-19-003 · API-19-009, 011 · ERR-19-022
    Biết U-ADM1; `PGSIM` cấu hình lần lượt bốn lỗi.
    Khi `PGSIM` trả chứng thư tự ký; chạy kiểm tra.
    Và `PGSIM` trả `401` ở bước xác thực; chạy kiểm tra.
    Và `PGSIM` không trả lời quá 10 giây; chạy kiểm tra.
    Và gỡ tham chiếu `PRODUCTION`; chạy kiểm tra `PRODUCTION`.
    Thì bước 1–3: lần chạy `FAILED`, bước con hỏng đúng vị trí (TLS, xác thực, gọi API), có thông điệp dễ hiểu, các bước sau "bỏ qua". Bước 4 trả `422` ERR-19-022 ngay, không tạo lần chạy. Không lần chạy nào làm đổi trạng thái NCC.

  @TC-19-028 @P1 @Dương
  Kịch bản: TC-19-028 Giao dịch thử thành công kèm IPN
    # Truy vết: FR-19-004 · BR-19-033 · API-19-010, 011, 201 · UI-19-06, 28
    Biết U-ADM1; kiểm tra kết nối `SANDBOX` đạt.
    Khi `POST /providers/{id}/test-transactions` với `{"amount":10000}`.
    Và mở `paymentUrl` trả về, `PGSIM` hoàn tất thanh toán và gửi IPN hợp lệ.
    Và thăm dò `check-runs`.
    Thì bước 1 trả `202`; giao dịch có `isTest = true`. Bước 2: UI-19-28 hiện nhãn "Giao dịch thử", nút quay về bước ② UI-19-06. Bước 3: lần chạy `TEST_TRANSACTION` `PASSED`, có liên kết IPN `VERIFIED`. Giao dịch thử không xuất hiện ở UI-19-01, UI-19-14 mặc định, hạn mức đối tác, phiên đối soát (BR-19-033). WH: không (giao dịch thử không thuộc đối tác).

  @TC-19-029 @P2 @Âm
  Kịch bản: TC-19-029 Giao dịch thử không nhận IPN, bị NCC từ chối
    # Truy vết: FR-19-004 · BR-19-010 · API-19-010, 011 · ERR-19-021
    Biết U-ADM1; `PGSIM` không gửi IPN (lần 1), từ chối khởi tạo mã `51` (lần 2); PV-PG.
    Khi tạo giao dịch thử, hoàn tất thanh toán, chờ 15 phút (đồng hồ giả).
    Và tạo giao dịch thử khi `PGSIM` từ chối.
    Và gọi `POST /providers/{PV-PG}/test-transactions` với `environment = PRODUCTION`.
    Thì bước 1: kết quả `PASSED_WITHOUT_IPN`; checklist điều kiện (2) không đạt. Bước 2: `FAILED` kèm mã đã ánh xạ. Bước 3 trả `400` ERR-19-001 (giao dịch thử chỉ ở môi trường thử, BR-19-033).
