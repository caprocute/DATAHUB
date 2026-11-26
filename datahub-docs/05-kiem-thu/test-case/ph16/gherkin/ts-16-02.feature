# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-02
Tính năng: TS-16-02 · Soạn định nghĩa chỉ tiêu: công thức, mục tiêu, ngưỡng

  @TC-16-005 @P1 @Dương
  Kịch bản: TC-16-005 Tạo chỉ tiêu và phiên bản định nghĩa nháp
    # Truy vết: FR-16-002 · API-16-002, 005, 003 · UI-16-04 · BR-16-002
    Biết T90; U-T90-TA1.
    Khi `POST /indicators` thân `{indicatorCode: tc-ket-noi-moi, name: "Tỷ lệ HTTT kết nối mới", groupCode: KET_NOI, kind: RATIO, direction: HIGHER_BETTER, measurement: AUTO, unit: "%", aggregation: LAST, mandatory: false}` với khóa idempotent `tc-ind-create-1`
    Và gửi lại đúng yêu cầu
    Và `POST /indicators/tc-ket-noi-moi/versions` thân `{changeNote: "Bản đầu"}`
    Và `GET /indicators/tc-ket-noi-moi`
    Thì bước 1 `201`, `Location` và `ETag`, `state = DRAFT`, `scope = TENANT`, `activeVersion` trống. Bước 2 trả lại cùng phản hồi, không tạo bản thứ hai. Bước 3 `201`, `version = 1`, `state = DRAFT`. EVT: không (chưa `ACTIVE`).

  @TC-16-006 @P1 @Âm
  Kịch bản: TC-16-006 Mã trùng, sai mẫu, tổ hợp thuộc tính sai
    # Truy vết: FR-16-002 · API-16-002, 005 · ERR-16-002, ERR-16-003, ERR-16-006, ERR-16-058
    Biết T90; chỉ tiêu `tc-ket-noi-moi` đã có (ind-create).
    Khi `POST /indicators` lại với `indicatorCode = tc-ket-noi-moi`
    Và `POST /indicators` với `indicatorCode = "Ket_Noi"`
    Và `POST /indicators` với `kind = BOOLEAN`, `aggregation = SUM`, `direction = HIGHER_BETTER`, `unit = "%"`
    Và `POST /indicators/tc-ket-noi-moi/versions` khi đã có phiên bản `DRAFT`
    Và gửi lại khóa idempotent `tc-ind-create-1` nhưng thân khác (đổi `name`)
    Thì bước 1 `409` ERR-16-002. Bước 2 `400` ERR-16-003, `errors[]` trỏ `indicatorCode`. Bước 3 `400` ERR-16-003 (tổ hợp thuộc tính sai). Bước 4 `409` ERR-16-006. Bước 5 `409` ERR-16-058. Không tạo thêm bản ghi.

  @TC-16-007 @P1 @Dương
  Kịch bản: TC-16-007 Soạn công thức CEL, kiểm và thử tính trên kỳ trước
    # Truy vết: FR-16-003 · API-16-007, 008, 009, 010 · UI-16-04 · BR-16-001, BR-16-034
    Biết T90; `tc-ket-noi-moi` bản 1 `DRAFT`; kỳ `M-2026-09` có quan sát `ph01.httt.connected` = 140, `ph01.httt.total` = 200.
    Khi `GET /metrics?page=0&size=20`
    Và `PATCH /indicators/tc-ket-noi-moi/versions/1` với `formula = obs("ph01.httt.connected") / obs("ph01.httt.total") * 100`, `variables = [{alias: connected, metricCode: ph01.httt.connected}, {alias: total, metricCode: ph01.httt.total}]`, `decimals = 1`
    Và `POST …/versions/1:validate`
    Và `POST …/versions/1:dry-run` với `dryRunPeriods = [M-2026-09]`
    Thì bước 1 liệt kê `metricCode` có nguồn kèm `sourceCode`. Bước 2 `200`. Bước 3 `valid = true`, `referencedMetrics` đủ hai biến. Bước 4 `results[0].value = 70`, `completeness = COMPLETE`, `elapsedMs` < 50, có `dryRunHash`. Dry-run không ghi giá trị chỉ tiêu nào.

  @TC-16-008 @P1 @Âm
  Kịch bản: TC-16-008 Công thức sai cú pháp hoặc biến chưa có nguồn
    # Truy vết: FR-16-003 · API-16-007, 008, 009 · ERR-16-008, ERR-16-009, ERR-16-011
    Biết `tc-ket-noi-moi` bản 1 `DRAFT`.
    Khi `PATCH …/versions/1` với `formula = obs("ph01.httt.connected") / (obs("ph01.httt.total") * 100` (thiếu ngoặc đóng) rồi `:validate`
    Và `PATCH` với `formula = obs("ph99.khong.co") * 2` và `variables` trỏ `ph99.khong.co`
    Và `:dry-run` với `dryRunPeriods = [M-2099-01]`
    Thì bước 1 `422` ERR-16-008, `errors[].field = formula`, có vị trí dòng và cột. Bước 2 `422` ERR-16-009. Bước 3 `400` ERR-16-003 (kỳ ở tương lai hoặc không có). Phiên bản vẫn `DRAFT`, dòng `dryRunHash` bị xóa sau mỗi lần sửa nên gửi duyệt sau đó bị ERR-16-011 (xem TC-16-012).

  @TC-16-009 @P1 @Dương
  Kịch bản: TC-16-009 Đặt mục tiêu, ngưỡng ba mức, đơn vị, làm tròn
    # Truy vết: FR-16-004 · API-16-007, 003 · UI-16-04 · BR-16-015, BR-16-034
    Biết `tc-ket-noi-moi` bản 1 `DRAFT` có công thức hợp lệ.
    Khi `PATCH …/versions/1` với `target = {baseline: 60, target: 95, targetDate: 2026-12-31, targetMode: ABSOLUTE}`, `thresholds = {greenFrom: 90, amberFrom: 70}`, `direction = HIGHER_BETTER`, `decimals = 1`
    Và `PATCH` chiều thấp tốt cho `tre-gateway-p95` bản nháp: `direction = LOWER_BETTER`, `thresholds = {greenFrom: 200, amberFrom: 300}`
    Và `PATCH` kiểu khoảng: `direction = TARGET_RANGE`, `thresholds = {range: {low: 80, high: 100, tolerance: 5}}`
    Thì cả ba `200`; `GET …/versions/1` trả đúng `target`, `thresholds`, `decimals`. Vùng `GREEN`, `AMBER`, `RED` suy ra theo chiều tốt (BR-16-015).

  @TC-16-010 @P1 @Âm
  Kịch bản: TC-16-010 Ngưỡng không đơn điệu hoặc ngoài miền
    # Truy vết: FR-16-004 · API-16-007 · ERR-16-010, ERR-16-003
    Biết `tc-ket-noi-moi` bản 1 `DRAFT`.
    Khi `PATCH` với `direction = HIGHER_BETTER`, `greenFrom = 60`, `amberFrom = 80`
    Và `PATCH` với `direction = LOWER_BETTER`, `greenFrom = 300`, `amberFrom = 200`
    Và `PATCH` với `decimals = 5`
    Và `PATCH` với `targetMode = RELATIVE_TO_BASELINE` nhưng thiếu `baseline`
    Thì bước 1, 2 `422` ERR-16-010, `errors[]` trỏ `thresholds`. Bước 3, 4 `400` ERR-16-003. Không đổi dữ liệu.
