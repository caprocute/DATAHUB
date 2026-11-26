# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-05
Tính năng: TS-02-05 · Kiểm tra đặc tả hai lớp

  @TC-02-017 @P1 @Âm
  Kịch bản: TC-02-017 Đặc tả không đạt lớp 1 chặn gửi duyệt
    # Truy vết: FR-02-016 · API-02-020, 021 · UI-02-04 · ERR-02-006, 005.
    Biết API nháp nạp F-SPEC-L1.
    Khi `POST …/lint-runs`.
    Và `GET …/lint-results`; mở UI-02-04, bấm nhảy tới lỗi.
    Thì có lỗi mức `ERROR` kèm dòng, cột, đường dẫn JSON; thao tác gửi duyệt trả `422` ERR-02-006; UI tô sáng đúng dòng.

  @TC-02-018 @P1 @Dương @Âm
  Kịch bản: TC-02-018 Lớp 2: lỗi nghiêm trọng chặn, cảnh báo cho phép chấp nhận kèm lý do
    # Truy vết: FR-02-016, 017 · API-02-020, 021, 092 · BR-02-002, 028 · ERR-02-007, 041 · KT: có (lint.acknowledge).
    Biết F-SPEC-L2; U-T68-SV1.
    Khi chạy kiểm tra; ghi số lỗi và cảnh báo.
    Và `:acknowledge` một cảnh báo không kèm lý do, rồi kèm lý do.
    Và sửa đặc tả thiếu mô tả tổng thể để hết lỗi nghiêm trọng.
    Thì bước 1: có lỗi nghiêm trọng ERR-02-007. Bước 2: `400` ERR-02-041 rồi `200`, có kiểm toán. Bước 3: cảnh báo ngôn ngữ chỉ cảnh báo, không chặn.

  @TC-02-019 @P2 @Dương @Biên @Âm
  Kịch bản: TC-02-019 Kiểm tra không lưu khi gõ: không ghi dữ liệu, giới hạn tần suất
    # Truy vết: FR-02-019 · API-02-022 · UI-02-03, 04 · ERR-02-036 · NFR-02-003.
    Biết F-SPEC-5K; U-T68-SV1.
    Khi `POST /spec-lint` F-SPEC-5K; đếm bản ghi `ph02_catalog.lint_result`.
    Và gọi 61 lần trong một giờ.
    Thì bước 1: `200` ≤ 5 giây, không thêm bản ghi. Bước 2: lần 61 `429` ERR-02-036 kèm `retryAfterSeconds`.

  @TC-02-020 @P2 @Dương @Âm
  Kịch bản: TC-02-020 Bộ luật quy ước theo tenant: đổi mức, phân quyền
    # Truy vết: FR-02-021 · API-02-024, 025 · UI-02-15 · UC-02-38 · ERR-02-014, 003 · KT: có (lint-rules.update).
    Biết U-T68-TA, U-T68-SV1.
    Khi U-T68-TA `PUT /lint-rules` hạ một luật từ `ERROR` xuống `WARN`.
    Và U-T68-SV1 gọi `PUT /lint-rules`.
    Và gửi luật nền tảng bắt buộc (không được tắt) với mức `OFF`.
    Thì bước 1: `200`, kiểm lại F-SPEC-L2 chỉ còn cảnh báo. Bước 2: 403-PQ. Bước 3: `400` ERR-02-003.

  @TC-02-094 @P2 @Âm @Biên
  Kịch bản: TC-02-094 Chạy kiểm tra đồng thời và vượt giới hạn tần suất
    # Truy vết: FR-02-016, 019 · API-02-021, 022 · UI-02-04 · UC-02-06 · ERR-02-035, 036.
    Biết A-DRAFT với F-SPEC-5K; U-T68-SV1; `02.lint.max-per-hour` = 60.
    Khi gửi hai `POST …/lint-runs` gần như cùng lúc cho cùng phiên bản.
    Và gọi `POST /spec-lint` 60 lần liên tiếp trong một giờ, rồi lần thứ 61.
    Và đợi hết `retryAfterSeconds` rồi gọi lại.
    Thì bước 1: một lần `200`, một lần `409` ERR-02-035; kết quả lưu chỉ có một bản. Bước 2: lần 61 `429` ERR-02-036 kèm `Retry-After`. Bước 3: `200`.

  @TC-02-095 @P2 @Âm
  Kịch bản: TC-02-095 Chấp nhận cảnh báo lớp 2: thiếu lý do, lỗi nghiêm trọng, sai quyền
    # Truy vết: FR-02-017 · API-02-092 · UI-02-04 · UC-02-06 · BR-02-028 · ERR-02-041, 011, 014.
    Biết A-DRAFT với F-SPEC-L2 (có cả cảnh báo và lỗi nghiêm trọng); U-T68-SV1, U-T68-VW.
    Khi `POST …/lint-findings/{id cảnh báo}:acknowledge` không có `reason`.
    Và chấp nhận phát hiện mức nghiêm trọng.
    Và U-T68-VW chấp nhận một cảnh báo.
    Và U-T68-SV1 chấp nhận cảnh báo kèm lý do hợp lệ; mở UI-02-04.
    Thì bước 1: `400` ERR-02-041. Bước 2: `409` ERR-02-011 (lỗi nghiêm trọng không chấp nhận được). Bước 3: `403` ERR-02-014. Bước 4: `200`, cảnh báo chuyển "đã chấp nhận" kèm người, lý do, thời điểm; lỗi nghiêm trọng vẫn chặn gửi duyệt.
