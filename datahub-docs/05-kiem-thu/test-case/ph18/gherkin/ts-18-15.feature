# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-15
Tính năng: TS-18-15 · Biên soạn sổ tay xử lý theo mã lỗi và cấp API đọc cho PH-17

  @TC-18-048 @P2 @Dương @Âm
  Kịch bản: TC-18-048 Soạn sổ tay xử lý theo mã lỗi có ETag và sự kiện cho PH-17
    # Truy vết: FR-18-025 · API-18-057, 058, 059 · BR-18-050 · ERR-18-003, 004 · EVT-18-11 · UI-18-07
    # Mục đích: Chứng minh FR-18-025: hướng dẫn theo mã ERR có phiên bản, sửa có `If-Match`, phát EVT-18-11, không chứa payload hay dữ liệu cá nhân.
    Biết T90; U-PA1 (`PERM-18-admin`); sổ tay `ERR-04-101` phiên bản 2.
    Khi `PUT /error-guides/ERR-04-101` nội dung mới, có `If-Match`.
    Và gửi lại với `ETag` cũ.
    Và gửi nội dung có chuỗi giống CCCD `"012345678901"`.
    Và mở `/van-hanh/dlq/so-tay`, tìm `ERR-04-101`.
    Thì bước 1 `200` phiên bản 3, EVT-18-11 có `errorCode`, `version`, `owner`. Bước 2 `412` ERR-18-004. Bước 3 `400` ERR-18-003 (bộ kiểm DLCN của sổ tay). Bước 4 hiện phiên bản 3 có nguyên nhân, bước xử lý, "có phát lại được".

  @TC-18-049 @P2 @Dương
  Kịch bản: TC-18-049 PH-17 đọc siêu dữ liệu DLQ và nguồn tri thức sổ tay
    # Truy vết: FR-18-026, 025 · API-18-060, 061, 062 · BR-18-016, 050
    # Mục đích: Chứng minh FR-18-026: scope `ops:dlq-read` với token đổi từ người dùng trả siêu dữ liệu trong phạm vi quyền của người đó, sổ tay đọc theo `updatedSince`.
    Biết T90; S-PH17 (`ops:dlq-read`); token đổi của U-T90-TO và U-T90-VW.
    Khi S-PH17 `GET /ops/internal/v1/dlq/messages?trangThai=NEW` với token của TO.
    Và S-PH17 `GET /ops/internal/v1/dlq/messages/DLQ-A-02` với token của TO.
    Và `GET /ops/internal/v1/error-guides:feed?updatedSince=...`.
    Và lặp bước 1 với token của VW.
    Thì bước 1, 2 `200` chỉ siêu dữ liệu, không có `payload`. Bước 3 `200` các mục sổ tay có `errorCode`, `version`, không chứa payload. Bước 4 `403` ERR-00-403 vì VW không xem danh sách mục.

  @TC-18-050 @P2 @Âm @Bảo_mật
  Kịch bản: TC-18-050 PH-17 thử ghi, đọc payload khi người dùng thiếu quyền, vượt tần suất
    # Truy vết: FR-18-026 · API-18-061 · BR-18-016, 017 · ERR-18-010 · ERR-00-403
    # Mục đích: Chứng minh BR-18-016, 017 trên API nội bộ: không có phương thức ghi, payload chỉ khi người dùng có `PERM-18-dlq-payload`, giới hạn tần suất bảo vệ PH-18.
    Biết T90; S-PH17; token của U-T90-TO (có `PERM-18-dlq-payload`) và U-T90-AU (không có).
    Khi S-PH17 gọi `POST /ops/internal/v1/dlq/messages/DLQ-A-02:discard`.
    Và S-PH17 đọc chi tiết kèm `include=payload` với token AU.
    Và lặp với token TO.
    Và S-PH17 gửi 200 yêu cầu trong một giây.
    Thì bước 1 `403` ERR-00-403 (không có quyền ghi với scope này). Bước 2 `403` ERR-00-403. Bước 3 `200` có payload đã che, KT: có (payload-reveal) với `act = PH-17`. Bước 4 có `429` ERR-18-010.

  @TC-18-051 @P3 @Dương @Âm
  Kịch bản: TC-18-051 Đổi sổ tay làm PH-17 cập nhật tri thức, sổ tay của mã lạ trả 404
    # Truy vết: FR-18-025 · API-18-058, 062 · EVT-18-11 · ERR-18-001
    # Mục đích: Chứng minh EVT-18-11 dẫn tới feed trả bản mới và mã lỗi chưa có hướng dẫn trả lỗi rõ.
    Biết T90; sổ tay `ERR-04-101` vừa lên phiên bản 3.
    Khi đọc `t90.ops.error-guide.changed.v1`.
    Và S-PH17 gọi feed với `updatedSince` trước thời điểm đổi.
    Và `GET /error-guides/ERR-99-999`.
    Thì bước 1 có bản tin mã `ERR-04-101`, `version = 3`. Bước 2 có bản mới. Bước 3 `404` ERR-18-001.
