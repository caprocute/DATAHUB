# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-08
Tính năng: TS-06-08 · Bộ quy tắc đối sánh, khóa gom nhóm và ngưỡng

  @TC-06-033 @P1 @Dương
  Kịch bản: TC-06-033 Soạn bộ quy tắc xác định, xác suất, loại trừ
    # Truy vết: FR-06-018 · API-06-030, 031, 032, 104 · UI-06-09 · PERM-06-config
    # Mục đích: Chứng minh bộ quy tắc có đủ ba `MatchRuleType` và các `Comparator`, theo FR-06-018.
    Biết CITIZEN `ACTIVE`; DS1.
    Khi `POST .../rule-sets` phiên bản 1 `DRAFT`.
    Và `PUT .../rule-sets/1` với: `DETERMINISTIC` `idNumber`; `PROBABILISTIC` `fullName` `NAME_VN` trọng số 4, `dateOfBirth` `DATE_TOLERANCE`, `phone` `PHONE`; `EXCLUSION` khóa định danh khác nhau.
    Thì `200`, lưu đủ ba loại, `ETag` mới; `GET` trả đúng. KT: có (ruleset-update).
    # Hậu điều kiện: Bộ quy tắc v1 DRAFT dùng ở các ca sau.

  @TC-06-034 @P1 @Âm
  Kịch bản: TC-06-034 Bỏ quy tắc loại trừ, comparator sai
    # Truy vết: FR-06-018 · BR-06-006 · API-06-032 · ERR-06-003, 022
    # Mục đích: Chứng minh quy tắc loại trừ khóa định danh khác nhau không tắt được, theo BR-06-006.
    Biết bộ quy tắc v1 DRAFT.
    Khi `PUT` xóa quy tắc `EXCLUSION` khóa định danh.
    Và `PUT` đặt `enabled = false` cho nó.
    Và `PUT` `Comparator = SOUNDEX`.
    Thì bước 1, 2 `422` ERR-06-022 (BR-06-006). Bước 3 `400` ERR-06-003.
    # Hậu điều kiện: Bộ quy tắc không đổi.

  @TC-06-035 @P2 @Dương
  Kịch bản: TC-06-035 Khóa gom nhóm và thống kê hiệu quả
    # Truy vết: FR-06-019 · API-06-036 · NFR-06-006 · BR-06-016 · UI-06-09
    # Mục đích: Chứng minh gom nhóm giảm tập so sánh và dùng HMAC cho thuộc tính nhạy cảm, theo FR-06-019.
    Biết T97 F-PERF; bộ quy tắc có khóa gom `nameKey + năm sinh`, `phone`.
    Khi `GET .../rule-sets/1/blocking-stats`.
    Và kiểm khối chứa giá trị `idNumber` trong bảng khóa gom.
    Thì bước 1 số ứng viên trung bình mỗi lượt ≤ 50, độ phủ cặp đúng ≥ 99,5 % trên F-LBL; khối > 200 cắt, tăng `mdm_block_truncated_total`. Bước 2 chỉ có HMAC, không rõ.
    # Hậu điều kiện: Không đổi.

  @TC-06-036 @P1 @Dương @Âm
  Kịch bản: TC-06-036 Đặt ngưỡng trong và ngoài miền
    # Truy vết: FR-06-023 · BR-06-020 · API-06-032 · ERR-06-023 · UI-06-09
    # Mục đích: Chứng minh ngưỡng tự hợp nhất ≥ 0,90 và cách ngưỡng xem xét ≥ 0,10, theo BR-06-020.
    Biết bộ quy tắc v1 DRAFT.
    Khi đặt `autoMergeThreshold = 0,92`, `reviewThreshold = 0,15`.
    Và đặt `0,85`.
    Và đặt `0,92` và `reviewThreshold = 0,85`.
    Và đổi ngưỡng ở bản `ACTIVE`.
    Thì bước 1 `200`. Bước 2, 3 `422` ERR-06-023. Bước 4 `422` ERR-06-008 (cần phiên bản mới, đánh giá lại).
    # Hậu điều kiện: v1 ngưỡng 0,92/0,15.
