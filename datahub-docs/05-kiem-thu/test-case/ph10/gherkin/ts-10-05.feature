# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-05
Tính năng: TS-10-05 · Ngừng topic và phiên bản chính mới

  @TC-10-022 @P1 @Dương
  Kịch bản: TC-10-022 Ngừng khuyến nghị topic có kế nhiệm
    # Truy vết: FR-10-014 · API-10-016 · EVT-10-03 · BR-10-016 · UC-10-05
    # Mục đích: Chứng minh luồng thành công, theo FR-10-014 (Ngừng khuyến nghị và ngừng dùng topic).
    Biết U-T68-IE1; topic thử `t68.tc.ho-so.da-nop.v1` `ACTIVE` có một subscription; kế nhiệm `t68.tc.ho-so.da-nop.v2` `ACTIVE`.
    Khi `POST /topics/t68.tc.ho-so.da-nop.v1:deprecate` với `reason`, `successorTopic`.
    Và HTTT phát lên topic cũ; bộ giao nhận giao cho subscription cũ.
    Và đề nghị subscription mới trên topic cũ.
    Thì bước 1 `200`, `DEPRECATED`, `sunsetAt` = hôm nay + 90 ngày. Bước 2 vẫn phát và giao bình thường. Bước 3 `422` ERR-10-025. EVT: `topic.deprecated` có `successorTopic`, `sunsetAt`. Đầu mối các bên nhận được thông báo.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-023 @P1 @Dương @Âm
  Kịch bản: TC-10-023 Ngừng dùng topic: còn subscription, qua duyệt, giữ khi còn DLQ
    # Truy vết: FR-10-014 · API-10-017, 059 · ERR-10-009, 010 · EVT-10-04 · BR-10-016, 024
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-014 (Ngừng khuyến nghị và ngừng dùng topic).
    Biết U-T68-IE1, U-T68-IA1; TP-GT không subscription; topic thử có subscription `ACTIVE` và 2 mục DLQ `NEW`.
    Khi `POST /topics/t68.dkkd.doanh-nghiep.giai-the.v1:retire` không có lý do, rồi có lý do.
    Và phát lên TP-GT qua API và Kafka.
    Và `:retire` topic thử với `immediate = true`.
    Và gửi yêu cầu `TOPIC_RETIRE`, IA1 duyệt; chờ quá `10.topic.delete-after-retire-days`.
    Thì bước 1 lần đầu `400` ERR-10-009; lần hai `200`, `RETIRED`, EVT: `topic.retired`. Bước 2 API trả 404-ẩn (ERR-10-103), Kafka từ chối do ACL bị xóa. Bước 3 `409` ERR-10-010. Bước 4 mọi publication, subscription thu hồi, ACL xóa, topic `RETIRED`; topic chưa bị xóa khỏi cụm vì còn mục DLQ `NEW`.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu. Giữ dữ liệu cho TC-10-049.

  @TC-10-024 @P1 @Dương
  Kịch bản: TC-10-024 Tạo phiên bản chính v2 khi thay đổi phá vỡ
    # Truy vết: FR-10-015 · API-10-018 · EVT-10-01, 03 · BR-10-013 · ADR-070 · LGC-HUB-009
    # Mục đích: Chứng minh luồng thành công, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).
    Biết U-T68-IE1, U-T68-IA1; topic thử `t68.tc.doanh-nghiep.cap-moi.v1` `ACTIVE` có 2 publication, 2 subscription; F-AV-BRK.
    Khi `POST /topics/t68.tc.doanh-nghiep.cap-moi.v1:new-major-version` với F-AV-BRK, `migrationNote` 40 ký tự, `sunsetDays = 30`.
    Và IA1 duyệt yêu cầu `TOPIC_CREATE` của topic mới.
    Và xem artifact Apicurio của hai topic.
    Thì bước 1 `201`, topic `t68.tc.doanh-nghiep.cap-moi.v2` `PENDING_APPROVAL`, `predecessorTopic` trỏ v1, yêu cầu kèm khác biệt lược đồ. Bước 2 v2 `ACTIVE`; v1 `DEPRECATED` với `successorTopic`, `sunsetAt` sau 30 ngày; có bản nháp publication trên v2 cho hai bên phát cũ. Bước 3 v2 là artifact mới, không chung lịch sử tương thích với v1. EVT: `topic.activated` (v2), `topic.deprecated` (v1).
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-025, TC-10-026.

  @TC-10-025 @P1 @Âm
  Kịch bản: TC-10-025 Kế nhiệm đã tồn tại; nguồn không ACTIVE; ghi đè lược đồ ENABLED
    # Truy vết: FR-10-015, 019 · API-10-018, 025 · ERR-10-006, 047 · BR-10-013
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-015 (Tạo phiên bản chính mới của topic khi thay đổi phá vỡ).
    Biết U-T68-IE1; v1, v2 từ TC-10-024.
    Khi gọi lại `:new-major-version` trên v1.
    Và gọi `:new-major-version` trên topic `DRAFT`.
    Và `PUT /topics/{v2}/schema/versions/1` với nội dung khác.
    Thì bước 1 `409` ERR-10-047. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 (phiên bản `ENABLED` bất biến); nội dung ở Apicurio không đổi (so `contentHash`).
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-026 @P3 @Dương
  Kịch bản: TC-10-026 Theo dõi chuyển đổi bên nhận sang v2 và nhắc trước hạn
    # Truy vết: FR-10-016 · API-10-019 · UI-10-06, 01
    # Mục đích: Chứng minh luồng thành công, theo FR-10-016 (Theo dõi chuyển đổi bên nhận sang phiên bản topic mới).
    Biết U-T68-VW; v1, v2 từ TC-10-024; một bên nhận đã có subscription trên v2, một chưa.
    Khi `GET /topics/{v1}/migration-status`.
    Và đặt đồng hồ SIT tới `sunsetAt` − 14 ngày và − 3 ngày.
    Và mở UI-10-01.
    Thì bước 1 liệt kê hai bên nhận với cờ đã chuyển, lag hai bên, số ngày còn lại; bên phát với số sự kiện 24 giờ trên v2. Bước 2 đầu mối bên chưa chuyển nhận thông báo hai lần. Bước 3 thẻ "Topic sắp hết hạn" đếm 1.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.
