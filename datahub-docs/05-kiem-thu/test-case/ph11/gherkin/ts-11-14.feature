# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-14
Tính năng: TS-11-14 · Quản lý lịch làm việc, tính hạn, nhắc hạn và leo thang quá hạn

  @TC-11-081 @P1 @Dương
  Kịch bản: TC-11-081 Khai và sửa lịch năm, tính lại hạn chưa đóng
    # Truy vết: FR-11-045 · API-11-090, 091, 092 · UI-11-18 · BR-11-017 · PERM-11-config
    Biết TA; phiên `HS-17` hạn 5 ngày LV có mốc rơi sau 4/5/2027; lịch `COMMON` 2027 do PA khai.
    Khi TA `POST /calendars/2027:import`
    Và TA `PUT /calendars/2027` đặt giờ LV 07:30–11:30, 13:30–17:00, thêm `HOLIDAY` 4/5/2027
    Và `GET /calendars`
    Và `GET /instances/{HS-17}`
    Thì bước 1 sao chép ngày lễ `COMMON`, giữ ngày riêng của tỉnh. Bước 2 `200`, `recalculatedDues = n`. Bước 4 `dueAt` của `HS-17` dời đúng một ngày LV. KT: có (ngày thêm, sửa, xóa).

  @TC-11-082 @P1 @Âm
  Kịch bản: TC-11-082 Lịch sai: trùng ngày, giờ chồng, ngoài năm, thiếu quyền
    # Truy vết: FR-11-045 · API-11-091 · ERR-11-028 · ERR-00-403
    Biết TA, TO.
    Khi TA `PUT /calendars/2027` có hai ngày cùng `date`
    Và TA đặt giờ LV 07:30–11:30 và 11:00–12:00
    Và TA thêm ngày `2028-01-01` vào lịch 2027
    Và TO `PUT /calendars/2027`
    Thì bước 1 đến 3 `422` ERR-11-028 nêu ngày trùng, giờ chồng, ngày ngoài năm. Bước 4 `403` ERR-00-403.

  @TC-11-083 @P1 @Dương
  Kịch bản: TC-11-083 Tính hạn 5 ngày LV qua ngày lễ, nghỉ bù và ngày làm bù
    # Truy vết: FR-11-046 · API-11-093 · UI-11-18 · BR-11-017 · NFR-11-016 · PERM-11-read
    Biết `LICH-T90-2027` và `LICH-T90-2027-LB`; TO.
    Khi TO `POST /calendars:compute-due` `{start:"2027-04-30T16:45+07:00", due:{value:5, unit:"WORKING_DAY"}}` với `LICH-T90-2027`
    Và lặp lại với `LICH-T90-2027-LB`
    Và tạo phiên `LT_KHAI_SINH` tiếp nhận đúng thời điểm đó rồi đọc `dueAt`
    Thì bước 1 `200`, `dueAt = 2027-05-10T17:00+07:00`; `explain[]` có 30/4 và 1/5 (lễ), 2/5 (Chủ nhật), 3/5 (nghỉ bù), 8/5 và 9/5 (cuối tuần). Bước 2 `dueAt = 2027-05-08T17:00+07:00`, `explain[]` ghi 8/5 là ngày làm bù. Bước 3 `dueAt` giống bước 1.

  @TC-11-084 @P2 @Biên
  Kịch bản: TC-11-084 Hạn theo giờ làm việc, ngoài giờ, ngày lịch
    # Truy vết: FR-11-046 · API-11-093 · BR-11-017 · NFR-11-016
    Biết `LICH-T90-2027`; thứ Năm 6/5/2027 và thứ Sáu 7/5/2027.
    Khi `compute-due` start 10:30 thứ Năm, 4 giờ LV
    Và start 16:00 thứ Sáu, 4 giờ LV
    Và start 17:30 thứ Sáu, 1 ngày LV, `NEXT_WORKING_START`
    Và start 10:00 thứ Sáu, 24 `CALENDAR_HOUR`
    Và start 10:00 thứ Sáu, 2 `CALENDAR_DAY`
    Thì bước 1 `16:30` cùng ngày (nghỉ 11:30–13:30). Bước 2 `10:30` thứ Hai sau (1 giờ thứ Sáu và 3 giờ thứ Hai). Bước 3 bắt đầu 07:30 thứ Hai, hạn 17:00 thứ Hai. Bước 4 10:00 thứ Bảy (không bỏ cuối tuần). Bước 5 23:59:59 `Asia/Ho_Chi_Minh` của ngày thứ hai, không phụ thuộc giờ tiếp nhận.

  @TC-11-085 @P1 @Âm
  Kịch bản: TC-11-085 Năm chưa có lịch: dùng lịch mặc định
    # Truy vết: FR-11-046 · API-11-093, 090 · ERR-11-116 · UI-11-18
    Biết T93 chưa khai lịch 2027; TO.
    Khi TO `POST /calendars:compute-due` ở T93
    Và tạo phiên ở T93
    Và TA mở UI-11-18 năm 2027
    Thì `200`, hạn tính theo lịch mặc định (thứ Hai đến thứ Sáu); ghi ERR-11-116; UI-11-18 có băng cảnh báo.

  @TC-11-086 @P1 @Dương
  Kịch bản: TC-11-086 Nhắc hạn đúng mốc, không nhắc trùng
    # Truy vết: FR-11-047 · EVT-11-11 · BR-11-019 · NFR-11-016 · PERM-11-read
    Biết việc hạn 2 ngày LV; `11.task.dueSoonHours = 8`; 2 bản sao quét đồng thời; `11.due.scanMinutes = 1`.
    Khi đọc `dueSoonAt`
    Và CLK tới `dueSoonAt`
    Và đợi một chu kỳ quét
    Và đếm bản tin `task.due-soon`
    Thì `dueSoonAt` = hạn trừ 8 giờ LV. Việc `DUE_SOON` trễ ≤ 5 phút so mốc; đúng 1 bản tin `task.due-soon` (khóa dòng `SKIP LOCKED`); thông báo trong ứng dụng gửi một lần; hộp việc đổi nhãn vàng.

  @TC-11-087 @P2 @Âm
  Kịch bản: TC-11-087 Không gửi được nhắc hạn
    # Truy vết: FR-11-047 · ERR-11-123 · EVT-11-11
    Biết bộ thông báo giả ngừng.
    Khi CLK tới mốc nhắc
    Và đọc `due_tracking`, UI-11-20
    Thì `DUE_SOON` đã đặt, EVT: `task.due-soon` đã phát; cảnh báo ERR-11-123 "Nhắc hạn việc … chưa gửi được."

  @TC-11-088 @P1 @Dương
  Kịch bản: TC-11-088 Quá hạn và leo thang hai mức
    # Truy vết: FR-11-048 · EVT-11-12 · BR-11-019 · UI-11-19
    Biết việc `duyetCapSo` hạn 3 ngày LV; mức 1 `NOTIFY_MANAGER`, mức 2 `REASSIGN_GROUP` sau 4 giờ LV; CB-LD là lãnh đạo đơn vị.
    Khi CLK qua hạn
    Và CLK +4 giờ LV
    Và CB-SO hoàn thành việc
    Và TO mở giám sát UI-11-19
    Và việc `duyetCapPhong` không khai `afterHours`, `11.escalation.nextLevelHours = 4`, CLK qua hạn rồi +4 giờ LV
    Thì bước 1 `OVERDUE`, EVT: `task.overdue` `escalationLevel = 0`, rồi mức 1 báo CB-LD. Bước 2 mức 2, việc chuyển nhóm. Bước 3 `dueResult = MISSED`. Bước 4 việc quá hạn hiện trên giám sát, chỉ số `bpm_task_overdue` tăng. Bước 5 mức đầu ngay khi quá hạn (0 giờ), mức sau cách 4 giờ LV.

  @TC-11-089 @P2 @Âm
  Kịch bản: TC-11-089 Không xác định được lãnh đạo
    # Truy vết: FR-11-048 · ERR-11-113 · EVT-11-12
    Biết PH-12 giả không có lãnh đạo đơn vị Tư pháp.
    Khi việc quá hạn mức 1
    Và đọc cảnh báo UI-11-19
    Thì ghi ERR-11-113, chuyển mức kế tiếp; cảnh báo "Không xác định được lãnh đạo đơn vị Tư pháp để báo quá hạn."
