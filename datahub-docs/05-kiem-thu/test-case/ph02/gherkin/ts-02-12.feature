# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-12
Tính năng: TS-02-12 · Tạm ngừng khẩn và tiếp tục

  @TC-02-042 @P1 @Dương
  Kịch bản: TC-02-042 Tạm ngừng khẩn, tiếp tục, hết thời hạn tối đa
    # Truy vết: FR-02-037 · API-02-048, 049 · UI-02-02 · UC-02-17 · BR-02-034 · EVT-02-06 · KT: có (version.suspend) · LGC-APIM-005.
    Biết A-DATDAI `PUBLISHED`; U-T68-SO, U-T68-TO; `02.suspend.max-days` = 30.
    Khi U-T68-SO `:suspend` lý do an ninh; U-T68-TO `:resume`.
    Và U-T68-TO `:resume` sau khi SO tạm ngừng; U-T68-SO `:resume`.
    Và đẩy đồng hồ 31 ngày.
    Thì bước 1: `200`, GW: gỡ route; TO không tiếp tục được vì SO tạm ngừng vì an ninh. Bước 2: SO tiếp tục được, GW: nạp route. Bước 3: cảnh báo quá hạn tạm ngừng.

  @TC-02-043 @P1 @Âm
  Kịch bản: TC-02-043 Tạm ngừng thiếu lý do hoặc sai quyền hoặc sai trạng thái
    # Truy vết: FR-02-037 · API-02-048, 049 · BR-02-034 · ERR-02-041, 014, 011, 039.
    Biết A-DATDAI; A-DRAFT; U-T68-SV1; cờ đóng băng thay đổi PROD.
    Khi tạm ngừng không có `reason`; SV1 tạm ngừng; tạm ngừng phiên bản `DRAFT`.
    Và bật đóng băng rồi tạm ngừng.
    Thì `400` ERR-02-041; 403-PQ; `409` ERR-02-011; `423` ERR-02-039.

  @TC-02-115 @P1 @Âm @Dương
  Kịch bản: TC-02-115 Tạm ngừng vì an ninh: ai được tiếp tục
    # Truy vết: FR-02-037 · API-02-048, 049 · UI-02-02 · UC-02-17 · BR-02-034 · ERR-02-014, 041.
    Biết A-DATDAI `PUBLISHED`; U-T68-SO, U-T68-TO, U-T68-TA.
    Khi U-T68-SO `:suspend` vì an ninh, có lý do.
    Và U-T68-TO `:resume`.
    Và U-T68-TA `:resume`; rồi U-T68-TO `:suspend` rồi `:resume`.
    Và U-T68-SO `:resume` không lý do.
    Thì bước 2: `403` ERR-02-014 (chỉ SO hoặc TA tiếp tục bản SO tạm ngừng vì an ninh). Bước 3: TA `200`; TO tạm ngừng thì chính TO hoặc TA tiếp tục được. Bước 4: `400` ERR-02-041. Mọi lần có kiểm toán trước, sau.

  @TC-02-165 @P1 @Âm @Biên
  Kịch bản: TC-02-165 Đóng băng thay đổi môi trường thật: chặn các lệnh ghi lên gateway, vẫn đọc được
    # Truy vết: FR-02-023, 036, 037 · API-02-028, 047, 048 · UI-02-02 · UC-02-15, 17 · ERR-02-039.
    Biết cờ đóng băng thay đổi PROD đặt tới `T+2 giờ` (đồng hồ giả); A-DATDAI `PUBLISHED`, một yêu cầu công bố đã duyệt; U-T68-TA, U-T68-SV1, U-T68-TO.
    Khi trong thời gian đóng băng: `PATCH` backend, `:publish`, `:suspend` (cùng giả định của TC-02-043: đóng băng chặn mọi lệnh ghi lên gateway, kể cả tạm ngừng; câu hỏi liên quan ở Q02-45 của D02-04-PH02).
    Và `GET` danh mục, chi tiết, lịch sử.
    Và đẩy đồng hồ qua `T+2 giờ` rồi gọi lại các lệnh ở bước 1.
    Thì bước 1: `423` ERR-02-039 kèm thời điểm kết thúc đóng băng, UI hiện dải thông báo đầu trang. Bước 2: đọc bình thường `200`. Bước 3: các lệnh thành công; không lệnh nào bị chạy ngầm trong lúc đóng băng.
