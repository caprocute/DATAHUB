# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-24
Tính năng: TS-10-24 · Danh mục, hạn mức và tham số

  @TC-10-105 @P1 @Dương @Âm
  Kịch bản: TC-10-105 Danh mục kiểu giao tiếp và chế độ định tuyến có mã hệ cũ
    # Truy vết: FR-10-060, 061 · API-10-067, 068, 105, 106 · UI-10-18 · ERR-10-043 · LGC-HUB-014
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-060 (Danh mục kiểu giao tiếp).
    Biết U-T68-TA; PB-DKKD-K dùng `KAFKA_NATIVE`.
    Khi `GET /comm-types`; `GET /routing-modes`.
    Và TA tắt `PULSAR_BRIDGE` (không ai dùng); tắt `KAFKA_NATIVE`; tắt `KEY_HASH`.
    Thì bước 1 đủ 8 mã A.2.8 với chiều, `partyType`, `deliveryMode`, `legacyCode` (`REST`, `PULSAR_CLIENT`, `ROUTE`, `HTTP_PUSH`); ba chế độ với `legacyCode` `CustomPartition`, `RoundRobinPartition`, `SinglePartition`. Bước 2 tắt `PULSAR_BRIDGE` `200`, KT: có; `KAFKA_NATIVE`, `KEY_HASH` `422` ERR-10-043.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-106 @P1 @Dương @Âm
  Kịch bản: TC-10-106 Hạn mức: PA đặt trần, TA phân bổ, vượt trần
    # Truy vết: FR-10-062 · API-10-069, 107 · ERR-10-011, 012 · BR-10-029, 036
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-062 (Hạn mức theo tenant và phân bổ cho bên tham gia).
    Biết U-PA, U-T68-TA; T68 trần sản xuất 10 MiB/s.
    Khi `GET /quota` ở T68.
    Và TA đặt `produceBytesPerSecond = 20971520` (vượt trần).
    Và TA phân bổ `quotaBytesPerSecond` cho PB-DKKD-K 2 MiB/s.
    Và PA nâng trần lên 20 MiB/s.
    Thì bước 1 trả trần, mức dùng, phần dự trữ nội bộ 30 %. Bước 2 `422` ERR-10-012. Bước 3 `KafkaUser` của principal có `producerByteRate = 2097152` sau khi cụm áp dụng; tổng phân bổ không vượt trần. Bước 4 `200`, `ceilingSetBy` là PA. KT: có.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-107 @P1 @Dương @Âm
  Kịch bản: TC-10-107 Tham số 10.* trong miền; tham số nền tảng chỉ PA
    # Truy vết: FR-10-063 · API-10-070, 108 · UI-10-18 · ERR-10-009, 012, 054 · BR-10-035
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-063 (Tham số phân hệ theo tenant).
    Biết U-T68-TA, U-PA, U-T68-IE1.
    Khi TA đặt `10.lag.warn-seconds = 120` có lý do.
    Và TA đặt `10.push.max-retries = 21`; không lý do.
    Và TA đặt `10.external-kafka.enabled = false`; `10.graph.max-nodes = 500`.
    Và IE1 sửa tham số.
    Thì bước 1 `200`, áp dụng ngay cho subscription dùng mặc định. Bước 2 `422` ERR-10-012; `400` ERR-10-009. Bước 3 403-PQ (tham số phạm vi N chỉ PA). Bước 4 403-PQ.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
