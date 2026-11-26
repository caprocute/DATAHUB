# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-28
Tính năng: TS-13-28 · Giám sát chính hệ thống giám sát và thống kê hiệu quả cảnh báo

  @TC-13-080 @P1 @Dương @Khả @dụng
  Kịch bản: TC-13-080 Mimir, Loki, Alertmanager ngừng thì có cảnh báo qua đường độc lập
    # Truy vết: FR-13-049 · UC-13-31 · API-13-053 · UI-13-01 · ERR-13-123, 122 · NFR-13-013
    Biết giám sát bên ngoài (watchdog) sẵn; U-PA.
    Khi ngừng Loki; ngừng Alertmanager; làm đầy kho tới 85 %; ngắt SIEM.
    Thì `GET /monitoring-health` nêu thành phần ngừng; đường cảnh báo độc lập vẫn báo U-PA; ERR-13-123 ở 85 %; ERR-13-122 khi SIEM không nhận; EVT: `capacity.warning`.

  @TC-13-081 @P3 @Dương @Biên
  Kịch bản: TC-13-081 Thống kê hiệu quả cảnh báo
    # Truy vết: FR-13-050 · UC-13-32 · API-13-052 · UI-13-10 · NFR-13-028 · BR-13-023
    Biết 100 cảnh báo, 30 đóng `NO_ACTION`.
    Khi `GET /alert-stats` 30 ngày.
    Thì tỷ lệ cảnh báo giả 30 %; thời gian xác nhận trung bình; theo luật; khoảng không có dữ liệu hiển thị "Chưa có dữ liệu".
