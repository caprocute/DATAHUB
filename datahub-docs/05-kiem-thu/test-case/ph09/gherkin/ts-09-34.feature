# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-34
Tính năng: TS-09-34 · Nhật ký bảo vệ dữ liệu, bảng điều khiển, báo cáo và tham số

  @TC-09-116 @P1 @Dương @Âm
  Kịch bản: TC-09-116 Tra nhật ký theo thời gian, người, loại thao tác; giới hạn khoảng tra; xuất
    # Truy vết: FR-09-061 · API-09-215, 216, 217 · UI-09-20 · PERM-09-audit-read · ERR-09-079 · BR-09-058
    # Mục đích: Chứng minh AU tra được, DS không, mọi thao tác ghi có bản ghi và không chứa giá trị `SENSITIVE`.
    Biết T99 2 triệu bản ghi kiểm toán một tháng; U-T90-AU, U-T90-DS1.
    Khi AU `GET /audit-events?from&to&actor=...` trong 30 ngày; chi tiết một bản ghi.
    Và AU tra khoảng 120 ngày (`09.audit.query-max-days = 90`).
    Và DS1 `GET /audit-events`.
    Và AU `POST /audit-exports`.
    Thì bước 1 `200`, bản ghi chỉ có tên trường, băm có khóa, số lượng. Bước 2 từ chối `422` ERR-09-079 "Chọn khoảng thời gian tối đa 90 ngày." Bước 3 ERR-00-403. Bước 4 `202`, tệp không có giá trị rõ, KT: có (audit-export).

  @TC-09-117 @P2 @Dương @Âm
  Kịch bản: TC-09-117 Bảng điều khiển, báo cáo tuân thủ và lịch lập báo cáo
    # Truy vết: FR-09-062, 063 · API-09-218, 219, 220, 221, 222, 223 · UI-09-01 · ERR-09-003 · NFR-09-022
    # Mục đích: Chứng minh thẻ chỉ số bấm được, VW chỉ xem tổng quan và báo cáo theo lịch.
    Biết T90; U-T90-VW, U-T90-TA.
    Khi VW mở UI-09-01; bấm thẻ "hợp đồng bị chặn".
    Và TA `POST /compliance-reports` kỳ quý; `PUT /compliance-reports:schedule` `0 6 1 * *`; rồi gửi lịch `hai ngay mot lan`.
    Và VW mở UI-09-15.
    Thì bước 1 danh sách đã lọc khớp `GET /activation-checks:blocked`; chỉ số `privacy_unclassified_fields`, `privacy_dsr_overdue`, `privacy_breach_clock_seconds` đúng. Bước 2 `201`, tệp tải được, lịch hợp lệ `200`, lịch sai `400` ERR-09-003. Bước 3 ERR-00-403.

  @TC-09-118 @P1 @Âm @Biên
  Kịch bản: TC-09-118 Tham số ngoài miền, vượt trần PA, không cần khởi động lại
    # Truy vết: FR-09-064 · API-09-224, 225, 226 · ERR-09-078 · BR-09-059 · PERM-09-config
    # Mục đích: Chứng minh BR-09-059 và hiệu lực không khởi động lại.
    Biết T90; trần PA `09.plan.cache-seconds ≤ 300`, sàn `09.anon.k-min ≥ 10`; U-T90-TA, U-PA.
    Khi TA đặt `09.plan.cache-seconds = 600`, `09.anon.k-min = 5`, `09.mask.reveal-seconds = 90`.
    Và TA đặt `09.plan.cache-seconds = 120`; PEP lấy kế hoạch.
    Và `GET /settings/history`.
    Thì bước 1 mỗi giá trị `422` ERR-09-078 "Giá trị của 09.plan.cache-seconds ngoài miền cho phép 60…300." Bước 2 `200`, PEP dùng `ttlSeconds = 120` ngay, không khởi động lại. Bước 3 lịch sử có người, giá trị cũ, mới, KT: có.
