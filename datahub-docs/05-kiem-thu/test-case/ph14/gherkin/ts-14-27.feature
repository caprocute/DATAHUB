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

  @TC-14-130 @P2 @Dương @Biên
  Kịch bản: TC-14-130 Tổng quan khi kho chỉ số lỗi: phần đọc từ PostgreSQL, dự báo cạn hạn mức
    # Truy vết: FR-14-048 · API-14-060 · UI-14-01 · UC-14-32 · ERR-14-001 · NFR-14-018.
    Biết U-T68-VW, U-T68-SO; V-HT dùng 80 % hạn mức giờ, nhịp 7 ngày gần nhất cho thấy cạn lúc 20:00; một chứng thư còn 20 ngày; một sự cố chữ ký `OPEN`; nền tảng `ndxp-moi` `UNHEALTHY`; kho chỉ số dừng ở bước 3.
    Khi `GET /dashboard`, mở UI-14-01.
    Và tăng mức dùng V-HT lên 96 %.
    Và dừng kho chỉ số, tải lại tổng quan.
    Và U-T01-TA mở cùng màn.
    Thì bước 1 `200` có `platforms[]`, `kpis`, `quotas[]` kèm `forecastExhaustAt` (khuyến nghị tăng thời hạn đệm khi dự báo cạn trước 22:00), `alerts[]` gồm biểu ngữ đỏ không ẩn được của sự cố chữ ký, chứng thư dưới 30 ngày, nền tảng `UNHEALTHY`. Bước 2 thẻ hạn mức đỏ. Bước 3 vẫn `200`, phần hạn mức, chứng thư, sự cố vẫn hiện, vùng biểu đồ ghi "Chưa lấy được số liệu lưu lượng. Thử lại sau." Bước 4 chỉ thấy dữ liệu tenant `T01`.
