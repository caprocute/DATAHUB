# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-23
Tính năng: TS-11-23 · Cấu hình cảnh báo, tham số `11.*` và chính sách lưu giữ

  @TC-11-124 @P1 @Dương
  Kịch bản: TC-11-124 Đổi tham số tenant
    # Truy vết: FR-11-062 · API-11-116, 117 · UI-11-23 · BR-11-024 · PERM-11-config
    Biết TA; mặc định `11.task.dueSoonHours = 8`.
    Khi TA `GET /settings`
    Và TA `PUT /settings` `If-Match` `{"11.task.dueSoonHours":12}`
    Và tạo việc mới, đọc `dueSoonAt`
    Thì bước 1 có mặc định theo FRS §8.2. Bước 2 `200`; KT: có (giá trị cũ, mới). Bước 3 `dueSoonAt` = hạn trừ 12 giờ LV.

  @TC-11-125 @P1 @Âm
  Kịch bản: TC-11-125 Tham số ngoài miền, vượt trần, thiếu quyền
    # Truy vết: FR-11-062 · API-11-117 · ERR-11-029 · ERR-00-403, 428 · BR-11-024
    Biết PA đã đặt trần `11.delegation.maxDays = 60` ở `COMMON`; TA, TO.
    Khi TA đặt `11.timer.minSeconds = 30`
    Và TA đặt `11.delegation.maxDays = 90`
    Và TA đặt `11.saga.reconcileCron = "abc"`
    Và TO `PUT /settings`
    Và TA `PUT` không `If-Match`
    Thì bước 1 đến 3 `422` ERR-11-029 nêu miền hoặc trần. Bước 4 `403` ERR-00-403. Bước 5 `428` ERR-00-428.

  @TC-11-126 @P2 @Dương @Âm
  Kịch bản: TC-11-126 Ngưỡng cảnh báo và chỉ số vận hành
    # Truy vết: FR-11-061 · API-11-114, 115 · ERR-11-029 · NFR-11-019 · BR-11-024
    Biết TA; bộ thu chỉ số của PH-13 giả.
    Khi TA `PUT /alert-rules` đặt ngưỡng `bpm_service_wait_seconds` p95 > 2 lần `timeout`
    Và TA `GET /alert-rules`
    Và TA `PUT` ngưỡng âm
    Và đọc điểm cuối chỉ số
    Thì bước 1 `200`, bước 2 trả đúng. Bước 3 `422` ERR-11-029. Điểm cuối chỉ số có các chỉ số của bảng vận hành.

  @TC-11-127 @P1 @Dương @Âm
  Kịch bản: TC-11-127 Chính sách lưu giữ, giữ pháp lý, dọn lịch sử
    # Truy vết: FR-11-063 · API-11-118…120, 134, 135 · ERR-11-007, 029, 047, 122 · BR-11-025 · NFR-11-024 · PERM-11-config
    Biết T99: 1.000 phiên kết thúc 13 tháng trước, trong đó 50 giữ pháp lý; `11.retention.engineHistoryMonths = 12`.
    Khi TA `PUT /retention-policy` `{instanceYears:3}`
    Và TA `POST /legal-holds` cho 50 hồ sơ
    Và CLK qua `0 0 1 * * *`, đo p99 API khi dọn
    Và TA dọn tay một hồ sơ giữ pháp lý
    Và chèn lỗi ở lô dọn thứ hai
    Và TA `GET /legal-holds`, rồi `POST /legal-holds/{id}:release` thiếu lý do và với lý do 40 ký tự
    Và TO `:release` hồ sơ khác
    Thì bước 1 `422` ERR-11-029 (miền 5…20). Bước 3 xóa `ACT_HI_*` của 950 phiên, giữ `instance_index`, `task_index`, `saga_*`, `service_call`, 50 phiên giữ pháp lý nguyên; p99 API tăng ≤ 10 %. Bước 4 `409` ERR-11-047. Bước 5 cảnh báo ERR-11-122 "Dọn lịch sử lỗi ở lô 2". Bước 6 danh sách kèm lý do, người, giờ; `422` ERR-11-007 rồi `200`, KT: có, hồ sơ đã gỡ bị dọn lần sau. Bước 7 `403` ERR-00-403.
