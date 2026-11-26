# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-07
Tính năng: TS-17-07 · Khai báo mô hình, phiên bản và duyệt phiên bản bốn mắt

  @TC-17-021 @P1 @Dương
  Kịch bản: TC-17-021 Phiên bản mô hình đi hết vòng đời tới APPROVED rồi RETIRED
    # Truy vết: FR-17-008, 009 · API-17-034, 037, 040, 041, 043, 154 · BR-17-014, 015 · EVT-17-07 · UI-17-20
    # Mục đích: Chứng minh trạng thái hợp lệ, cổng phát hành và EVT ở từng bước.
    Biết `P-INT-1` `ACTIVE`; bộ đánh giá `ES-SEARCH-1`, bộ ca đỏ 66 ca (mục 2.5); LLM-MOCK đạt điểm 0,86 và chặn 100 %; U-PA1 (đề nghị), U-T90-TA1 (duyệt), U-T90-SO.
    Khi PA1 `POST /models` rồi `POST /models/{id}/versions` (`DRAFT`).
    Và PA1 `POST /model-versions/{vid}:submit-eval`; chờ `EvalRun` và `RedteamRun` xong.
    Và `GET /release-gates/model-version/{vid}`.
    Và TA1 `POST /model-versions/{vid}:approve`.
    Và U-T90-IE gửi câu hỏi buộc dùng phiên bản này sau khi bật cho tenant.
    Và PA1 `POST /model-versions/{vid}:retire`.
    Thì bước 1 `DRAFT`. Bước 2 `EVALUATING`, EVT: `assist.eval.run-completed`, `assist.redteam.run-completed`. Bước 3 cổng `OPEN`: điểm 0,86 ≥ `17.eval.min-score` (0,80), ca đỏ 66/66. Bước 4 `200`, `APPROVED`, KT: có, EVT: `assist.model-version.state-changed`. Bước 5 `200`, vết ghi phiên bản. Bước 6 `RETIRED`, lời gọi mới bị từ chối.

  @TC-17-022 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-022 Duyệt khi chưa đạt điều kiện, người duyệt trùng người đề nghị, dùng bản chưa duyệt
    # Truy vết: FR-17-009 · API-17-040, 041, 042, 154 · BR-17-014, 015 · ERR-17-005, 029, 030
    # Mục đích: Chứng minh bốn mắt, điều kiện đánh giá và ca đỏ, và chỉ `APPROVED` mới được định tuyến.
    Biết phiên bản `MV-LOW` (LLM-MOCK điểm 0,70) và `MV-LEAK` (một ca đỏ lọt); U-PA1, U-T90-TA1.
    Khi PA1 `:submit-eval` rồi PA1 `:approve` chính phiên bản `MV-OK` mình đề nghị.
    Và TA1 `:approve` `MV-LOW`.
    Và TA1 `:approve` `MV-LEAK`.
    Và TA1 `:approve` phiên bản còn `DRAFT`.
    Và U-T90-TA1 `PUT /tenant-models/defaults` chọn phiên bản `DRAFT`.
    Và TA1 `:reject` `MV-LOW` kèm lý do.
    Thì bước 1 `403` ERR-17-005. Bước 2 `409` ERR-17-029 nêu "điểm đánh giá 0,70 thấp hơn 0,80". Bước 3 `409` ERR-17-029 nêu ca đỏ lọt và dẫn ERR-17-073. Bước 4 `409` ERR-17-029 (chưa qua `EVALUATING`). Bước 5 `409` ERR-17-030. Bước 6 `200` về `DRAFT`, EVT trạng thái.

  @TC-17-023 @P2 @Âm
  Kịch bản: TC-17-023 Phiên bản đã ngừng không sửa được, mô hình thiếu năng lực
    # Truy vết: FR-17-008, 009 · API-17-036, 039, 043 · ERR-17-040, 003, 002
    # Mục đích: Chứng minh tính bất biến của phiên bản `RETIRED` và kiểm dữ liệu khai báo.
    Biết phiên bản `MV-OLD` `RETIRED`; U-PA1.
    Khi PA1 `PATCH /model-versions/{id}` đổi giới hạn ngữ cảnh của `MV-OLD`.
    Và PA1 `POST /models` với `kind = CHAT` nhưng `contextTokens = 0`.
    Và PA1 `POST /models` trùng mã `code`.
    Thì bước 1 `409` ERR-17-040. Bước 2 `400` ERR-17-003 nêu trường. Bước 3 `409` ERR-17-002.
