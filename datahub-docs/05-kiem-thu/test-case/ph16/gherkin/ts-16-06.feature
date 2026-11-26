# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-06
Tính năng: TS-16-06 · Tiếp nhận quan sát: sự kiện, kéo API, API đẩy

  @TC-16-023 @P1 @Dương
  Kịch bản: TC-16-023 Tiếp nhận quan sát từ sự kiện Kafka, idempotent
    # Truy vết: FR-16-010 · API-16-043, 042 · UI-16-06 · BR-16-012, BR-16-013 · NFR-16-004
    Biết T90; nguồn `tc-ph01-event` `ACTIVE`; bộ phát Kafka thử.
    Khi phát EVT-01-03 mang `eventId = e-001`, số HTTT kết nối 150 và tổng 200 kỳ `M-2026-10`
    Và phát lại đúng bản tin `e-001`
    Và `GET /observations?sourceCode=tc-ph01-event&periodCode=M-2026-10`
    Và `GET /sources/tc-ph01-event/ingest-logs`
    Thì bước 1 tạo hai quan sát chuẩn hóa `ph01.httt.connected` = 150, `ph01.httt.total` = 200 với `periodStart = 2026-10-01`, `periodEnd = 2026-10-31`, `idempotencyRef = e-001`, `channel = EVENT`, `late = false`, trễ p95 ≤ 60 giây. Bước 2 không tạo thêm (`DUPLICATE` trong nhật ký). Bước 3 đúng hai quan sát. Kỳ tính theo `periodEnd`, múi giờ `Asia/Ho_Chi_Minh`.

  @TC-16-024 @P1 @Âm
  Kịch bản: TC-16-024 Bản tin sai lược đồ, chỉ số ngoài hợp đồng, dữ liệu thử
    # Truy vết: FR-16-010 · API-16-042, 044 · ERR-16-105, ERR-16-102 · BR-16-019
    Biết T90; hợp đồng `tc-ph01-event` chỉ có `ph01.httt.*`; nguồn PH-19 `src-ph19`.
    Khi phát bản tin thiếu trường `periodEnd`
    Và phát bản tin có `metricCode = ph01.khac.chi-so`
    Và phát EVT-19-07 có `isTest = true`
    Và `GET /rejected-observations`
    Thì bước 1 loại, ghi ERR-16-105, bản tin vào hàng lỗi (DLQ), không tạo quan sát. Bước 2 loại, ERR-16-102. Bước 3 không tạo quan sát nào cho `giao-dich-thanh-toan-truc-tuyen` (BR-16-019). Bước 4 liệt kê hai dòng bị loại với `code`, `detail`.

  @TC-16-025 @P1 @Dương @Âm @Biên
  Kịch bản: TC-16-025 API đẩy quan sát theo lô, kết quả từng phần tử, idempotent
    # Truy vết: FR-16-012, FR-16-010 · API-16-030 · UI-16-06 · ERR-16-103 · BR-16-012 · NFR-16-003 · scope `kpi.ingest`
    Biết S-T90-PH01; nguồn `tc-ph01-push`.
    Khi `POST /ingest/observations` với 100 quan sát hợp lệ (`metricCode` thuộc hợp đồng, `idempotencyRef` khác nhau)
    Và gửi lô 4 phần tử: 2 hợp lệ, 1 trùng bước trước, 1 `metricCode` ngoài hợp đồng
    Và `GET /sources/tc-ph01-push/ingest-logs?result=ACCEPTED`
    Và gửi lô một quan sát `snap-1001` giá trị 200, gửi lại đúng lô, rồi gửi lại `snap-1001` với giá trị 210
    Thì bước 1 `202`, `accepted = 100`, `duplicate = 0`, `rejected = 0`. Bước 2 `207`, `accepted = 2`, `duplicate = 1`, `rejected = 1`, `results[].index`, `status`, `code = ERR-16-102` cho phần tử bị loại. Bước 3 có đủ dòng. Với 100 quan sát p95 ≤ 300 ms (đo chi tiết ở TC-16-115). Bước 4 `202` `accepted = 1`; gửi lại `duplicate = 1`; giá trị 210 `REJECTED` `code = ERR-16-103`, không ghi đè 200.

  @TC-16-026 @P1 @Âm @Bảo @mật
  Kịch bản: TC-16-026 API đẩy: thiếu scope, lệch tenant, định danh cá nhân trong dimensions
    # Truy vết: FR-16-012, FR-16-010 · API-16-030 · ERR-16-101, ERR-16-037 · BR-16-028 · scope `kpi.ingest`
    Biết S-T90-NOSCOPE, S-T91-PH01, S-T90-PH01; mồi `0010990123456`.
    Khi S-T90-NOSCOPE `POST /ingest/observations`
    Và S-T91-PH01 gửi lô với `sourceCode = tc-ph01-push` của T90
    Và S-T90-PH01 gửi quan sát có `dimensions = {cccd: "0010990123456", ghiChu: "DH-CANARY-ing-push"}`
    Và S-T90-PH01 gửi quan sát thiếu `value`
    Thì bước 1 `403` ERR-00-403. Bước 2 `403` ERR-16-037 (hoặc `400` ERR-16-101 lệch tenant), không ghi vào T90. Bước 3 loại, `code = ERR-16-101`, `errors[]` trỏ `dimensions`; mồi sạch ở log, nhật ký tiếp nhận, kiểm toán. Bước 4 `400` ERR-16-101.

  @TC-16-027 @P1 @Dương @Âm
  Kịch bản: TC-16-027 Kéo API chỉ số theo lịch, đọc bù khi lỡ sự kiện, kéo lỗi
    # Truy vết: FR-16-011 · API-16-029, 042, 043 · UI-16-06 · ERR-16-006, ERR-16-060, ERR-16-106 · BR-16-012 · NFR-16-004
    Biết T90; nguồn `tc-ph13-pull` `ACTIVE`; `src-sim` PH-13 trả chỉ số tháng cho `M-2026-10`; nguồn `tc-ph01-event` mất bản tin `e-777` (không tới Kafka) nhưng có ở API thống kê PH-01.
    Khi `POST /sources/tc-ph13-pull:pull` với `from = 2026-10-01`, `to = 2026-10-31`
    Và `GET /sources/tc-ph13-pull/ingest-logs`
    Và chạy bộ đọc bù của `tc-ph01-event` (lịch đêm)
    Và `GET /observations?sourceCode=tc-ph01-event&late=false`
    Và `POST /sources/tc-phu:pull` (nguồn `PAUSED`)
    Và `POST /sources/tc-ph13-pull:pull` khi `src-sim` PH-13 trả `503`, rồi đọc bù với `from`/`to` cách nhau 14 tháng
    Thì bước 1 `202`, `ingestLogId`, `state = QUEUED`. Bước 2 có dòng `ACCEPTED` kèm `channel = PULL_API`. Bước 3 phát hiện thiếu `e-777`, kéo bù và ghi quan sát (`idempotencyRef` theo `snapshotId`), không trùng với quan sát đã nhận từ sự kiện. Kéo lại cùng khoảng không tạo bản trùng. Bước 5 `409` ERR-16-006. Bước 6 tác vụ kết thúc lỗi, nhật ký ERR-16-106 kèm `503`, không ghi quan sát, dữ liệu cũ giữ; khoảng đọc bù quá 12 tháng `400` ERR-16-060 "Khoảng thời gian tra cứu tối đa 12 tháng mỗi lần."
