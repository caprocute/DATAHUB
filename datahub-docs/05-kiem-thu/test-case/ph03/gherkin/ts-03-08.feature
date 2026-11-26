# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-08
Tính năng: TS-03-08 · Thu hồi token nhanh và tạm ngừng khẩn cấp

  @TC-03-037 @P1 @Dương @Bảo @mật
  Kịch bản: TC-03-037 Thu hồi token có hiệu lực không quá 60 giây
    # Truy vết: FR-03-018 · API-03-053, 054 · UI-03-05 · UC-03-10 · ERR-03-105 · BR-03-021 · NFR-03-009 · SEC-25.
    Biết S-REVOKE; token C-HTTT1 còn hạn 1 giờ, đang gọi 5 lượt/giây; U-T68-TA.
    Khi gọi liên tục mỗi 1 giây bằng token.
    Và S-REVOKE `POST /revocations` `{jti, reason, expiresAt}` kèm `Idempotency-Key`.
    Và ghi thời gian tới lượt gọi đầu tiên nhận lỗi.
    Và U-T68-TA `GET /revocations`.
    Thì bước 2 `201`. Bước 3 lượt gọi bị `401` Lỗi GW 105 "Token đã bị thu hồi. Liên hệ quản trị Datahub." trong ≤ 60 s (mục tiêu ≤ 30 s). Bước 4 `200`, `jti` có trong danh sách. Thu hồi không ảnh hưởng token khác của C-HTTT1. KT: có (`TOKEN_REVOKE`).

  @TC-03-038 @P2 @Âm
  Kịch bản: TC-03-038 Thu hồi token: thiếu scope dịch vụ, người dùng thường, lặp lại
    # Truy vết: FR-03-018 · API-03-053 · ERR-03-022, 003, 019 · BR-03-021.
    Biết U-T68-TA (không có scope `gateway:revoke`); S-SYNC (scope khác); S-REVOKE.
    Khi U-T68-TA `POST /revocations`.
    Và S-SYNC `POST /revocations`.
    Và S-REVOKE gửi thân thiếu `jti`.
    Và S-REVOKE gửi lại cùng `Idempotency-Key` và thân cũ; rồi cùng khóa nhưng thân khác.
    Thì bước 1, 2 403-PQ. Bước 3 `400` ERR-03-003. Bước 4 lần đầu trả lại kết quả cũ không tạo bản ghi mới; thân khác `400` ERR-03-003.

  @TC-03-039 @P1 @Dương
  Kịch bản: TC-03-039 Tạm ngừng khẩn cấp consumer, mở lại
    # Truy vết: FR-03-047 · API-03-017, 018 · UI-03-05 · UC-03-11 · ERR-03-127 · EVT-03-04 · BR-03-021, 022 · NFR-03-009 · SEC-72.
    Biết U-T68-SO1; C-HTTT1 đang gọi.
    Khi SO1 `POST /consumers/ht-ndxp:suspend` có lý do.
    Và đo thời gian tới lượt gọi đầu tiên bị chặn.
    Và SO1 `POST /consumers/ht-ndxp:resume`.
    Thì bước 1 `200`. Bước 2 `403` Lỗi GW 127 "HTTT đang bị tạm ngừng truy cập. Liên hệ quản trị Datahub." trong ≤ 30 s. Bước 3 `200`, gọi lại được ≤ 60 s. EVT: `consumer.state-changed` hai lần. KT: có (`CONSUMER_SUSPEND`, `CONSUMER_RESUME`).

  @TC-03-040 @P1 @Dương @Âm
  Kịch bản: TC-03-040 Tạm ngừng khẩn cấp route và route sai trạng thái
    # Truy vết: FR-03-047 · API-03-019, 020 · UI-03-02 · UC-03-11 · ERR-03-123, 019, 023, 001 · EVT-03-03 · BR-03-021, 029.
    Biết U-T68-SO1; `r-ho-tich` `ACTIVE`; `r-pending` `PENDING`.
    Khi `POST /routes/r-ho-tich:suspend`; gọi route.
    Và `POST …:suspend` lần hai.
    Và `POST /routes/r-pending:suspend`.
    Và `POST /routes/khong-co:suspend`.
    Và `POST /routes/r-ho-tich:resume`.
    Thì bước 1 `200`; lượt gọi `503` Lỗi GW 123 "API đang tạm ngừng. Thử lại sau." kèm `Retry-After` ≤ 30 s. Bước 2 `409` ERR-03-019. Bước 3 `409` ERR-03-023. Bước 4 404-ẩn. Bước 5 `200`, gọi được. Mã route không đổi (BR-03-029).

  @TC-03-041 @P2 @Âm @Bảo @mật
  Kịch bản: TC-03-041 Thiếu quyền thao tác khẩn cấp
    # Truy vết: FR-03-047, 018 · API-03-017, 019, 054 · ERR-03-022 · BR-03-021.
    Biết U-T68-VW; U-T68-AU.
    Khi U-T68-VW `POST /consumers/ht-ndxp:suspend`, `POST /routes/r-ho-tich:suspend`.
    Và U-T68-AU `POST …:resume`.
    Thì cả ba 403-PQ; trạng thái không đổi; KT: không.
