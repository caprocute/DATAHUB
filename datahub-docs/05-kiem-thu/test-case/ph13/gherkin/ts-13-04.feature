# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-04
Tính năng: TS-13-04 · Kiểm tra tổng hợp và cách ly dữ liệu quan sát theo tenant

  @TC-13-012 @P1 @Dương
  Kịch bản: TC-13-012 Khai báo và chạy kiểm tra tổng hợp mỗi phút
    # Truy vết: FR-13-008 · UC-13-04 · API-13-070, 071 · UI-13-01, 17 · NFR-13-030
    Biết U-T68-TA; HTTT giả lập `HT-NDXP`.
    Khi mở UI-13-17, thêm kiểm tra tổng hợp tới `HT-NDXP`, chu kỳ mặc định 60 giây.
    Và chờ 3 chu kỳ; mở UI-13-01.
    Thì `PATCH /settings` trả `200`; KT: có (`OBS.SETTINGS.UPDATE`); có kết quả mỗi phút; thay đổi có hiệu lực ≤ 60 giây.

  @TC-13-013 @P1 @Âm
  Kịch bản: TC-13-013 Kiểm tra thất bại liên tiếp sinh cảnh báo và sự kiện
    # Truy vết: FR-13-008 · ERR-13-124 · EVT-13-13 · BR-13-016
    Biết `HT-NDXP` ngắt.
    Khi ngắt `HT-NDXP`; chờ 5 chu kỳ.
    Thì ERR-13-124; EVT: `probe.failed`; cảnh báo hiển thị ở UI-13-01; khi `HT-NDXP` về, sau 5 phút cảnh báo tự `RESOLVED`.

  @TC-13-014 @P2 @Âm @Biên
  Kịch bản: TC-13-014 Tham số quan sát ngoài miền bị từ chối
    # Truy vết: FR-13-008, 061 · API-13-071 · ERR-13-040, 007 · BR-13-020
    Biết U-T68-TA.
    Khi `PATCH /settings` đặt `13.probe.interval-seconds = 5` rồi `13.audit.worm-retention-years = 2`.
    Và `PATCH` lại với `If-Match` cũ.
    Thì cả hai lần đầu `422` ERR-13-040 (thời hạn lưu dưới 3 năm); lần ba `412` ERR-13-007; không có thay đổi nào được lưu.

  @TC-13-015 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-015 Truy vấn quan sát không thấy dữ liệu tenant khác
    # Truy vết: FR-13-009 · BR-13-030 · NFR-13-022 · ERR-13-036 · API-13-019
    Biết T01 và T68 đều có log `luong-chung`; U-T68-TO, U-T01-TO.
    Khi U-T68-TO tra log `luong-chung`; gửi thêm `targetTenant=t01`.
    Và truy vấn Loki, Mimir, Tempo trực tiếp bằng chứng thư của T68 với nhãn `t01`.
    Thì bước 1: chỉ log T68; có `targetTenant` thì `403` ERR-13-036. Bước 2: 0 kết quả ở cả ba kho.
