# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-19
Tính năng: TS-08-19 · Mở phiếu khắc phục, phân công và theo dõi SLA

  @TC-08-095 @P1 @Dương
  Kịch bản: TC-08-095 Mở phiếu khắc phục từ nhóm lỗi
    # Truy vết: FR-08-041, 042 · API-08-078, 084, 086, 087 · UI-08-13, 15 · EVT-08-07 · PERM-08-remediate
    Biết 12 lỗi `R-CCCD-NN` `CRITICAL` của `mdm-citizen` (miền DAN_CU, chủ quản ORG-CA); DS1.
    Khi `GET /finding-groups?assetCode=mdm-citizen`
    Và `POST /issues` `{findingGroup: …, severity: CRITICAL}`
    Và `GET /issues/{code}`
    Và DO1 `POST /issues/{code}:assign` cho `U-T90-DO1-NV` cùng ORG-CA
    Thì bước 2 `201`, `issueCode = DQ-2026-000001`, `status = ASSIGNED` hoặc `OPEN`, `ownerOrgId = ORG-CA`, `findingCount = 12`, `dueDate`; 12 lỗi thành `IN_REMEDIATION`. Bước 4 `200`, `assigneeUserId`, `slaRemainingDays`. EVT: `issue.created` (EVT-08-07).

  @TC-08-096 @P1 @Âm
  Kịch bản: TC-08-096 Lỗi đã thuộc phiếu khác, giao người ngoài tổ chức
    # Truy vết: FR-08-041, 042 · API-08-084, 087 · BR-08-026 · ERR-08-034, 007
    Biết phiếu `DQ-2026-000001` đang mở với 12 lỗi; DO1 (ORG-CA); người dùng `U-T90-XX` thuộc ORG-TC.
    Khi DS1 `POST /issues` chọn 12 lỗi đó
    Và DO1 `POST /issues/DQ-2026-000001:assign` cho `U-T90-XX`
    Và DS1 `:assign` đổi hạn thiếu lý do
    Thì bước 1 `409` ERR-08-034. Bước 2 `403` ERR-08-032 (người được giao không thuộc tổ chức). Bước 3 `422` ERR-08-007.

  @TC-08-097 @P2 @Biên
  Kịch bản: TC-08-097 Hạn SLA theo mức nghiêm trọng và ngày làm việc
    # Truy vết: FR-08-042 · API-08-084, 085 · BR-08-015
    Biết `08.issue.sla-days`: `CRITICAL` 5, `MAJOR` 15, `MINOR` 30 ngày làm việc; mở phiếu lúc thứ Sáu 2026-12-04; Q08-43 (lịch nghỉ lễ).
    Khi mở một phiếu mỗi mức
    Và đọc `dueDate`, `slaRemainingDays`
    Thì `CRITICAL` hạn 2026-12-11 (thứ Sáu tuần sau, bỏ thứ Bảy, Chủ nhật); `MAJOR` 2026-12-25; `MINOR` 2027-01-15 (lịch làm việc giả định chỉ trừ thứ Bảy, Chủ nhật; ngày nghỉ lễ chờ Q08-43). `overdue = false`.

  @TC-08-098 @P2 @Dương @Biên
  Kịch bản: TC-08-098 Tự mở phiếu khi lỗi CRITICAL mới vượt ngưỡng
    # Truy vết: FR-08-041 · API-08-084 · BR-08-035 · EVT-08-07
    Biết `08.issue.auto-open-critical = 100`; lần đo `FAIL`.
    Khi lần đo A: 101 lỗi `CRITICAL` mới
    Và lần đo B: 100 lỗi `CRITICAL` mới
    Và đặt tham số 0, lần đo có 500 lỗi
    Thì A tự mở một phiếu gộp theo (đối tượng, quy tắc). B không mở. Với tham số 0 không phiếu nào được tự mở.
