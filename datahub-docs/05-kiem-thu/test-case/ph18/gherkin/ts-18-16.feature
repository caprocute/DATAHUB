# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-16
Tính năng: TS-18-16 · Phát lại một mục DLQ và nhận kết quả lũy đẳng

  @TC-18-052 @P1 @Dương
  Kịch bản: TC-18-052 Phát lại một mục qua topic của PH-04 và nhận kết quả thành công
    # Truy vết: FR-18-027, 030 · API-18-064, 076 · BR-18-019, 020 · EVT-18-07, 09 · UI-18-03
    # Mục đích: Chứng minh BR-18-019: mục của nguồn `KAFKA_TOPIC` được phát lại bằng EVT-18-09 tới lối vào của PH-04, PH-18 không gọi hệ đích; kết quả callback đưa mục sang `RESOLVED`.
    Biết T90; `DLQ-A-02` `TRIAGED` nguồn `SRC-PH04`; S-PH04 (`ops:replay-callback`); WireMock hệ đích của luồng đếm lời gọi.
    Khi U-T90-TO `POST /dlq/messages/DLQ-A-02:replay` (bản gốc), `Idempotency-Key`.
    Và đọc `t90.ops.replay.requested.v1`.
    Và S-PH04 `POST /ops/internal/v1/replay-results` `idempotencyKey = DLQ-A-02:0`, `result = SUCCEEDED`.
    Và mở UI-18-03 của mục.
    Thì bước 1 `202`, mục `REPLAY_PENDING` rồi `REPLAYING`. Bước 2 một bản tin EVT-18-09 có `dlqId`, `revision = 0`, `idempotencyKey`, `payloadRef`. Bước 3 `200`, mục `RESOLVED`, EVT-18-07. WireMock hệ đích nhận 0 lời gọi từ PH-18 (chỉ PH-04 gọi). Bước 4 lịch sử có lượt phát lại và kết quả.

  @TC-18-053 @P1 @Lũy_đẳng @Biên
  Kịch bản: TC-18-053 Gọi phát lại hai lần, callback lặp và kết quả đến sau khi quá hạn
    # Truy vết: FR-18-030, 027 · API-18-064, 076 · BR-18-020 · ERR-18-109 · EVT-18-07, 09
    # Mục đích: Chứng minh BR-18-020 và ĐN-UC-15: cùng khóa `dlqId:revision` không tạo xử lý trùng ở nguồn; kết quả cuối của một khóa chỉ ghi một lần; kết quả đến muộn sau `18.dlq.replay.result-timeout-minutes` vẫn được nhận một lần.
    Biết T95 (đồng hồ giả); `DLQ-A-07` `TRIAGED`; WireMock PH-04 lưu khóa đã xử lý (giả lập 30 ngày); `18.dlq.replay.result-timeout-minutes = 30`.
    Khi TO phát lại `DLQ-A-07` hai lần liên tiếp cùng `Idempotency-Key`, rồi lần ba khóa khác khi mục đang `REPLAYING`.
    Và tua đồng hồ 31 phút không có callback.
    Và S-PH04 gửi callback `SUCCEEDED` cho `DLQ-A-07:0`, rồi gửi lại `FAILED` cùng khóa.
    Thì bước 1 lần hai trả cùng kết quả `202`, chỉ một EVT-18-09; lần ba `409` ERR-18-031. Bước 2 mục `REPLAY_FAILED` ghi ERR-18-109, lượt có cờ `timedOut`. Bước 3 callback đầu ghi `RESOLVED` (kết quả muộn được nhận); callback hai `200` `duplicate = true`, trạng thái không đổi; nguồn chỉ xử lý một lần.

  @TC-18-054 @P1 @Âm
  Kịch bản: TC-18-054 Phát lại mục POISON, mục đang trong lượt khác, nguồn không có cổng
    # Truy vết: FR-18-027 · API-18-064 · BR-18-023, 019 · ERR-18-028, 031, 033
    # Mục đích: Chứng minh các điều kiện chặn phát lại ở FR-18-027.
    Biết T90; `DLQ-P-02` `POISON`; `DLQ-A-08` thuộc lượt `RJ-01` đang chạy; `DLQ-PH08-1` của nguồn cổng `NONE`.
    Khi phát lại `DLQ-P-02`.
    Và phát lại `DLQ-A-08`.
    Và phát lại `DLQ-PH08-1`.
    Thì bước 1 `409` ERR-18-028. Bước 2 `409` ERR-18-031 nêu mã lượt. Bước 3 `409` ERR-18-033. Không có EVT-18-09.

  @TC-18-055 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-055 Cổng HTTP của PH-19 từ chối, quá thời gian và callback sai danh tính
    # Truy vết: FR-18-027, 030 · API-18-064, 076 · BR-18-019, 020 · ERR-18-038, 107, 108
    # Mục đích: Chứng minh lỗi của cổng nguồn được ghi vào trạng thái mục với mã worker, và chỉ nguồn của mục mới báo kết quả được.
    Biết T90; `DLQ-PH19-1` nguồn `SRC-PH19` cổng `HTTP_PORT`; WireMock cổng PH-19 lần lượt trả `422`, trễ 40 giây; S-PH04 (khác nguồn).
    Khi TO phát lại `DLQ-PH19-1` khi cổng trả `422`.
    Và TO đưa mục về hàng phát lại, cổng trễ 40 giây.
    Và S-PH04 gửi callback cho `DLQ-PH19-1:0`.
    Thì bước 1 mục `REPLAY_FAILED`, ghi ERR-18-107 kèm lý do của nguồn. Bước 2 ghi ERR-18-108, mục được thử lại theo lịch thử của lượt. Bước 3 `403` ERR-18-038, trạng thái không đổi.

  @TC-18-056 @P2 @Dương @Lũy_đẳng
  Kịch bản: TC-18-056 Phát lại bằng bản sửa đã duyệt dùng khóa dlqId:revision riêng
    # Truy vết: FR-18-027, 024, 030 · API-18-064, 076 · BR-18-020 · EVT-18-09
    # Mục đích: Chứng minh bản gốc và bản sửa có khóa lũy đẳng khác nhau nên nguồn xử lý bản sửa dù bản gốc đã từng phát lại thất bại.
    Biết T90; `DLQ-A-05` có bản sửa 1 `APPROVED`, bản gốc đã `REPLAY_FAILED` với khóa `DLQ-A-05:0`.
    Khi TO phát lại chọn `useRevision = 1`.
    Và S-PH04 callback `DLQ-A-05:1` `SUCCEEDED`.
    Thì bước 1 EVT-18-09 có `revision = 1`, `idempotencyKey = DLQ-A-05:1`. Bước 2 mục `RESOLVED`.
