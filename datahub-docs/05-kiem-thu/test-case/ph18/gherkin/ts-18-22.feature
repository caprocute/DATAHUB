# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-22
Tính năng: TS-18-22 · Đặt tùy chọn nhận, giờ yên lặng và đọc thông báo trong ứng dụng

  @TC-18-076 @P1 @Dương @Biên
  Kịch bản: TC-18-076 Tắt nhóm nhắc việc qua thư, đặt giờ yên lặng, URGENT vẫn gửi ngay
    # Truy vết: FR-18-038, 036 · API-18-095, 096, 097, 098 · BR-18-030 · UI-18-14
    # Mục đích: Chứng minh BR-18-030: thông báo thường trong giờ yên lặng giữ tới hết giờ (≤ 12 giờ), `URGENT` gửi ngay, kênh trong ứng dụng vẫn nhận.
    Biết T95 (đồng hồ giả, 21:50); U-T95-IE; `18.notify.quiet-hours = 22:00-06:00`.
    Khi IE mở `/ca-nhan/thong-bao`, tắt "Nhắc việc" ở kênh thư, đặt giờ yên lặng mặc định, lưu.
    Và tua đến 23:00, S-PH01 gửi cho IE một thông báo `NORMAL` và một `URGENT`.
    Và tua đến 06:01.
    Và IE `GET /me/notifications`, `POST /me/notifications/{id}:read`.
    Thì bước 1 `200`, `ETag` mới. Bước 2 `URGENT` `DELIVERED` ngay; `NORMAL` giữ `QUEUED`. Bước 3 `NORMAL` được gửi. Bước 4 hai thông báo trong ứng dụng, số chưa đọc giảm 1.

  @TC-18-077 @P2 @Âm
  Kịch bản: TC-18-077 Tắt nhóm bắt buộc, giờ yên lặng sai định dạng, lưu với ETag cũ
    # Truy vết: FR-18-038 · API-18-096 · BR-18-030 · ERR-18-003, 004, 046
    # Mục đích: Chứng minh người dùng không tắt được nhóm bắt buộc và tùy chọn có kiểm định dạng, khóa lạc quan.
    Biết T90; U-T90-IE.
    Khi tắt nhóm "Bảo trì hệ thống" (bắt buộc).
    Và đặt giờ yên lặng `25:00-06:00`.
    Và lưu với `ETag` cũ.
    Thì bước 1 `422` ERR-18-046. Bước 2 `400` ERR-18-003. Bước 3 `412` ERR-18-004.
