# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-27
Tính năng: TS-08-27 · Tham số tenant, lưu giữ dữ liệu đo và nhật ký kiểm toán

  @TC-08-124 @P1 @Dương
  Kịch bản: TC-08-124 Xem và sửa tham số tenant
    # Truy vết: FR-08-058 · API-08-123, 124 · UI-08-19 · PERM-08-config
    Biết T90; U-T90-TA; U-T90-DS1.
    Khi TA `GET /settings`
    Và TA `PUT /settings` `{08.scan.manual-per-hour: 20}` với `If-Match` đúng
    Và `GET /settings`
    Thì bước 1 liệt kê 43 khóa với `default`, `max`, `updatedBy`. Bước 3 giá trị 20, `updatedBy = TA`. KT: có (setting.update) ghi giá trị trước và sau.

  @TC-08-125 @P1 @Âm
  Kịch bản: TC-08-125 Ngoài miền, vượt trần, xung đột, thiếu quyền
    # Truy vết: FR-08-058 · API-08-124 · ERR-00-403 · ERR-00-428 · ERR-08-042, 004
    Biết `08.scan.min-interval-hours` miền ≥ 6; PA đặt trần `08.scan.manual-per-hour = 30`.
    Khi TA `PUT` `08.scan.min-interval-hours = 2`
    Và TA `PUT` `08.scan.manual-per-hour = 50`
    Và TA `PUT` với `If-Match` cũ
    Và TA `PUT` không `If-Match`
    Và DS1 `PUT`
    Thì bước 1 và 2 `422` ERR-08-042. Bước 3 `409` ERR-08-004. Bước 4 `428` ERR-00-428. Bước 5 `403` ERR-00-403.

  @TC-08-126 @P1 @Dương
  Kịch bản: TC-08-126 Xem trước và chạy dọn dữ liệu theo lưu giữ
    # Truy vết: FR-08-059 · API-08-125, 126 · UI-08-19 · BR-08-028
    Biết T90 có lỗi 400 ngày tuổi, kết quả quy tắc 25 tháng, ảnh chụp 6 năm, báo cáo công bố 11 năm (dữ liệu dựng bằng `clock-sim`).
    Khi `POST /retention-runs:preview`
    Và chạy job dọn 03:00
    Và `GET /retention-runs`
    Thì bước 1 `estimates{}` theo loại, chưa xóa. Bước 2 xóa lỗi quá 13 tháng (395 ngày) và kết quả quy tắc quá 24 tháng; không xóa ảnh chụp trong 5 năm và báo cáo công bố trong 10 năm. Bước 3 ghi số dòng đã xóa.

  @TC-08-127 @P2 @Âm
  Kịch bản: TC-08-127 Lưu giữ dưới sàn và dọn lỗi
    # Truy vết: FR-08-059 · API-08-124, 125 · BR-08-028 · ERR-08-117 · ERR-08-043
    Biết sàn lưu lỗi 13 tháng; job dọn gặp lỗi CSDL giả lập.
    Khi TA `PUT /settings` `08.finding.retention-months = 12`
    Và chạy job dọn với lỗi giả lập
    Thì bước 1 `422` ERR-08-043. Bước 2 job ghi ERR-08-117 ở UI-08-19 và PH-13, dữ liệu chưa xóa còn nguyên, thử lại ngày sau.

  @TC-08-128 @P1 @Dương @Bảo @mật
  Kịch bản: TC-08-128 Đọc nhật ký kiểm toán và tính bất biến
    # Truy vết: FR-08-060 · API-08-127 · UI-08-04, 19 · PERM-08-audit-read · ERR-00-403
    Biết sau các ca duyệt, xuất, đổi tham số; U-T90-SO, U-T90-AU, U-T90-DS1.
    Khi SO `GET /audit-events?assetCode=mdm-citizen&action=ruleset.activate`
    Và AU `GET /audit-events` xuất nhật ký
    Và DS1 `GET /audit-events`
    Và thử `UPDATE` và `DELETE` bản ghi kiểm toán bằng `dh_data_app`
    Thì bước 1 mỗi bản ghi có người thao tác, `tenantId`, hành động, đối tượng, giá trị trước và sau, `traceId`, thời điểm; không chứa giá trị thuộc tính Nhạy cảm. Bước 2 có kiểm toán lượt xuất. Bước 3 `403` ERR-00-403. Bước 4 bị chặn (bất biến).

  @TC-08-129 @P1 @Âm
  Kịch bản: TC-08-129 Không ghi được kiểm toán thì từ chối thao tác
    # Truy vết: FR-08-060 · API-08-039 · ERR-08-054 · BR-08-007
    Biết kênh kiểm toán PH-13 giả lập ngừng; bộ quy tắc chờ duyệt.
    Khi DA1 `POST …:approve` khi kênh kiểm toán ngừng
    Và bật lại, `POST …:approve`
    Thì bước 1 `503` ERR-08-054, phiên bản vẫn `PENDING_APPROVAL`, không phát EVT-08-01. Bước 2 `200`.
