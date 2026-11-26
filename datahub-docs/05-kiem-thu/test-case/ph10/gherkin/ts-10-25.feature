# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-25
Tính năng: TS-10-25 · Hợp đồng PH-05: topic CDC tự duyệt và thay đổi lược đồ

  @TC-10-108 @P1 @Dương
  Kịch bản: TC-10-108 PH-05 đăng ký topic CDC, tự duyệt, trả 202 rồi ACTIVE
    # Truy vết: FR-10-066 · API-10-009 · EVT-10-01 · BR-10-031 · UC-10-23 · FR-05-048 · LGC-TOOL-010
    # Mục đích: Chứng minh luồng thành công, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).
    Biết S-PH05; bộ điều hợp `dkkd-cdc` mới thêm bảng `public.nganhnghe`; `onBehalfOf = an`.
    Khi `POST /topics` với `topicKind = CDC`, `topicName = t68.cdc.dkkd-cdc.public.nganhnghe.v1`, lược đồ Avro sinh từ bảng, `partitionKeyField` là khóa chính, `sourceRef`.
    Và gọi lại cùng thân.
    Và theo dõi tới `ACTIVE`.
    Thì bước 1 `202`, `Location`; dự án hệ thống `cdc-dkkd-cdc` có sẵn; yêu cầu `TOPIC_CREATE` `APPROVED`, `autoApproved = true`, `decidedBy = system:auto`, `requestedBy` là tài khoản dịch vụ; publication `ACTIVE` cho bên phát `INTERNAL_SERVICE` của `dh-cdc`. Bước 2 `200`, trạng thái hiện tại. Bước 3 `ACTIVE` ≤ 3 phút. EVT: `topic.activated`. KT: có (`onBehalfOf`, `sourceRef`).
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-109 @P1 @Âm
  Kịch bản: TC-10-109 CDC sai tên, sai tiền tố, cấu hình khác, người dùng sửa topic CDC, tự duyệt tắt
    # Truy vết: FR-10-066 · API-10-009, 011 · ERR-10-002, 004, 005, 045 · BR-10-002, 030
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).
    Biết S-PH05; U-T68-IE1; TP-CDC; T95 (tự duyệt tắt).
    Khi `topicName = t68.cdc.a.b.c.d.v1` (5 đoạn giữa).
    Và `topicName = t01.cdc.dkkd-cdc.public.dangky.v1` bằng token T68.
    Và đăng ký lại TP-CDC với `partitions` khác.
    Và IE1 `PATCH` cấu hình TP-CDC; IE1 sửa mô tả.
    Và Ở T95 đăng ký topic CDC.
    Thì bước 1 `422` ERR-10-004. Bước 2 `422` ERR-10-005. Bước 3 `409` ERR-10-002. Bước 4 cấu hình `422` ERR-10-045; mô tả `200`. Bước 5 `202` nhưng yêu cầu `PENDING`, chờ người duyệt.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-110 @P1 @Dương @Âm
  Kịch bản: TC-10-110 Thay đổi lược đồ tương thích và phá vỡ theo EVT-05-11
    # Truy vết: FR-10-068, 015 · API-10-023, 018 · EVT-05-11 · EVT-10-03, 05 · ERR-10-016
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-068 (Xử lý thông báo thay đổi lược đồ CDC).
    Biết SIM-PH05; TP-CDC v1; F-AV-ADD, F-AV-BRK dạng Avro CDC.
    Khi SIM-PH05 phát EVT-05-11 `COMPATIBLE` rồi gửi phiên bản thêm cột có mặc định.
    Và gửi phiên bản đổi kiểu cột theo nhánh `COMPATIBLE`.
    Và phát EVT-05-11 `BREAKING` đã `ACCEPT`; gọi `:new-major-version`.
    Và phát lại EVT-05-11 ở bước 3 cùng `id`.
    Thì bước 1 phiên bản tự duyệt `ENABLED`, EVT: `schema.version-enabled`. Bước 2 `409` ERR-10-016. Bước 3 topic `.v2` tự duyệt, `.v1` `DEPRECATED` với `successorTopic`, EVT: `topic.deprecated`, đầu mối subscription nhận thông báo. Bước 4 inbox bỏ qua.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-111 @P2 @Âm @Khả @dụng
  Kịch bản: TC-10-111 PH-10 ngừng thì PH-05 không khai báo CDC mới, CDC đang chạy không ảnh hưởng
    # Truy vết: FR-10-066 · ERR-10-029 · ERR-05-029 · NFR-10-013
    # Mục đích: Chứng minh hệ thống giữ đúng hành vi khi có sự cố nêu ở tên ca, theo FR-10-066 (Đăng ký topic hộ PH-05 cho CDC).
    Biết S-PH05; `dh-integration` mô-đun `event` ngừng; CDC TP-CDC đang ghi.
    Khi PH-05 đăng ký topic CDC mới.
    Và đếm bản tin CDC trên TP-CDC trong 5 phút.
    Thì bước 1 PH-05 nhận ERR-10-029 và trả ERR-05-029 cho người dùng. Bước 2 CDC tiếp tục ghi (chỉ phụ thuộc Kafka, Apicurio).
    # Hậu điều kiện: Lỗi giả lập đã gỡ, các thành phần hoạt động lại bình thường.
