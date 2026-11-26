# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-14
Tính năng: TS-19-14 · Hủy và hết hạn giao dịch

  @TC-19-326 @P2 @Dương
  Kịch bản: TC-19-326 Đối tác và cán bộ hủy giao dịch chờ thanh toán
    # Truy vết: FR-19-026 · BR-19-019 · API-19-104, 055 · UI-19-15
    Biết hai giao dịch `PENDING`; U-OPR1; `PGSIM` không có API hủy.
    Khi C-DVC `P: POST /payments/{code}/cancellations` có khóa.
    Và U-OPR1 bấm "Hủy giao dịch" ở UI-19-15, nhập lý do, gõ lại 4 ký tự cuối.
    Thì cả hai: ST: `PENDING` → `CANCELLED` (hủy cục bộ). WH: `transaction.cancelled`. KT: có cho bước 2. Phát hành Đ2b.

  @TC-19-327 @P2 @Âm
  Kịch bản: TC-19-327 Hủy giao dịch đã thanh toán, đã hủy, của đối tác khác
    # Truy vết: FR-19-026 · BR-19-019 · API-19-104 · ERR-19-021, 020
    Biết TX-OK; giao dịch `CANCELLED`; giao dịch của P-MC.
    Khi C-DVC hủy TX-OK.
    Và hủy lại giao dịch `CANCELLED`.
    Và C-DVC hủy giao dịch của P-MC.
    Thì bước 1, 2 trả `409` ERR-19-021. Bước 3: 404-ẩn.

  @TC-19-328 @P1 @Dương
  Kịch bản: TC-19-328 Hết hạn sau truy vấn cuối
    # Truy vết: FR-19-027 · BR-19-017 · ExpiryScheduler
    Biết giao dịch A `PENDING`, `expiresAt` cách 31 phút; `PGSIM` trả "chưa thanh toán". Giao dịch B tương tự, `PGSIM` không trả lời. Giao dịch C `CREATED` `initUncertain` cách 72 giờ 1 phút.
    Khi chạy ExpiryScheduler.
    Thì A: ST: `PENDING` → `EXPIRED` (nguồn `EXPIRY_JOB`), WH: `transaction.expired`. B: ST: giữ `PENDING`, lần truy vấn kế theo BR-19-016. C: ST: `CREATED` → `EXPIRED` (quá trần 72 giờ). Mỗi giao dịch chỉ được một bản sao `worker` xử lý.

  @TC-19-329 @P1 @Âm
  Kịch bản: TC-19-329 Không hết hạn giao dịch đã có kết quả, không chạy trùng
    # Truy vết: FR-19-027 · BR-19-017 · ExpiryScheduler
    Biết giao dịch D `PENDING` quá hạn, `PGSIM` trả "thành công" ở truy vấn cuối; giao dịch E `SUCCEEDED` quá `expiresAt`; 3 bản sao `worker`.
    Khi chạy ExpiryScheduler đồng thời trên 3 bản sao.
    Thì D: ST: `PENDING` → `SUCCEEDED` nguồn `POLL`, không phải `EXPIRED`. E: không đổi. Mỗi giao dịch chỉ một lần truy vấn cuối (khóa `SKIP LOCKED`), không có sự kiện trùng.
