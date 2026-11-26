# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-04
Tính năng: TS-10-04 · Thay đổi cấu hình topic đang hoạt động

  @TC-10-017 @P1 @Dương
  Kịch bản: TC-10-017 Tăng phân vùng có xác nhận tác động thứ tự
    # Truy vết: FR-10-011 · API-10-015, 059 · EVT-10-02 · BR-10-005 · UC-10-04
    # Mục đích: Chứng minh luồng thành công, theo FR-10-011 (Tăng số phân vùng của topic đang hoạt động).
    Biết U-T68-IE1, U-T68-IA1; TP-CP 6 phân vùng, SUB-PUSH đang giao.
    Khi `POST /topics/t68.dkkd.doanh-nghiep.da-cap-phep.v1/change-requests` với `partitions = 12`, `reason`, `acknowledgeOrderingImpact = true`.
    Và IA1 duyệt.
    Và phát 1.000 sự kiện trong lúc áp dụng.
    Thì bước 1 `201`, phản hồi có cảnh báo khóa ánh xạ sang phân vùng khác và gợi ý FR-10-015. Bước 2 Cụm áp dụng, `partitions = 12`. Bước 3 SUB-PUSH tự nhận phân vùng mới qua tái cân bằng, không mất sự kiện. EVT: `topic.changed`. KT: có (6 sang 12, người duyệt).
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-018 @P1 @Âm
  Kịch bản: TC-10-018 Giảm phân vùng, thiếu xác nhận, topic một phân vùng
    # Truy vết: FR-10-011 · API-10-015 · ERR-10-012, 013, 014 · BR-10-005
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-011 (Tăng số phân vùng của topic đang hoạt động).
    Biết U-T68-IE1; TP-CP; topic `SINGLE_PARTITION` thử.
    Khi đề nghị `partitions = 3` cho TP-CP.
    Và đề nghị `partitions = 8` không có `acknowledgeOrderingImpact`.
    Và đề nghị `partitions = 49`.
    Và đề nghị tăng phân vùng cho topic `SINGLE_PARTITION`.
    Thì bước 1 `422` ERR-10-013. Bước 2 `409` ERR-10-014. Bước 3 `422` ERR-10-012. Bước 4 `422` ERR-10-046. Không có yêu cầu duyệt nào được tạo.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-019 @P1 @Dương @Âm
  Kịch bản: TC-10-019 Tăng lưu giữ không cần duyệt; giảm lưu giữ chặn khi có subscription chậm
    # Truy vết: FR-10-012 · API-10-015, 059 · ERR-10-009, 012 · EVT-10-02
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-012 (Thay đổi lưu giữ và chính sách dọn (compaction)).
    Biết U-T68-IE1, U-T68-IA1; TP-CP; SUB-FLOW có `lagSeconds = 7200` (giả lập dừng luồng).
    Khi đổi `retentionHours = 336`.
    Và đổi `retentionHours = 1`.
    Và IA1 duyệt yêu cầu ở bước 2 không có `acknowledgeDataLoss`.
    Và IA1 duyệt có `acknowledgeDataLoss = true` và ý kiến.
    Thì bước 1 áp dụng ngay không qua duyệt, EVT: `topic.changed`. Bước 2 `201` tạo `TOPIC_CHANGE`, phản hồi liệt kê `luong-dong-bo-thue-dn-cap-phep` có lag lớn hơn lưu giữ mới. Bước 3 `400` ERR-10-009. Bước 4 `200`, `retention.ms = 3600000` sau khi cụm áp dụng.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-020 @P1 @Dương @Âm
  Kịch bản: TC-10-020 Đổi chế độ định tuyến và khóa; chế độ bị tắt
    # Truy vết: FR-10-013 · API-10-015 · ERR-10-043, 046, 047 · BR-10-006 · LGC-HUB-014
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-013 (Chế độ định tuyến và khóa phân vùng).
    Biết U-T68-IE1, U-T68-IA1, U-T68-TA; TP-GT (`ROUND_ROBIN`, không `orderingRequired`).
    Khi đề nghị TP-GT sang `KEY_HASH` theo `maDoanhNghiep`; IA1 duyệt; phát 10 sự kiện cùng khóa.
    Và đề nghị TP-CP (`orderingRequired`) sang `ROUND_ROBIN`.
    Và đề nghị TP-CP đổi `partitionKeyField` sang `loaiThayDoi`.
    Và TA tắt `SINGLE_PARTITION` (không topic nào dùng) rồi IE1 đề nghị topic thử sang `SINGLE_PARTITION`.
    Thì bước 1 10 sự kiện cùng khóa vào cùng một phân vùng, đúng thứ tự offset; cổng áp dụng cấu hình mới ≤ 60 giây sau EVT `topic.changed`. Bước 2 `422` ERR-10-046. Bước 3 `409` ERR-10-047 kèm gợi ý tạo `.v2`. Bước 4 `422` ERR-10-043.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-021 @P1 @Dương @Âm
  Kịch bản: TC-10-021 Đổi mức tương thích: nới lỏng, siết chặt, NONE
    # Truy vết: FR-10-021 · API-10-015 · ERR-10-016, 019 · BR-10-012 · ADR-070
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-021 (Đặt mức tương thích của lược đồ).
    Biết U-T68-IE1, U-T68-IA1; TP-CP v1…v3 `ENABLED` (v3 bỏ một trường không mặc định so với v1); topic thử `DRAFT` chưa từng `ACTIVE`.
    Khi đề nghị TP-CP sang `FULL_TRANSITIVE`.
    Và đề nghị TP-CP sang `NONE`.
    Và đề nghị TP-CP sang `BACKWARD_TRANSITIVE` có lý do; IA1 duyệt.
    Và đặt `NONE` cho topic `DRAFT`.
    Thì bước 1 `409` ERR-10-016 kèm cặp phiên bản vi phạm (v1, v3). Bước 2 `422` ERR-10-019. Bước 3 duyệt xong, quy tắc tương thích của artifact ở Apicurio là `BACKWARD_TRANSITIVE`; bên phát, bên nhận nhận thông báo; EVT: `topic.changed`. Bước 4 được nhận.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
