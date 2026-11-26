# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-09
Tính năng: TS-13-09 · Chịu lỗi, đệm bản ghi và đối chiếu số lượng

  @TC-13-030 @P1 @Dương @Khả @dụng
  Kịch bản: TC-13-030 PH-13 ngừng 4 giờ, 0 bản ghi mất
    # Truy vết: FR-13-016 · BR-13-004 · NFR-13-011 · API-13-089 · UC-13-09
    Biết F-DU-SIM phát 10 bản ghi/giây; ngừng toàn bộ pod PH-13 4 giờ (rút gọn 30 phút ở SIT, 4 giờ ở đợt phát hành).
    Khi ngừng PH-13; DU tiếp tục thao tác; bật lại.
    Thì bản ghi chờ ở hộp thư đi và Kafka; sau khi bật lại vào đủ theo thứ tự, không trùng (idempotent theo `id`); số mất = 0; `POST /internal/records:batch` nhận được lô dự phòng, trả `202`.

  @TC-13-031 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-031 Không ghi vết được ở nguồn thì từ chối thao tác dữ liệu Nhạy cảm
    # Truy vết: FR-13-016 · BR-13-003 · BR-13-001 · NFR-13-014
    Biết F-DU-SIM; chặn Kafka `acks=all` và hộp thư đi đầy.
    Khi DU thử thực hiện thao tác thường và thao tác xem giá trị Nhạy cảm.
    Thì thao tác Nhạy cảm bị từ chối, không có thay đổi dữ liệu; thao tác thường không bị chặn chỉ vì PH-13 ngừng (BR-13-003).

  @TC-13-032 @P1 @Dương
  Kịch bản: TC-13-032 Đối chiếu số bản ghi khớp bộ đếm của DU
    # Truy vết: FR-13-017 · BR-13-001 · NFR-13-026 · API-13-086 · UI-13-18
    Biết F-DU-SIM phát 5.000 bản ghi, bộ đếm 5.000.
    Khi chạy đối chiếu; `GET /reconciliations`.
    Thì chênh lệch 0 cho mọi DU.

  @TC-13-033 @P1 @Âm
  Kịch bản: TC-13-033 Đối chiếu lệch phát cảnh báo
    # Truy vết: FR-13-017 · ERR-13-111 · EVT-13-09 · API-13-086 · BR-13-001
    Biết F-DU-SIM bỏ 3 bản ghi khỏi Kafka nhưng đếm.
    Khi chạy đối chiếu.
    Thì lệch 3; ERR-13-111; EVT: `reconciliation-mismatch` nêu `duCode`; UI-13-14 hiện.

  @TC-13-034 @P2 @Âm
  Kịch bản: TC-13-034 Ghi vào chuỗi tenant đã đóng
    # Truy vết: FR-13-016, 060 · ERR-13-043 · API-13-089
    Biết chuỗi T91 đã đóng.
    Khi `POST /internal/records:batch` bản ghi cho T91.
    Thì `409` ERR-13-043; không có bản ghi nào vào chuỗi.
