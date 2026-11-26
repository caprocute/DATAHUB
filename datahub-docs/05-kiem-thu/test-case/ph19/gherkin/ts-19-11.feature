# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-11
Tính năng: TS-19-11 · Tạo giao dịch thanh toán

  @TC-19-251 @P1 @Dương
  Kịch bản: TC-19-251 Tạo giao dịch hợp lệ, nhận đường thanh toán
    # Truy vết: FR-19-022, 023, 024, 028 · BR-19-002, 003 · API-19-101 · LGC-PAY-024
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi `P: POST /payments` với `serviceCode = S-XD`, `amount = 1250000`, `partnerOrderId = TC19-251-1`, `returnUrl = https://dvc.t68.test/ket-qua`, người nộp giả, `Idempotency-Key` UUID.
    Và `GET /transactions/{id}/events` (quản trị).
    Thì bước 1 trả `201` với `transactionCode` dạng `T68yyMMdd` + 10 ký tự Base32 Crockford, `paymentUrl` của `PGSIM`, `expiresAt = createdAt + 15 phút`, `status = PENDING`. Bước 2: hai dòng `CREATED` (nguồn `PARTNER_API`), `PENDING` (nguồn `PROVIDER_INIT`). Họ tên, số định danh lưu mã hóa mức trường (kiểm cột `bytea` trong CSDL). EVT: `transaction.created`.

  @TC-19-252 @P1 @Âm
  Kịch bản: TC-19-252 Thứ tự kiểm hợp lệ BR-19-004 dừng ở lỗi đầu tiên
    # Truy vết: FR-19-022, 023 · BR-19-004, 001 · API-19-101 · ERR-19-049, 005, 006, 002, 001, 007, 008, 009, 014, 010, 011, 012, 013, 015, 016
    Biết mười lăm yêu cầu, mỗi yêu cầu sai đúng điều kiện thứ n và đồng thời sai mọi điều kiện sau n.
    Khi gửi lần lượt: tenant T50; C-SUS; C-LEG; thiếu `Idempotency-Key`; `amount = "1e6"`; dịch vụ không có; S-OFF; dịch vụ chưa gán; `currency = USD`; `amount = 0`; S-XD 5.000 ₫; S-XD 25.000.000 ₫; vượt ngày; trùng mã đơn hàng; `returnUrl` lạ.
    Thì mã lỗi theo đúng thứ tự: ERR-19-049, 005, 006, 002, 001, 007, 008, 009, 014, 010, 011, 012, 013, 015, 016. Không yêu cầu nào ghi `payment_transaction`. UT có bảng 15 dòng tương ứng.

  @TC-19-253 @P1 @Dương
  Kịch bản: TC-19-253 Cùng Idempotency-Key, cùng nội dung trả lại kết quả cũ
    # Truy vết: FR-19-033 · BR-19-006 · API-19-101
    Biết yêu cầu R1 từ TC-19-251.
    Khi gửi lại R1 cùng khóa, cùng thân (đổi thứ tự trường JSON).
    Và đếm giao dịch có `partnerOrderId = TC19-251-1`.
    Thì bước 1 trả `201` y hệt, tiêu đề `Idempotent-Replayed: true` (thân so bằng RFC 8785 nên đổi thứ tự trường vẫn khớp). Bước 2: 1. EVT: không thêm.

  @TC-19-254 @P1 @Âm
  Kịch bản: TC-19-254 Idempotency-Key sai định dạng, khác nội dung, đang xử lý
    # Truy vết: FR-19-033 · BR-19-006 · API-19-101 · ERR-19-002, 003, 004
    Biết `PGSIM` trễ khởi tạo 3 giây.
    Khi gửi khóa 10 ký tự.
    Và gửi khóa K1 với thân A; sau khi xong gửi K1 với thân B.
    Và gửi khóa K2 thân C, trong lúc đang chờ `PGSIM` gửi lại K2 thân C.
    Và khách C-MC dùng lại K1 với thân A.
    Thì bước 1 trả `400` ERR-19-002. Bước 2 lần sau trả `422` ERR-19-003. Bước 3 lần sau trả `409` ERR-19-004 có `Retry-After`. Bước 4 trả `201` giao dịch mới (phạm vi khóa theo client).

  @TC-19-255 @P1 @Dương @Âm
  Kịch bản: TC-19-255 Trùng mã đơn hàng và tạo lại sau khi giao dịch trước kết thúc không thành công
    # Truy vết: FR-19-034 · BR-19-007 · API-19-101, 103 · ERR-19-015
    Biết bộ dữ liệu chuẩn mục 2 đã nạp
    Khi tạo giao dịch mã đơn hàng `TC19-255` (khóa K3).
    Và tạo lại `TC19-255` khóa K4.
    Và cho giao dịch bước 1 `EXPIRED`; tạo lại `TC19-255` khóa K5.
    Và gửi đồng thời 50 yêu cầu `TC19-256` với 50 khóa khác nhau.
    Và `P: GET /payments?partnerOrderId=TC19-255`.
    Thì bước 2 trả `409` ERR-19-015 với mã giao dịch hiện có. Bước 3 trả `201`. Bước 4: đúng 1 `201`, 49 `409` ERR-19-015 (bảng `transaction_order_guard`). Bước 5 trả hai lượt theo thời gian.

  @TC-19-256 @P1 @Âm
  Kịch bản: TC-19-256 NCC từ chối khởi tạo
    # Truy vết: FR-19-024 · BR-19-012, 005 · API-19-101 · ERR-19-018
    Biết `PGSIM` trả mã `05` (ánh xạ `FAILED`).
    Khi tạo giao dịch.
    Và xem hạn mức ngày qua `P: GET /services`.
    Thì bước 1 trả `502` ERR-19-018 với `detail` mang lý do đã ánh xạ; ST: `CREATED` → `FAILED`; `providerResultCode = 05`. Bước 2: không tính giao dịch này. WH: `transaction.failed`.

  @TC-19-257 @P1 @Âm @Biên
  Kịch bản: TC-19-257 Không xác định được kết quả khởi tạo
    # Truy vết: FR-19-024, 036 · BR-19-012, 016 · API-19-101, 102 · ERR-19-019
    Biết `PGSIM` ghi nhận khởi tạo nhưng không trả lời trong 10 giây.
    Khi tạo giao dịch khóa K6.
    Và gửi lại cùng K6.
    Và chạy PendingQueryScheduler sau 2 phút; `PGSIM` trả "đã khởi tạo, chưa thanh toán".
    Thì bước 1 trả `504` ERR-19-019; giao dịch `CREATED` với `initUncertain = true`. Bước 2 trả lại đúng phản hồi `504` đã lưu (không gọi NCC lần hai). Bước 3: ST: `CREATED` → `PENDING`, `providerReference` có giá trị.

  @TC-19-258 @P2 @Biên
  Kịch bản: TC-19-258 Số tiền lớn, biên và không dùng số thực
    # Truy vết: FR-19-022 · BR-19-001 · NFR-19-017 · API-19-101
    Biết dịch vụ thử `S-MAX` khoảng 1 … 999.999.999.999 ₫, hạn mức đối tác không giới hạn.
    Khi tạo giao dịch 999.999.999.999 ₫.
    Và tạo giao dịch 1.000.000.000.000 ₫.
    Và tạo giao dịch `amount = 1250000.5`.
    Và xem giao dịch bước 1 ở UI-19-15 và trong tệp CSV xuất.
    Thì bước 1 trả `201`; giá trị lưu, trả, gửi NCC không sai một đồng (so chuỗi). Bước 2 trả `422` ERR-19-010. Bước 3 trả `400` ERR-19-001. Bước 4 hiện "999.999.999.999 ₫" đúng (không qua `Number` của JavaScript).
