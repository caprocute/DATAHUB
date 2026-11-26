# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-27
Tính năng: TS-04-27 · Tham số PH-04 và đóng băng thay đổi

  @TC-04-153 @P2 @Dương
  Kịch bản: TC-04-153 Đọc tham số và đặt khoảng đóng băng
    # Truy vết: FR-04-084 · API-04-090 · UI-04-20 · LGC-BUS-031
    Biết U-T68-TA.
    Khi gọi `GET /settings`.
    Và trên UI-04-20 (nhúng màn tham số PH-18), đặt `04.test.max-concurrent = 8`.
    Và đặt khoảng đóng băng 2026-12-30 18:00 tới 2027-01-02 08:00, lý do "Nghỉ Tết dương lịch".
    Thì bước 1: đủ 23 tham số `04.*` có `value`, `default`, `domain`. Bước 2: có hiệu lực trong 60 giây (lần chạy thử thứ 6 không còn bị 429). Bước 3: `freezeWindows` có khoảng mới; banner đóng băng hiện trên UI-04-15 trong khoảng đó.

  @TC-04-154 @P2 @Âm
  Kịch bản: TC-04-154 Tham số ngoài miền và ràng buộc không tắt được
    # Truy vết: FR-04-084
    Biết U-T68-TA.
    Khi đặt `04.test.max-concurrent = 21`.
    Và đặt `04.review.require-test = false` khi tenant có luồng đối ngoại.
    Và đặt `04.env.stages = PROD,TEST`.
    Thì cả ba bị PH-18 từ chối với thông điệp miền; giá trị không đổi.

  @TC-04-155 @P2 @Dương @Âm
  Kịch bản: TC-04-155 Biến môi trường không chứa bí mật
    # Truy vết: FR-04-084 · API-04-090 · ERR-04-010
    Biết U-T68-TA.
    Khi `PUT /settings/env-vars` với `ma-co-quan` có giá trị khác nhau cho TEST, STAGING, PROD.
    Và `PUT` với `api-token` có giá trị dạng JWT.
    Thì bước 1 trả `200`; luồng dùng `{{dh.env.ma-co-quan}}` nhận đúng giá trị theo môi trường. Bước 2 trả `422` ERR-04-010, gợi ý dùng `{{vault:…}}`.
