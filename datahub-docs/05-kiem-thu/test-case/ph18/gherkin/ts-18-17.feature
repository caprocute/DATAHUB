# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-17
Tính năng: TS-18-17 · Phát lại loạt có duyệt bốn mắt và điều khiển lượt

  @TC-18-057 @P1 @Dương
  Kịch bản: TC-18-057 Lượt 50 mục theo bộ lọc dưới ngưỡng chạy ngay và hoàn tất
    # Truy vết: FR-18-028, 030 · API-18-065, 066, 067, 068, 069 · BR-18-021 · EVT-18-10 · UI-18-05
    # Mục đích: Chứng minh lượt dưới ngưỡng không cần duyệt, danh sách mục chốt lúc tạo, tiến độ theo từng mục, EVT-18-10 theo từng lần đổi trạng thái.
    Biết T90; 50 mục `TRIAGED` của `SRC-PH04` mã `ERR-04-101`; `18.dlq.replay.approval-threshold = 500`; WireMock PH-04 trả thành công.
    Khi TO `POST /replay-jobs` theo bộ lọc nguồn và mã lỗi.
    Và `POST /replay-jobs/{jobId}:submit`.
    Và theo dõi `/van-hanh/dlq/phat-lai/{jobId}`.
    Thì bước 1 `201` `DRAFT`, `total = 50`. Bước 2 `200` `RUNNING`. Bước 3 tiến độ tăng, kết thúc `COMPLETED`, `succeeded = 50`; EVT-18-10 cho `DRAFT → RUNNING → COMPLETED`.

  @TC-18-058 @P1 @Âm @Dương @Bảo_mật
  Kịch bản: TC-18-058 Lượt 800 mục vượt ngưỡng chờ duyệt, người tạo tự duyệt bị chặn, danh sách kiểm lại khi duyệt
    # Truy vết: FR-18-028 · API-18-069, 070, 071 · BR-18-021, 046 · ERR-18-005 · EVT-18-10 · UI-18-05, 15
    # Mục đích: Chứng minh BR-18-021 và LP-18-01: lượt vượt ngưỡng vào `PENDING_APPROVAL`, người tạo không duyệt được, khi duyệt mục đã đổi trạng thái bị loại khỏi lượt.
    Biết T90; 800 mục `TRIAGED`; U-T90-TO có cả `PERM-18-approve` để kiểm tách nhiệm vụ; U-T90-TA2.
    Khi TO tạo lượt 800 mục và gửi.
    Và TO `POST /replay-jobs/{jobId}:approve`.
    Và trong lúc chờ, bỏ qua 20 mục của lượt.
    Và TA2 duyệt từ việc ở `/viec-cua-toi`.
    Thì bước 1 `200` `PENDING_APPROVAL`. Bước 2 `403` ERR-18-005. Bước 4 `200` `APPROVED` rồi `RUNNING`, `total = 780`, 20 mục ghi `SKIPPED`; việc duyệt không hiện cho TO.

  @TC-18-059 @P1 @Âm @Biên
  Kịch bản: TC-18-059 Lượt vượt số mục tối đa, bộ lọc rỗng, tốc độ vượt trần
    # Truy vết: FR-18-028, 029 · API-18-065, 075 · BR-18-021, 022 · ERR-18-032, 036, 037
    # Mục đích: Chứng minh giới hạn cứng của lượt phát lại.
    Biết T92 với `18.dlq.replay.batch-max = 100`; 101 mục `TRIAGED`; trần nguồn `SRC-PH04` 50 mục mỗi giây.
    Khi tạo lượt 101 mục.
    Và tạo lượt bộ lọc không khớp mục nào.
    Và tạo lượt 100 mục rồi `PATCH /replay-jobs/{jobId}` tốc độ 80.
    Thì bước 1 `422` ERR-18-032. Bước 2 `422` ERR-18-036. Bước 3 `422` ERR-18-037.

  @TC-18-060 @P1 @Dương @Âm
  Kịch bản: TC-18-060 Tạm dừng, tiếp tục, đổi tốc độ, hủy lượt; hủy lượt đã xong bị chặn
    # Truy vết: FR-18-029 · API-18-072, 073, 074, 075 · BR-18-022, 046 · ERR-18-006 · EVT-18-10 · NFR-18-006
    # Mục đích: Chứng minh FR-18-029: điều khiển lượt có hiệu lực trong lô kế tiếp, hủy đưa mục chưa chạy về `TRIAGED`, thao tác khẩn ghi kiểm toán trễ qua outbox.
    Biết T90; lượt `RJ-02` 1.000 mục `RUNNING` tốc độ 10 mục mỗi giây; lượt `RJ-03` `COMPLETED`.
    Khi `:pause`, chờ 10 giây, đếm mục đã gửi.
    Và `PATCH` tốc độ 20 kèm `If-Match`, `:resume`.
    Và `:cancel` lượt `RJ-02`.
    Và `:cancel` lượt `RJ-03`.
    Thì bước 1 `PAUSED`, số mục gửi không tăng sau lô hiện hành. Bước 2 tốc độ đo được 20 ± 10%. Bước 3 `CANCELLED`, mục chưa chạy về `TRIAGED`. Bước 4 `409` ERR-18-006. EVT-18-10 cho mỗi lần đổi.

  @TC-18-061 @P1 @Biên @Chịu_lỗi
  Kịch bản: TC-18-061 Lượt tự dừng khi tỷ lệ lỗi vượt 20 % và kết thúc PARTIAL
    # Truy vết: FR-18-029, 030 · BR-18-022 · EVT-18-08, 10
    # Mục đích: Chứng minh BR-18-022: lượt dừng khi tỷ lệ lỗi vượt `18.dlq.threshold.replay-failure-percent`, phát EVT-18-08 `REPLAY_FAILURE_RATE`.
    Biết T90; lượt 200 mục; WireMock PH-04 trả thất bại cho 30 % mục từ mục thứ 50.
    Khi chạy lượt.
    Và tiếp tục lượt sau khi chỉnh WireMock thành công rồi để chạy xong.
    Thì bước 1 lượt `PAUSED` khi tỷ lệ lỗi cửa sổ trượt vượt 20 %, EVT-18-08 phát. Bước 2 kết thúc `PARTIAL` với số thành công, thất bại đúng; mục lỗi `REPLAY_FAILED`.
