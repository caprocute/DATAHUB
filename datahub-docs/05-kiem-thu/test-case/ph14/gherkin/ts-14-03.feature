# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-03
Tính năng: TS-14-03 · Tạm ngừng, tiếp tục, ngừng dùng nền tảng

  @TC-14-008 @P1 @Dương
  Kịch bản: TC-14-008 Tạm ngừng có hiệu lực ≤ 30 giây, lượt đang chạy kết thúc
    # Truy vết: FR-14-003 · API-14-005, 006, 075 · ERR-14-117 · BR-14-032 · NFR-14-017 · UC-14-03.
    Biết `ndxp` `ACTIVE`; `sim-ndxp` chế độ `SLOW` 10 giây; U-T68-TO; S-HT-MC gọi `hotich-tra-cuu` liên tục 20 lượt/giây.
    Khi khởi động một lượt gọi dài 10 giây, rồi `POST /platforms/ndxp:suspend` kèm lý do.
    Và đo thời gian tới khi lượt mới bị từ chối.
    Và `POST …:resume`.
    Thì lượt đang chạy hoàn tất; lượt mới từ bước 1 + 30 giây trả `503` ERR-14-117; `resume` đưa về `ACTIVE`, lượt mới gọi được trong 30 giây.

  @TC-14-009 @P2 @Dương
  Kịch bản: TC-14-009 Ngừng dùng nền tảng và không dùng lại mã
    # Truy vết: FR-14-003 · API-14-007 · ERR-14-002, 117 · BR-14-032.
    Biết `ndxp-moi` `ACTIVE`, không có lượt đang chạy; U-T68-TO.
    Khi `POST /platforms/ndxp-moi:retire` kèm lý do.
    Và gọi dịch vụ thuộc nền tảng đó.
    Và `POST /platforms` với mã `ndxp-moi`.
    Thì `RETIRED`; bước 2 `503` ERR-14-117; bước 3 `409` ERR-14-002.

  @TC-14-010 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-010 Thao tác sai trạng thái hoặc không có quyền
    # Truy vết: FR-14-003 · API-14-005, 006, 007 · ERR-14-004 · PERM-14-operate.
    Biết `ndxp` `ACTIVE`; U-T68-VW; U-T68-TO.
    Khi U-T68-TO `:resume` lên nền tảng đang `ACTIVE`.
    Và U-T68-VW `:suspend`.
    Và U-T68-TO `:suspend` thiếu lý do.
    Thì bước 1 `409` ERR-14-004; bước 2 `403`; bước 3 `400` ERR-14-003.
