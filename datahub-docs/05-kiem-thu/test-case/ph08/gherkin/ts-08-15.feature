# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-15
Tính năng: TS-08-15 · Kiểm tra trực tuyến bản ghi và bước trong luồng PH-04

  @TC-08-079 @P1 @Dương
  Kịch bản: TC-08-079 Kết luận PASS, WARN, FAIL ở chế độ STRICT
    # Truy vết: FR-08-032 · API-08-068, 071, 072 · UI-08-20 · BR-08-016 · PERM-08-rule-admin
    Biết `mdm-citizen` bật trực tuyến `STRICT`, `FAIL_OPEN`; `RS-CITIZEN` v5 `ACTIVE` (`R-CCCD-NN` `CRITICAL`, `R-CAPNHAT` `MINOR`); `S-T90-PH04` scope `dq.check`.
    Khi `PUT /assets/mdm-citizen/inline-config` `{inlineEnabled: true, inlineMode: STRICT, onDependencyFailure: FAIL_OPEN}`
    Và `POST /checks:evaluate` bản ghi hợp lệ
    Và bản ghi thiếu `nationalId`
    Và bản ghi chỉ cũ hơn 365 ngày
    Và `GET /assets/mdm-citizen/inline-config`
    Và bản ghi thiếu `nationalId` và `birthDate` với `failFast = true`
    Thì bước 2 `200` `PASS`. Bước 3 `FAIL`, `violations[]` có `ruleCode`, `dimension`, `severity`, `fieldPath`, `message`, không chứa giá trị. Bước 4 `WARN` (chỉ `MINOR`). Mỗi phản hồi có `evaluatedRules`, `durationMs`, `ruleSetVersion = 5`. Bước 5 trả cấu hình đang đặt. Bước 6 dừng ở quy tắc `CRITICAL` đầu tiên vi phạm, `violations[]` có đúng một phần tử, `durationMs` nhỏ hơn bước 3. EVT: `check.failed` (EVT-08-13) gộp theo phút.

  @TC-08-080 @P1 @Dương
  Kịch bản: TC-08-080 ADVISORY không bao giờ FAIL, có vi phạm thì WARN
    # Truy vết: FR-08-032 · FR-08-033 · API-08-068, 071 · BR-08-016
    Biết như chk-verdict nhưng `mode = ADVISORY`.
    Khi `POST /checks:evaluate` bản ghi thiếu `nationalId` (`CRITICAL`)
    Và `POST /checks:evaluate` bản ghi hợp lệ
    Thì bước 1 `200`, `verdict = WARN` (không bao giờ `FAIL`) kèm `violations[]` có quy tắc `CRITICAL`; bước 2 `200`, `verdict = PASS`, `violations[]` trống (BR-08-016). Bản tin trong luồng luôn đi tiếp, chỉ gắn tiêu đề.

  @TC-08-081 @P1 @Âm
  Kịch bản: TC-08-081 Bản ghi sai lược đồ, chưa bật trực tuyến, thiếu scope, tenant khác
    # Truy vết: FR-08-032 · API-08-068 · ERR-00-403 · BR-08-026 · ERR-08-101, 102
    Biết đối tượng `src-hotich` chưa bật trực tuyến; bản ghi 70 KB; `S-T90-NOSCOPE` không có `dq.check`; `S-T91-PH04` (T91 có `mdm-citizen` riêng).
    Khi `POST /checks:evaluate` bản ghi sai kiểu `birthDate`
    Và bản ghi 70 KB
    Và `POST /checks:evaluate` cho `src-hotich`
    Và `S-T90-NOSCOPE` gọi
    Và `S-T91-PH04` gọi `mdm-citizen` với bộ quy tắc khác
    Thì bước 1 và 2 `422` ERR-08-101. Bước 3 `404` ERR-08-102. Bước 4 `403` ERR-00-403. Bước 5 dùng bộ quy tắc của T91, không dùng của T90 (bộ đệm theo tenant).

  @TC-08-082 @P2 @Dương
  Kịch bản: TC-08-082 Chỉ quy tắc cho phép trực tuyến được chạy
    # Truy vết: FR-08-032 · API-08-068, 069 · BR-08-017 · ERR-08-101
    Biết `RS-CITIZEN` có `UNIQUE_IN_ASSET`, `EQ_SOURCE`, `SQL_PREDICATE`, CEL gán `INLINE`; `evaluate-batch` 100 và 101 bản ghi.
    Khi `POST /checks:evaluate`
    Và xem `evaluatedRules`
    Và `POST /checks:evaluate-batch` 100 bản ghi
    Và 101 bản ghi
    Thì `evaluatedRules` không gồm `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE`. Batch 100 trả 100 kết luận đúng thứ tự. Batch 101 bị từ chối cả lô `422` ERR-08-101.

  @TC-08-083 @P1 @Dương @Âm
  Kịch bản: TC-08-083 Kamelet dh-dq-check trong luồng PH-04
    # Truy vết: FR-08-033 · API-08-068 · UI-08-20 · BR-08-016, 018 · EVT-08-13
    Biết luồng `lgsp-hotich` (PH-04 giả lập `flow-sim`) có bước `dh-dq-check` trỏ `mdm-citizen`; `S-T90-PH04`.
    Khi `onFail = STOP_TO_DLQ`, `STRICT`: gửi bản tin `FAIL`
    Và `onFail = CONTINUE_WITH_HEADER`
    Và `ADVISORY`
    Và trỏ bước tới đối tượng chưa bật trực tuyến
    Thì bước 1 bản tin vào DLQ lý do `DQ_FAIL` kèm tiêu đề `dh-dq-verdict`, `dh-dq-violations`. Bước 2 đi tiếp kèm tiêu đề. Bước 3 luôn đi tiếp. Bước 4 runtime ghi cảnh báo luồng "Bước kiểm tra chất lượng trỏ tới đối tượng src-hotich chưa bật trực tuyến." và áp `onUnavailable`.
