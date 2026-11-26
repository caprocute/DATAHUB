# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-30
Tính năng: TS-16-30 · Tham số, lưu giữ dữ liệu và nhật ký kiểm toán

  @TC-16-103 @P1 @Dương
  Kịch bản: TC-16-103 Sửa tham số tenant và áp dụng không cần phát hành
    # Truy vết: FR-16-055 · API-16-128, 127 · UI-16-19 · NFR-16-020
    Biết T90; U-T90-TA1.
    Khi `GET /settings`
    Và `PATCH /settings` mảng `settings` đặt `16.export.link-hours` = 48 và `16.period.close-day` = 7 kèm `If-Match`
    Và tạo xuất mới và kiểm `expiresAt`
    Và `GET /settings`
    Thì bước 1 25 khóa `16.*` kèm `default`, `ceiling`, `scope`. Bước 2 `200`. Bước 3 `expiresAt` = tạo + 48 giờ, áp dụng ≤ 60 giây, không cần khởi động lại. Bước 4 giá trị mới, `updatedBy`. Thêm chỉ tiêu, nguồn, mẫu gói cũng không cần phát hành.

  @TC-16-104 @P1 @Âm
  Kịch bản: TC-16-104 Tham số ngoài miền, vượt trần, khóa bởi PA
    # Truy vết: FR-16-055 · API-16-128 · ERR-16-051, ERR-00-403, ERR-00-428
    Biết T92 (PA khóa `16.manual.evidence-required = true`); U-T90-TA1, U-T90-VW.
    Khi `PATCH /settings` `16.report.retention-years = 5`
    Và `PATCH /settings` `16.compare.min-tenants = 2`
    Và Ở T92 `PATCH /settings` `16.manual.evidence-required = false`
    Và U-T90-VW `PATCH /settings`
    Và `PATCH /settings` không `If-Match`
    Thì bước 1, 2, 3 `422` ERR-16-051 (ngoài miền, dưới sàn, vượt khóa PA). Bước 4 `403` ERR-00-403. Bước 5 `428` ERR-00-428. Giá trị không đổi.

  @TC-16-105 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-16-105 Nhật ký kiểm toán thao tác PH-16, quyền xem, khoảng tra quá dài
    # Truy vết: FR-16-056 · API-16-129 · UI-16-20 · ERR-16-060 · BR-16-032
    Biết T90 đã chạy các ca ghi; U-T90-AU, U-T90-VW, U-PU.
    Khi U-T90-AU `GET /audit-events?objectType=report&action=report.publish&from=2026-11-01`
    Và `GET /audit-events?actor=U-T90-TA2`
    Và U-T90-VW `GET /audit-events`
    Và U-PU xem kiểm toán liên tenant
    Và `GET /audit-events?from=2025-01-01&to=2026-11-26` (quá 12 tháng)
    Thì bước 1, 2 `200`, mỗi dòng có `at`, `actor`, `role`, `action`, `objectType`, `objectRef`, `before`, `after`, `traceId`; không có nội dung nhạy cảm. Bước 3 `403` ERR-00-403 (VW không có `PERM-16-audit-read`). Bước 4 PU chỉ đọc, thấy theo tenant. Bước 5 `400` ERR-16-060.

  @TC-16-106 @P2 @Dương @Âm
  Kịch bản: TC-16-106 Lưu giữ, xóa dữ liệu theo hạn; báo cáo công bố giữ 10 năm
    # Truy vết: FR-16-057 · API-16-130 · ERR-16-122, ERR-16-125 · BR-16-010, BR-16-031 · NFR-16-013
    Biết T90; quan sát tháng M-2023-09 cũ hơn 36 tháng; `16.observation.retention-months = 36`; tệp xuất hết hạn 8 ngày; `bc-thang-2026-09` `PUBLISHED`; `clock-sim`.
    Khi `GET /retention/status`
    Và chạy tác vụ dọn theo hạn
    Và cố xóa báo cáo `bc-thang-2026-09` hoặc tệp WORM trước hạn 10 năm
    Và làm lỗi tác vụ dọn (khóa phân vùng)
    Và ghi quan sát vào tháng chưa có phân vùng
    Thì bước 1 liệt kê `partitions[]` (`name`, `rowCount`, `rangeFrom`, `rangeTo`), `lastPurgeAt`, `nextPurgeAt`. Bước 2 phân vùng quá hạn bị loại, `bytesFreed`; giá trị chỉ tiêu và lần tổng hợp chính thức vẫn còn; tệp xuất hết hạn bị xóa sau 7 ngày. Bước 3 bị từ chối, báo cáo còn nguyên. Bước 4 ghi ERR-16-122, thông báo PH-13, không mất dữ liệu cũ. Bước 5 ghi ERR-16-125, quan sát vào đệm, không mất.
