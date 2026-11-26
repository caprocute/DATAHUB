# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-32
Tính năng: TS-10-32 · Kiểm toán và an toàn bí mật

  @TC-10-134 @P1 @Dương
  Kịch bản: TC-10-134 Đối chiếu kiểm toán với mọi lệnh ghi
    # Truy vết: FR-10-065 · NFR-10-020
    Biết toàn bộ ca API của TS-10-01…29 trong một lần chạy SIT.
    Khi lấy danh sách lệnh ghi thành công từ nhật ký APISIX; lấy bản ghi kiểm toán PH-13 theo `traceId`.
    Và mở tab Lịch sử ở UI-10-03, 06, 12.
    Thì mỗi lệnh ghi có đúng một bản ghi với chủ thể, hành động, đối tượng, giá trị trước và sau, lý do, mã yêu cầu duyệt, mã commit khi có; thao tác hệ thống có chủ thể `system:dh-…`. Tab Lịch sử hiển thị đúng.

  @TC-10-135 @P1 @Bảo @mật
  Kịch bản: TC-10-135 Mồi khóa ký qua toàn bộ vòng đời subscription
    # Truy vết: FR-10-042, 037, 047, 070 · NFR-10-016 · BR-10-027 · API-10-120, 054, 100, 074
    Biết U-T68-IE1, U-T68-TO; subscription PUSH thử.
    Khi duyệt, nhận khóa, xoay, thu hồi khẩn, xuất khai báo, thu hồi subscription; ghi lại mọi giá trị `whsec_…` đã thấy.
    Và tìm các giá trị đó trong HAR của Playwright, `localStorage`, `sessionStorage`, log mọi pod 1 giờ, vết, bảng `ph10_event.*`, outbox, Kafka `t68.*`, DLQ, tệp xuất, kiểm toán, thư thông báo.
    Thì mồi sạch; giá trị chỉ có ở OpenBao `kv/dh/t68/event/subscriptions/{subscriptionCode}/signing`; khóa ≥ 256 bit ngẫu nhiên; `signing_key` chỉ có `keyId`, `secretRef`.

  @TC-10-136 @P2 @Âm @Biên
  Kịch bản: TC-10-136 Idempotency-Key dùng lại với thân khác
    # Truy vết: FR-10-003, 008, 035 · API-10-002, 009, 047 · ERR-10-037
    Biết U-T68-IE1.
    Khi `POST /projects` hai lần cùng khóa cùng thân; lần ba cùng khóa khác tên.
    Và khóa 15 ký tự; sau 25 giờ dùng lại khóa.
    Thì bước 1 lần hai trả lại phản hồi cũ (`201`, cùng `Location`), lần ba `422` ERR-10-037. Bước 2 khóa ngắn `400` ERR-10-003; sau 25 giờ xử lý như mới.
