# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-12
Tính năng: TS-08-12 · Tính điểm có trọng số, so kỳ trước và xu hướng

  @TC-08-062 @P1 @Dương
  Kịch bản: TC-08-062 Điểm sáu chiều và điểm tổng theo ví dụ số
    # Truy vết: FR-08-028 · API-08-065 · UI-08-12 · BR-08-002, 022, 023 · NFR-08-007
    Biết F-SCORE-1 (bảng 2.4) với trọng số mặc định 0,20/0,20/0,15/0,10/0,15/0,20; mỗi chiều một quy tắc.
    Khi chạy lần đo `FULL` của `mdm-citizen`
    Và `GET /scans/{id}/score`
    Và UT tính điểm với ví dụ của FRS (91,2; 88,0; 79,5; 72,0; 96,0; 85,0)
    Thì điểm chiều 98,00 (COMPLETENESS), 95,00 (ACCURACY), 80,00 (CONSISTENCY), 90,00 (TIMELINESS), 99,00 (UNIQUENESS), 85,00 (VALIDITY). Điểm tổng = 98×0,20 + 95×0,20 + 80×0,15 + 90×0,10 + 99×0,15 + 85×0,20 = 91,45; `verdict = PASS`; không cờ. Ảnh chụp ghi `ruleSetVersionId`, `weightConfigId`; từng chiều ghi `rulesPassed`, `rulesFailed`, `rulesSkipped`. EVT: `scan.completed` kèm `score = 91.45`. Ví dụ thứ hai của FRS cho 86,365, làm tròn nửa lên 86,37, `PASS` với ngưỡng 80.

  @TC-08-063 @P1 @Dương @Biên
  Kịch bản: TC-08-063 Chiều bị bỏ qua và cờ INCOMPLETE_DIMENSIONS
    # Truy vết: FR-08-028, 031 · API-08-065 · UI-08-12 · BR-08-022 · ERR-08-108
    Biết như score-formula nhưng `rdm-sim` trả `503` suốt lần đo nên `R-GT-RDM` là `SKIPPED`.
    Khi chạy lần đo `FULL`
    Và `GET /scans/{id}/score`
    Thì điểm VALIDITY rỗng (`null`), `skippedCount ≥ 1`. Điểm tổng chuẩn hóa trên năm chiều: (19,60 + 19,00 + 12,00 + 9,00 + 14,85) / 0,80 = 74,45 / 0,80 = 93,06; `verdict = PASS`; cờ `INCOMPLETE_DIMENSIONS`; UI-08-12 tô xám chiều VALIDITY kèm lý do. Không dùng 91,45 và không tính VALIDITY bằng 0.

  @TC-08-064 @P1 @Âm
  Kịch bản: TC-08-064 Mọi quy tắc bị bỏ qua thì không có điểm
    # Truy vết: FR-08-028 · API-08-065 · UI-08-12 · ERR-08-108
    Biết đối tượng `rdm-only` chỉ có quy tắc `IN_RDM`; `rdm-sim` trả `503`.
    Khi chạy lần đo
    Và `GET /scans/{id}/score`
    Thì lần đo kết thúc có ảnh chụp với `score = null`, `verdict` rỗng, cờ `INCOMPLETE_DIMENSIONS`, dòng "Không đủ dữ liệu để tính điểm cho lần đo {mã}."; không có điểm 0 giả; không phát EVT-08-05.

  @TC-08-065 @P2 @Dương
  Kịch bản: TC-08-065 POOLED và RULE_AVERAGE
    # Truy vết: FR-08-028 · API-08-065 · BR-08-022 · ERR-08-042
    Biết chiều CONSISTENCY có hai quy tắc, trọng số quy tắc bằng nhau: `R-A` pass 900 fail 100 (90,00); `R-B` pass 100 fail 100 (50,00).
    Khi đo với `08.score.dimension-method = POOLED`
    Và đổi tham số thành `RULE_AVERAGE`, đo lại cùng dữ liệu
    Và đặt tham số `TRUNG_BINH`
    Thì POOLED: 100 × 1.000 / 1.200 = 83,33. RULE_AVERAGE: (90,00 + 50,00) / 2 = 70,00. Bước 3 `422` ERR-08-042.

  @TC-08-066 @P1 @Dương
  Kịch bản: TC-08-066 Ngoại lệ và ERROR không vào mẫu số
    # Truy vết: FR-08-028 · FR-08-040 · API-08-065 · BR-08-021, 022
    Biết `R-CCCD-NN` pass 9.800, fail 200 trong đó 50 lỗi thuộc ngoại lệ `ACTIVE`; quy tắc `R-X` `ERROR`.
    Khi đo
    Và `GET /scans/{id}/score`
    Thì mẫu số của `R-CCCD-NN` = 9.800 + 150 = 9.950; điểm 100 × 9.800 / 9.950 = 98,49; `waivedCount = 50` hiển thị riêng; `R-X` không có trong mẫu số.

  @TC-08-067 @P1 @Biên
  Kịch bản: TC-08-067 Kết luận ở các ngưỡng biên
    # Truy vết: FR-08-028 · API-08-065 · BR-08-023 · EVT-08-05
    Biết ngưỡng 80/70; bộ dữ liệu cài sẵn cho điểm 80,00; 79,99; 70,00; 69,99; lần đo trước điểm 90.
    Khi đo bốn lần với bốn bộ dữ liệu
    Và ghi `verdict`
    Và đếm EVT-08-05 theo lần đo
    Thì 80,00 → `PASS`; 79,99 → `WARN`; 70,00 → `WARN`; 69,99 → `FAIL`. EVT: `score.threshold-breached` (EVT-08-05) chỉ khi chuyển từ `PASS` hoặc `WARN` sang `FAIL` hoặc xuống dưới ngưỡng cảnh báo lần đầu, không lặp ở lần `FAIL` kế tiếp.

  @TC-08-068 @P1 @Dương
  Kịch bản: TC-08-068 So kỳ trước và xu hướng
    # Truy vết: FR-08-029 · API-08-065, 066 · UI-08-04, 12 · BR-08-024 · EVT-08-04
    Biết `src-hotich` chưa từng đo; tháng 1 điểm 91,45; tháng 2 điểm 85,00; tháng 3 điểm 85,75; tháng 4 điểm 87,30.
    Khi đo tháng 1
    Và đo tháng 2
    Và đo tháng 3
    Và đo tháng 4
    Và `GET /assets/src-hotich/score-history`
    Thì tháng 1 `trend = BASELINE`. Tháng 2 Δ = −6,45 → `DEGRADED`, EVT: `score.degraded` (EVT-08-04) vì giảm ≥ 5,0. Tháng 3 Δ = +0,75 → `STABLE`. Tháng 4 Δ = +1,55 → `IMPROVED`. `series[]` đủ bốn điểm, mỗi điểm có `score`, `trend`.

  @TC-08-069 @P2 @Dương
  Kịch bản: TC-08-069 Khác cấu hình trọng số, khác phiên bản quy tắc
    # Truy vết: FR-08-029 · API-08-065 · BR-08-008
    Biết hai ảnh chụp liên tiếp khác `weightConfigId` và khác phiên bản bộ quy tắc (thêm `R-NEW`, bớt `R-OLD`).
    Khi `GET /scans/{id}/score`
    Thì `flags` có `WEIGHTS_CHANGED`; thân ghi danh sách quy tắc thêm (`R-NEW`) và bớt (`R-OLD`); Δ vẫn tính.

  @TC-08-070 @P3 @Âm
  Kịch bản: TC-08-070 Chưa có ảnh chụp nào
    # Truy vết: FR-08-029 · API-08-065, 066
    Biết đối tượng `src-moi` `ACTIVE` chưa có lần đo thành công.
    Khi `GET /assets/src-moi/score-history`
    Thì `404` ERR-08-001 theo ngữ cảnh "chưa có lần đo nào thành công".
