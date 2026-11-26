# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-10
Tính năng: TS-08-10 · Lập lịch đo, đo theo yêu cầu, theo dõi và hủy

  @TC-08-049 @P1 @Dương
  Kịch bản: TC-08-049 Lập lịch đo tháng, tạm dừng và tiếp tục
    # Truy vết: FR-08-023 · API-08-054, 055, 056, 057, 058 · UI-08-11 · BR-08-001 · PERM-08-run
    Biết `mdm-citizen` có bộ quy tắc `ACTIVE`; U-T90-TO; `08.scan.timezone = Asia/Ho_Chi_Minh`; ngày hiện tại 2026-11-26.
    Khi `POST /schedules` `{assetCode: mdm-citizen, cron: "0 0 2 1 * ?", scanMode: FULL}`
    Và `POST /schedules/{id}:pause`
    Và `POST /schedules/{id}:resume`
    Và `GET /schedules?assetCode=mdm-citizen`
    Và `PATCH /schedules/{id}` đổi `cron` thành `0 0 3 1 * ?`
    Thì bước 1 `201`, `nextRunAt = 2026-12-01T02:00:00+07:00`, `status = ACTIVE`. Bước 2 `PAUSED`, không bắn lần đo. Bước 3 `ACTIVE`, `nextRunAt` giữ. Bước 5 `200`, `nextRunAt` 03:00. Lịch bắn trên một bản sao duy nhất khi có hai bản sao `dh-data` (ShedLock).

  @TC-08-050 @P1 @Âm
  Kịch bản: TC-08-050 Cron quá dày, lịch trùng, chưa có bộ quy tắc
    # Truy vết: FR-08-023 · API-08-055 · BR-08-001 · ERR-08-029, 049, 027
    Biết như sch-create; `rdm-dvhc` chưa có bộ quy tắc `ACTIVE`.
    Khi `POST /schedules` với `cron = "0 */5 * * * ?"`
    Và `POST /schedules` lại cho `mdm-citizen` cùng chế độ `FULL`
    Và `POST /schedules` cho `rdm-dvhc`
    Thì bước 1 `422` ERR-08-029 (dày hơn 24 giờ). Bước 2 `409` ERR-08-049. Bước 3 `422` ERR-08-027.

  @TC-08-051 @P1 @Dương
  Kịch bản: TC-08-051 Đo theo yêu cầu và theo dõi tiến độ
    # Truy vết: FR-08-024, 030 · API-08-059, 060, 061, 067 · UI-08-11, 12 · EVT-08-02 · PERM-08-run
    Biết `mdm-citizen` với F-SCORE (10.000 bản ghi), bộ quy tắc `ACTIVE`; không có lần đo đang chạy.
    Khi `POST /scans` `{assetCode: mdm-citizen, scanMode: FULL}` kèm `Idempotency-Key`
    Và `GET /scans/{scanId}` lặp đến `SUCCEEDED`
    Và `GET /scans/{scanId}/tasks`
    Thì bước 1 `202`, `status = QUEUED`, `estimatedRows`, `position`, `Location`. Bước 2 `progress` tăng, trạng thái `QUEUED → RUNNING → SUCCEEDED`. Bước 3 có 1 tác vụ (10.000 < `08.scan.task-size`). EVT: `scan.completed` (EVT-08-02) kèm `score`, `verdict`, `flags`.

  @TC-08-052 @P1 @Âm
  Kịch bản: TC-08-052 Đo trùng, vượt hạn mức, mẫu sai, đo năm bằng mẫu
    # Truy vết: FR-08-024 · API-08-059 · BR-08-020 · ERR-08-028, 052, 030, 055
    Biết T92 (`duplicate-policy = REJECT`, `manual-per-hour = 3`); `mdm-citizen` của T92 có lần đo `RUNNING`.
    Khi `POST /scans` khi đang `RUNNING`
    Và hủy, tạo đủ 3 lần đo rồi lần thứ 4 trong cùng giờ
    Và `POST /scans` `{assetCode: mdm-citizen, scanMode: SAMPLE, sampleSize: 50}`
    Và `POST /scans` `{assetCode: A, scanTrigger: ANNUAL, scanMode: SAMPLE, periodCode: 2026-12}`
    Và `POST /scans` lần hai cùng `Idempotency-Key` nhưng thân khác
    Và lặp cùng khóa, cùng thân
    Thì bước 1 `409` ERR-08-028. Bước 2 `429` ERR-08-052. Bước 3 và 4 `422` ERR-08-030. Bước 5 `409` ERR-08-055. Bước 6 trả lại kết quả lần đầu, không tạo lần đo mới. Với `QUEUE` (T90) bước 1 trả `202`, lần mới xếp hàng, mỗi đối tượng tối đa một lần `QUEUED` hoặc `RUNNING`.

  @TC-08-053 @P1 @Dương
  Kịch bản: TC-08-053 Hủy và chạy lại lần đo
    # Truy vết: FR-08-030 · API-08-062, 063 · UI-08-12 · BR-08-020 · ERR-08-007, 006
    Biết lần đo `RUNNING` của `src-hotich` (F-HT); U-T90-TO.
    Khi `POST /scans/{id}:cancel` lý do 10 ký tự
    Và `POST /scans/{id}:cancel` lý do 30 ký tự
    Và `POST /scans/{id}:cancel` lần nữa
    Và `POST /scans/{id}:rerun`
    Thì bước 1 `422` ERR-08-007. Bước 2 `200`, `CANCELLED`, không có ảnh chụp, không phát EVT-08-03. Bước 3 `409` ERR-08-006. Bước 4 `202`, `scanId` mới `QUEUED`; lần cũ không bị sửa.

  @TC-08-054 @P2 @Âm
  Kịch bản: TC-08-054 Lần đo chờ quá hạn tự hủy
    # Truy vết: FR-08-030 · API-08-061 · ERR-08-119
    Biết T92 đặt `08.scan.queue-timeout-hours = 1`; nguồn của lần đo đang bận do lần đo khác chiếm.
    Khi tạo lần đo `QUEUED`
    Và đẩy `clock-sim` thêm 61 phút
    Và `GET /scans/{id}`
    Thì lần đo thành `CANCELLED`, lý do tự động; UI-08-11 nhận ERR-08-119; không có ảnh chụp.

  @TC-08-055 @P2 @Dương
  Kịch bản: TC-08-055 Đo cả miền
    # Truy vết: FR-08-024 · API-08-059, 060 · UI-08-04 · PERM-08-run
    Biết miền `DAN_CU` có 3 đối tượng `ACTIVE` và 1 `SUSPENDED`.
    Khi UI-08-04 "Đo cả miền" gửi `POST /scans` `{assetCode, scanMode: FULL}` cho từng đối tượng `ACTIVE` của `DAN_CU`, mỗi yêu cầu một `Idempotency-Key`
    Và `GET /scans?assetCode=...` cho đối tượng `SUSPENDED`
    Thì ba yêu cầu `202`, ba `scanId` khác nhau (mỗi đối tượng `ACTIVE` một lần đo); không có yêu cầu nào cho đối tượng `SUSPENDED` (giao diện bỏ qua) và danh sách lần đo của đối tượng này trống. FRS không có API gộp theo miền.
