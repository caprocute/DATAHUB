# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-11
Tính năng: TS-16-11 · Tính giá trị, độ đầy đủ, trạng thái và điểm nhóm

  @TC-16-045 @P1 @Dương
  Kịch bản: TC-16-045 Tính giá trị chỉ tiêu bằng công thức CEL và lưu dòng truy nguồn
    # Truy vết: FR-16-019 · API-16-053, 054, 043 · UI-16-09 · BR-16-001, BR-16-002, BR-16-034
    Biết T90; `httt-ket-noi-ty-le` bản 1 `ACTIVE`; quan sát kỳ `M-2026-10`: `ph01.httt.connected` = 150, `ph01.httt.total` = 200.
    Khi chạy tổng hợp `M-2026-10`
    Và `GET /runs/{runId}/values?indicatorCode=httt-ket-noi-ty-le`
    Và `GET /values/{valueId}/lineage`
    Và chạy tổng hợp `Q-2026-Q3` cho chỉ tiêu thử có tháng 70, 75, 80
    Thì `value = 75`, `displayValue` theo `decimals`, `versionUsed = 1`, `status = AT_RISK`, `threshold = AMBER`. `lineage.formula` là công thức đang hiệu lực, `inputs[]` có hai phần tử với `observationId` thật và `value` 150, 200 (BR-16-001). Giá trị lưu đủ 6 chữ số thập phân. Quý gộp từ giá trị tháng con (không đọc lại quan sát): `AVG` 75, `SUM` 225, `MAX` 80, `MIN` 70, `LAST` 80.

  @TC-16-046 @P1 @Dương @Biên
  Kịch bản: TC-16-046 Nhiều nguồn cùng chỉ số: lấy nguồn ưu tiên cao nhất
    # Truy vết: FR-16-019 · API-16-054, 043 · BR-16-014
    Biết T90; hai nguồn cùng `ph13.dataplane.availability` kỳ `M-2026-10`: `src-ph13` `priority = 1` giá trị 99,5, `tc-nguon-phu` `priority = 2` giá trị 98,0; `src-ph13` có hai quan sát, nhận lúc 08:00 giá trị 99,4 và lúc 09:00 giá trị 99,5.
    Khi chạy tổng hợp
    Và `GET /values/{valueId}/lineage` của `san-sang-data-plane`
    Và tạm dừng `src-ph13` rồi chạy lại
    Thì bước 2 dùng 99,5 (nguồn `priority` cao nhất, quan sát mới nhất theo `receivedAt`). Bước 3 khi `src-ph13` `PAUSED` thì lấy 98,0 từ nguồn kế tiếp có số. Dòng truy nguồn ghi đúng `observationId` được chọn.

  @TC-16-047 @P1 @Âm
  Kịch bản: TC-16-047 Công thức lỗi khi tính: chia cho 0
    # Truy vết: FR-16-019, FR-16-020 · API-16-053 · ERR-16-109 · BR-16-007
    Biết T90; kỳ có `ph01.httt.total` = 0; các chỉ tiêu khác bình thường.
    Khi chạy tổng hợp
    Và `GET /runs/{runId}/values?status=NO_DATA`
    Và `GET /runs/{runId}`
    Thì `httt-ket-noi-ty-le` có `value` trống, `completeness = NO_DATA`, `flags` có `FORMULA_ERROR`; không điền 0. 23 chỉ tiêu còn lại vẫn tính. Lần chạy `PARTIAL`, `errorCode` trống (lỗi theo chỉ tiêu).

  @TC-16-048 @P1 @Dương @Biên
  Kịch bản: TC-16-048 Thiếu nguồn: PARTIAL, cờ, không bịa số
    # Truy vết: FR-16-020 · API-16-051, 053, 048 · ERR-16-111, ERR-16-112, ERR-16-107 · BR-16-007, BR-16-030 · UI-16-09
    Biết T94; kỳ `M-2026-10`; nguồn PH-13 `FAILED` (5 chỉ tiêu dùng riêng PH-13: `san-sang-data-plane`, `tre-gateway-p95`, `nhat-ky-khai-thac-du`, `mttd`, `mttr-muc-1`); 1 chỉ tiêu có số tay `SUBMITTED`; kỳ trước có số.
    Khi chạy tổng hợp
    Và `GET /runs/{runId}`
    Và `GET /runs/{runId}/values?completeness=NO_DATA`
    Và `GET /periods/M-2026-10`
    Thì lần chạy `PARTIAL`, `completeness` = (24 − 6) / 24 = `0,75` với 6 chỉ tiêu `NO_DATA` (5 của PH-13 và 1 chờ xác nhận tay), `flags` gồm `MISSING_SOURCE`, `STALE_SOURCE`, `MANUAL_PENDING`. Chỉ tiêu `NO_DATA` có `missingMetrics` đủ, không nội suy, không lấy số kỳ trước, không bằng 0 (BR-16-007). Kỳ báo `completeness` và cờ.

  @TC-16-049 @P1 @Dương @Biên
  Kịch bản: TC-16-049 Trạng thái theo ngưỡng ba mức, hai chiều tốt, làm tròn
    # Truy vết: FR-16-021, FR-16-019 · API-16-053 · BR-16-015, BR-16-034 · UI-16-01, UI-16-02
    Biết `httt-ket-noi-ty-le` (HIGHER_BETTER, `greenFrom` 90, `amberFrom` 70); `tre-gateway-p95` (LOWER_BETTER, 200, 300, đơn vị ms); chỉ tiêu `RELATIVE_TO_BASELINE` `baseline` 60, mục tiêu +50 %.
    Khi đặt giá trị 95, 90, 89,99, 70, 69,99 cho chỉ tiêu thứ nhất và đọc `status`, `threshold`
    Và đặt 150, 200, 250, 300, 350 cho `tre-gateway-p95`
    Và chỉ tiêu `NO_DATA`
    Và chỉ tiêu `decimals = 0`, `greenFrom` 90 nhận 89,96; chỉ tiêu khác nhận 2 trên 3 nhân 100
    Thì chỉ tiêu thứ nhất: 95 → `ON_TRACK`/`GREEN`; 90 → `ON_TRACK`; 89,99 → `AT_RISK`/`AMBER`; 70 → `AT_RISK`; 69,99 → `OFF_TRACK`/`RED`. `tre-gateway-p95`: 150, 200 → `ON_TRACK`; 250, 300 → `AT_RISK`; 350 → `OFF_TRACK`. Chỉ tiêu tương đối quy đổi ngưỡng từ giá trị nền trước khi so. `NO_DATA` giữ `NO_DATA`. Bước 4 `value = 89,96`, `displayValue = "90"`, `status = AT_RISK` (so trên giá trị chưa làm tròn); chỉ tiêu kia `value = 66,666667` (6 chữ số thập phân).

  @TC-16-050 @P1 @Dương @Âm
  Kịch bản: TC-16-050 Sự kiện chệch chỉ phát khi trạng thái đổi; đổi ngưỡng không đổi kỳ đã chốt
    # Truy vết: FR-16-021 · API-16-056 · EVT-16-06 · BR-16-017, BR-16-033
    Biết T90; `httt-ket-noi-ty-le` kỳ `M-2026-10` đang `ON_TRACK` ở lần chạy trước (giá trị 95).
    Khi đẩy số trễ làm giá trị còn 75, chạy lại
    Và chạy lại lần nữa với dữ liệu không đổi
    Và đẩy số làm giá trị còn 95, chạy lại
    Và đẩy số làm chỉ tiêu `NO_DATA`
    Và `GET /periods/M-2026-10/status-changes`
    Và duyệt bản mới của chỉ tiêu đổi `thresholds`, đọc lại giá trị kỳ `M-2026-09` đã chốt
    Thì lần 1 phát một EVT-16-06 (`ON_TRACK` → `AT_RISK`). Lần 2 không phát (BR-16-017). Lần 3 phát một (về `ON_TRACK`). Lần 4 không phát EVT-16-06 (chuyển `NO_DATA` dựa cảnh báo nguồn). `status-changes` có đúng các thay đổi, `from`, `to`, `runId`, `at`. Bước 6 trạng thái và điểm của kỳ đã chốt không đổi (BR-16-033).

  @TC-16-051 @P1 @Dương
  Kịch bản: TC-16-051 Điểm nhóm, điểm tổng, xu hướng và chênh lệch
    # Truy vết: FR-16-022, FR-16-007 · API-16-090 · UI-16-01 · BR-16-016
    Biết T90; F-KY-1 (bảng 2.4); trọng số 30/20/20/15/15; `M-2026-09` có `overallScore` 60,00.
    Khi `GET /dashboard?periodCode=M-2026-10&view=LATEST`
    Và `GET /dashboard?periodCode=M-2026-10&compareTo=M-2026-09`
    Thì `groups[]`: `KET_NOI` 50,00, `CHIA_SE` 100,00, `DU_LIEU` 75,00, `VAN_HANH` 60,00, `KIEN_TRUC` 50,00 (`NO_DATA` bị loại khỏi trung bình), `coverage` mỗi nhóm = số chỉ tiêu có số / tổng (ví dụ `KET_NOI` 0,75). `overallScore = 66,5`. `statusCounts = {ON_TRACK: 12, AT_RISK: 5, OFF_TRACK: 3, NO_DATA: 4}`. So kỳ trước `delta = +6,5`, `trend = UP`.
