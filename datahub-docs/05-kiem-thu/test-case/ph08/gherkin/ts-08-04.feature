# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-04
Tính năng: TS-08-04 · Hồ sơ dữ liệu và gợi ý quy tắc

  @TC-08-019 @P1 @Dương
  Kịch bản: TC-08-019 Chạy hồ sơ dữ liệu và xem thẻ cột
    # Truy vết: FR-08-008, 009 · API-08-019, 020, 021, 022 · UI-08-05 · BR-08-025 · NFR-08-013
    Biết `src-hotich` `ACTIVE` với F-HT (5.000 dòng, cột `cccd` Nhạy cảm, 4,2 % `ten_cha` rỗng); U-T90-DS1.
    Khi `POST /assets/src-hotich/profile-runs` `{mode: SAMPLE, sampleSize: 5000}`
    Và poll `GET /profile-runs/{runId}` đến `SUCCEEDED`
    Và `GET /profile-runs/{runId}/columns`
    Thì bước 1 `202`, `status = QUEUED`, `Location` tới API-08-021. Bước 3 mỗi cột có `nullRatio`, `distinctEstimate`, `min`, `max`, `quantiles`, `topPatterns`, `inferredType`; `ten_cha.nullRatio` = 0,042 ± 0,001; `distinctEstimate` lệch ≤ 2 % so với đếm chính xác. Truy vấn lên nguồn chỉ `SELECT`.

  @TC-08-020 @P1 @Âm
  Kịch bản: TC-08-020 Hồ sơ cho bản tin luồng, mẫu sai, đang chạy, nguồn lỗi
    # Truy vết: FR-08-008 · API-08-019 · ERR-08-111 · ERR-08-050, 030, 028
    Biết `flow-hotich` (`FLOW_MESSAGE`); `src-hotich`; một lần hồ sơ `RUNNING`; `conn-sim` có thể ngắt.
    Khi `POST /assets/flow-hotich/profile-runs`
    Và `POST /assets/src-hotich/profile-runs` `{mode: SAMPLE, sampleSize: 50}`
    Và `POST` hồ sơ lần hai khi lần một còn `RUNNING`
    Và ngắt `conn-sim` rồi chạy hồ sơ mới
    Thì bước 1 `422` ERR-08-050. Bước 2 `422` ERR-08-030. Bước 3 `409` ERR-08-028. Bước 4 lần hồ sơ `FAILED`, UI-08-05 và PH-13 nhận ERR-08-111; điểm không đổi.

  @TC-08-021 @P1 @Bảo @mật @Âm
  Kịch bản: TC-08-021 Hồ sơ cột Nhạy cảm không lưu giá trị phổ biến, chưa có hồ sơ
    # Truy vết: FR-08-008, 009 · API-08-022 · BR-08-012 · NFR-08-016 · PERM-08-finding-read
    Biết `src-hotich.cccd` `SENSITIVE`, đặt canary `DH-CANARY-prof` vào một dòng; U-T90-DS1 (có `PERM-08-finding-read`), U-T90-TA (không có).
    Khi chạy hồ sơ
    Và DS1 `GET /profile-runs/{runId}/columns`
    Và TA `GET` cùng đường dẫn
    Và quét `ph08_dq`, log, vết OTel tìm `DH-CANARY-prof`
    Và `GET /profile-runs/{runId}/columns` của đối tượng `src-moi` chưa chạy hồ sơ
    Thì cột `cccd` chỉ có `topPatterns` (ví dụ `\d{12}`) và số đếm, không có `topValues`. `topValues` của cột không Nhạy cảm chỉ hiện cho DS1, TA thấy rỗng. Quét canary 0 kết quả (Mồi sạch). Bước 5 `404` ERR-08-001 (chưa có hồ sơ).

  @TC-08-022 @P3 @Dương @Âm
  Kịch bản: TC-08-022 Gợi ý quy tắc từ hồ sơ
    # Truy vết: FR-08-010 · API-08-023, 031 · UI-08-05 · ERR-08-022
    Biết hồ sơ `SUCCEEDED` của `src-hotich`; bộ `RS-HOTICH` chưa có nháp.
    Khi `POST /profile-runs/{runId}:suggest-rules`
    Và chọn 2 gợi ý, sửa tham số một gợi ý rồi `POST /rule-sets/RS-HOTICH/versions/1/rules`
    Và DS2 lặp bước 2 khi nháp do DS1 tạo
    Thì bước 1 `200`, `suggestions[]` có `dimension`, `operator`, `target`, `params`, `confidence`, `evidence` (ví dụ `NOT_NULL` cho cột `nullRatio < 1 %`, `REGEX` từ `topPatterns`). Bước 2 quy tắc vào bản nháp với `source = SUGGESTED`. Bước 3 `409` ERR-08-022.

  @TC-08-023 @P3 @Dương @Âm
  Kịch bản: TC-08-023 Nhận chỉ số hồ sơ từ PH-05
    # Truy vết: FR-08-011 · API-08-024 · ERR-08-118
    Biết tài khoản dịch vụ `S-T90-PH05` (mTLS); lô chỉ số hợp lệ và một lô thiếu trường `nullRatio`.
    Khi `POST /internal/profile-metrics` lô hợp lệ
    Và gửi lô thứ hai cùng cửa sổ
    Và gửi lô sai định dạng
    Và `GET /assets/src-hotich/profile-runs`
    Thì bước 1 `202`, `accepted`, `ignored`. Bước 2 cộng dồn. Bước 3 `422` ERR-08-118, hiển thị cho vận hành ở PH-13. Bước 4 có lần hồ sơ `mode = EXTERNAL`, UI-08-05 ghi nguồn "PH-05".
