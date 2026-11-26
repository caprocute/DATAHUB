# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-13
Tính năng: TS-08-13 · Xử lý phụ thuộc không khả dụng khi đo

  @TC-08-071 @P1 @Âm
  Kịch bản: TC-08-071 Nguồn không khả dụng ngay đầu lần đo
    # Truy vết: FR-08-031 · API-08-061, 063 · UI-08-12 · EVT-08-03 · ERR-08-105
    Biết `src-hotich`; `conn-sim` trả lỗi kết nối.
    Khi `POST /scans` cho `src-hotich`
    Và quan sát 3 lần thử
    Và bật lại `conn-sim`, `POST /scans/{id}:rerun`
    Thì lần đo `FAILED` sau 3 lần thử, không có ảnh chụp, `dependencyIssues[]` ghi ERR-08-105; EVT: `scan.failed` (EVT-08-03); cảnh báo vận hành tới PH-13. Lần chạy lại `SUCCEEDED`.

  @TC-08-072 @P1 @Biên
  Kịch bản: TC-08-072 Nguồn rớt giữa chừng và ngưỡng phủ 95 %
    # Truy vết: FR-08-031 · API-08-061, 067 · BR-08-001 · EVT-08-02
    Biết đối tượng 1.000.000 bản ghi, `08.scan.task-size = 20000` (50 tác vụ); `08.scan.min-coverage = 95`.
    Khi ngắt nguồn khi 1 tác vụ lỗi (98 % phủ)
    Và chạy lại, ngắt khi 3 tác vụ lỗi (94 % phủ)
    Thì bước 1 lần đo `PARTIAL`, quy tắc ở tác vụ lỗi `ERROR`, điểm tính trên tác vụ thành công, EVT: `scan.completed` kèm `flags`. Bước 2 lần đo `FAILED`, không điểm.

  @TC-08-073 @P1 @Chịu @lỗi
  Kịch bản: TC-08-073 PH-07 không khả dụng thì chiều hợp lệ bị bỏ qua
    # Truy vết: FR-08-031 · FR-08-027 · UI-08-12 · ERR-08-108 · NFR-08-006
    Biết `mdm-citizen`; `rdm-sim` ngừng 02:10–02:40 giả lập; ngắt mạch sau 5 lỗi liên tiếp, thử lại sau 30 giây.
    Khi chạy lần đo trong lúc `rdm-sim` ngừng
    Và `GET /scans/{id}`
    Và bật `rdm-sim`, chạy lại
    Thì quy tắc `IN_RDM` `SKIPPED` ERR-08-108, các chiều khác có điểm, cờ `INCOMPLETE_DIMENSIONS`; UI-08-12 ghi "PH-07 gián đoạn 02:10–02:40". Lần chạy lại có điểm đủ sáu chiều, không cờ.

  @TC-08-074 @P2 @Dương
  Kịch bản: TC-08-074 Chiều còn quy tắc khác thì vẫn có điểm
    # Truy vết: FR-08-031 · API-08-065 · BR-08-022
    Biết chiều `VALIDITY` có `R-GT-RDM` (`IN_RDM`) và `R-NHOM-CEL` (`CEL_EXPRESSION` không cần PH-07).
    Khi chạy lần đo khi `rdm-sim` ngừng
    Thì `R-GT-RDM` `SKIPPED`, `R-NHOM-CEL` chạy; điểm VALIDITY tính từ `R-NHOM-CEL`; không có cờ `INCOMPLETE_DIMENSIONS`.

  @TC-08-075 @P2 @Chịu @lỗi
  Kịch bản: TC-08-075 PH-13, PH-16 chậm thì sự kiện nằm ở hộp gửi
    # Truy vết: FR-08-031 · FR-08-057 · EVT-08-02 · EVT-08-14 · ERR-08-113
    Biết `notif-sim` và `kpi-sim` ngừng.
    Khi chạy lần đo thành công
    Và kiểm hộp gửi `dq_outbox`
    Và bật lại `notif-sim`, `kpi-sim` sau 10 phút
    Thì lần đo vẫn `SUCCEEDED`, ảnh chụp ghi; sự kiện chờ ở hộp gửi, tự thử lại và giao sau khi bật lại, không giao trùng.
