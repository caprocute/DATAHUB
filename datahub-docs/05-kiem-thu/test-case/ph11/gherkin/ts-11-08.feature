# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-08
Tính năng: TS-11-08 · Chờ thông điệp, hẹn giờ, gửi thông báo và gọi quy trình con

  @TC-11-049 @P1 @Dương
  Kịch bản: TC-11-049 Tương quan thông điệp, thông điệp đến sớm
    # Truy vết: FR-11-030 · API-11-069 · BR-11-022 · bpm.instance.start
    Biết phiên `HS-08` chờ thông điệp `HO_SO_BO_SUNG`; phiên `HS-09` chưa tới bước chờ; T92 `11.message.bufferMinutes = 2`.
    Khi S-DVC `POST /messages` `{messageId:"M-1", messageName:"HO_SO_BO_SUNG", businessKey:"HS-08"}`
    Và gửi lại cùng `M-1`
    Và gửi `M-2` cho `HS-09` khi chưa tới bước, rồi đưa `HS-09` tới bước trong 1 phút
    Thì bước 1 `202`, phiên `HS-08` đi tiếp. Bước 2 trả kết quả lần đầu, không đi tiếp lần hai. Bước 3 thông điệp được giữ rồi giao khi phiên tới bước chờ.

  @TC-11-050 @P1 @Âm
  Kịch bản: TC-11-050 Thông điệp: không có phiên chờ, biến sai, hết thời gian chờ, thiếu scope
    # Truy vết: FR-11-030 · API-11-069 · ERR-11-019, 049, 109 · ERR-00-403
    Biết phiên `HS-10` có `TIMER_BOUNDARY` chờ `HO_SO_BO_SUNG` 1 ngày; S-DVC, S-DVC2.
    Khi S-DVC gửi thông điệp cho `businessKey` không chờ
    Và S-DVC gửi thông điệp có biến sai kiểu
    Và Ở T92 gửi thông điệp cho phiên chưa tới bước rồi CLK +3 phút
    Và CLK +25 giờ cho `HS-10`
    Và S-DVC2 gửi thông điệp
    Thì bước 1 `404` ERR-11-049. Bước 2 `422` ERR-11-019. Bước 3 thông điệp quá đệm bị loại, `404` ERR-11-049. Bước 4 timeline "Hồ sơ HS-T90-2026-0008 hết thời gian chờ thông điệp HO_SO_BO_SUNG." (ERR-11-109). Bước 5 `403` ERR-00-403.

  @TC-11-051 @P1 @Dương
  Kịch bản: TC-11-051 Hẹn giờ biên, trung gian và khởi tạo
    # Truy vết: FR-11-031 · BR-11-017, 034 · EVT-11-03
    Biết bước `choPhanHoi` có hẹn giờ biên `PT24H`; mô hình `LT_NHAC_VIEC` có hẹn giờ khởi tạo cron 07:30 hằng ngày.
    Khi phiên tới `choPhanHoi`, CLK +24 giờ
    Và CLK qua 07:30 hai ngày liên tiếp
    Và Ở T92 đặt hẹn giờ 30 giây rồi `:validate`
    Thì bước 1 biên nổ, việc bị hủy, token rẽ nhánh. Bước 2 hai phiên `startChannel = TIMER`. Bước 3 `TIMER_TOO_SHORT` (nhỏ hơn `11.timer.minSeconds`).

  @TC-11-052 @P2 @Âm
  Kịch bản: TC-11-052 Job hẹn giờ hết lượt thử
    # Truy vết: FR-11-031 · ERR-11-108 · EVT-11-16 · BR-11-019
    Biết hẹn giờ trỏ biểu thức lỗi chèn bằng CSDL; `11.outbox.maxAttempts` mặc định.
    Khi phiên tới hẹn giờ lỗi
    Và chờ job hết lượt thử
    Và TO xem `GET /incidents`
    Thì sự cố `TIMER_FAILED` `OPEN` (ERR-11-108), EVT: `incident.opened`, cảnh báo PH-13; phiên không mất.

  @TC-11-053 @P3 @Dương @Âm
  Kịch bản: TC-11-053 Gửi thông báo từ quy trình
    # Truy vết: FR-11-032 · EVT-11-20 · ERR-11-123 · BR-11-014, 030
    Biết mô hình có `SEND_TASK` mẫu `TB_HO_SO_NHAN`; bộ thông báo giả.
    Khi phiên chạy qua `SEND_TASK`
    Và đọc `t90.bpm.notification.requested.v1`
    Và ngừng bộ thông báo, chạy phiên khác
    Và đặt biến `SENSITIVE` vào `params` rồi `:validate`
    Thì bước 2 có `templateCode`, `audience`, `channel`, `params` không DLCN; PH-11 không tự gửi. Bước 3 cảnh báo ERR-11-123, phiên vẫn đi tiếp. Bước 4 `SENSITIVE_IN_PUBLIC`.

  @TC-11-054 @P3 @Dương @Âm
  Kịch bản: TC-11-054 Gọi quy trình con, vòng và độ sâu
    # Truy vết: FR-11-033 · ERR-11-118 · BR-11-035
    Biết `LT_XAC_MINH` `PUBLISHED`; T92 `11.callActivity.maxDepth = 2`; mô hình vòng A gọi B gọi A; chuỗi sâu 3 cấp; `LT_CON_CHUA` chưa phát hành.
    Khi phiên `LT_KHAI_SINH` gọi `LT_XAC_MINH`
    Và `:validate` mô hình vòng
    Và `:validate` chuỗi sâu 3 ở T92
    Và chạy phiên gọi `LT_CON_CHUA`
    Thì bước 1 phiên con `startChannel = CALL_ACTIVITY`, tiến độ công khai gộp vào bước gọi. Bước 2 `CALL_CYCLE`. Bước 3 `CALL_DEPTH`. Bước 4 sự cố ERR-11-118.
