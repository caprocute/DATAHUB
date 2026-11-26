# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-06
Tính năng: TS-05-06 · Tạm ngừng, tiếp tục, ngừng dùng kết nối

  @TC-05-023 @P1 @Dương
  Kịch bản: TC-05-023 Tạm ngừng có hiệu lực trong 30 giây
    # Truy vết: FR-05-008 · API-05-007 · EVT-05-04 · NFR-05-006 · ERR-05-118 · UC-05-05
    Biết U-T68-SO; C-NDXP; luồng mẫu chạy ba bản sao.
    Khi `POST …/ndxp-ho-tich:suspend` với lý do, mã sự cố `SC-2026-11-01`.
    Và đo thời điểm lượt mới cuối cùng tới SIM-HTTP.
    Thì bước 1 `200`, `SUSPENDED`. EVT: `connection.state-changed`. Bước 2 ≤ 30 giây sau lệnh; lượt mới của luồng nhận ERR-05-118. KT: có (`CONNECTION_SUSPEND`, mã sự cố).

  @TC-05-024 @P2 @Dương @Âm
  Kịch bản: TC-05-024 Tiếp tục sau tạm ngừng của SO
    # Truy vết: FR-05-008 · API-05-008 · ERR-05-008, 012
    Biết C-NDXP do U-T68-SO tạm ngừng; U-T68-TO; U-T68-SO.
    Khi TO `POST …:resume`.
    Và SO `POST …:resume`.
    Và SO `POST …:resume` lần nữa.
    Thì bước 1 403-PQ (tạm ngừng do SO chỉ SO tiếp tục). Bước 2 `200`, `ACTIVE`. Bước 3 `409` ERR-05-008.

  @TC-05-025 @P1 @Âm
  Kịch bản: TC-05-025 Ngừng dùng bị chặn khi còn nơi dùng
    # Truy vết: FR-05-008, 013 · API-05-009, 025 · ERR-05-010 · UI-05-02
    Biết U-T68-IE1; C-NDXP được 4 phiên bản luồng dùng.
    Khi `POST …/ndxp-ho-tich:retire` với lý do.
    Và mở UI-05-02, bấm "Ngừng dùng".
    Thì bước 1 `409` ERR-05-010 với `usages[]` 4 mục. Bước 2 nút vô hiệu với lý do "Còn 4 nơi đang dùng".

  @TC-05-026 @P2 @Dương
  Kịch bản: TC-05-026 Ngừng dùng, hủy bí mật sau 30 ngày
    # Truy vết: FR-05-008 · API-05-009 · BR-05-012, 004 · EVT-05-04
    Biết U-T68-IE1; `tc-ndxp-moi` không nơi dùng.
    Khi `POST …/tc-ndxp-moi:retire` với lý do.
    Và đồng hồ giả +29 ngày, kiểm OpenBao.
    Và đồng hồ giả +31 ngày, kiểm OpenBao.
    Và `POST /connections` với mã `tc-ndxp-moi`.
    Thì bước 1 `200`, `RETIRED`, UI-05-02 chỉ đọc có banner ngày hủy bí mật. Bước 2 bí mật còn. Bước 3 mọi phiên bản bị xóa (`metadata` cũng xóa). Bước 4 `409` ERR-05-002.
