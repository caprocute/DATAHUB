# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-21
Tính năng: TS-18-21 · Phân hệ gửi thông báo và phân giải người nhận

  @TC-18-071 @P1 @Dương @Lũy_đẳng
  Kịch bản: TC-18-071 PH-01 gửi thông báo bất đồng bộ tới vai trò và đầu mối HTTT, lũy đẳng theo khóa
    # Truy vết: FR-18-036, 037 · API-18-091, 093, 094 · BR-18-028, 029 · UI-18-13
    # Mục đích: Chứng minh BR-18-028, 029: gửi qua outbox, người nhận phân giải từ `recipientRef`, phân hệ gọi chỉ nhận mã thông báo và số người nhận, gửi lại cùng khóa trả cùng kết quả.
    Biết T90; S-PH01 (`ops:notify`); `TPL-ONB-MAIL` `ACTIVE`; `recipientRef` gồm `ROLE:TA`, `SYSTEM_CONTACT:HTTT-THUE`; WireMock PH-01 trả đầu mối; máy chủ thư giả MOCK-SMTP.
    Khi S-PH01 `POST /ops/internal/v1/notifications` kèm `Idempotency-Key`.
    Và gửi lại cùng khóa, cùng thân.
    Và S-PH01 `POST /ops/internal/v1/recipients:resolve` cùng `recipientRef`.
    Và `GET /ops/internal/v1/notifications/{messageId}`.
    Thì bước 1 `202` `messageId`, `recipientCount = 3`. Bước 2 `202` cùng `messageId`, MOCK-SMTP chỉ nhận 3 thư. Bước 3 `200` danh sách mã người nhận, không có địa chỉ thư hay số điện thoại. Bước 4 `DELIVERED`, không có địa chỉ.

  @TC-18-072 @P1 @Âm
  Kịch bản: TC-18-072 Khóa lũy đẳng dùng lại với thân khác, không có mẫu ACTIVE, không phân giải được, biến cấm lúc gửi
    # Truy vết: FR-18-036, 037 · API-18-091 · BR-18-027, 028 · ERR-18-009, 039, 041, 042
    # Mục đích: Chứng minh các lỗi của `NotificationApi` trả đúng mã, không thư nào rời hệ thống.
    Biết T90; S-PH01; `TPL-DRAFT` chỉ có phiên bản nháp; MOCK-SMTP đếm thư.
    Khi gửi lại khóa của ca trước với thân khác.
    Và gửi bằng `TPL-DRAFT`.
    Và gửi tới `USER:khong-ton-tai`.
    Và gửi `TPL-ONB-MAIL` kèm biến dữ liệu `soCccd`.
    Thì bước 1 `409` ERR-18-009. Bước 2 `409` ERR-18-041. Bước 3 `422` ERR-18-042. Bước 4 `422` ERR-18-039. MOCK-SMTP nhận 0 thư.

  @TC-18-073 @P1 @Dương @Âm
  Kịch bản: TC-18-073 Gửi đồng bộ thư mang liên kết trong 3 giây và máy chủ thư gián đoạn
    # Truy vết: FR-18-036 · API-18-092 · ERR-18-044 · NFR-18-007
    # Mục đích: Chứng minh chế độ đồng bộ (Q01-52): trả kết quả khi máy chủ thư nhận, quá `18.notify.sync.timeout-ms` hoặc kênh gián đoạn trả `503` để bên gọi xử lý.
    Biết T90; S-PH01; MOCK-SMTP; ở bước 2 MOCK-SMTP ngắt cổng.
    Khi S-PH01 `POST /ops/internal/v1/notifications:send-sync` thư kích hoạt có liên kết.
    Và ngắt MOCK-SMTP, gửi lại khóa mới.
    Thì bước 1 `200` trong ≤ 3 giây, `status = SENT`. Bước 2 `503` ERR-18-044 sau ≤ 3 giây, không tạo bản ghi gửi lại tự động.

  @TC-18-074 @P1 @Chịu_lỗi
  Kịch bản: TC-18-074 Máy chủ thư và SMS gateway lỗi thì thử lại tới 5 lần rồi FAILED có sự kiện
    # Truy vết: FR-18-036, 040 · BR-18-028 · ERR-18-110, 111 · EVT-18-13
    # Mục đích: Chứng minh FR-18-040: lỗi tạm thời được thử lại theo `18.notify.retry.max-attempts` trong `retry.window-hours`, hết lượt thì `FAILED` và phát EVT-18-13 cho phân hệ gọi.
    Biết T95 (đồng hồ giả); `18.notify.sms.enabled = true` cho T95; MOCK-SMTP trả `451` mọi lần; MOCK-SMS trả `503`.
    Khi S-PH01 gửi một thư và một SMS bất đồng bộ.
    Và tua đồng hồ qua 5 lần thử.
    Và đọc `t95.ops.notification.failed.v1`.
    Thì mỗi lần thử ghi ERR-18-110 (thư) và ERR-18-111 (SMS) vào lần gửi; sau lần thứ 5 cả hai `FAILED`; EVT-18-13 có `notificationId`, `templateCode`, `channel`, `errorCode`, `callerPh`, không có địa chỉ.

  @TC-18-075 @P2 @Biên
  Kịch bản: TC-18-075 Tenant SUSPENDED chỉ nhận thông báo nhóm bắt buộc
    # Truy vết: FR-18-036, 038 · BR-18-030
    # Mục đích: Chứng minh xử lý `platform.tenant.status-changed.v1`: khi tenant tạm ngừng, thông báo thường bị `SUPPRESSED`, nhóm bắt buộc vẫn gửi.
    Biết T93; WireMock PH-20 phát `platform.tenant.status-changed.v1` sang `SUSPENDED`; mẫu thường `TPL-NHAC` và mẫu bắt buộc `TPL-BAO-TRI`.
    Khi phát sự kiện tạm ngừng.
    Và S-PH01 gửi bằng `TPL-NHAC` và `TPL-BAO-TRI`.
    Thì thông báo `TPL-NHAC` `SUPPRESSED` có lý do `TENANT_SUSPENDED`; thông báo `TPL-BAO-TRI` `DELIVERED`.
