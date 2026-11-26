# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-13
Tính năng: TS-15-13 · Ứng dụng sandbox và thành viên

  @TC-15-079 @P1 @Dương
  Kịch bản: TC-15-079 Tạo ứng dụng sandbox
    # Truy vết: FR-15-025 · UC-15-14 · API-15-055, 056, 057 · UI-15-10, 11 · EVT-15-01 · BR-15-007, 009 · LGC-APIM-020.
    Biết U-T68-DEV-AN đã chấp nhận điều khoản.
    Khi mở UI-15-11, nhập `app-tra-cuu-ho-tich`, tên, mô tả, chủ sở hữu cá nhân.
    Và `GET /apps`, `GET /apps/app-tra-cuu-ho-tich`.
    Thì `201`, `ACTIVE`, An là `OWNER`; EVT-15-01; xuất hiện ở UI-15-10; chọn "Cấp thông tin xác thực ngay" chuyển sang UI-15-13.

  @TC-15-080 @P1 @Âm
  Kịch bản: TC-15-080 Mã sai, trùng, vượt giới hạn, HTTT lạ
    # Truy vết: FR-15-025 · UC-15-14 · API-15-056, 141 · ERR-15-002, 003, 015, 032 · BR-15-010 · LGC-APIM-020.
    Biết `15.app.max-per-user = 2`; An đã có 2 ứng dụng; U-T68-OR; HT-TUPHAP không thuộc đơn vị của Bình.
    Khi an `GET /apps:check-code` với mã đã dùng và mã `AB`; rồi tạo mã trùng, mã `AB`.
    Và an tạo ứng dụng thứ 3.
    Và bình tạo ứng dụng gắn `HT-TUPHAP`.
    Thì `check-code` báo mã đã dùng, mã sai mẫu; `409` ERR-15-002; `400` ERR-15-003; `422` ERR-15-015 "Đã đạt số ứng dụng tối đa (2)..."; `422` ERR-15-032 "HTTT này không thuộc đơn vị của bạn".

  @TC-15-081 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-081 Người ngoài ứng dụng không xem, sửa được
    # Truy vết: FR-15-026 · UC-15-14 · API-15-055, 057, 058 · ERR-15-005, 001 · BR-15-009, 034 · NFR-15-017 · LGC-APIM-020.
    Biết `app-tra-cuu-ho-tich` của An; U-T68-DEV-CU (cùng tenant, không thành viên); U-T01-DEV có ứng dụng cùng mã ở T01.
    Khi cự `GET /apps/app-tra-cuu-ho-tich`, `PATCH`, `:archive`.
    Và cự `GET /apps`.
    Và U-T01-DEV qua tên miền T68 gọi `GET /apps/app-tra-cuu-ho-tich`.
    Thì bước 1 `403` ERR-15-005; bước 2 không có ứng dụng của An; bước 3 `404` ERR-15-001 thân giống "không tồn tại"; dữ liệu của An không đổi.

  @TC-15-082 @P2 @Dương
  Kịch bản: TC-15-082 Sửa ứng dụng, xung đột phiên bản, vai trò VIEWER
    # Truy vết: FR-15-026 · UC-15-14 · API-15-058 · ERR-15-005, 006 · BR-15-009, 034 · LGC-APIM-020.
    Biết ứng dụng có An `OWNER`, Bi `VIEWER`.
    Khi an `PATCH` đổi tên với `If-Match` đúng; lặp với `If-Match` cũ.
    Và bi `PATCH`.
    Thì `200`; `412` ERR-15-006; Bi `403` ERR-15-005.

  @TC-15-083 @P1 @Dương
  Kịch bản: TC-15-083 Lưu trữ thu hồi credential, khôi phục không khôi phục bí mật
    # Truy vết: FR-15-026 · UC-15-14, 16 · API-15-059, 060 · EVT-15-02, 05 · ERR-15-017, 102 · BR-15-010 · LGC-APIM-020.
    Biết ứng dụng ACTIVE có 2 credential; An.
    Khi `:archive`; thử gọi sandbox bằng credential cũ.
    Và `:restore` trong 30 ngày.
    Và lặp `:restore` khi ACTIVE; `PATCH` ứng dụng ARCHIVED.
    Thì bước 1 `ARCHIVED`, hai credential `REVOKED` (EVT-15-05 hai lần), `POST /try/requests` `403` ERR-15-102; bước 2 `ACTIVE`, credential vẫn REVOKED phải cấp mới; bước 3 `409` ERR-15-017; sau 30 ngày xóa không khôi phục được.

  @TC-15-084 @P3 @Biên
  Kịch bản: TC-15-084 Ứng dụng không dùng 180 ngày tự lưu trữ
    # Truy vết: FR-15-026 · EVT-15-02 · BR-15-010 · LGC-APIM-020.
    Biết ứng dụng không có lượt gọi; đồng hồ +180 ngày.
    Khi chạy tác vụ lưu trữ tự động.
    Thì có thông báo trước; ứng dụng `ARCHIVED`, EVT-15-02 `reason` ghi không hoạt động; credential bị thu hồi.

  @TC-15-085 @P2 @Dương
  Kịch bản: TC-15-085 Giao ứng dụng cho thành viên và vai trò
    # Truy vết: FR-15-033 · UC-15-13 · API-15-066, 067, 068 · UI-15-12 · EVT-15-13 · BR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ứng dụng của An; Bi.
    Khi `PUT /apps/{}/members/{Bi}` vai `DEVELOPER`; Bi cấp credential, thử API.
    Và đổi Bi thành `VIEWER`; Bi cấp credential.
    Và `DELETE` Bi.
    Thì DEVELOPER dùng được; VIEWER xem được thống kê nhưng cấp credential, thử API `403` ERR-15-005; sau xóa Bi mất truy cập; EVT-15-13 mỗi lần.

  @TC-15-086 @P2 @Âm
  Kịch bản: TC-15-086 Thành viên trùng, xóa chủ duy nhất, không đủ quyền
    # Truy vết: FR-15-033 · API-15-067, 068 · ERR-15-005, 027, 028 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ứng dụng của An (OWNER duy nhất), Bi DEVELOPER.
    Khi an thêm Bi lần hai.
    Và an xóa chính mình.
    Và bi thêm người.
    Thì `409` ERR-15-027; `422` ERR-15-028; `403` ERR-15-005.
