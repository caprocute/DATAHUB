# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-16
Tính năng: TS-11-16 · Tạm dừng, tiếp tục và hủy phiên

  @TC-11-094 @P1 @Dương
  Kịch bản: TC-11-094 Tạm dừng và tiếp tục phiên
    # Truy vết: FR-11-023 · API-11-056, 057 · EVT-11-07 · BR-11-018, 023 · PERM-11-instance
    Biết phiên `HS-18` có việc mở và lệnh `guiCuTru` đang chờ; TO.
    Khi TO `POST /instances/{id}:suspend` `{reason:"Chờ ý kiến pháp lý", pauseDue:true}`
    Và `ph04-sim` trả kết quả `guiCuTru` khi đang tạm dừng
    Và CB hoàn thành việc
    Và TO `:resume`
    Thì bước 1 `SUSPENDED`, hạn `PAUSED`, EVT: `instance.suspended` `state = SUSPENDED`. Bước 2 kết quả ghi `service_call` nhưng token chưa đi tiếp. Bước 3 `409` ERR-11-006. Bước 4 `RUNNING`, EVT `state = RESUMED`, token đi tiếp, hạn dời đúng thời gian dừng.

  @TC-11-095 @P1 @Âm
  Kịch bản: TC-11-095 Tạm dừng, tiếp tục sai trạng thái
    # Truy vết: FR-11-023 · API-11-056, 057 · ERR-11-006, 007, 030 · ERR-00-403
    Biết phiên `COMPLETED`; phiên `RUNNING`; phiên `COMPENSATING`; VW.
    Khi TO `:suspend` phiên `COMPLETED`
    Và TO `:resume` phiên `RUNNING`
    Và TO `:suspend` thiếu `reason`
    Và TO `:suspend` phiên `COMPENSATING`
    Và VW `:suspend`
    Thì bước 1, 2 `409` ERR-11-006. Bước 3 `422` ERR-11-007. Bước 4 `409` ERR-11-030. Bước 5 `403` ERR-00-403.

  @TC-11-096 @P1 @Dương
  Kịch bản: TC-11-096 Hủy phiên chưa có bước rủi ro đã xong
    # Truy vết: FR-11-024 · API-11-058 · EVT-11-06 · PERM-11-instance
    Biết phiên `HS-19` ở `nhanHoSo`; TO.
    Khi TO `POST /instances/{id}:cancel` `{reason:"Hồ sơ nộp trùng"}`
    Và `GET /tasks` của phiên
    Và đọc `due_tracking`
    Thì `200`, `CANCELLED`; việc mở `CANCELLED`; hạn đóng; EVT: `instance.cancelled` `reason`, `compensated = false`.

  @TC-11-097 @P1 @Dương
  Kịch bản: TC-11-097 Hủy kèm bù trừ
    # Truy vết: FR-11-024, 051 · API-11-058 · EVT-11-06, 13, 14 · BR-11-008, 010, 011
    Biết phiên `HS-20` đã xong `guiTuPhap`, `guiCuTru`; TO.
    Khi TO `POST /instances/{id}:cancel` `{reason:"Công dân rút hồ sơ", compensate:"AUTO"}`
    Và theo dõi Saga
    Và giải quyết bước `MANUAL` bằng `resolve-manual`
    Thì bước 1 `202`, phiên `COMPENSATING`, giao diện hiện "Sẽ bù trừ 2 bước", `trigger = INSTANCE_CANCEL`. Khi mọi bước `DONE` hoặc `SKIPPED`: `COMPENSATED`, EVT: `instance.cancelled` `compensated = true`.

  @TC-11-098 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-098 Hủy sai trạng thái, thiếu lý do, bỏ bù trừ không đủ quyền
    # Truy vết: FR-11-024 · API-11-058 · ERR-11-006, 007 · ERR-00-403
    Biết phiên `COMPLETED`; phiên có bước rủi ro đã xong; TO, TA.
    Khi TO `:cancel` phiên `COMPLETED`
    Và TO `:cancel` thiếu `reason`
    Và TO `:cancel` `{compensate:"NONE"}` phiên có bước rủi ro
    Và TA gọi như bước 3 với lý do 40 ký tự
    Thì bước 1 `409` ERR-11-006. Bước 2 `422` ERR-11-007. Bước 3 `403` ERR-00-403 "Chỉ quản trị tỉnh được hủy mà không bù trừ." Bước 4 `CANCELLED`, tạo việc đối chiếu thủ công cho TO.

  @TC-11-170 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-11-170 Client hệ thống hủy phiên của chính mình
    # Truy vết: FR-11-024 · API-11-058 · ERR-11-001 · bpm.instance.start
    Biết `HS-21` do S-DVC khởi tạo và đã xong `guiTuPhap`, `guiCuTru`; `HS-22` do S-PH01 khởi tạo; `HS-23` do S-DVC khởi tạo chưa có bước ghi.
    Khi S-DVC `POST /instances/{HS-21}:cancel` kèm lý do
    Và S-DVC `POST /instances/{HS-22}:cancel`
    Và S-DVC `POST /instances/{HS-23}:cancel`
    Thì bước 1 `202`, bù trừ `AUTO`, `trigger = INSTANCE_CANCEL`. Bước 2 `404` ERR-11-001 (phiên của client khác). Bước 3 `200`, `CANCELLED`.
