# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-03
Tính năng: TS-10-03 · Duyệt topic và cấp phát qua GitOps

  @TC-10-012 @P1 @Dương
  Kịch bản: TC-10-012 Duyệt tạo topic, cấp phát tới ACTIVE trong 3 phút
    # Truy vết: FR-10-009 · API-10-057, 058, 059 · UI-10-13 · UC-10-03 · EVT-10-01, 05 · BR-10-004, 023 · NFR-10-008 · LGC-HUB-009
    Biết U-T68-IA1; topic `t68.tc.doanh-nghiep.da-tam-ngung.v1` `PENDING_APPROVAL` do IE1 gửi.
    Khi mở UI-10-13 (`/viec-cua-toi?phan-he=10`), mở yêu cầu `TOPIC_CREATE`, xem khác biệt và kết quả kiểm tra lược đồ; duyệt với ý kiến "Đồng ý cấp phát".
    Và theo dõi `GET /topics/{topicName}` mỗi 10 giây.
    Và đọc `dh-config-t68/kafka/topics/{topicName}.yaml` và artifact Apicurio.
    Thì bước 1 `200`, yêu cầu `APPROVED`. Bước 2 `PROVISIONING` rồi `ACTIVE` trong ≤ 3 phút. Bước 3: `replicas: 3`, `min.insync.replicas: 2`, `retention.ms = 604800000`, nhãn `dh.gov.vn/tenant: t68`; có thêm tệp topic `{topicName}.dlq`; Apicurio có artifact `groupId = t68`, `artifactId = {topicName}`, quy tắc tương thích `BACKWARD`, phiên bản 1 `ENABLED`. EVT: `topic.activated`, `schema.version-enabled`. KT: có (duyệt topic, mã commit).

  @TC-10-013 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-013 Người tạo tự duyệt, thiếu ý kiến, thiếu xác nhận dữ liệu cá nhân, từ chối
    # Truy vết: FR-10-009 · API-10-059, 101 · ERR-10-008, 009 · BR-10-010, 014
    Biết U-T68-TA tạo và gửi topic `t68.tc.nguoi-dai-dien.da-dang-ky.v1` với F-AV-PII (`WARN`); U-T68-IA2 là người gửi một yêu cầu khác; U-T68-IA1.
    Khi U-T68-TA duyệt chính yêu cầu của mình.
    Và U-T68-IA2 duyệt yêu cầu do chính mình gửi.
    Và U-T68-IA1 duyệt không có `comment`.
    Và U-T68-IA1 duyệt có `comment` nhưng thiếu `acknowledgePii`.
    Và U-T68-IA1 từ chối với `comment = "Không"` (dưới 10 ký tự), rồi với lý do đủ dài.
    Thì bước 1, 2 `403` ERR-10-008 (bốn mắt áp cả với TA). Bước 3, 4 `400` ERR-10-009. Bước 5 lần đầu `400` ERR-10-009; lần hai `200`, yêu cầu `REJECTED`, topic về `DRAFT`, người gửi nhận thông báo. Không có artifact Apicurio, không có commit Git.

  @TC-10-014 @P1 @Âm @Khả @dụng
  Kịch bản: TC-10-014 Apicurio hoặc Git ngừng khi duyệt không để lại trạng thái dở
    # Truy vết: FR-10-009 · API-10-059 · ERR-10-029 · BR-10-036
    Biết U-T68-IA1; hai topic `PENDING_APPROVAL`; SIM-GIT có thể dừng.
    Khi dừng Apicurio; duyệt topic thứ nhất.
    Và bật Apicurio, dừng SIM-GIT; duyệt topic thứ hai.
    Thì bước 1 `503` ERR-10-029 có `Retry-After`; yêu cầu vẫn `PENDING`. Bước 2 `503` ERR-10-029; artifact đã tạo ở Apicurio được xóa bù; yêu cầu vẫn `PENDING`, topic vẫn `PENDING_APPROVAL`. Sau khi bật lại và duyệt lần nữa thì `ACTIVE` bình thường.

  @TC-10-015 @P1 @Dương @Âm
  Kịch bản: TC-10-015 Cấp phát thất bại, thử lại và hủy cấp phát
    # Truy vết: FR-10-010 · API-10-013, 014 · ERR-10-006, 038 · BR-10-036
    Biết U-T68-IE1; chính sách Kyverno thử nghiệm từ chối `KafkaTopic` có nhãn `dh.gov.vn/project: tc-loi`; topic của dự án `tc-loi` được duyệt.
    Khi chờ quá `10.provisioning.timeout-minutes` (đặt 3 phút ở SIT).
    Và đề nghị publication trên topic đó.
    Và gỡ chính sách, gọi `POST /topics/{topicName}:retry-provisioning`.
    Và với topic `FAILED` thứ hai gọi `:cancel-provisioning`; gọi `:retry-provisioning` với topic `ACTIVE`.
    Thì bước 1 topic `FAILED`, `provisioningError` có thông điệp Kyverno, IE và TA nhận cảnh báo. Bước 2 `409` ERR-10-038. Bước 3 `202`, rồi `ACTIVE`. Bước 4: hủy trả `200`, topic về `DRAFT`, tệp YAML bị gỡ khỏi Git; thử lại với `ACTIVE` trả `409` ERR-10-006.

  @TC-10-016 @P2 @Âm @Bảo @mật
  Kịch bản: TC-10-016 Phát hiện lệch giữa cụm và Git
    # Truy vết: FR-10-010 · BR-10-036 · NFR-10-019
    Biết TP-GT `ACTIVE`; quyền quản trị cụm ở SIT.
    Khi sửa tay `retention.ms` của TP-GT bằng `kafka-configs`.
    Và xóa tay tài nguyên `KafkaTopic` của một topic thử.
    Và chờ một chu kỳ đối chiếu 10 phút.
    Thì cảnh báo lệch cho cả hai trường hợp, kèm giá trị Git và giá trị cụm; Argo CD khôi phục cấu hình theo Git; PH-10 không tự sửa cấu hình bằng Admin API; trạng thái topic ở UI-10-06 hiện dải "Lệch cấu hình".
