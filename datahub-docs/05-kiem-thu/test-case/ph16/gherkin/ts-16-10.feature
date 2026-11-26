# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-10
Tính năng: TS-16-10 · Chạy tổng hợp theo lịch hoặc thủ công và tính lại

  @TC-16-040 @P1 @Dương
  Kịch bản: TC-16-040 Chạy tổng hợp thủ công và theo dõi lần chạy
    # Truy vết: FR-16-018 · API-16-050, 051, 049, 053 · UI-16-08, UI-16-09 · EVT-16-05 · BR-16-030
    Biết T90; kỳ `M-2026-10` `COLLECTING`, dữ liệu F-KY-1; U-T90-TO1.
    Khi `POST /periods/M-2026-10/runs` `{trigger: MANUAL, reason: "Tổng hợp thử"}` khóa idempotent `tc-run-1`
    Và `GET /runs/{runId}` đến khi kết thúc
    Và `GET /runs?periodCode=M-2026-10&state=PARTIAL`
    Thì bước 1 `202`, `runId`, `state = QUEUED`, `trigger = MANUAL`. Bước 2 `RUNNING` rồi `PARTIAL`, `completeness = 0,833333`, `counts = {indicatorTotal: 24, indicatorComputed: 20, noData: 4}`, `flags` gồm `MISSING_SOURCE`, `MANUAL_PENDING`. Bước 3 có lần này. EVT: `period.computed` (EVT-16-05) kèm `completeness`, `flags`. Tổng hợp xong ≤ 5 phút (NFR-16-001).

  @TC-16-041 @P1 @Âm
  Kịch bản: TC-16-041 Chạy kỳ đã chốt, đang chạy, quá thời gian; hủy lần chạy
    # Truy vết: FR-16-018 · API-16-050, 051, 052 · ERR-16-022, ERR-16-023, ERR-16-110, ERR-16-007 · BR-16-030 · NFR-16-001
    Biết kỳ `M-2026-09` `CLOSED`; kỳ `M-2026-11` đang có lần chạy `RUNNING`; T92 với `16.aggregate.timeout-minutes = 5` (trần thấp), nguồn giả làm chậm.
    Khi `POST /periods/M-2026-09/runs`
    Và `POST /periods/M-2026-11/runs` khi đang chạy
    Và chạy kỳ ở T92 với công thức giả chậm quá 5 phút
    Và `POST /runs/{runId}:cancel` thiếu lý do, rồi với lý do 25 ký tự khi lần chạy `RUNNING`
    Thì bước 1 `409` ERR-16-022. Bước 2 `409` ERR-16-023. Bước 3 lần chạy `FAILED`, `errorCode = ERR-16-110`, kết quả lần trước giữ nguyên (không ghi đè, BR-16-030), thông báo tới PH-13. Bước 4 thiếu lý do `422` ERR-16-007; có lý do `200`, `CANCELLED`, kết quả lần trước còn.

  @TC-16-042 @P1 @Dương
  Kịch bản: TC-16-042 Số liệu trễ tự tính lại sau cửa sổ gom
    # Truy vết: FR-16-023 · API-16-055, 069 · UI-16-09 · NFR-16-002 · BR-16-011 · EVT-16-05
    Biết T90; kỳ `M-2026-10` chưa chốt đã tổng hợp; `16.late-data.recompute = true`, `16.late-data.debounce-minutes = 5`; báo cáo `bc-thang-2026-10` `DRAFT`.
    Khi đẩy ba quan sát trễ trong 2 phút
    Và quan sát kết quả sau 10 phút
    Và `GET /runs?periodCode=M-2026-10&trigger=LATE_DATA`
    Và `GET /reports/bc-thang-2026-10`
    Thì chỉ một lần chạy `trigger = LATE_DATA` sau cửa sổ 5 phút (gom ba yêu cầu); giá trị mới hiển thị ≤ 10 phút từ khi nhận quan sát. Báo cáo `DRAFT` hiện dải "Số liệu kỳ đã được tính lại" và có thể `:refresh`. EVT: `period.computed`.

  @TC-16-043 @P1 @Âm
  Kịch bản: TC-16-043 Tính lại kỳ đã chốt hoặc đã tắt tự tính lại
    # Truy vết: FR-16-023 · API-16-055 · ERR-16-022, ERR-16-023, ERR-16-007
    Biết kỳ `M-2026-09` `CLOSED`; tenant T92 `16.late-data.recompute = false`.
    Khi `POST /periods/M-2026-09:recompute` `{reason: <25 ký tự>}`
    Và `POST /periods/M-2026-10:recompute` khi có lần chạy `RUNNING`
    Và `POST /periods/M-2026-10:recompute` với `reason` ngắn
    Và Ở T92 đẩy quan sát trễ rồi `GET /periods/M-2026-10`
    Thì bước 1 `409` ERR-16-022. Bước 2 `409` ERR-16-023. Bước 3 `422` ERR-16-007. Bước 4 không tạo lần chạy; quan sát được ghi; UI-16-08 báo "Có 1 số liệu mới chưa tính".

  @TC-16-044 @P1 @Dương
  Kịch bản: TC-16-044 Đổi công thức rồi tính lại; kỳ đã chốt giữ phiên bản cũ
    # Truy vết: FR-16-023, FR-16-019 · API-16-055, 053, 054 · BR-16-002, BR-16-033
    Biết `httt-ket-noi-ty-le` phiên bản 1 `ACTIVE` (`effectiveFrom = 2026-01-01`); phiên bản 2 đổi công thức làm tròn `ACTIVE` với `effectiveFrom = 2026-11-01`; kỳ `M-2026-10` chưa chốt, `M-2026-09` đã chốt.
    Khi `POST /periods/M-2026-10:recompute` `{reason: <25 ký tự>, indicatorCodes: [httt-ket-noi-ty-le]}`
    Và `GET /runs/{runId}/values?indicatorCode=httt-ket-noi-ty-le`
    Và `GET /values/{valueId}/lineage`
    Và `GET /periods/M-2026-09` rồi đọc giá trị kỳ này
    Thì kỳ `M-2026-10` (`effectiveFrom` ≤ ngày cuối kỳ) tính bằng phiên bản 2: `versionUsed = 2`, `lineage.formula` là công thức mới, `inputs[]` đủ biến. Kỳ `M-2026-09` giữ `versionUsed = 1` và số đã chốt không đổi (BR-16-033).
