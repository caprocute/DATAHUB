# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-18
Tính năng: TS-01-18 · Xoay vòng thông tin xác thực

  @TC-01-070 @P1 @Dương
  Kịch bản: TC-01-070 Xoay vòng có chuyển tiếp rồi kết thúc
    # Truy vết: FR-01-025 · UC-01-18 · API-01-045, 046 · UI-01-08, 09 · BR-01-009, 021 · EVT-01-06.
    Biết `HT-DVC` PRODUCTION chuỗi bí mật; U-T68-OR2 có `PERM-01-credential` trong phạm vi; `rotationOverlapDays = 7`.
    Khi OR2 `POST /credentials/{id}:rotate` kèm lý do, MFA mới.
    Và mở liên kết bàn giao mới; gọi API cổng bằng bí mật cũ và mới.
    Và tua 7 ngày hoặc `POST …:finish-rotation`.
    Thì bước 1: `ROTATING`. Bước 2: cả hai bí mật gọi được; bí mật mới chỉ lộ ở phản hồi mở bàn giao. Bước 3: `ACTIVE` với bí mật mới, bí mật cũ vô hiệu. EVT: `EVT-01-06` khi bắt đầu và khi kết thúc. KT: có. Mồi sạch.

  @TC-01-071 @P1 @Âm
  Kịch bản: TC-01-071 Xoay chồng, sai trạng thái, thiếu lý do, thiếu MFA
    # Truy vết: FR-01-025 · API-01-045, 046 · BR-01-009 · ERR-01-021, 023, 029, 030, 033, 035.
    Biết định danh `ROTATING`; định danh `REVOKED`; OR2, TA1.
    Khi `:rotate` khi đang `ROTATING`.
    Và `:rotate` định danh `REVOKED`.
    Và `:rotate` thiếu lý do; thiếu MFA mới.
    Và PH-12 `fail`; OpenBao `fail`; `:rotate`.
    Thì `409` ERR-01-029; `409` ERR-01-030; `400` ERR-01-033; `403` ERR-01-035; `503` ERR-01-021 và `503` ERR-01-023, định danh giữ nguyên bí mật cũ.

  @TC-01-072 @P1 @Biên @Bảomật
  Kịch bản: TC-01-072 Xoay khẩn do SO, chuyển tiếp bằng 0
    # Truy vết: FR-01-025 · UC-01-18 · API-01-045 · BR-01-021 · EVT-01-06.
    Biết `HT-DVC`; U-T68-SO có `PERM-01-suspend`.
    Khi SO `:rotate` kèm `overlapDays = 0`.
    Và gọi cổng bằng bí mật cũ.
    Thì bí mật cũ vô hiệu ngay (≤ 60 giây tại cổng); bàn giao mới tạo; `EVT-01-06`. Thời gian chuyển tiếp vượt 14 ngày bị `400`/`422` theo miền tham số.
