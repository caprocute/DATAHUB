# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-11
Tính năng: TS-17-11 · Bảo vệ tải, cầu dao, sức khỏe mô hình và vết lời gọi

  @TC-17-033 @P1 @Âm @Biên
  Kịch bản: TC-17-033 Cổng mô hình giới hạn tần suất độc lập với hạn mức người dùng
    # Truy vết: FR-17-012 · API-17-052, 053 · BR-17-021 · NFR-17-016 · ERR-17-037
    # Mục đích: Chứng minh `429` ERR-17-037 ở cổng khi vượt giới hạn và hàng đợi mô hình tối đa 50.
    Biết T90; giới hạn cổng 20 lời gọi mỗi giây; LLM-MOCK trả 100 ms; U-PA1.
    Khi PA1 `PUT /gateway/limits` 20/giây.
    Và k6 gửi 60 lời gọi mỗi giây từ 60 người dùng khác nhau trong 30 giây.
    Và gửi 70 yêu cầu đồng thời để hàng đợi mô hình đầy.
    Thì bước 2 phần vượt nhận `429` ERR-17-037 kèm `Retry-After`, không có lời gọi mô hình dư, hạn mức người dùng không bị trừ cho lượt bị chặn ở cổng. Bước 3 yêu cầu thứ 51 trở đi `429` ERR-17-037.

  @TC-17-034 @P1 @Dương @Chịu_lỗi @Hiệu_năng
  Kịch bản: TC-17-034 Cầu dao mở ≤ 10 giây, đóng thủ công, hết thời gian chờ
    # Truy vết: FR-17-012, 014 · API-17-054, 055 · BR-17-021, 023 · NFR-17-019 · ERR-17-036, 038 · EVT-17-10, 11
    # Mục đích: Chứng minh cầu dao mở khi tỷ lệ lỗi vượt ngưỡng, chuyển dự phòng ≤ 2 giây và timeout trả ERR-17-038.
    Biết T94 `17.breaker.error-rate = 50`, `open-seconds = 30`, `17.model.timeout-seconds = 10`; `MV-CHAT-1`, dự phòng `MV-CHAT-2`.
    Khi cho `MV-CHAT-1` trả lỗi 80 % lời gọi trong cửa sổ 30 giây; đo thời gian tới khi cầu dao mở.
    Và gửi câu hỏi khi cầu dao mở.
    Và cho `MV-CHAT-1` treo 15 giây rồi gửi câu hỏi (không có dự phòng).
    Và TO/PA `POST /gateway/breakers/{id}:reset` khi mô hình đã phục hồi.
    Thì bước 1 cầu dao mở ≤ 10 giây sau khi vượt ngưỡng, EVT: `assist.breaker.state-changed`. Bước 2 chuyển sang `MV-CHAT-2` ≤ 2 giây, vết `FALLBACK`; nếu không có dự phòng `503` ERR-17-036. Bước 3 `504` ERR-17-038 sau 10 giây. Bước 4 `HealthState` về `HEALTHY` sau 2 lần thăm dò đạt, EVT đóng cầu dao.

  @TC-17-035 @P1 @Dương @Bảo_mật @Chịu_lỗi
  Kịch bản: TC-17-035 Vết lời gọi mô hình đủ trường, không có nội dung thô, từ chối khi không ghi được vết
    # Truy vết: FR-17-013 · API-17-056, 057, 058 · BR-17-022 · NFR-17-023 · ERR-17-118
    # Mục đích: Chứng minh BR-17-022 và đóng an toàn của vết ở data plane.
    Biết T90; canary `DH-CANARY-vet` nằm trong câu hỏi; U-T90-SO có `PERM-17-log-read`; S-T90-PH04.
    Khi IE hỏi câu có canary; SO `GET /invocations` và `GET /invocations/{id}`.
    Và `GET /invocations/stats` theo mô hình và kết quả.
    Và làm bảng `invocation_log` ghi lỗi rồi S-T90-PH04 gọi `POST /assist/v1/inference/classify`.
    Thì bước 1 vết có mô hình, phiên bản, loại năng lực, token vào ra, độ trễ, kết quả, mã yêu cầu, người dùng; không có trường nội dung, canary không xuất hiện ở vết, log, OTel. Bước 2 số liệu khớp 100 %. Bước 3 `503` ERR-17-118, không gọi mô hình.

  @TC-17-036 @P2 @Dương @Âm
  Kịch bản: TC-17-036 Ba lần thăm dò lỗi thì DOWN, hai lần đạt thì UP
    # Truy vết: FR-17-014 · API-17-059, 060, 061, 193 · BR-17-023 · EVT-17-10
    # Mục đích: Chứng minh BR-17-023 và API thăm dò, lịch sử, `ready` của data plane.
    Biết `MV-CHAT-1` có thể bật tắt lỗi; U-PA1.
    Khi PA1 `POST /model-health/{vid}:probe` khi mô hình lỗi, 3 lần liên tiếp.
    Và `GET /model-health`, `GET /assist/v1/health/ready`.
    Và cho mô hình phục hồi, thăm dò 2 lần.
    Và `GET /model-health/{vid}/history`.
    Thì bước 1 sau lần thứ 3 `HealthState = DOWN`, cầu dao mở, EVT: `assist.model.health-changed`. Bước 2 `ready` báo suy giảm có chỉ rõ mô hình. Bước 3 về `HEALTHY` sau lần đạt thứ 2 (lần 1 vẫn `DEGRADED`). Bước 4 đủ chuyển trạng thái.
