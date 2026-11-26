# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-11
Tính năng: TS-11-11 · Trả về bước trước, yêu cầu bổ sung hồ sơ và tạm dừng tính hạn

  @TC-11-068 @P1 @Dương
  Kịch bản: TC-11-068 Trả về bước trước
    # Truy vết: FR-11-044 · API-11-087 · BR-11-033 · PERM-11-task
    Biết `HS-13` ở `duyetCapSo`; `nhanHoSo` do CB-TP xử lý; CB-SO.
    Khi CB-SO `POST /tasks/{id}:return` `{toElementId:"nhanHoSo", comment:"Thiếu giấy chứng sinh, yêu cầu cán bộ tiếp nhận kiểm tra lại"}`
    Thì `200`; việc cũ `COMPLETED` `decision = RETURN`; việc `nhanHoSo` mới giao lại CB-TP; dòng thời gian ghi lý do.

  @TC-11-069 @P1 @Âm
  Kịch bản: TC-11-069 Trả về bước không cho phép, thiếu ý kiến, sai trạng thái
    # Truy vết: FR-11-044 · API-11-087, 088 · ERR-11-006, 007, 026 · BR-11-033
    Biết việc `duyetCapSo` của CB-SO; một việc của phiên `SUSPENDED`.
    Khi CB-SO `:return` tới bước không nằm trong danh sách cho phép
    Và CB-SO `:return` với `comment` 6 ký tự
    Và CB-SO `:request-supplement` với `comment` rỗng
    Và CB-SO `:return` việc phiên `SUSPENDED`
    Thì bước 1 `422` ERR-11-026. Bước 2 và 3 `422` ERR-11-007. Bước 4 `409` ERR-11-006.

  @TC-11-070 @P1 @Dương
  Kịch bản: TC-11-070 Yêu cầu bổ sung, tạm dừng hạn, DVC báo đã bổ sung
    # Truy vết: FR-11-044, 049 · API-11-088, 089 · EVT-11-04 · BR-11-017, 018 · bpm.instance.start
    Biết `HS-14` hạn 5 ngày LV; CB-VT; S-DVC; `LICH-T90-2027`; thứ Ba 10:00.
    Khi CB-VT `POST /tasks/{id}:request-supplement` `{comment}` lúc thứ Ba 10:00
    Và đọc `due_tracking`, `GET /progress/HS-14`
    Và CLK tới thứ Năm 10:00, S-DVC `POST /instances/{id}:supplement-received`
    Và đọc `due_tracking`
    Thì bước 1 phiên chờ thông điệp `HO_SO_BO_SUNG`; hạn `PAUSED`, `pauseReason = WAITING_SUPPLEMENT`; EVT: `step.completed` `displayStatus = WAITING_SUPPLEMENT`. Bước 2 tiến độ DVC hiện "Chờ bổ sung". Bước 3 `202`; `pausedDuration = 15` giờ LV (5 + 7,5 + 2,5), `dueAt` dời đúng 15 giờ LV; phiên đi tiếp.

  @TC-11-071 @P1 @Âm
  Kịch bản: TC-11-071 Báo bổ sung khi phiên không chờ
    # Truy vết: FR-11-049 · API-11-089 · ERR-11-049 · ERR-00-403
    Biết phiên `HS-15` `RUNNING` không chờ bổ sung; S-DVC, S-DVC2.
    Khi S-DVC `POST /instances/{HS-15}:supplement-received`
    Và S-DVC2 gọi cùng API cho phiên đang chờ
    Thì bước 1 `404` ERR-11-049. Bước 2 `403` ERR-00-403.

  @TC-11-169 @P1 @Âm @Biên
  Kịch bản: TC-11-169 Hết hạn bổ sung hồ sơ: không tự hủy, mở sự cố
    # Truy vết: FR-11-049, 024, 060 · API-11-088, 109, 058 · ERR-11-125 · EVT-11-16 · BR-11-017 · PERM-11-instance
    Biết `HS-17`; CB-VT; TO; `LICH-T90-2027`.
    Khi CB-VT `:request-supplement` `HS-17` với `deadline` 2 ngày LV
    Và CLK +3 ngày LV
    Và TO `GET /incidents?type=SUPPLEMENT_EXPIRED`
    Và TO `:cancel` phiên `HS-17` kèm lý do
    Thì bước 2 phiên không tự hủy, hạn giữ `PAUSED`, sự cố `SUPPLEMENT_EXPIRED` `OPEN` ERR-11-125, EVT: `incident.opened`. Bước 3 thấy sự cố ở UI-11-20. Bước 4 `CANCELLED`, sự cố đóng.

  @TC-11-072 @P3 @Biên
  Kịch bản: TC-11-072 Tính lại hạn từ đầu khi bổ sung
    # Truy vết: FR-11-049, 046 · API-11-089 · BR-11-017, 018
    Biết tenant `T92` với `11.supplement.resetDue = true`; phiên `HS-16` đã dừng 2 ngày.
    Khi S-DVC báo đã bổ sung lúc thứ Năm 10:00
    Và đọc `dueAt`
    Thì `dueAt` là 5 ngày LV tính từ lúc nhận bổ sung (thứ Năm 10:00), không cộng `pausedDuration` kiểu cũ.
