# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-10
Tính năng: TS-18-10 · Phân hệ ghi mục DLQ qua API

  @TC-18-031 @P1 @Dương
  Kịch bản: TC-18-031 PH-19 ghi một mục và một lô 500 mục DLQ qua API
    # Truy vết: FR-18-014, 016 · API-18-035, 036 · BR-18-014, 015 · EVT-18-05 · UI-18-01
    # Mục đích: Chứng minh đường ghi DLQ qua API cho nguồn không dùng Kafka: kết quả theo từng mục, khử trùng giống đường topic.
    Biết T90; S-PH19 (`ops:dlq-write`), `SRC-PH19` `ACTIVE`; lô `DLQ-PH19-500` có 2 mục trùng `dlqKey` và 3 mục payload 300 KB.
    Khi S-PH19 `POST /ops/internal/v1/dlq/messages` một mục `reason = TARGET_UNAVAILABLE`.
    Và S-PH19 `POST /ops/internal/v1/dlq/messages:batch` với 500 mục.
    Và gọi lại bước 1 cùng `Idempotency-Key`.
    Thì bước 1 `201` `dlqId`, `status = NEW`. Bước 2 `200`, 499 mục `CREATED`, 1 mục `DEDUPLICATED`, 3 mục có payload ở Garage. Bước 3 `200` trả cùng `dlqId`. EVT-18-05 có số đếm đúng.

  @TC-18-032 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-032 Thiếu ngữ cảnh, payload quá 20 MB, nguồn chưa đăng ký, thiếu scope, tenant giả mạo
    # Truy vết: FR-18-014, 015 · API-18-035 · BR-18-013, 014 · ERR-18-024, 025, 026 · ERR-00-403
    # Mục đích: Chứng minh API ghi DLQ kiểm đủ điều kiện trước khi nhận và không cho danh tính của tenant khác ghi vào T90.
    Biết T90; S-PH19; S-NOSCOPE; S-T91-PH19 (SPIFFE của T91); `18.dlq.payload.max-mb = 20`.
    Khi S-PH19 ghi mục thiếu `stage`.
    Và S-PH19 ghi mục payload 21 MB.
    Và S-PH19 ghi với `sourceCode = SRC-LA`.
    Và S-NOSCOPE ghi mục hợp lệ.
    Và S-T91-PH19 ghi mục có `tenant = T90`.
    Thì bước 1 `422` ERR-18-024 nêu trường `stage` (API khác topic: thiếu ngữ cảnh bị từ chối thay vì thành `POISON`). Bước 2 `413` ERR-18-025. Bước 3 `403` ERR-18-026. Bước 4 `403` ERR-00-403. Bước 5 `403` ERR-00-403, không có mục ở T90.

  @TC-18-033 @P2 @Biên
  Kịch bản: TC-18-033 Lô có mục thiếu trường "nên có" vẫn nhận, mục thiếu trường bắt buộc trong lô bị báo theo mục
    # Truy vết: FR-18-015, 014 · API-18-036 · BR-18-013, 015 · ERR-18-024
    # Mục đích: Chứng minh FR-18-015 trên đường API: thiếu `traceId` hoặc `messageId` vẫn nhận (dùng băm), mục thiếu trường bắt buộc trong lô bị từ chối riêng, các mục khác vẫn vào.
    Biết T90; S-PH19; lô 10 mục: 2 thiếu `traceId`, 1 thiếu `messageId`, 1 thiếu `errorCode`.
    Khi S-PH19 gửi lô.
    Và mở chi tiết mục thiếu `traceId` ở UI-18-03.
    Thì bước 1 `200`; 9 mục `CREATED`, mục thiếu `errorCode` có `result = REJECTED` kèm ERR-18-024. Bước 2 mục hiện "Không có ngữ cảnh chẩn đoán" thay cho khung PH-13.
