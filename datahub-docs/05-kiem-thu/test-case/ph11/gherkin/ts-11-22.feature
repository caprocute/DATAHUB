# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-22
Tính năng: TS-11-22 · Xử lý sự cố engine và thử lại

  @TC-11-121 @P1 @Dương
  Kịch bản: TC-11-121 Sự cố job: mở, thử lại, đóng
    # Truy vết: FR-11-060 · API-11-109, 110, 111, 113 · UI-11-20 · EVT-11-16 · BR-11-012 · PERM-11-compensate
    Biết hai job chèn lỗi tạm thời `JOB_FAILED`; TO.
    Khi để job hết lượt thử
    Và TO `GET /incidents`, `GET /incidents/{id}`
    Và sửa nguyên nhân, TO `POST /incidents/{id}:retry`
    Và TO `POST /incidents:bulk-retry` cho sự cố còn lại
    Thì sự cố `OPEN` có ngăn xếp rút gọn, `traceId`, phiên, bước, số lần thử; EVT: `incident.opened`, cảnh báo PH-13. `RETRYING` rồi `RESOLVED`. Bước 4 mọi sự cố chọn được chuyển `RETRYING`.

  @TC-11-122 @P1 @Âm
  Kịch bản: TC-11-122 Sự cố: đã đóng, lỗi tiếp, thiếu lý do, PO không phiếu
    # Truy vết: FR-11-060 · API-11-111, 112 · ERR-11-006, 007, 107 · ERR-00-403
    Biết sự cố `RESOLVED`; sự cố còn lỗi nguyên nhân; TO, PO, VW.
    Khi TO `:retry` sự cố `RESOLVED`
    Và TO `:retry` sự cố nguyên nhân chưa sửa
    Và TO `:ignore` không lý do
    Và PO `:retry` không có phiếu sự cố
    Và VW `:retry`
    Thì bước 1 `409` ERR-11-006. Bước 2 sự cố về `OPEN`, ERR-11-107 "Thử lại không thành công". Bước 3 `422` ERR-11-007. Bước 4 `403` ERR-00-403. Bước 5 `403` ERR-00-403.

  @TC-11-123 @P3 @Dương
  Kịch bản: TC-11-123 Bỏ qua sự cố có lý do
    # Truy vết: FR-11-060 · API-11-112 · UI-11-20
    Biết sự cố `STUCK_INSTANCE` của phiên đã được hủy; TO.
    Khi TO `POST /incidents/{id}:ignore` `{reason:"Phiên đã hủy, hồ sơ nộp lại"}`
    Và đọc job chết của phiên
    Thì `IGNORED`, ghi `handled_by`, `reason`; job chết bị xóa; KT: có.
