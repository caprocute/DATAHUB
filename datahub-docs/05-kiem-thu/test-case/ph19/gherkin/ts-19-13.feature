# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-13
Tính năng: TS-19-13 · Nhận và xử lý IPN

  @TC-19-301 @P1 @Dương
  Kịch bản: TC-19-301 IPN thành công hợp lệ
    # Truy vết: FR-19-029, 030, 028, 060 · BR-19-015 · API-19-201 · LGC-PAY-010, 011, 012
    Biết TX `PENDING` 1.250.000 ₫.
    Khi `PGSIM` gửi `C: POST /paygov/{connectionKey}/ipn` có chữ ký đúng, số tiền 1.250.000, mã `00`.
    Và đọc `callback_inbox`, giao dịch, `outbox_event`.
    Thì bước 1 trả phản hồi thành công theo hợp đồng PayGov giả định trong p95 ≤ 200 ms. Bước 2: hộp nhận `VERIFIED`, `PROCESSED`, nguyên văn và `rawHash` lưu; ST: `PENDING` → `SUCCEEDED`, `paidAt` theo NCC, `sequence` tăng. EVT: `transaction.succeeded`. WH: `transaction.succeeded` trong p95 ≤ 5 s.

  @TC-19-302 @P1 @Dương
  Kịch bản: TC-19-302 IPN thất bại
    # Truy vết: FR-19-030 · API-19-201
    Biết TX `PENDING`.
    Khi `PGSIM` gửi IPN mã `24` (ánh xạ `FAILED`, "người nộp hủy").
    Thì ST: `PENDING` → `FAILED`, `reasonCode`, `reasonMessage` theo bảng ánh xạ. WH: `transaction.failed`.

  @TC-19-303 @P1 @Âm
  Kịch bản: TC-19-303 IPN lặp đúng nội dung, đồng thời
    # Truy vết: FR-19-030 · API-19-201 · AC-19-04
    Biết TX `PENDING`.
    Khi gửi cùng IPN 20 lần song song.
    Và gửi lại IPN đó sau 1 giờ.
    Thì bước 1: mọi lượt nhận phản hồi thành công; một bản ghi `PROCESSED`, các bản còn lại `DUPLICATE`; ST: một lần `PENDING` → `SUCCEEDED`; một webhook. Bước 2: `DUPLICATE`, không đổi gì.

  @TC-19-304 @P1 @Âm
  Kịch bản: TC-19-304 IPN sai số tiền, sai tham chiếu, không tìm thấy, mã chưa ánh xạ
    # Truy vết: FR-19-031 · BR-19-015 · API-19-201, 056 · ERR-19-028 · UI-19-16 · AC-19-05
    Biết bốn giao dịch `PENDING`.
    Khi IPN thành công số tiền 1.249.999 cho giao dịch 1.250.000.
    Và IPN có `providerReference` khác giá trị đã lưu.
    Và IPN cho mã giao dịch không có.
    Và IPN mã `99` chưa có trong bảng ánh xạ.
    Và mở UI-19-16 lọc "Cần chú ý".
    Thì bước 1–4: NCC nhận phản hồi đã tiếp nhận; hộp nhận `QUARANTINED` với lý do `AMOUNT_MISMATCH`, `REF_MISMATCH`, `NOT_FOUND`, `UNMAPPED_CODE`; ST: giữ `PENDING`; bước 1 sinh chênh lệch `AMOUNT_MISMATCH`, bước 3 sinh `ORPHAN_CALLBACK`; cảnh báo PH-13. Bước 5 hiện đủ bốn dòng với nhãn lý do.

  @TC-19-305 @P1 @Dương
  Kịch bản: TC-19-305 IPN thành công cho giao dịch đã hủy hoặc hết hạn (thanh toán muộn)
    # Truy vết: FR-19-031 · BR-19-018 · API-19-201 · OQ-19-23
    Biết TX-EXP; một giao dịch `CANCELLED`.
    Khi `PGSIM` gửi IPN thành công hợp lệ cho từng giao dịch.
    Thì ST: `EXPIRED` → `SUCCEEDED` và `CANCELLED` → `SUCCEEDED`, `latePaid = true`; mỗi giao dịch có chênh lệch `LATE_PAYMENT` `OPEN`. WH: `transaction.succeeded` có `latePaid = true`. UI-19-15 hiện huy hiệu "Thanh toán muộn".

  @TC-19-306 @P1 @Âm
  Kịch bản: TC-19-306 IPN mâu thuẫn với trạng thái cuối khác
    # Truy vết: FR-19-031 · BR-19-015 · API-19-201
    Biết TX-OK `SUCCEEDED`; một giao dịch `FAILED`.
    Khi IPN thất bại cho TX-OK.
    Và IPN thành công cho giao dịch `FAILED`.
    Thì cả hai `QUARANTINED` lý do `CONFLICT_FINAL`; ST: giữ nguyên; sinh chênh lệch `STATUS_MISMATCH` để kế toán xử lý (không tự đảo trạng thái cuối).
