# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-21
Tính năng: TS-13-21 · Hạ tầng: nút gateway, cụm Kafka

  @TC-13-062 @P1 @Dương
  Kịch bản: TC-13-062 Nút gateway và cụm Kafka hiển thị tài nguyên
    # Truy vết: FR-13-036, 037, 038 · UC-13-23 · API-13-011, 012, 013, 014 · UI-13-04 · LGC-APIM-023; 024, 025 · LGC-HUB-005, 006
    Biết SIT có 2 nút APISIX, 3 broker; U-PO.
    Khi mở UI-13-04; mở một nút gateway; xem CPU, heap, kết nối; xem cụm Kafka (lag, broker, phân vùng).
    Thì danh sách đủ 2 nút; số liệu khớp Prometheus; Kafka đủ 3 broker; ngừng 1 nút thì hiện `DOWN` trong ≤ 3 phút.

  @TC-13-063 @P2 @Âm
  Kịch bản: TC-13-063 Nút không tồn tại, thiếu dữ liệu, không quyền
    # Truy vết: FR-13-036, 037, 038 · API-13-012, 013, 014 · ERR-13-001, 009 · BR-13-016
    Biết U-T68-IE; nút `khong-co`.
    Khi `GET /gateways/khong-co`.
    Và U-T68-IE gọi `GET /kafka/cluster`.
    Thì `404` ERR-13-001; IE giữ `PERM-13-dashboard` như D02-08 nên không nhận `403`, nhưng chỉ thấy dữ liệu của luồng và HTTT do mình thiết kế, hạ tầng chung chỉ ở mức tenant theo BR-13-030 (đã chốt 27/11/2026, Q13-41); exporter ngừng hiện "Chưa có dữ liệu".
