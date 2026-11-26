# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-26
Tính năng: TS-16-26 · Đánh giá tuân thủ kiến trúc, xác nhận và miễn trừ

  @TC-16-090 @P1 @Dương @Âm
  Kịch bản: TC-16-090 Tạo và kích hoạt bộ tiêu chí tuân thủ
    # Truy vết: FR-16-047 · API-16-103, 104, 102 · UI-16-16 · ERR-16-045
    Biết T90; U-T90-TA1; F-TC phiên bản 1 `ACTIVE`.
    Khi `POST /compliance/criteria-sets` `{name: "Bộ tiêu chí v2", criteria: [{criterionCode: C-01, name: "Có tài liệu thiết kế", appliesTo: [HTTT, API], mandatory: true, weight: 10, frameworkRef: "CPĐT 3.0"}, …]}`
    Và `POST /compliance/criteria-sets/2:activate`
    Và `POST /compliance/criteria-sets` với tiêu chí `weight = -1` hoặc `criterionCode` trùng
    Và `GET /compliance/criteria-sets`
    Thì bước 1 `201`, `state = DRAFT`. Bước 2 `200`, bản 2 `ACTIVE`, bản 1 `SUPERSEDED`. Bước 3 `422` ERR-16-045. Bước 4 trả hai bản. Đánh giá đã `CONFIRMED` theo bản cũ giữ kết quả.

  @TC-16-091 @P1 @Dương
  Kịch bản: TC-16-091 Đánh giá, gửi và xác nhận bốn mắt
    # Truy vết: FR-16-047 · API-16-105, 106, 107, 108 · UI-16-16 · EVT-16-11 · BR-16-024
    Biết T90; thành phần `httt-hotich` `NOT_ASSESSED`; bộ tiêu chí F-TC (8 bắt buộc); U-T90-SO lập, U-T90-TA2 xác nhận.
    Khi U-T90-SO `POST /arch/components/httt-hotich/assessments` `{criteriaSetVersion: 1}`
    Và `PATCH /arch/assessments/{id}` điền `results` 12 tiêu chí: 10 `PASS`, 1 `FAIL` kèm `note`, 1 `NA`
    Và `POST …:submit`
    Và U-T90-TA2 `POST …:confirm`
    Và `GET /arch/components/httt-hotich`
    Và `POST …/waivers` với `until` = hôm nay + 200 ngày, rồi với `reason` 10 ký tự
    Thì bước 1 `201`, `DRAFT`. Bước 3 `SUBMITTED`, `proposedLevel` (ví dụ `PARTIAL`), `score`. Bước 4 `CONFIRMED`, `confirmedBy = TA2`. Bước 5 `complianceLevel = PARTIAL` (chỉ đổi sau khi `CONFIRMED`). EVT: `arch-compliance.assessed` (EVT-16-11).

  @TC-16-092 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-092 Thiếu kết quả bắt buộc, tự xác nhận, từ chối thiếu lý do
    # Truy vết: FR-16-047 · API-16-107, 108, 109 · ERR-16-043, ERR-16-005, ERR-16-007 · BR-16-024
    Biết đánh giá `DRAFT` thiếu kết quả 3 tiêu chí bắt buộc; đánh giá `SUBMITTED` do U-T90-SO lập; có tiêu chí `FAIL` thiếu `note`.
    Khi `POST …:submit`
    Và U-T90-SO `POST …:confirm` bản của mình
    Và U-T90-TA2 `POST …:reject` với `comment` 5 ký tự
    Và gửi đánh giá có `FAIL` thiếu `note`
    Thì bước 1 `422` ERR-16-043. Bước 2 `403` ERR-16-005. Bước 3 `422` ERR-16-007. Bước 4 `422` ERR-16-043. `complianceLevel` không đổi.

  @TC-16-093 @P1 @Dương @Âm
  Kịch bản: TC-16-093 Miễn trừ có hạn, vượt hạn tối đa và hết hạn miễn trừ
    # Truy vết: FR-16-047 · API-16-110, 096 · UI-16-16 · ERR-16-044, ERR-16-007 · EVT-16-11 · BR-16-024
    Biết `httt-hotich` `PARTIAL` đã `CONFIRMED`; `16.compliance.waiver-max-days = 180`; `clock-sim`; U-T90-TA1.
    Khi `POST /arch/components/httt-hotich/waivers` `{criterionCode: C-07, reason: <60 ký tự>, until: <ngày hiện tại + 90>, planNote}`
    Và `GET /arch/components/httt-hotich`
    Và đẩy đồng hồ qua `until`, chạy tác vụ hết hạn
    Và `GET /arch/components/httt-hotich`
    Và `POST …/waivers` với `until` = hôm nay + 200 ngày, rồi với `reason` 10 ký tự
    Và U-T90-VW `POST …/waivers`
    Thì bước 1 `201`, `approvedBy`. Bước 2 `complianceLevel = EXEMPTED`. EVT: `arch-compliance.assessed` (miễn trừ). Bước 3 miễn trừ hết hạn, mức quay về `PARTIAL` (mức `CONFIRMED` gần nhất), EVT lần hai (hết hạn miễn trừ). Bước 5 `422` ERR-16-044; bước 6 `422` ERR-16-007 (hoặc `400` ERR-16-003 theo lược đồ). Bước 7 `403` ERR-00-403. Mức tuân thủ không đổi ở các bước lỗi.
