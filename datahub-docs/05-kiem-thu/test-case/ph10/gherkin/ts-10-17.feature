# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-17
Tính năng: TS-10-17 · Giao nhận KÉO qua API: lease và cursor

  @TC-10-077 @P1 @Dương
  Kịch bản: TC-10-077 Kéo, xác nhận, kéo tiếp; chờ dài khi rỗng
    # Truy vết: FR-10-043 · API-10-080, 081 · UC-10-15 · LGC-HUB-013
    # Mục đích: Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).
    Biết C-BHXH có scope `topic:{TP-CP}:subscribe`; SUB-PULL; 250 sự kiện mới.
    Khi `GET /event/v1/subscriptions/ht-bhxh-dn-cap-phep/events?max=100&waitSeconds=0`.
    Và `POST …/events:ack` với `cursor`.
    Và lặp tới hết; gọi `waitSeconds=10` khi rỗng, phát một sự kiện sau 3 giây.
    Thì bước 1 `200`, 100 sự kiện CloudEvents JSON, `cursor`, `leaseExpiresAt` sau 30 giây. Bước 2 `204`, offset nhóm `dh-sub-t68-ht-bhxh-dn-cap-phep` tiến đúng 100. Bước 3 đủ 250 sự kiện không trùng; lượt chờ dài trả sự kiện mới sau khoảng 3 giây; hết giờ không có sự kiện trả `204`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-078 @P1 @Dương @Biên
  Kịch bản: TC-10-078 Kéo lặp khi chưa ack trả đúng lô cũ; lease hết hạn
    # Truy vết: FR-10-043 · API-10-080, 081 · ERR-10-109 · BR-10-009
    # Mục đích: Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).
    Biết C-BHXH; SUB-PULL; ba bản sao cổng sự kiện.
    Khi kéo lô A, không ack; kéo lại ngay qua bản sao cổng khác.
    Và chờ 31 giây; ack bằng cursor của lô A.
    Và kéo lại.
    Thì bước 1 trả lại đúng lô A (cùng `id`, cùng `cursor` vị trí). Bước 2 `409` ERR-10-109. Bước 3 lô mới bắt đầu từ cùng vị trí lô A (ít nhất một lần), `leaseId` khác.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-079 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-079 Cursor giả, cursor của subscription khác, client không phải bên nhận
    # Truy vết: FR-10-043, 064 · API-10-080, 081 · ERR-10-101, 102, 103, 109
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-043 (Giao nhận KÉO qua API).
    Biết C-BHXH, C-THUE; cursor hợp lệ của SUB-PULL; subscription kéo thử thứ hai của `HT-BHXH`.
    Khi sửa phần `offsets` của cursor (base64url) rồi ack.
    Và dùng cursor SUB-PULL để ack subscription thứ hai.
    Và C-THUE kéo SUB-PULL; token hết hạn kéo SUB-PULL.
    Và C-BHXH kéo `ht-bhxh-dn-cap-phep` ở đường T01 (subscription trùng mã ở T01).
    Thì bước 1, 2 `409` ERR-10-109 (HMAC sai), offset không đổi. Bước 3 403-PQ (ERR-10-102); `401` ERR-10-101. Bước 4 404-ẩn, không lộ sự kiện T01.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-080 @P1 @Dương
  Kịch bản: TC-10-080 Nack đưa sự kiện vào DLQ, phần còn lại được xác nhận
    # Truy vết: FR-10-043, 049 · API-10-082 · ERR-10-113 · EVT-10-11
    # Mục đích: Chứng minh luồng thành công, theo FR-10-043 (Giao nhận KÉO qua API).
    Biết C-BHXH; lô 100 sự kiện chưa ack.
    Khi `POST …/events:nack` với `cursor`, `eventIds` gồm 2 sự kiện, `reason`.
    Thì `204`; 2 mục DLQ `NEW` với `origin = PULL_NACK`, `errorCode = ERR-10-113`; offset tiến 100; lượt kéo sau không trả lại 2 sự kiện đó. EVT: `delivery.dead-lettered`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-081 @P2 @Âm @Khả @dụng
  Kịch bản: TC-10-081 Hạn mức kéo và Valkey ngừng
    # Truy vết: FR-10-043 · API-10-080 · ERR-10-107, 121
    # Mục đích: Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-043 (Giao nhận KÉO qua API).
    Biết C-BHXH với hạn mức 60 lượt/phút ở SIT.
    Khi kéo 80 lượt/phút.
    Và dừng Valkey; kéo; phát qua API phát.
    Thì bước 1 lượt vượt `429` ERR-10-107 có `Retry-After`. Bước 2 kéo trả `503` ERR-10-121 `Retry-After: 5`; API phát vẫn `202` (chống trùng bị bỏ qua).
    # Hậu điều kiện: Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
