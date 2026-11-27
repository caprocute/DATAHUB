# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-13
Tính năng: TS-04-13 · Ca kiểm thử của luồng

  @TC-04-080 @P2 @Dương
  Kịch bản: TC-04-080 Tạo ca kiểm thử và chạy tất cả
    # Truy vết: FR-04-031 · API-04-044, 101, 040 · UI-04-13 · UC-04-09.
    Biết F-HT v4.
    Khi tạo ca "KS-01 tra cứu hợp lệ" (MSG-OK, `STATUS = 200`, `BODY_JQ .ketQua == "OK"`).
    Và tạo ca "KS-02 thiếu số định danh" (MSG-NOID, `STATUS = 400`, `ERROR_CODE = ERR-04-101`, `STEP_NOT_VISITED deliver-ht`).
    Và trên UI-04-13 bấm "Chạy tất cả".
    Thì bước 1, 2 trả `201`. Bước 3: hai lần chạy có `testCaseId`, cả hai `PASSED`; cột "Kết quả trên bản hiện tại" xanh.

  @TC-04-081 @P2 @Âm
  Kịch bản: TC-04-081 Ca kiểm thử sai và kết quả cũ hết hiệu lực
    # Truy vết: FR-04-031 · API-04-044, 101, 102 · ERR-04-030, 006.
    Biết ca KS-01 đã đạt trên băm cũ.
    Khi tạo ca không có khẳng định nào.
    Và sửa ca với ETag cũ.
    Và xóa ca không tồn tại.
    Và sửa định nghĩa v4 (đổi băm), xem lại danh sách ca.
    Thì bước 1 trả `400` ERR-04-049 (`minItems = 1`, VR-20). Bước 2 trả `412` ERR-04-006. Bước 3 trả `404` ERR-04-030. Bước 4: `lastResult.onCurrentHash = false` cho KS-01, nhãn "Cần chạy lại".
