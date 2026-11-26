# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-29
Tính năng: TS-10-29 · Cầu nối Pulsar, đối chiếu, chuyển hẳn và quay lui

  @TC-10-118 @P1 @Dương
  Kịch bản: TC-10-118 Cầu nối Pulsar sang Kafka có duyệt, không ảnh hưởng subscriber cũ
    # Truy vết: FR-10-073 · API-10-113, 059, 077, 090 · EVT-10-16 · NFR-10-018 · UC-10-27
    Biết U-T68-TA, U-T68-IA1 ở T96; ánh xạ topic `PLANNED`; topic Kafka đích `ACTIVE`; SIM-PULSAR có producer 200 bản tin/giây và subscriber cũ.
    Khi TA `POST /migrations/bridges` `PULSAR_TO_KAFKA`, `startFrom = LATEST`, `expiresAt` sau 90 ngày; IA1 duyệt.
    Và chạy 30 phút.
    Thì bước 1 bên phát `LEGACY_BRIDGE` và publication tự duyệt; cầu nối `RUNNING`, ánh xạ `BRIDGING`; EVT: `bridge.state-changed`. Bước 2 bản tin xuất hiện trên Kafka với `id` từ `messageId`, `source = /legacy-hub/{pulsarTopic}`; độ trễ p95 ≤ 60 giây; subscriber cũ vẫn nhận đủ (subscription `Failover` riêng `dh-bridge`).

  @TC-10-119 @P1 @Âm
  Kịch bản: TC-10-119 Cầu nối trùng, ngược chiều cùng cặp, quá hạn dùng, bản tin không chuyển được
    # Truy vết: FR-10-073, 074 · API-10-113, 115 · ERR-10-012, 042, 118 · BR-10-033
    Biết U-T68-TA ở T96; cầu nối `brg-t96-cp` `RUNNING`.
    Khi tạo cầu nối thứ hai cho cùng topic; tạo cầu nối `KAFKA_TO_PULSAR` cùng cặp.
    Và `expiresAt` sau 200 ngày.
    Và SIM-PULSAR phát bản tin không chuyển được theo lược đồ đích.
    Và đặt đồng hồ quá `expiresAt`.
    Thì bước 1 `409` ERR-10-042 cả hai. Bước 2 `422` ERR-10-012. Bước 3 bản tin vào DLQ của cầu nối, `origin = BRIDGE`, `bridgeCode`, ERR-10-118; cầu nối vẫn chạy. Bước 4 cầu nối `EXPIRED`, EVT: `bridge.state-changed`.

  @TC-10-120 @P2 @Dương
  Kịch bản: TC-10-120 Cầu nối ngược Kafka sang Pulsar cho bên nhận cũ
    # Truy vết: FR-10-074 · API-10-113 · EVT-10-16
    Biết bên phát đã chuyển sang phát thẳng Datahub; cầu nối chiều cũ đã `STOPPED`; subscriber cũ còn trên Pulsar.
    Khi TA tạo cầu nối `KAFKA_TO_PULSAR`; IA1 duyệt; phát 100 sự kiện qua API.
    Thì subscriber cũ nhận 100 bản tin định dạng cũ (không phong bì CloudEvents); nhóm `dh-bridge-t96-{bridgeCode}`.

  @TC-10-121 @P1 @Dương @Âm
  Kịch bản: TC-10-121 Đối chiếu, chuyển hẳn có điều kiện và quay lui trong cửa sổ
    # Truy vết: FR-10-075 · API-10-117, 078, 116, 059 · EVT-10-15 · ERR-10-006, 042 · UC-10-27
    Biết U-T68-TA, U-T68-IA1 ở T96; ánh xạ `BRIDGING` 3 ngày (dưới `10.migration.min-parallel-days`), ánh xạ khác 15 ngày đủ điều kiện.
    Khi `GET /migrations/reconciliations`.
    Và đề nghị chuyển hẳn ánh xạ 3 ngày.
    Và đề nghị chuyển hẳn ánh xạ 15 ngày; IA1 duyệt.
    Và trong cửa sổ 30 ngày gọi `:rollback`.
    Thì bước 1 chênh lệch 0 sau khi trừ lag. Bước 2 `409` ERR-10-006 kèm điều kiện chưa đạt. Bước 3 ánh xạ `CUT_OVER`, cầu nối dừng; EVT: `migration.cut-over`. Bước 4 ánh xạ `ROLLED_BACK` rồi `BRIDGING` khi cầu nối chạy lại; EVT: `migration.cut-over` (quay lui).

  @TC-10-122 @P3 @Dương
  Kịch bản: TC-10-122 Báo cáo tiến độ di trú
    # Truy vết: FR-10-076 · API-10-118 · UI-10-20
    Biết U-T68-TA ở T96.
    Khi `GET /migrations/progress`; xuất Excel ở UI-10-20.
    Thì số ánh xạ theo trạng thái theo loại, HTTT còn dùng Pulsar, cầu nối đang chạy và lag, đối chiếu gần nhất; tệp Excel khớp.
