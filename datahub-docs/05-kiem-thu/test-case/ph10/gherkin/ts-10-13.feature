# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-13
Tính năng: TS-10-13 · Subscription: đề nghị, xác minh endpoint, duyệt

  @TC-10-056 @P1 @Dương
  Kịch bản: TC-10-056 Đề nghị subscription PUSH, xác minh endpoint, duyệt, giao trong 2 phút
    # Truy vết: FR-10-035, 036, 037 · API-10-047, 051, 059, 120 · UI-10-11, 13 · EVT-10-08 · NFR-10-008 · UC-10-12, 13 · LGC-HUB-013
    # Mục đích: Chứng minh luồng thành công, theo FR-10-035 (Đề nghị subscription).
    Biết U-T68-IE1, U-T68-IA1; bên nhận thử `tc-ht-thue2` (`WEBHOOK_PUSH`); SIM-WH `https://hooks.sim.test/tc` trả `WebHook-Allowed-Origin: event.t68.datahub`.
    Khi Ở UI-10-11 chọn TP-CP, chế độ ĐẨY, URI, `workerCount = 3`, `maxRetries = 5`, `startPosition = LATEST`; bấm "Xác minh endpoint" rồi "Gửi đề nghị".
    Và IA1 duyệt.
    Và IE1 gọi `POST /subscriptions/{subscriptionCode}/signing-keys:claim` hai lần.
    Và phát một sự kiện lên TP-CP.
    Thì bước 1 `POST /endpoint-verifications` trả `result = PASSED` (SIM-WH nhận `OPTIONS` có `WebHook-Request-Origin`); `POST /subscriptions` trả `201`, mã mặc định `tc-ht-thue2-doanh-nghiep-da-cap-phep` khi không nhập. Bước 2 `PROVISIONING` rồi `ACTIVE`, `consumerGroup = dh-sub-t68-{subscriptionCode}`, nhóm khởi tạo ở cuối topic. Bước 3 lần đầu trả khóa `whsec_…` một lần, lần hai `409` ERR-10-006. Bước 4 SIM-WH nhận trong ≤ 2 phút sau duyệt. EVT: `subscription.activated`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-057 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-057 Endpoint không hợp lệ: HTTP, tự ký, chuyển hướng, IP riêng, ngoài egress, bắt tay sai
    # Truy vết: FR-10-035, 036 · API-10-047, 051 · ERR-10-026, 027 · BR-10-026
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-035 (Đề nghị subscription).
    Biết U-T68-IE1; SIM-WH-BAD; `https://hooks.sim.test/no-origin` không trả `WebHook-Allowed-Origin`.
    Khi xác minh lần lượt `http://plain.sim.test`, `https://10.96.0.10/h`, `https://ngoai-egress.example/h`.
    Và xác minh `https://selfsigned.sim.test/h`, `https://redirect.sim.test/h`, `https://hooks.sim.test/no-origin`.
    Và đề nghị subscription với endpoint đã xác minh cách đây 25 giờ.
    Thì bước 1 `422` ERR-10-026. Bước 2 `422` ERR-10-027 với lý do TLS, chuyển hướng (không theo), thiếu tiêu đề. Bước 3 hệ thống chạy lại xác minh; thất bại thì `422` ERR-10-027. Không có lượt kết nối nào tới `10.0.0.5` hay `10.96.0.10` ở nhật ký egress gateway.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-058 @P1 @Âm @Biên
  Kịch bản: TC-10-058 Tổ hợp chế độ, worker vượt phân vùng, thời điểm ngoài lưu giữ, trùng cặp, topic nhạy cảm
    # Truy vết: FR-10-035, 040 · API-10-047 · ERR-10-011, 024, 025, 028, 030, 031, 051 · BR-10-017, 019, 025
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-035 (Đề nghị subscription).
    Biết U-T68-IE1; U-T01-IE; T92 đã có 2 subscription.
    Khi SB-THUE (`WEBHOOK_PUSH`) với `deliveryMode = PULL_API`; SB-THUE với `INTERNAL`.
    Và `workerCount = 7` trên TP-CP 6 phân vùng; `workerCount = 6` (biên).
    Và `startPosition = TIMESTAMP`, `startAt` 10 ngày trước (lưu giữ 7 ngày).
    Và đề nghị lần hai cặp (SB-THUE, TP-CP).
    Và bên nhận chưa đạt cấp độ ATTT trên TP-KS; subscription TP-KS thiếu `legalBasis`.
    Và U-T01-IE đề nghị `PULL_KAFKA`; T92 đề nghị subscription thứ ba.
    Thì bước 1 `400` ERR-10-003. Bước 2: 7 trả `422` ERR-10-030; 6 được nhận. Bước 3 `422` ERR-10-031 có `availableRange[]`. Bước 4 `409` ERR-10-024. Bước 5 `422` ERR-10-051; `400` ERR-10-003. Bước 6 `422` ERR-10-028; `422` ERR-10-011.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-059 @P1 @Dương
  Kịch bản: TC-10-059 Điểm bắt đầu EARLIEST và TIMESTAMP
    # Truy vết: FR-10-040 · API-10-047 · BR-10-022 · LGC-HUB-013
    # Mục đích: Chứng minh luồng thành công, theo FR-10-040 (Điểm bắt đầu và offset bắt đầu).
    Biết TP-CP có 5.000 bản tin trong 3 ngày gần nhất; hai bên nhận thử.
    Khi subscription A `EARLIEST`; subscription B `TIMESTAMP` tại đầu ngày hôm qua; duyệt cả hai.
    Và đọc offset đã commit ban đầu của hai nhóm.
    Thì phản hồi đề nghị A có cảnh báo số bản tin ước lượng và thời gian giao hết. A bắt đầu từ offset sớm nhất còn trên cụm; B từ offset trả bởi `offsetsForTimes` theo từng phân vùng. Nhóm do PH-10 khởi tạo vị trí, bộ giao nhận chạy với `auto.offset.reset=none`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-060 @P2 @Dương @Âm
  Kịch bản: TC-10-060 OR đề nghị cho HTTT của tổ chức mình; ngoài tổ chức; bốn mắt; ngoại lệ xác minh
    # Truy vết: FR-10-035, 036, 037 · API-10-047, 059, 091 · ERR-10-008, 044, 012
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-035 (Đề nghị subscription).
    Biết U-T68-OR (`SO-TC`); SB-TC; SB-THUE (`SO-CT`); U-T68-TA; U-T68-IA1.
    Khi OR đề nghị subscription SB-TC trên TP-CP.
    Và OR đề nghị subscription SB-THUE.
    Và TA đề nghị rồi tự duyệt một subscription.
    Và TA cấp ngoại lệ xác minh 7 ngày cho endpoint nội mạng của tỉnh; cấp 400 ngày.
    Thì bước 1 `201`. Bước 2 403-TC. Bước 3 `403` ERR-10-008. Bước 4: 7 ngày `200`, `lastVerification.result = WAIVED` có hạn; 400 ngày `422` ERR-10-012. KT: có cho ngoại lệ.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
