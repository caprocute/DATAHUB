# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-15
Tính năng: TS-19-15 · Đối tác truy vấn trạng thái

  @TC-19-351 @P1 @Dương
  Kịch bản: TC-19-351 Truy vấn theo mã giao dịch và mã đơn hàng
    # Truy vết: FR-19-035 · API-19-102, 103
    Biết TX-OK; mã đơn hàng `TC19-255` có hai lượt.
    Khi C-DVC `P: GET /payments/{TX-OK}`.
    Và `P: GET /payments?partnerOrderId=TC19-255`.
    Thì bước 1 trả `200` có `status`, `amount`, `paidAt`, `refundedAmount`, `sequence`, không có dữ liệu cá nhân chưa che. Bước 2 trả hai lượt, mới nhất trước.

  @TC-19-352 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-352 Truy vấn giao dịch của đối tác khác, tỉnh khác
    # Truy vết: FR-19-035 · API-19-102, 103 · ERR-19-020 · NFR-19-025
    Biết giao dịch của P-MC; TX-T99.
    Khi C-DVC truy vấn giao dịch của P-MC.
    Và C-DVC-T99 truy vấn TX-OK của T68.
    Và C-DVC truy vấn mã giao dịch ngẫu nhiên đúng định dạng.
    Thì cả ba: 404-ẩn, cùng thân, thời gian trả lời không phân biệt được (chênh p50 < 5 ms qua 200 lần).

  @TC-19-353 @P2 @Dương
  Kịch bản: TC-19-353 Kéo thông báo dự phòng theo con trỏ
    # Truy vết: FR-19-035, 060 · API-19-109 · BR-19-021
    Biết đầu nhận webhook của P-DVC ngừng 1 giờ; trong thời gian đó có 5 giao dịch kết thúc.
    Khi `P: GET /notifications?after=` (con trỏ rỗng), `limit = 3`.
    Và gọi lại với `next`.
    Thì bước 1 trả 3 thông báo đầu theo thứ tự phát, có `sequence`. Bước 2 trả 2 thông báo còn lại, `hasMore = false`. Nội dung trùng với webhook sẽ gửi.
