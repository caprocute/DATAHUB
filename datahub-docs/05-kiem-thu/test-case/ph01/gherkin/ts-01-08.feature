# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-08
Tính năng: TS-01-08 · Phân công, theo dõi hạn thẩm định, tham vấn

  @TC-01-038 @P1 @Dương @Âm
  Kịch bản: TC-01-038 Phân công ba bước và hàng đợi
    # Truy vết: FR-01-016 · UC-01-08 · API-01-027, 028 · UI-01-05 · BR-01-017 · ERR-01-017, 020.
    Biết `HT-HOTICH-SS` (`WAITING_ASSIGN`); U-T68-TA1, TA2, IE, SO, OR1.
    Khi TA1 `POST …/reviews:assign`: IE cho `TECHNICAL`, SO cho `SECURITY`, TA2 cho `LEGAL`; mở UI-01-05 bằng từng người.
    Và TA1 phân công OR1 (người lập hồ sơ) cho bước `LEGAL`.
    Và IE gọi `…:assign`.
    Thì bước 1: `200`, `reviewStage = IN_REVIEW`; mỗi người chỉ thấy việc của mình trong `GET /review-queue`. KT: có. EVT: `EVT-01-02`. Bước 2: `403` ERR-01-017. Bước 3: `403-PQ`.

  @TC-01-039 @P2 @Dương @Biên
  Kịch bản: TC-01-039 Tham vấn dừng đồng hồ hạn, tiếp tục chạy lại
    # Truy vết: FR-01-016 · UC-01-08 · API-01-029, 030 · BR-01-032 · ERR-01-020.
    Biết `HT-HOTICH-SS` đã phân công; đồng hồ giả.
    Khi IE `POST …/reviews:consult`; tua 3 ngày làm việc; `POST …/reviews:resume`.
    Và IE gọi `…:resume` lần hai.
    Thì bước 1: `reviewStage = CONSULTING`, `dueAt` không lùi trong 3 ngày, sau `resume` được cộng đúng thời gian dừng. Bước 2: `409` ERR-01-020.

  @TC-01-040 @P2 @Biên
  Kịch bản: TC-01-040 Quá hạn nhắc và leo thang
    # Truy vết: FR-01-016 · UC-01-08 · EVT-01-02 · NFR-01-016.
    Biết `HT-HOTICH-SS`; `review.slaWorkingDays = 2`, `escalate.afterWorkingDays = 3`; đồng hồ giả.
    Khi tua tới hạn bước; tua tiếp 3 ngày làm việc.
    Thì quá hạn: nhắc người được giao và nhãn quá hạn ở UI-01-05; sau ngày thứ 3: leo thang tới TA và PO, cảnh báo PH-13 "hồ sơ quá hạn".
