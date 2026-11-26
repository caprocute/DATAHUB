# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-27
Tính năng: TS-19-27 · Thông báo kết quả cho đối tác

  @TC-19-651 @P1 @Dương
  Kịch bản: TC-19-651 Gửi webhook có ký, đối tác xác minh được
    # Truy vết: FR-19-060 · NFR-19-005, 021 · LGC-PAY-012
    Biết `WHSINK` cho P-DVC trả `200`.
    Khi hoàn tất TX-OK qua IPN.
    Và Ở `WHSINK` kiểm chữ ký.
    Thì bước 1: lượt gửi `PENDING` → `DELIVERED` trong p95 ≤ 5 s. Bước 2: header `Webhook-Id`, `Webhook-Timestamp`, `X-Datahub-Signature: t={unix},v1={hex}`, `traceparent`; HMAC-SHA256 trên `{id}.{t}.{body}` khớp; thân CloudEvents JSON thân có `transactionCode`, `status`, `amount`, `sequence`, không có dữ liệu cá nhân.

  @TC-19-652 @P1 @Âm
  Kịch bản: TC-19-652 Thử lại theo lịch rồi hết lần thử
    # Truy vết: FR-19-060, 062 · BR-19-020 · API-19-079
    Biết `WHSINK` trả `503`; đồng hồ giả.
    Khi hoàn tất một giao dịch; tiến đồng hồ 17 giờ.
    Và cho `WHSINK` trả `410`.
    Thì bước 1: 11 lần gửi theo lịch BR-19-020 (ngay, rồi 10 s, 30 s, 1 phút, 5, 15, 30 phút, 1, 2, 4, 8 giờ; dung sai ±10%), mỗi lần ghi mã HTTP, độ trễ; sau lần cuối `EXHAUSTED`; huy hiệu "Webhook" tăng; cảnh báo PH-13. Bước 2: lượt gửi mới trả `410` chuyển `EXHAUSTED` ngay, không thử lại.

  @TC-19-653 @P2 @Dương
  Kịch bản: TC-19-653 Thứ tự `sequence` trong một giao dịch
    # Truy vết: FR-19-060, 061 · BR-19-021
    Biết `WHSINK` lỗi lượt đầu rồi phục hồi.
    Khi giao dịch `SUCCEEDED` rồi hoàn một phần trong 10 giây.
    Thì hai webhook đến đúng thứ tự `sequence` tăng dần; lượt sau không gửi trước khi lượt trước `DELIVERED` hoặc `EXHAUSTED` (theo khóa giao dịch).

  @TC-19-654 @P2 @Dương
  Kịch bản: TC-19-654 Gửi lại thủ công lượt đã hết lần thử
    # Truy vết: FR-19-062 · API-19-077, 078, 079 · UI-19-24
    Biết lượt `EXHAUSTED` từ TC-19-652; `WHSINK` đã phục hồi; U-OPR1.
    Khi UI-19-24 lọc `EXHAUSTED`, mở chi tiết, bấm "Gửi lại", nhập lý do.
    Thì `202`; lượt gửi `PENDING` → `DELIVERED`; giữ nguyên `Webhook-Id` (đối tác khử trùng được); các lần thử cũ vẫn xem được. KT: có.

  @TC-19-655 @P3 @Dương
  Kịch bản: TC-19-655 Hủy lượt gửi khi đối tác hoặc đầu nhận bị gỡ
    # Truy vết: FR-19-062 · BR-19-020
    Biết lượt `RETRY_SCHEDULED` tới đầu nhận của P-DVC.
    Khi vô hiệu đầu nhận đó.
    Thì lượt gửi `CANCELLED`, không thử tiếp; thông báo vẫn kéo được qua API-19-109.

  @TC-19-656 @P2 @Âm
  Kịch bản: TC-19-656 Gửi lại lượt đang gửi, đã giao, sai phiên bản
    # Truy vết: FR-19-062 · API-19-078 · ERR-19-021, 045, 046
    Biết lượt `RETRY_SCHEDULED`; lượt `DELIVERED`; U-ACC1 (không có `webhook-resend`).
    Khi gửi lại lượt `RETRY_SCHEDULED`.
    Và gửi lại lượt `DELIVERED`.
    Và gửi lại với `If-Match` cũ.
    Và U-ACC1 gửi lại.
    Thì bước 1, 2 trả `409` ERR-19-021. Bước 3 trả `412` ERR-19-045. Bước 4: 403-PQ.

  @TC-19-657 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-19-657 Kafka ngừng, outbox giữ và phát bù
    # Truy vết: FR-19-061 · NFR-19-013
    Biết kafka của SIT bị chặn mạng 20 phút.
    Khi trong 20 phút tạo và hoàn tất 500 giao dịch.
    Và mở lại Kafka.
    Thì bước 1: API vẫn trả lời bình thường; `outbox_event` tăng 500 × số sự kiện; không lỗi phía đối tác. Bước 2: phát bù hết trong ≤ 5 phút; không mất, không đảo thứ tự trong một giao dịch; webhook đến sau đó.
