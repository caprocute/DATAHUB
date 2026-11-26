# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-10
Tính năng: TS-10-10 · Publication: đề nghị, duyệt, cấp scope và ACL

  @TC-10-044 @P1 @Dương
  Kịch bản: TC-10-044 Đề nghị và duyệt publication HTTP, phát được trong 2 phút
    # Truy vết: FR-10-030, 031 · API-10-043, 059 · UI-10-06, 13 · EVT-10-06 · NFR-10-008 · UC-10-09 · LGC-HUB-012
    Biết U-T68-IE1, U-T68-IA1; bên phát `tc-ht-qldd` từ TC-10-037; TP-GT `ACTIVE`.
    Khi IE1 `POST /publications` với `publisherCode = tc-ht-qldd`, `topicName = TP-GT`, `purpose` 30 ký tự, `expectedRatePerMinute = 60`.
    Và IA1 duyệt ở UI-10-13.
    Và client của `HT-QLDD` xin token mới, phát một sự kiện.
    Thì bước 1 `201`, `publicationCode = pub-{ULID chữ thường}`, `PENDING_APPROVAL`. Bước 2 `ACTIVE`, `grantedScope = topic:t68.dkkd.doanh-nghiep.giai-the.v1:publish`; Keycloak có client scope tùy chọn; bundle OPA có cặp (client, topic). Bước 3 `202` trong ≤ 2 phút sau duyệt. EVT: `publication.activated`. KT: có (scope, hạn mức).

  @TC-10-045 @P1 @Âm
  Kịch bản: TC-10-045 Publication trên topic ngừng khuyến nghị, trùng cặp, topic nhạy cảm, vượt hạn mức, tự duyệt
    # Truy vết: FR-10-030, 031 · API-10-043, 059 · ERR-10-008, 011, 024, 025, 051 · BR-10-016, 019, 029
    Biết U-T68-IE1, U-T68-TA; TP-TD `DEPRECATED`; TP-KS `SENSITIVE`; `HT-QLDD` chưa đạt cấp độ ATTT tenant yêu cầu; T92 hạn mức sản xuất 1 MiB/s đã phân bổ hết.
    Khi đề nghị publication `tc-ht-qldd` trên TP-TD.
    Và đề nghị lần hai cho cặp (`ht-dkkd`, TP-CP).
    Và đề nghị `tc-ht-qldd` trên TP-KS.
    Và Ở T92 duyệt publication có `quotaBytesPerSecond = 524288`.
    Và TA đề nghị rồi tự duyệt.
    Thì bước 1 `422` ERR-10-025. Bước 2 `409` ERR-10-024. Bước 3 `422` ERR-10-051. Bước 4 `422` ERR-10-011. Bước 5 `403` ERR-10-008.

  @TC-10-046 @P1 @Dương @Âm
  Kịch bản: TC-10-046 Tạm ngừng có hiệu lực trước khi token hết hạn; tiếp tục; thu hồi
    # Truy vết: FR-10-032 · API-10-045, 096, 097 · ERR-10-006, 102 · EVT-10-07 · BR-10-020 · NFR-10-009
    Biết U-T68-TO, U-T68-IE1; publication của PB-DKKD trên TP-CP; token của C-DKKD còn hạn 5 phút; publication của PB-DKKD-K trên TP-GT.
    Khi TO `:suspend` publication HTTP; C-DKKD phát liên tục bằng token cũ.
    Và TO `:suspend` publication Kafka; producer đang mở kết nối tiếp tục gửi.
    Và TO `:resume` cả hai.
    Và IE1 `:revoke` publication HTTP; TO gọi `:resume` publication đã thu hồi.
    Thì bước 1 lượt phát bị từ chối 403-PQ trong ≤ 60 giây dù token còn hạn. Bước 2 producer nhận `TopicAuthorizationException` trong ≤ 2 phút. Bước 3 phát lại được, không cần duyệt. Bước 4 `REVOKED`, scope gỡ khỏi client; `:resume` trả `409` ERR-10-006. EVT: `publication.state-changed` cho mỗi lần đổi.
