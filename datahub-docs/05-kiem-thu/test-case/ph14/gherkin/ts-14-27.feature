# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-27
Tính năng: TS-14-27 · Tổng quan và kiểm tra kết nối chủ động

  @TC-14-069 @P1 @Dương @Biên
  Kịch bản: TC-14-069 Tổng quan, sức khỏe và phát hiện mất kết nối ≤ 3 phút
    # Truy vết: FR-14-047, 048 · API-14-058, 060 · UI-14-01, 02 · UC-14-32 · NFR-14-007, 018.
    Biết U-T68-TO; `14.health.interval-seconds = 60`; `sim-ndxp` `OK` rồi `DOWN`.
    Khi `GET /dashboard`; mở UI-14-01.
    Và đặt `DOWN`; đo tới khi `health = UNHEALTHY`.
    Thì thẻ nền tảng, chỉ số 24 giờ, hạn mức kèm dự báo cạn, cảnh báo nổi bật; `UNHEALTHY` trong ≤ 3 phút và có cảnh báo; `GET /health` khớp.

  @TC-14-070 @P3 @Âm @Biên
  Kịch bản: TC-14-070 Kiểm tra tay vượt số lần mỗi giờ
    # Truy vết: FR-14-047, 048 · API-14-059, 060 · ERR-14-029 · ERR-14-001.
    Biết U-T68-TO; `14.test.max-per-hour = 5`.
    Khi gọi `POST /platforms/ndxp:probe` 6 lần trong 1 giờ.
    Và gọi cho nền tảng của T01; U-T01-TA `GET /dashboard`.
    Thì lần 6 `429` ERR-14-029; bước 2 `404` ERR-14-001 và tổng quan của T01 chỉ có số liệu T01 (FR-14-048).
