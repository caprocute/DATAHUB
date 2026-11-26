# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-06
Tính năng: TS-11-06 · Khởi tạo phiên liên thông từ Cổng DVC, sự kiện PH-10 hoặc thủ công

  @TC-11-036 @P1 @Dương
  Kịch bản: TC-11-036 Khởi tạo phiên qua API từ Cổng DVC
    # Truy vết: FR-11-018, 046, 056 · API-11-049, 052 · EVT-11-03 · BR-11-006, 014, 023 · bpm.instance.start
    Biết S-DVC; `M-KS` v3; `F-DLCN`; `HS-03`; `Idempotency-Key = K-03`.
    Khi S-DVC `POST /instances` `{processKey:"LT_KHAI_SINH", businessKey:"HS-T90-2026-0003", variables:F-DLCN, callbackTopic:"t90.motcua.hoso.ketqua.v1"}`
    Và S-DVC `GET /instances:by-key?processKey=LT_KHAI_SINH&businessKey=HS-T90-2026-0003`
    Và tra `instance_index`, `due_tracking`, `outbox_event`, `ACT_RU_VARIABLE_`
    Thì bước 1 `201`, `instanceId`, `status = RUNNING`, `version = 3`, `dueAt`, `progressUrl`, `Location`. Bước 2 cùng `instanceId`. Bước 3 một dòng mỗi bảng; `due_tracking` `ON_TIME`; EVT: `instance.started` có `startChannel = API`; biến `soDinhDanhMe` chỉ dạng mã hóa, Mồi sạch; việc `nhanHoSo` đã tạo. KT: có (`instance.start`).
    # Hậu điều kiện: `HS-03` dùng lại ở TS-11-07, 09.

  @TC-11-037 @P1 @Dương @Biên
  Kịch bản: TC-11-037 Gửi lại cùng Idempotency-Key và cùng businessKey
    # Truy vết: FR-11-018 · API-11-049 · BR-11-007, 023 · EVT-11-03
    Biết S-DVC; `HS-04`; thân yêu cầu cố định.
    Khi S-DVC gửi `POST /instances` `HS-04` với `K-04`
    Và gửi lại đúng như vậy
    Và gửi lại với `K-05` cùng thân
    Và CLK +25 giờ, gửi lại với `K-04`
    Và đếm `instance_index` và `outbox_event` theo `HS-04`
    Thì lần 1 `201`. Lần 2 trả đúng phản hồi lần 1. Lần 3 `200` cùng `instanceId`. Lần 4 (quá 24 giờ) `200` cùng phiên đang chạy. Đúng 1 phiên, đúng 1 bản tin `instance.started`.

  @TC-11-038 @P1 @Âm
  Kịch bản: TC-11-038 Khởi tạo: trùng khác dữ liệu, thiếu bản phát hành, biến sai, client lạ, quá hạn mức
    # Truy vết: FR-11-018 · API-11-049 · ERR-11-003, 017, 018, 019, 020, 041 · ERR-00-401 · BR-11-007
    Biết sau `start-idem`; `LT_THU_NGHIEM` không có bản `PUBLISHED`; S-DVC2; T92 `11.instance.startRatePerClient = 5`.
    Khi S-DVC gửi `HS-04` với `variables` khác
    Và S-DVC khởi tạo `LT_THU_NGHIEM`
    Và S-DVC khởi tạo `LT_KHAI_SINH` thiếu `maXa`, `ngaySinhTre` sai kiểu
    Và S-DVC khởi tạo với `businessKey = "ab"`
    Và S-DVC2 khởi tạo `LT_KHAI_SINH`
    Và Ở T92 gửi 6 lượt trong 1 giây
    Và gọi không token
    Thì bước 1 `409` ERR-11-018. Bước 2 `422` ERR-11-017. Bước 3 `422` ERR-11-019, liệt kê hai biến. Bước 4 `400` ERR-11-003. Bước 5 `403` ERR-11-020. Bước 6 lượt thứ 6 `429` ERR-11-041 kèm `Retry-After`. Bước 7 `401` ERR-00-401.

  @TC-11-168 @P1 @Âm
  Kịch bản: TC-11-168 Dùng lại Idempotency-Key với nội dung khác
    # Truy vết: FR-11-018 · API-11-049 · ERR-11-051 · BR-11-007
    Biết S-DVC; `HS-06`, `HS-07`; khóa `K-06`.
    Khi S-DVC `POST /instances` `HS-06` với `Idempotency-Key = K-06`
    Và S-DVC `POST /instances` `HS-07` với cùng `K-06` trong 24 giờ
    Thì bước 1 `201`. Bước 2 `409` ERR-11-051, không có phiên `HS-07`, không có bản tin mới.

  @TC-11-039 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-11-039 Lỗi giữa giao dịch khởi tạo không để phiên nửa vời
    # Truy vết: FR-11-018 · API-11-049 · ERR-11-046 · BR-11-023 · EVT-11-03
    Biết bộ chèn lỗi ở điểm "sau `startProcessInstance`, trước `commit`"; `HS-05`.
    Khi bật lỗi giả, S-DVC `POST /instances` `HS-05`
    Và đếm `ACT_RU_EXECUTION`, `instance_index`, `due_tracking`, `outbox_event` theo `HS-05`
    Và tắt lỗi, gửi lại cùng `Idempotency-Key`
    Thì bước 1 `5xx` hoặc `503` ERR-11-046. Bước 2 engine và `ph11_bpm` không chung giao dịch (nguyên tử về hiệu ứng): `instance_index`, `due_tracking`, `outbox_event` 0 dòng, không bản tin Kafka. Bước 3 `201`, tra ngược engine theo `businessKey` rồi dựng bản chiếu, đúng 1 phiên; không gọi lại thì sau 60 giây `StartRecoveryJob` dựng bản chiếu.

  @TC-11-040 @P2 @Dương @Âm
  Kịch bản: TC-11-040 Khởi tạo từ sự kiện PH-10
    # Truy vết: FR-11-019 · API-11-126 · ERR-11-104, 120 · BR-11-007, 022
    Biết `event-start-binding` `t90.hoso.moi.v1 → LT_KHAI_SINH`; IE1 cấu hình; `HS-06`.
    Khi IE1 `GET /event-start-bindings`
    Và PH-10 giả phát sự kiện hợp lệ `HS-06`
    Và phát lại cùng `id` 3 lần
    Và phát sự kiện thiếu `businessKey`
    Thì bước 2 một phiên `startChannel = EVENT`. Bước 3 không phiên mới, bộ đếm trùng tăng 3 (ERR-11-104 chỉ đếm). Bước 4 không phiên, bản tin vào DLQ, ERR-11-120 hiện ở UI-11-20 "Sự kiện khởi tạo … không hợp lệ: {mô tả}."

  @TC-11-041 @P2 @Dương @Âm
  Kịch bản: TC-11-041 Khởi tạo thủ công trên giao diện
    # Truy vết: FR-11-020 · API-11-127, 049 · UI-11-13 · ERR-11-018, 019, 020 · PERM-11-instance
    Biết TO, VW; `M-KS` cho phép khởi tạo thủ công; `M-DUYET` có `allow_manual_start = false`.
    Khi TO mở UI-11-13, `GET /models/LT_KHAI_SINH/start-form`
    Và TO nhập biểu mẫu thiếu `maXa`, rồi đủ, `POST /instances` `{startChannel:"MANUAL"}`
    Và TO khởi tạo `DUYET_KET_NAP_HTTT`
    Và VW khởi tạo
    Thì bước 1 `200` có lược đồ. Bước 2 thiếu `422` ERR-11-019, đủ `201` `startChannel = MANUAL`. Bước 3 `403` ERR-11-020. Bước 4 `403` ERR-00-403.
