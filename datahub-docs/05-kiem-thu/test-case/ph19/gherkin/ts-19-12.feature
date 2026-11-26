# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-12
Tính năng: TS-19-12 · Người nộp quay về

  @TC-19-276 @P1 @Dương
  Kịch bản: TC-19-276 Quay về sau khi IPN thành công đã tới
    # Truy vết: FR-19-025 · API-19-202 · UI-19-28 · LGC-PAY-012 · NFR-19-029
    Biết giao dịch `SUCCEEDED` mới nhận IPN; trình duyệt di động 360 × 740.
    Khi `PGSIM` chuyển người nộp về `C: GET /paygov/{connectionKey}/return` với tham số có chữ ký.
    Và chờ 5 giây.
    Thì bước 1 trả `200` HTML: "Thanh toán thành công", số tiền, nội dung, mã giao dịch, không có họ tên, điện thoại. Bước 2: chuyển tới `returnUrl` kèm `transactionCode`, `status = SUCCEEDED`, `ts`, `sig`; `sig` xác minh được bằng bí mật webhook của P-DVC trên chuỗi `{transactionCode}.{status}.{ts}`. axe-core không có lỗi nghiêm trọng.

  @TC-19-277 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-277 Quay về trước IPN: hiển thị đang xác nhận, không đổi trạng thái
    # Truy vết: FR-19-025, 036 · BR-19-014 · API-19-202, 205 · UI-19-28
    Biết TX `PENDING`; `PGSIM` gắn mã kết quả "thành công" vào tham số quay về nhưng chưa gửi IPN.
    Khi người nộp quay về.
    Và trang thăm dò API-19-205 trong 20 giây.
    Và đọc `transaction_event`, `next_poll_at`.
    Thì bước 1: "Đang xác nhận kết quả với ngân hàng". Bước 2: sau 20 giây hiện "Bạn không cần thanh toán lại…". Bước 3: ST: giữ `PENDING`; `next_poll_at` được đặt về hiện tại (truy vấn sớm). Không có webhook.

  @TC-19-278 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-278 Tham số quay về bị sửa, chuyển hướng mở
    # Truy vết: FR-19-025 · BR-19-014 · API-19-202 · NFR-19-020
    Biết TX `PENDING`.
    Khi sửa `responseCode` trong tham số rồi gọi.
    Và thêm `&returnUrl=https://evil.test` và `&next=//evil.test`.
    Và gọi với `connectionKey` không tồn tại.
    Thì bước 1 trả `400`, trang "Không xác nhận được kết quả", không chuyển tới đối tác; ghi sự kiện an ninh. Bước 2: tham số bị bỏ qua, địa chỉ chuyển về chỉ là `returnUrl` đã lưu. Bước 3: trang lỗi chung, cùng nội dung với khóa sai khác, không lộ lý do.
