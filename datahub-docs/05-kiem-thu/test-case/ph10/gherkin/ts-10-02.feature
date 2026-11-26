# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-02
Tính năng: TS-10-02 · Tạo topic và gửi duyệt

  @TC-10-006 @P1 @Dương
  Kịch bản: TC-10-006 Tạo topic bằng trình hướng dẫn và gửi duyệt ngay
    # Truy vết: FR-10-008 · API-10-009 · UI-10-07 · UC-10-02 · BR-10-002, 004 · LGC-HUB-009
    Biết U-T68-IE1; P-DKKD; F-AV1.
    Khi Ở UI-10-07 chọn dự án P-DKKD, miền `tc`, thực thể `doanh-nghiep`, sự kiện `da-tam-ngung`, mô tả 40 ký tự, phân loại `INTERNAL`, `KEY_HASH` với `partitionKeyField = maDoanhNghiep`, lược đồ F-AV1, đánh dấu "Gửi duyệt ngay".
    Và `GET /topics/t68.tc.doanh-nghiep.da-tam-ngung.v1`.
    Thì bước 1 `201` có `approvalRequestCode` dạng `apr-{ULID}`. Bước 2: `status = PENDING_APPROVAL`, `partitions = 6`, `retentionHours = 168`, `replicationFactor = 3`, `minInsyncReplicas = 2`, `cleanupPolicy = DELETE`, `majorVersion = 1`, `topicKind = BUSINESS`; lược đồ v1 `PENDING_APPROVAL`; chưa có `KafkaTopic` ở `dh-config-t68`. Trình hướng dẫn không có ô nhập hệ số nhân bản. KT: có (`TOPIC_CREATE`, băm lược đồ). EVT: không.

  @TC-10-007 @P1 @Âm
  Kịch bản: TC-10-007 Tên topic sai quy ước, miền dành riêng, trùng tên đã ngừng dùng
    # Truy vết: FR-10-008 · API-10-009 · ERR-10-002, 003, 004 · BR-10-002, 003, 030
    Biết U-T68-IE1; topic `t68.tc.cu.da-xoa.v1` đã `RETIRED`.
    Khi `POST /topics` với `domain = "DKKD"`, rồi `entity = "doanh_nghiep"`.
    Và lặp với `domain` lần lượt `event`, `cdc`, `audit`, `obs`, `integration`, `adapter`, `rdm`, `connect`, `payment`, `platform`.
    Và ghép tên dài 201 ký tự.
    Và tạo lại `t68.tc.cu.da-xoa.v1`.
    Và `POST /topics` có `topicKind = CDC` bằng U-T68-IE1.
    Thì bước 1, 2, 3 `422` ERR-10-004 với `errors[].field` đúng trường. Bước 4 `409` ERR-10-002. Bước 5 `422` ERR-10-004 hoặc ERR-10-003 theo API §3.3 (người dùng không đăng ký `CDC`); không có bản ghi topic nào được tạo.

  @TC-10-008 @P1 @Âm @Biên
  Kịch bản: TC-10-008 Tham số vượt trần, tổ hợp định tuyến không hợp lệ, compaction không khóa
    # Truy vết: FR-10-008, 013 · API-10-009 · ERR-10-011, 012, 046, 048 · BR-10-006
    Biết U-T68-IE1; U-T90-IE trên T92 (đã có 3 topic).
    Khi `partitions = 49`; rồi `partitions = 48` (biên).
    Và `retentionHours = 721` khi trần 720.
    Và `KEY_HASH` không có `partitionKeyField`.
    Và `orderingRequired = true` với `ROUND_ROBIN`.
    Và `cleanupPolicy = COMPACT` với `ROUND_ROBIN`.
    Và `SINGLE_PARTITION` với `partitions = 6`.
    Và trên T92 tạo topic thứ tư.
    Thì bước 1: 49 trả `422` ERR-10-012, 48 trả `201`. Bước 2 `422` ERR-10-012. Bước 3, 4, 6 `422` ERR-10-046. Bước 5 `422` ERR-10-048. Bước 7 `422` ERR-10-011 (hạn mức tính cả topic chờ duyệt).

  @TC-10-009 @P1 @Âm
  Kịch bản: TC-10-009 Lược đồ không hợp lệ khi tạo topic
    # Truy vết: FR-10-008, 017 · API-10-009, 012 · ERR-10-015, 017, 018, 020 · BR-10-011
    Biết U-T68-IE1 ở T68; U-T90-IE ở T93 (`pii-check-mode = BLOCK`); F-AV-BAD, F-AV-NOKEY, F-AV-PII.
    Khi tạo topic với F-AV-BAD.
    Và tạo topic `KEY_HASH` theo `maDoanhNghiep` với F-AV-NOKEY.
    Và Ở T93 tạo topic `INTERNAL` với F-AV-PII.
    Và tạo topic với `schemaFormat = PROTOBUF`.
    Thì bước 1 `422` ERR-10-015 kèm dòng, cột lỗi. Bước 2 `422` ERR-10-017 "Trường khóa phân vùng `maDoanhNghiep` không có trong lược đồ". Bước 3 `422` ERR-10-018 liệt kê `soDinhDanh`, `soDienThoai`. Bước 4 `422` ERR-10-020. Không ghi gì vào Apicurio (đếm artifact nhóm `t68`, `t93` không đổi).

  @TC-10-010 @P2 @Dương @Âm
  Kịch bản: TC-10-010 Danh sách topic, chi tiết và thông tin kết nối
    # Truy vết: FR-10-006, 007 · API-10-008, 010, 020 · UI-10-05, 06 · ERR-10-049 · LGC-HUB-009
    Biết U-T68-VW; TP-CP, TP-TD, TP-CDC; topic DLQ `t68.dkkd.doanh-nghiep.da-cap-phep.v1.dlq` có trên cụm.
    Khi `GET /topics?projectCode=dang-ky-kinh-doanh&sort=topicName,asc`.
    Và `GET /topics?topicKind=DLQ`.
    Và `GET /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1` và `/connection-info`.
    Và `GET /topics?status=XYZ&sort=khongco,asc`.
    Và mở UI-10-06 với route `/tich-hop/topic/t68.dkkd.doanh-nghiep.da-cap-phep.v1`.
    Thì bước 1 không có topic `RETIRED`, không có topic `DLQ`; dòng TP-TD có `successorTopic`; `facets` theo `status`, `topicKind`, `dataClass`. Bước 2 trả topic DLQ khi lọc rõ. Bước 3 có `latestSchemaVersion = 3`, danh sách publication, subscription kèm `alertState`; `connection-info` có đường API phát, API kéo, địa chỉ listener `external` (T68 đã bật), URI artifact Apicurio `groups/t68/artifacts/{topicName}`. Bước 4 `400` ERR-10-049. Bước 5 route có dấu chấm mở đúng màn, tab "Cách kết nối" có mã mẫu.

  @TC-10-011 @P2 @Dương @Âm
  Kịch bản: TC-10-011 Rút yêu cầu tạo topic trước khi duyệt
    # Truy vết: FR-10-008 · API-10-102, 011, 012 · ERR-10-006
    Biết U-T68-IE1, U-T68-IE2; topic từ TC-10-006 ở `PENDING_APPROVAL`.
    Khi IE2 gọi `POST /approval-requests/{requestCode}:withdraw`.
    Và IE1 gọi `:withdraw`.
    Và IE1 `PATCH /topics/{topicName}` đổi `partitions = 3`, rồi `:submit`.
    Thì bước 1 403-PQ (chỉ người gửi được rút). Bước 2 `200`, yêu cầu `WITHDRAWN`, topic và lược đồ về `DRAFT`. Bước 3 sửa được khi `DRAFT`, gửi lại tạo yêu cầu mới `PENDING`.
