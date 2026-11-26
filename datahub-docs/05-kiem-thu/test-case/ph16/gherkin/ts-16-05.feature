# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-05
Tính năng: TS-16-05 · Đăng ký nguồn số liệu và theo dõi độ tươi

  @TC-16-018 @P1 @Dương
  Kịch bản: TC-16-018 Đăng ký nguồn EVENT, PULL_API, PUSH_API, MANUAL và thử nguồn
    # Truy vết: FR-16-009 · API-16-022, 023, 021, 025, 024 · UI-16-05
    Biết T90; U-T90-TO1; `src-sim` có API chỉ số của PH-13 trả `200`.
    Khi `POST /sources` `{sourceCode: tc-ph01-event, sourceType: EVENT, providerModule: PH-01, topic: "t90.httt.activated.v1", schemaRef: "evt-01-03@1", contract: {metricCodes: [ph01.httt.connected, ph01.httt.total]}, priority: 1}`
    Và `POST /sources` `{sourceCode: tc-ph13-pull, sourceType: PULL_API, providerModule: PH-13, endpoint: "/metrics/sla-month", cron: "0 0 2 * * *", scope: "metrics.read", contract: {metricCodes: [ph13.dataplane.availability]}}`
    Và `POST /sources` loại `PUSH_API` (`clientId = S-T90-PH19`) và loại `MANUAL`
    Và `POST /sources/tc-ph13-pull:test`
    Và `GET /sources?page=0&size=10`
    Và `PATCH /sources/tc-ph13-pull` đổi `priority = 2` kèm `If-Match`
    Thì bốn lần tạo `201`, `state = ACTIVE`, `Location`, `ETag`. `:test` `200`, `ok = true`, `sampleMetrics` chứa `ph13.dataplane.availability`, `elapsedMs`. Danh sách có `freshness.state`, `ageHours`. Sau `PATCH` `priority = 2`. EVT: `source.state-changed` (EVT-16-03) khi tạo `ACTIVE`.

  @TC-16-019 @P1 @Âm
  Kịch bản: TC-16-019 Cấu hình thiếu theo loại, mã trùng, thử nguồn thất bại
    # Truy vết: FR-16-009 · API-16-022, 025 · ERR-16-015, ERR-16-002, ERR-16-016
    Biết nguồn `tc-ph01-event` đã có; `src-sim` PH-13 trả `500` cho `/metrics/hong`.
    Khi `POST /sources` loại `EVENT` thiếu `topic`
    Và `POST /sources` loại `PULL_API` thiếu `endpoint`
    Và `POST /sources` lại `sourceCode = tc-ph01-event`
    Và tạo nguồn `tc-hong` với `endpoint = "/metrics/hong"` rồi `:test`
    Và U-T90-VW `POST /sources`
    Thì bước 1, 2 `422` ERR-16-015. Bước 3 `409` ERR-16-002. Bước 4 `422` ERR-16-016, `ok = false`. Bước 5 `403` ERR-00-403.

  @TC-16-020 @P1 @Dương
  Kịch bản: TC-16-020 Nguồn quá hạn chuyển STALE rồi ACTIVE khi có số mới
    # Truy vết: FR-16-013 · API-16-023, 021 · UI-16-05, UI-16-06 · ERR-16-107 · EVT-16-03 · NFR-16-014 · BR-16-007
    Biết T90; nguồn `src-ph13` `ACTIVE`, quan sát cuối cùng lúc T0; `clock-sim`; `16.source.stale-hours = 26`.
    Khi đẩy `clock-sim` tới T0 + 25 giờ, đợi bộ quét 10 phút
    Và đẩy tới T0 + 26 giờ 10 phút, đợi bộ quét
    Và `GET /sources/src-ph13`
    Và đẩy một quan sát mới `ph13.dataplane.availability` qua `kpi.ingest`
    Thì sau bước 1 vẫn `ACTIVE`. Sau bước 2 `state = STALE` trong ≤ 15 phút kể từ khi quá ngưỡng (NFR-16-014), `freshness.ageHours` ≥ 26, `stateReason` ghi ERR-16-107; EVT: `source.state-changed` tới PH-13 (thông báo) và PH-18. Lần tổng hợp tiếp theo gắn cờ `STALE_SOURCE` cho chỉ tiêu dùng nguồn này. Sau bước 4 về `ACTIVE`, phát thêm một EVT.

  @TC-16-021 @P1 @Chịu @lỗi
  Kịch bản: TC-16-021 Kéo API lỗi liên tiếp chuyển FAILED
    # Truy vết: FR-16-013, FR-16-011 · API-16-023, 029 · ERR-16-106, ERR-16-108 · EVT-16-03 · UI-16-06
    Biết T94; nguồn `src-ph19` loại `PULL_API`; `src-sim` PH-19 trả `503`; `16.source.fail-after = 3`.
    Khi kích hoạt kéo theo lịch ba lần liên tiếp (hoặc `POST /sources/src-ph19:pull` ba lần)
    Và `GET /sources/src-ph19/ingest-logs?result=REJECTED`
    Và đổi `src-sim` về `200`, kéo lần bốn
    Và `GET /sources/src-ph19`
    Thì lần 1, 2 ghi ERR-16-106 "lần 1", "lần 2", nguồn vẫn `ACTIVE`. Lần 3 nguồn `FAILED` (ERR-16-108), EVT: `source.state-changed`. Nhật ký có ba dòng lỗi. Lần 4 thành công, nguồn về `ACTIVE`, bộ đếm lỗi về 0.

  @TC-16-022 @P2 @Dương @Âm
  Kịch bản: TC-16-022 Tạm dừng, tiếp tục và ngừng nguồn
    # Truy vết: FR-16-009, FR-16-013 · API-16-026, 027, 028 · ERR-16-007, ERR-16-017, ERR-16-006 · EVT-16-03
    Biết T90; `src-ph13` là nguồn duy nhất của `san-sang-data-plane` (đang `ACTIVE`); nguồn `tc-phu` không chỉ tiêu nào dùng.
    Khi `POST /sources/tc-phu:pause` với `reason` 5 ký tự
    Và `:pause` với `reason` 25 ký tự và `until`
    Và `POST /sources/tc-phu:pull`
    Và `:resume`
    Và `POST /sources/src-ph13:retire` với `reason` 25 ký tự
    Và `POST /sources/tc-phu:retire`
    Thì bước 1 `422` ERR-16-007. Bước 2 `PAUSED`, EVT. Bước 3 `409` ERR-16-006. Bước 4 `ACTIVE`. Bước 5 `409` ERR-16-017. Bước 6 `200`, `RETIRED`. KT: có từng thao tác.
