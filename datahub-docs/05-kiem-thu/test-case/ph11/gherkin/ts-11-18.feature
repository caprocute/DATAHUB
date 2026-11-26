# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-18
Tính năng: TS-11-18 · Điều phối bù trừ Saga khi lỗi bước

  @TC-11-103 @P1 @Dương
  Kịch bản: TC-11-103 Nhánh BHYT lỗi: bù trừ ngược, tự động rồi thủ công
    # Truy vết: FR-11-051, 053 · EVT-11-13, 14, 17 · BR-11-008, 009, 010, 011, 013 · PERM-11-compensate
    Biết phiên `HS-21` có `guiTuPhap`, `guiCuTru` `DONE`; `ph04-sim` trả `BUSINESS_ERROR` cho `capTheBHYT`, `completed` cho `huyDangKyThuongTru`.
    Khi gây lỗi `capTheBHYT`
    Và theo dõi `GET /sagas?instanceId=`
    Và `ph04-sim` trả `completed` cho lệnh bù trừ
    Và TO xử lý việc `MANUAL_COMPENSATION` của `guiTuPhap` bằng `:resolve-manual`
    Thì phiên `COMPENSATING`, `saga_log` `RUNNING`, EVT: `saga.compensation.started`. `saga_step`: `guiCuTru` trước, `guiTuPhap` sau; `guiCuTru` gửi lệnh `huyDangKyThuongTru` với `commandId` mới, `DONE` chỉ sau khi ghi nhật ký. `guiTuPhap` `MANUAL`, việc cho nhóm vận hành, cảnh báo P1. Khi xong: `SUCCEEDED`, phiên `COMPENSATED`, EVT: `saga.compensation.completed`.

  @TC-11-104 @P1 @Dương @Biên
  Kịch bản: TC-11-104 Thứ tự ngược, nhánh song song, bước chưa xong, miễn bù trừ
    # Truy vết: FR-11-051 · ERR-11-112 · BR-11-008, 011, 013
    Biết mô hình có hai bước song song `songSong1`, `songSong2` hoàn thành cùng lúc, bước `chuaXong` chưa chạy, bước `mienBu` `NONE_APPROVED`, bước `khongBu` ghi ngoài nhưng không có bù trừ (mô hình cũ).
    Khi gây lỗi ở bước cuối
    Và đọc `saga_step` và thời điểm gửi lệnh
    Thì bước nối tiếp bù trừ ngược thời điểm hoàn thành; hai bước song song gửi lệnh gần như đồng thời; `chuaXong` và `mienBu` `SKIPPED`; `khongBu` chuyển `MANUAL` kèm ERR-11-112 "Bước khongBu chưa có bù trừ, đã chuyển xử lý thủ công."

  @TC-11-105 @P1 @Dương @Âm
  Kịch bản: TC-11-105 Kích hoạt bù trừ thủ công
    # Truy vết: FR-11-051 · API-11-098 · ERR-11-006, 030 · ERR-00-403
    Biết phiên `HS-22` có bước đã xong; phiên `HS-23` chưa có bước nào cần bù trừ; phiên đang `COMPENSATING`; TO, VW.
    Khi TO `POST /instances/{HS-22}:compensate`
    Và TO `:compensate` `HS-23`
    Và TO `:compensate` phiên đang `COMPENSATING`
    Và VW `:compensate`
    Thì bước 1 `202` kèm `sagaId`, `steps[]`. Bước 2 `409` ERR-11-006. Bước 3 `409` ERR-11-030. Bước 4 `403` ERR-00-403.

  @TC-11-106 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-11-106 Không ghi được nhật ký Saga
    # Truy vết: FR-11-051 · ERR-11-111 · BR-11-013, 022
    Biết chèn lỗi ghi `saga_step`; phiên `HS-24` đang bù trừ `guiCuTru`.
    Khi bật lỗi ghi nhật ký khi lệnh bù trừ trả `completed`
    Và đọc `saga_step`
    Và tắt lỗi, đợi thử lại
    Và đếm lệnh bù trừ tới `ph04-sim`
    Thì bước giữ `RUNNING`, cảnh báo ERR-11-111; sau khi tắt lỗi bước `DONE` đúng một lần; chỉ một lệnh bù trừ (idempotent theo `commandId`).
