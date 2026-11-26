# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-23
Tính năng: TS-02-23 · Di trú từ APIM cũ và tham số phân hệ

  @TC-02-068 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-02-068 Di trú: xem trước, xác nhận, đăng ký vào `SUSPENDED`, không nhập khóa
    # Truy vết: FR-02-061 · API-02-085, 086, 087 · UI-02-16 · UC-02-37 · BR-02-036, 021, 015 · ERR-02-045, 002, 014 · LGC-APIM-002; 003, 009 · EVT-02-01.
    Biết F-APIM-EXPORT; tệp sai định dạng; U-T68-TA, U-T68-SV1; mồi `DH-CANARY-legacy` ở trường khóa API.
    Khi `POST /legacy-imports` tệp hợp lệ; xem trước; `:commit`; `GET …/report`.
    Và nạp tệp sai định dạng; SV1 gọi `POST /legacy-imports`.
    Và commit lần hai gói trùng mã.
    Thì 12 API, 20 gói, 35 đăng ký ở `SUSPENDED`, không có khóa; báo cáo đối chiếu khớp số lượng; mồi sạch; `400` ERR-02-045; SV1 403-PQ; trùng mã `409` ERR-02-002.

  @TC-02-069 @P2 @Dương @Biên @Âm
  Kịch bản: TC-02-069 Sửa tham số `02.*`: trong miền, ngoài miền, vượt trần nền tảng
    # Truy vết: FR-02-062 · API-02-088, 089 · UI-02-17 · UC-02-38 · BR-02-028 · ERR-02-040, 003, 014 · KT: có (settings.update).
    Biết U-T68-TA, U-T68-SV1.
    Khi `PATCH /settings` `02.suspend.max-days` = 45; = 91; `02.deprecation.min-days` = 20.
    Và SV1 `PATCH /settings`; `GET /settings`.
    Thì 45 `200`, có hiệu lực ≤ 60 giây; 91 và 20 `422` ERR-02-040 hoặc `400` ERR-02-003; SV1 403-PQ, SV1 đọc được.

  @TC-02-139 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-139 Gói xuất APIM cũ sai định dạng: thiếu cột, tệp hỏng, quá lớn, chứa khóa
    # Truy vết: FR-02-061 · API-02-085, 086 · UI-02-16 · UC-02-37 · BR-02-015, 036 · ERR-02-045, 009, 008.
    Biết biến thể của F-APIM-EXPORT: thiếu trường `context-path`; tệp JSON cụt; tệp quá giới hạn kích thước; tệp có khóa bí mật mồi `DH-CANARY-legacy-…`; U-T68-TA.
    Khi `POST /legacy-imports` lần lượt từng biến thể.
    Và `POST /legacy-imports` với F-APIM-EXPORT nguyên vẹn.
    Và quét phản hồi, log, bảng `ph02_catalog.*`, báo cáo `GET …/report`.
    Thì bước 1: `400` ERR-02-045 nêu dòng, cột lỗi (thiếu trường, tệp hỏng); quá lớn `413` ERR-02-009; không có dữ liệu nào được ghi. Bước 2: `200` kèm bản xem trước; khóa mồi bị loại, báo "không nhập khóa". Bước 3: mồi không xuất hiện ở bất kỳ nơi nào.

  @TC-02-140 @P1 @Âm
  Kịch bản: TC-02-140 Xác nhận nhập: định danh lạ, nhập lại, xung đột mã, sai quyền
    # Truy vết: FR-02-061 · API-02-085, 086, 087 · UI-02-16 · UC-02-37 · BR-02-021, 036 · ERR-02-001, 002, 014, 042.
    Biết bản xem trước `IMP-1` từ F-APIM-EXPORT (có một mã API trùng A-DATDAI); `IMP-2` của T01; U-T68-TA, U-T68-SV1.
    Khi U-T68-TA `POST /legacy-imports/{IMP-2}:commit`.
    Và U-T68-SV1 `:commit IMP-1`.
    Và U-T68-TA `:commit IMP-1` hai lần cùng `Idempotency-Key`; rồi lần ba khác khóa.
    Và `GET /legacy-imports/{IMP-1}/report`.
    Thì bước 1: `404` ERR-02-001. Bước 2: `403` ERR-02-014. Bước 3: lần đầu `201`; lần hai trả lại phản hồi cũ; lần ba không nhập thêm (đã nhập) và báo xung đột mã `409` ERR-02-002 cho phần trùng. Bước 4: báo cáo đối chiếu số API, gói, đăng ký khớp bản xem trước; mã trùng A-DATDAI được liệt kê là bỏ qua, không đè.

  @TC-02-141 @P2 @Dương @Âm
  Kịch bản: TC-02-141 Sửa tham số `02.*` ghi kiểm toán qua PH-18, khóa lạ, xung đột `If-Match`
    # Truy vết: FR-02-062 · API-02-088, 089 · UI-02-17 · UC-02-38 · BR-02-028 · ERR-02-003, 015, 014.
    Biết U-T68-TA, U-T68-VW; `02.suspend.max-days` = 14 (giả định mặc định).
    Khi U-T68-TA `PATCH /settings` đổi `02.suspend.max-days` thành 30, kèm `If-Match`.
    Và gửi lại với `ETag` cũ.
    Và `PATCH` khóa không có (`02.khong-co`) và giá trị sai kiểu.
    Và U-T68-VW `GET /settings`, rồi `PATCH`.
    Thì bước 1: `200`, có bản ghi kiểm toán qua PH-18 (người, trước, sau). Bước 2: `412` ERR-02-015. Bước 3: `400` ERR-02-003 nêu khóa hoặc kiểu sai. Bước 4: đọc được `200`; sửa `403` ERR-02-014. Tham số mới có hiệu lực ở lần tạm ngừng kế tiếp.
