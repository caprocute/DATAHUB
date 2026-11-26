# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-28
Tính năng: TS-06-28 · Chính sách lưu giữ và tham số theo tenant

  @TC-06-119 @P1 @Dương @Âm
  Kịch bản: TC-06-119 Dọn dữ liệu quá hạn và giữ pháp lý
    # Truy vết: FR-06-059 · BR-06-031 · API-06-093, 094 · ERR-06-049, 114 · UI-06-17
    # Mục đích: Chứng minh `RETENTION_PURGE` xóa `raw`, `normalized` quá hạn, giữ dòng rút gọn, bỏ qua `legalHold`, theo FR-06-059.
    Biết T90 có ứng viên quá hạn, 50 trong số đó thuộc nguồn có `legalHold`; TA.
    Khi `PUT /retention-policies/CANDIDATE` thấp hơn mức tối thiểu.
    Và đặt hợp lệ; chạy job.
    Và đọc kết quả và nhật ký xử lý.
    Thì bước 1 `422` ERR-06-049. Bước 3 ứng viên quá hạn mất `raw`, `normalized`, còn dòng rút gọn (nguồn, `sourceKey` băm, trạng thái, `goldenId`); 50 ứng viên giữ pháp lý bị bỏ qua, ERR-06-114 ghi nhận; không xóa bản ghi vàng; số lượng ghi vào nhật ký, báo cáo tháng.
    # Hậu điều kiện: Dữ liệu trung gian đã dọn.

  @TC-06-120 @P1 @Dương @Âm
  Kịch bản: TC-06-120 Tham số theo tenant trong và ngoài miền
    # Truy vết: FR-06-060 · BR-06-020, 022 · API-06-095, 096 · ERR-06-047 · PERM-06-config
    # Mục đích: Chứng minh đổi tham số trong miền có hiệu lực, ngoài miền và vượt trần bị chặn, theo FR-06-060.
    Biết TA, DS1, PA.
    Khi TA `PUT /settings` `06.queue.sla-days = 5`, `06.batch.safety-ratio = 0,08`.
    Và TA đặt `06.batch.safety-ratio = 0,5`; `06.export.max-rows = 5.000.000`.
    Và DS1 `PUT /settings`.
    Thì bước 1 `200`, tạo mục hàng đợi mới có SLA 5 ngày, job lô dùng 8 %. Bước 2 `422` ERR-06-047 nêu miền. Bước 3 ERR-00-403. KT: có (settings-update) ghi giá trị cũ, mới.
    # Hậu điều kiện: Hai tham số đã đổi.
