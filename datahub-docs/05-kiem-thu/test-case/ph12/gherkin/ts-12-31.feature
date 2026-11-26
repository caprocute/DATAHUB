# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-31
Tính năng: TS-12-31 · Tham số phân hệ theo tenant

  @TC-12-101 @P2 @Dương @Âm @Biên
  Kịch bản: TC-12-101 Đọc và sửa tham số trong trần, vượt trần
    # Truy vết: FR-12-061 · UC-12-41 · UI-12-16 · API-12-110, 111 · BR-12-022 · ERR-12-043 · ERR-12-044
    Biết U-T68-TA1; tham số `idleMinutes` = 15.
    Khi `GET /settings`; `PUT /settings` đặt `idleMinutes=10`, rồi 4, rồi 16.
    Và `PUT` với `If-Match` cũ.
    Thì 10 được nhận và áp cho phiên mới; 4 và 16 `422` ERR-12-043; `If-Match` cũ `412` ERR-12-044; KT: có.
