# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-07
Tính năng: TS-01-07 · Theo dõi tiến độ, rút hồ sơ, xóa nháp

  @TC-01-033 @P2 @Dương
  Kịch bản: TC-01-033 Xem tiến độ hồ sơ
    # Truy vết: FR-01-019 · UC-01-07 · API-01-034 · UI-01-02 · BR-01-030.
    Biết U-T68-OR1; U-T68-OR2; `HT-HOTICH-SS`.
    Khi OR1 mở UI-01-02 của `HT-HOTICH-SS`.
    Và OR2 gọi `GET /systems/HT-HOTICH-SS/progress`.
    Thì bước 1: dòng thời gian có các bước, thời gian ở mỗi bước, đang chờ ai, hạn dự kiến. Bước 2: `404-ẩn`.

  @TC-01-034 @P1 @Dương
  Kịch bản: TC-01-034 Rút hồ sơ đã nộp về nháp
    # Truy vết: FR-01-009 · UC-01-07 · API-01-019 · UI-01-02 · BR-01-011 · EVT-01-03.
    Biết U-T68-OR1; `HT-HOTICH-SS` (chưa có kết luận phê duyệt).
    Khi `POST /systems/HT-HOTICH-SS:withdraw` kèm lý do.
    Và `GET …/history`.
    Thì `200`, `status = DRAFT`; các bước thẩm định giữ trong lịch sử, không xóa (BR-01-011); nội dung sửa được. KT: có. EVT: `EVT-01-03` (SUBMITTED → DRAFT).

  @TC-01-035 @P2 @Âm
  Kịch bản: TC-01-035 Rút hồ sơ khi đã có quyết định, thiếu lý do
    # Truy vết: FR-01-009 · API-01-019 · ERR-01-005, 033, 020.
    Biết U-T68-OR1; `HT-HOTICH-AP` APPROVED; `HT-HOTICH-SS`.
    Khi `:withdraw` vào `HT-HOTICH-AP`.
    Và `:withdraw` vào `HT-HOTICH-SS` không có lý do.
    Thì `409` ERR-01-005 hoặc ERR-01-020 (không ở giai đoạn rút được); `400` ERR-01-033.

  @TC-01-036 @P1 @Dương @Âm
  Kịch bản: TC-01-036 Xóa nháp chưa từng nộp, mã vẫn bị giữ
    # Truy vết: FR-01-009 · API-01-018 · BR-01-011, 018 · ERR-01-005, 002.
    Biết U-T68-OR1; nháp `tc-xoa` chưa từng nộp; `HT-HOTICH-SS` từng nộp.
    Khi `DELETE /systems/tc-xoa`; sau đó tạo lại hồ sơ cùng mã.
    Và `DELETE /systems/HT-HOTICH-SS`.
    Thì bước 1: `204`; tạo lại mã `409` ERR-01-002 (mã giữ vĩnh viễn). Bước 2: `409` ERR-01-005, hồ sơ đã nộp không xóa cứng.

  @TC-01-037 @P3 @Biên
  Kịch bản: TC-01-037 Nháp quá 90 ngày: nhắc trước 14 ngày, xóa mềm
    # Truy vết: FR-01-009 · BR-01-024 · EVT-01-03.
    Biết nháp `tc-cu` cập nhật cuối cách 76 ngày; `draft.retentionDays = 90`; đồng hồ giả.
    Khi chạy tác vụ hằng ngày; tua đồng hồ tới ngày 90; chạy lại.
    Thì ngày 76: thư nhắc cho người lập qua PH-18 (mail-sink). Ngày 91: hồ sơ xóa mềm, mã vẫn giữ; có bản ghi lịch sử.
