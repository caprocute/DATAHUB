# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-09
Tính năng: TS-16-09 · Kỳ báo cáo, chốt kỳ và mở lại kỳ

  @TC-16-035 @P1 @Dương
  Kịch bản: TC-16-035 Tạo kỳ tháng, quý, năm và xem lịch kỳ
    # Truy vết: FR-16-017 · API-16-047, 046, 048 · UI-16-08 · BR-16-013
    Biết T90; U-T90-TO1; `16.period.types = MONTH,QUARTER,YEAR`; ngày hiện tại 2026-11-05.
    Khi `POST /periods` `{periodCode: M-2026-11}`
    Và `POST /periods` `{periodCode: Q-2026-Q4}`
    Và `POST /periods` `{periodCode: Y-2026}`
    Và `GET /periods?periodType=MONTH&year=2026&page=0&size=12`
    Và `GET /periods/M-2026-11`
    Thì ba lần tạo `201`; `state = OPEN`, `startDate`, `endDate` đúng (`M-2026-11`: 2026-11-01…2026-11-30; `Q-2026-Q4`: 2026-10-01…2026-12-31), `closeDueDate = 2026-12-05` cho kỳ tháng 11 (`16.period.close-day = 5`). Danh sách trả đủ kỳ.

  @TC-16-036 @P1 @Âm
  Kịch bản: TC-16-036 Mã kỳ sai mẫu, trùng, ở tương lai
    # Truy vết: FR-16-017 · API-16-047 · ERR-16-024
    Biết kỳ `M-2026-11` đã có; ngày hiện tại 2026-11-05.
    Khi `POST /periods` `{periodCode: M-2026-13}`
    Và `POST /periods` `{periodCode: M-2026-11}`
    Và `POST /periods` `{periodCode: M-2027-06}`
    Và `POST /periods` `{periodCode: "T-2026-10"}`
    Thì cả bốn `422` ERR-16-024 (sai mẫu, trùng, tương lai, sai loại); không tạo kỳ.

  @TC-16-037 @P1 @Dương
  Kịch bản: TC-16-037 Chốt kỳ khi đủ điều kiện
    # Truy vết: FR-16-024, FR-16-017 · API-16-057, 048 · UI-16-08 · EVT-16-14 · BR-16-011, BR-16-030
    Biết T90; kỳ `M-2026-10` đã tổng hợp `PARTIAL` (F-KY-1), không còn số tay `SUBMITTED`, không quan sát mới chưa tính; U-T90-TA1.
    Khi `POST /periods/M-2026-10:close` thân `{confirmPartial: true}` kèm `If-Match`
    Và `GET /periods/M-2026-10`
    Và đẩy một quan sát mới `periodEnd = 2026-10-31`
    Và đặt `clock-sim` 2026-12-05 03:00 với `16.period.auto-close = true`: kỳ `M-2026-11` đủ điều kiện, kỳ `Q-2026-Q3` còn số tay `SUBMITTED`
    Thì bước 1 `200`, `state = CLOSED`, `closedBy`, `closedAt`, `officialRunId` trỏ lần tổng hợp chính thức, nhãn `PARTIAL` giữ trên số chốt. Bước 3 quan sát ghi `late = true`, không tính (ERR-16-104). EVT: `period.state-changed` (EVT-16-14, `CLOSED`, kèm `officialRunId`) tới PH-13, PH-17, PH-18. Bước 4 hệ thống tự chốt `M-2026-11`; `Q-2026-Q3` giữ nguyên và PH-18 nhận việc cho TA "Kỳ Q-2026-Q3 chưa chốt được" kèm lý do ERR-16-025.

  @TC-16-038 @P1 @Âm
  Kịch bản: TC-16-038 Chốt chưa đủ điều kiện, mở lại sai
    # Truy vết: FR-16-024 · API-16-057, 058 · ERR-16-025, ERR-16-026, ERR-16-007
    Biết kỳ `M-2026-11` còn 2 số tay `SUBMITTED`; kỳ `M-2026-10` `CLOSED` và báo cáo `bc-thang-2026-10` `IN_REVIEW`; U-T90-TA1.
    Khi `POST /periods/M-2026-11:close`
    Và `POST /periods/M-2026-10:reopen` `{reason: "Sửa số liệu nguồn PH-13"}` (dưới 50 ký tự)
    Và `POST /periods/M-2026-10:reopen` với `reason` 60 ký tự khi báo cáo đang `IN_REVIEW`
    Thì bước 1 `422` ERR-16-025 kèm lý do "còn 2 số liệu tay chờ xác nhận". Bước 2 `422` ERR-16-007. Bước 3 `409` ERR-16-026. Kỳ vẫn `CLOSED`.

  @TC-16-039 @P1 @Dương
  Kịch bản: TC-16-039 Mở lại kỳ, chốt lại và cờ cần đính chính
    # Truy vết: FR-16-024, FR-16-030 · API-16-058, 057, 066 · UI-16-08, UI-16-10 · EVT-16-14 · BR-16-011
    Biết T90; kỳ `M-2026-09` `CLOSED`, báo cáo `bc-thang-2026-09` `PUBLISHED`, chỉ tiêu `httt-ket-noi-ty-le` = 70; U-T90-TA1.
    Khi `POST /periods/M-2026-09:reopen` `{reason: <60 ký tự>, indicatorCodes: [httt-ket-noi-ty-le]}`
    Và nhập quan sát sửa `ph01.httt.connected` từ 140 thành 150 (số trễ)
    Và `POST /periods/M-2026-09/runs`, rồi `POST /periods/M-2026-09:close`
    Và `GET /reports/bc-thang-2026-09`
    Thì bước 1 `200`, `state = REOPENED`, `reopenReason`, EVT-16-14 (`REOPENED`, kèm lý do). Bước 3 giá trị mới 75 khác 70, kỳ `CLOSED` lại. Bước 4 `needsCorrection = true`; bản `PUBLISHED` không đổi nội dung (BR-16-009).
