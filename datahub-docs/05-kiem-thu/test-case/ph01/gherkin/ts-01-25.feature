# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-25
Tính năng: TS-01-25 · Rà soát quyền: mở kỳ, mức sử dụng, hiệu lực căn cứ

  @TC-01-096 @P1 @Dương
  Kịch bản: TC-01-096 Mở kỳ rà soát và tổng hợp mức sử dụng
    # Truy vết: FR-01-039, 040 · UC-01-27 · API-01-065, 066, 067, 068 · UI-01-12 · BR-01-014.
    Biết các HTTT ACTIVE có số lần dùng từng phạm vi ở giả lập PH-13 (có phạm vi 0 lần trong 400 ngày); U-T68-TA1.
    Khi TA1 `POST /access-reviews` kèm `Idempotency-Key`; `GET /access-reviews/{cycleCode}`.
    Và `GET /access-reviews/{cycleCode}/items`.
    Và tua 6 tháng, chạy tác vụ lịch.
    Thì bước 1: `201`, kỳ `OPEN` gồm mọi HTTT ACTIVE. Bước 2: mỗi phạm vi có số lần dùng, căn cứ, hiệu lực, đề xuất; phạm vi không dùng quá 365 ngày đề xuất thu hồi. Bước 3: kỳ mới tự mở. KT: có.

  @TC-01-097 @P1 @Âm
  Kịch bản: TC-01-097 Mở kỳ khi đã có kỳ mở, tham số vượt miền, PH-13 ngừng
    # Truy vết: FR-01-039, 040 · API-01-065, 068 · BR-01-014 · ERR-01-039, 044, 046.
    Biết kỳ `OPEN` có sẵn; TA1; PH-13 giả lập `fail`.
    Khi mở kỳ thứ hai.
    Và đặt `accessReview.intervalMonths = 7`.
    Và `GET …/items` khi PH-13 `fail`.
    Thì `409` ERR-01-039; `422` ERR-01-044 (tối đa 6 tháng để thỏa BR-01-014); `503` ERR-01-046 và mục hiện "chưa có số liệu", không đề xuất sai.

  @TC-01-098 @P1 @Dương @Âm
  Kịch bản: TC-01-098 Căn cứ hết hiệu lực: tạm ngừng phạm vi ngay
    # Truy vết: FR-01-043 · UC-01-27 · API-01-073 · UI-01-12 · BR-01-015 · ERR-01-003 · EVT-01-11.
    Biết phạm vi có căn cứ "Văn bản X" có ngày hết hiệu lực; U-T68-SO.
    Khi chạy tác vụ ở ngày sau hiệu lực; xem nhãn "Căn cứ hết hiệu lực".
    Và SO `POST /scope-ceilings:mark-legal-expired` với văn bản bãi bỏ thủ công.
    Và gửi mã văn bản không tồn tại.
    Thì bước 1 và 2: phạm vi tương ứng tạm ngừng ngay, không chờ kỳ rà soát; `EVT-01-11`; định danh mất scope đó trong ≤ 60 giây. Bước 3: `400` ERR-01-003.
