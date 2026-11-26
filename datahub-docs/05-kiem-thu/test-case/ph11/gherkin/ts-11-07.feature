# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-07
Tính năng: TS-11-07 · Thực thi bước tự động qua PH-04 và nhận kết quả

  @TC-11-042 @P1 @Dương
  Kịch bản: TC-11-042 Gửi lệnh thực thi service task
    # Truy vết: FR-11-028 · API-11-070 · EVT-11-17 · BR-11-002, 014, 022, 023
    Biết phiên `HS-03` ở `nhanHoSo`; CB-TP; `ph04-sim` im lặng; `F-DLCN`.
    Khi CB-TP hoàn thành `nhanHoSo`
    Và đọc bản tin trên `t90.bpm.service.requested.v1`
    Và `GET /instances/{id}/service-calls`
    Thì đúng một lệnh `intentCode = dangKyKhaiSinh`, `commandId` duy nhất, `elementId = guiTuPhap`, `replyTopic`, `timeoutAt`, `payload` là tham chiếu; khóa phân vùng `businessKey`; không có địa chỉ, giao thức HTTT, không có giá trị biến (Mồi sạch). `service_call` `REQUESTED`; phiên `WAITING_SERVICE`.

  @TC-11-043 @P1 @Dương
  Kịch bản: TC-11-043 Nhận kết quả thành công và đi tiếp
    # Truy vết: FR-11-029 · EVT-11-18, 04 · API-11-070 · BR-11-022, 023 · bpm.service.worker
    Biết sau `cmd-send`; S-PH04.
    Khi `ph04-sim` trả `completed` `{commandId, output:{maHoTich:"KS-0003"}}` trên `t90.bpm.service.completed.v1`
    Và đọc `service_call`, biến, `GET /instances/{id}`, sự kiện tiến độ
    Thì `service_call` `COMPLETED`; biến theo `outputMapping`; phiên sang `guiCuTru` và gửi lệnh kế; EVT: `instance.step.completed` có `publicName`, `elementId`. Trạng thái và bản tin cùng cam kết.

  @TC-11-044 @P1 @Âm @Biên
  Kịch bản: TC-11-044 Kết quả trùng, không tương quan, đã đóng
    # Truy vết: FR-11-029 · API-11-070 · ERR-11-103, 104 · EVT-11-18 · BR-11-022
    Biết phiên `HS-03` có lệnh `guiCuTru` đang chờ.
    Khi `ph04-sim` trả cùng bản tin `completed` hai lần (cùng `id`)
    Và trả `completed` với `commandId` lạ
    Và trả `completed` cho lệnh `guiTuPhap` đã đóng
    Thì lần trả thứ hai bỏ qua, bộ đếm trùng +1 (ERR-11-104), phiên đi tiếp đúng một lần, không có bản tin tiến độ thứ hai. Bước 2, 3 ERR-11-103: bản tin vào DLQ, sự cố `CORRELATION_FAILED` `OPEN`.

  @TC-11-045 @P1 @Âm
  Kịch bản: TC-11-045 Lỗi nghiệp vụ BHXH_TU_CHOI
    # Truy vết: FR-11-029 · EVT-11-19, 13 · ERR-11-105 · BR-11-010
    Biết `HS-03` ở `capTheBHYT`; `guiTuPhap`, `guiCuTru` đã `DONE`; không có `ERROR_BOUNDARY`.
    Khi `ph04-sim` trả `failed` `{errorKind:"BUSINESS", errorCode:"BHXH_TU_CHOI"}`
    Và đọc `service_call`, dòng thời gian, trạng thái phiên
    Thì `service_call` `FAILED`, `errorKind = BUSINESS`; dòng thời gian "capTheBHYT: cơ quan trả lỗi BHXH_TU_CHOI"; phiên `COMPENSATING`, EVT: `saga.compensation.started`. (Nhánh có biên bắt: token đi nhánh lỗi, không Saga.)

  @TC-11-046 @P1 @Âm
  Kịch bản: TC-11-046 Lỗi kỹ thuật PH-04, gửi lại lệnh
    # Truy vết: FR-11-029, 028 · API-11-071 · EVT-11-19 · ERR-11-106, 006 · ERR-00-403
    Biết phiên `HS-07` ở `guiCuTru`; TO, VW.
    Khi `ph04-sim` trả `failed` `{errorKind:"TECHNICAL", attempts:3}`
    Và TO `POST /service-calls/{commandId}:resend`
    Và `ph04-sim` trả `completed` cho `commandId` mới
    Và TO `:resend` lệnh đã `COMPLETED`
    Và VW `:resend`
    Thì bước 1 sự cố mở (ERR-11-106), phiên giữ `WAITING_SERVICE`. Bước 2 `202`, `commandId` mới, lệnh cũ `CANCELLED`. Bước 3 phiên đi tiếp. Bước 4 `409` ERR-11-006. Bước 5 `403` ERR-00-403.

  @TC-11-047 @P2 @Âm
  Kịch bản: TC-11-047 Quá thời gian chờ kết quả
    # Truy vết: FR-11-029 · API-11-070 · ERR-11-102 · BR-11-019 · NFR-11-016
    Biết `guiTuPhap` có `timeout = 120` phút; `ph04-sim` im lặng; một bản thử có `TIMER_BOUNDARY`.
    Khi phiên không biên: CLK +121 phút
    Và phiên có biên: CLK +121 phút
    Thì phiên không biên: `service_call` `TIMED_OUT`, sự cố `SERVICE_TIMEOUT`, cảnh báo "Bước … chờ PH-04 quá 120 phút." Phiên có biên: token đi nhánh biên, không sự cố.

  @TC-11-048 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-11-048 Không đẩy được lệnh lên Kafka
    # Truy vết: FR-11-028 · EVT-11-17 · ERR-11-101, 107 · BR-11-022, 023
    Biết T95; `11.outbox.maxAttempts = 5`; Chaos Mesh.
    Khi ngừng Kafka, hoàn thành bước tới `guiTuPhap`
    Và chờ vượt 5 lần thử
    Và phục hồi Kafka
    Và TO `:retry` sự cố
    Thì bước nghiệp vụ không hoàn lại; outbox `PENDING`. Sau 5 lần: sự cố ERR-11-101 "Không gửi được lệnh dangKyKhaiSinh của hồ sơ HS-T90-2026-0004 sau 5 lần." Sau khi Kafka lên và `:retry`, đúng một lệnh với cùng `commandId`; `PH-04` chỉ xử lý một lần; sự cố `RESOLVED`; job hết lượt thử cũng mở ERR-11-107.
