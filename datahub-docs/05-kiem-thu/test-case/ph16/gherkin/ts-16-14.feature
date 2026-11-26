# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-14
Tính năng: TS-16-14 · Gửi duyệt và duyệt báo cáo bốn mắt

  @TC-16-058 @P1 @Dương
  Kịch bản: TC-16-058 Gửi duyệt, duyệt bốn mắt
    # Truy vết: FR-16-028 · API-16-071, 072, 078 · UI-16-11, UI-16-12 · EVT-16-07 · BR-16-004
    Biết `bc-thang-2026-10` `DRAFT` đủ giải trình (rep-explain); U-T90-TO1 lập, U-T90-TA1 duyệt.
    Khi U-T90-TO1 `POST /reports/bc-thang-2026-10:submit` `{note: "Gửi duyệt"}`
    Và U-T90-TA1 `GET /review-queue?itemType=REPORT`
    Và U-T90-TA1 `POST /reports/bc-thang-2026-10:approve` kèm `If-Match`
    Thì bước 1 `200`, `state = IN_REVIEW`, `submittedBy = TO1`. EVT: `report.submitted` (EVT-16-07) tới PH-18. Bước 3 `200`, `state = APPROVED`, `reviewedBy = TA1`.

  @TC-16-059 @P1 @Âm
  Kịch bản: TC-16-059 Chỉ tiêu bắt buộc thiếu số hoặc thiếu giải trình
    # Truy vết: FR-16-028 · API-16-071 · ERR-16-029, ERR-16-030, ERR-16-061 · BR-16-008, BR-16-029
    Biết báo cáo `PERIODIC` kỳ `M-2026-11` có `bi-mat-ngoai-kho` (bắt buộc) `NO_DATA` và 2 chỉ tiêu `OFF_TRACK` chưa giải trình; chỉ tiêu bắt buộc `ho-so-cap-do-phe-duyet` `PARTIAL` có giải trình.
    Khi `POST …:submit` khi có chỉ tiêu bắt buộc `NO_DATA`
    Và nhập số tay cho chỉ tiêu bắt buộc và xác nhận, tính lại, `POST …:submit` khi còn 2 chỉ tiêu chưa giải trình
    Và báo cáo dùng mẫu `tc-thieu-dau-de` (thiếu `letterhead.formNo`, `recipients`) rồi `POST …:submit`
    Và giải trình đủ, dùng mẫu `tc-thang-ngan` rồi `POST …:submit`
    Thì bước 1 `422` ERR-16-029, nêu danh sách chỉ tiêu. Bước 2 `422` ERR-16-030. Bước 3 `422` ERR-16-061. Bước 4 `200` (chỉ tiêu bắt buộc `PARTIAL` được phép khi có giải trình). Báo cáo `AD_HOC` không bị chặn bởi ERR-16-029.

  @TC-16-060 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-060 Người lập hoặc người gửi không tự duyệt; ngoại lệ báo cáo đột xuất
    # Truy vết: FR-16-028 · API-16-072, 073 · ERR-16-005, ERR-16-007 · BR-16-004
    Biết báo cáo `IN_REVIEW` do U-T90-TO1 lập, U-T90-TA3 gửi; U-T90-TA3 có đủ quyền; báo cáo `AD_HOC` ở T92 với `16.report.four-eyes = false`.
    Khi U-T90-TA3 `POST …:approve` bản mình gửi
    Và U-T90-TO1 `POST …:approve`
    Và Ở T92 người lập báo cáo `AD_HOC` tự `:approve`
    Và Ở T92 người lập báo cáo `PERIODIC` tự `:approve` khi `four-eyes = false`
    Thì bước 1 `403` ERR-16-005 (người gửi). Bước 2 `403` ERR-00-403 (TO không có `PERM-16-approve`). Bước 3 `200` (chỉ `AD_HOC` được miễn bốn mắt). Bước 4 `403` ERR-16-005 (tham số không áp cho `PERIODIC`).

  @TC-16-061 @P2 @Dương @Âm
  Kịch bản: TC-16-061 Yêu cầu sửa, sửa lại và gửi lại
    # Truy vết: FR-16-028 · API-16-073, 071 · ERR-16-007 · EVT-16-09 · UI-16-12
    Biết báo cáo `IN_REVIEW` (hoặc `APPROVED`) do TO1 lập; U-T90-TA1 duyệt.
    Khi U-T90-TA1 `POST …:request-changes` với `comment` 5 ký tự
    Và `POST …:request-changes` với `comment` 30 ký tự (≥ 20)
    Và U-T90-TO1 sửa thuyết minh, `:submit` lại
    Và U-T90-TA1 `:request-changes` bản `APPROVED`
    Thì bước 1 `422` ERR-16-007. Bước 2 `state = CHANGES_REQUESTED`, EVT: `report.state-changed` (EVT-16-09). Bước 3 về `IN_REVIEW`, `latestVersion` tăng. Bước 4 báo cáo `APPROVED` chuyển `CHANGES_REQUESTED` ("Trả về soạn"), phát EVT-16-09, có kiểm toán ý kiến.
