# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-03
Tính năng: TS-16-03 · Duyệt định nghĩa, ngừng và thay thế chỉ tiêu

  @TC-16-011 @P1 @Dương
  Kịch bản: TC-16-011 Thử tính, gửi duyệt, duyệt và kích hoạt
    # Truy vết: FR-16-005 · API-16-011, 012, 078, 004, 006 · UI-16-04, UI-16-12 · EVT-16-01 · BR-16-002, BR-16-003
    Biết T90; `tc-ket-noi-moi` bản 1 đã `:dry-run` và `target-ok`; U-T90-TA1 soạn, U-T90-TA2 duyệt.
    Khi U-T90-TA1 `POST …/versions/1:submit` với `changeNote` 25 ký tự và `effectiveFrom = 2026-11-01`
    Và U-T90-TA2 `GET /review-queue?itemType=INDICATOR_VERSION`
    Và U-T90-TA2 `POST …/versions/1:approve` kèm `If-Match`
    Và `GET /indicators/tc-ket-noi-moi/versions/1?compareTo=0`
    Thì bước 1 `200`, `state = PENDING_APPROVAL`, `submittedBy = TA1`. Bước 2 có mục chờ duyệt. Bước 3 `200`, `state = ACTIVE`, `approvedBy = TA2`, chỉ tiêu `activeVersion = 1`. EVT: `indicator.activated` (EVT-16-01) tới PH-13, PH-17. Mỗi chỉ tiêu chỉ một phiên bản `ACTIVE` (BR-16-002).

  @TC-16-012 @P1 @Âm
  Kịch bản: TC-16-012 Gửi duyệt khi chưa thử tính hoặc thiếu ghi chú
    # Truy vết: FR-16-005 · API-16-011 · ERR-16-011, ERR-16-007
    Biết `tc-ket-noi-moi` bản 2 `DRAFT`, vừa sửa `formula` sau lần dry-run.
    Khi `POST …/versions/2:submit` với `changeNote` đủ dài
    Và `:dry-run` rồi `POST …/versions/2:submit` với `changeNote = "sửa"`
    Thì bước 1 `422` ERR-16-011. Bước 2 `422` ERR-16-007. Phiên bản vẫn `DRAFT`.

  @TC-16-013 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-16-013 Bốn mắt, yêu cầu sửa và rút bản gửi duyệt
    # Truy vết: FR-16-005 · API-16-012, 013, 014 · EVT-16-01 · ERR-16-005, ERR-16-007 · BR-16-003
    Biết bản 2 `PENDING_APPROVAL` do U-T90-TA1 soạn và gửi; U-T90-TA3 có cả quyền soạn và duyệt.
    Khi U-T90-TA1 `POST …/versions/2:approve`
    Và U-T90-TA2 soạn, U-T90-TA3 gửi một bản khác rồi U-T90-TA2 `:approve`
    Và U-T90-TA2 `POST …/versions/2:request-changes` với `comment` 10 ký tự
    Và U-T90-TA2 `:request-changes` với `comment` 30 ký tự, TA1 sửa, `:submit` lại, rồi `:withdraw` với `reason` 25 ký tự
    Thì bước 1 `403` ERR-16-005. Bước 2 `403` ERR-16-005 (người duyệt là người soạn). Bước 3 `422` ERR-16-007. Bước 4 `CHANGES_REQUESTED` kèm `decisionComment`, sau gửi lại về `PENDING_APPROVAL`, sau rút về `DRAFT`. Ở các bước lỗi trạng thái vẫn `PENDING_APPROVAL`, không bản ghi kiểm toán thành công.

  @TC-16-014 @P2 @Dương @Âm
  Kịch bản: TC-16-014 Ngừng và thay thế chỉ tiêu, xem lịch sử phiên bản, ngừng sai điều kiện
    # Truy vết: FR-16-006 · API-16-015, 004, 006 · UI-16-03 · ERR-16-013, ERR-16-054, ERR-16-007 · EVT-16-02
    Biết T90; `tc-ket-noi-moi` `ACTIVE`; `httt-ket-noi-ty-le` `ACTIVE`, không nằm trong báo cáo chờ duyệt.
    Khi `POST /indicators/tc-ket-noi-moi:retire` với `reason` 25 ký tự, `replacedBy = httt-ket-noi-ty-le`, `effectivePeriod = M-2026-12`
    Và `GET /indicators/tc-ket-noi-moi`
    Và `GET …/versions/2?compareTo=1`
    Và `POST /indicators/mttd:retire` khi `mttd` đang trong báo cáo `IN_REVIEW`
    Và `:retire` với `replacedBy` đã `RETIRED` hoặc khác `kind`
    Và `:retire` với `reason` 5 ký tự
    Thì bước 1 `200`, chỉ tiêu `state = RETIRED`, `replacedBy` đúng, kỳ từ `M-2026-12` không tính; giá trị các kỳ trước giữ. Bước 3 trả `diff[]` các trường khác nhau giữa hai phiên bản. EVT: `indicator.retired` (EVT-16-02). Bước 4 `409` ERR-16-013. Bước 5 `422` ERR-16-054. Bước 6 `422` ERR-16-007.
