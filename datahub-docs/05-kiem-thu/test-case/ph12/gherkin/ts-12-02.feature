# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-02
Tính năng: TS-12-02 · Tạo tài khoản, kích hoạt lần đầu và sửa thông tin

  @TC-12-007 @P1 @Dương
  Kịch bản: TC-12-007 Tạo tài khoản và kích hoạt lần đầu
    # Truy vết: FR-12-003, 006 · UC-12-02 · UI-12-03, UI-12-18 · API-12-003 · LGC-IAM-002 · BR-12-018
    Biết U-T68-TA1; SIM-PH07 `DV-A`; SIM-SMTP.
    Khi `POST /users` với `username=tc-an`, thư `an@dv.t68.test`, `unit=DV-A`, `Idempotency-Key`.
    Và đọc thư ở SIM-SMTP, mở liên kết, đặt mật khẩu 14 ký tự đạt chuẩn, đăng ký TOTP.
    Thì `201`, trạng thái `PENDING_ACTIVATION`; sau bước 2 là `ACTIVE`; liên kết dùng một lần; KT: có (user.create, user.activate); không có mật khẩu trong log.

  @TC-12-008 @P1 @Âm
  Kịch bản: TC-12-008 Tạo tài khoản trùng tên, thư, hoặc sai lược đồ
    # Truy vết: FR-12-003 · API-12-003 · ERR-12-002, ERR-12-003 · BR-12-014
    Biết U-T68-TA1; tài khoản `tc-an` đã có.
    Khi `POST /users` lại cùng `username`.
    Và `POST /users` cùng thư, khác tên.
    Và `POST /users` thiếu `unit`, tên có ký tự cấm.
    Thì bước 1 và 2 `409` ERR-12-002; bước 3 `400` ERR-12-003 kèm danh sách lỗi theo trường.

  @TC-12-009 @P1 @Âm
  Kịch bản: TC-12-009 Đơn vị hết hiệu lực hoặc thư ngoài miền công vụ
    # Truy vết: FR-12-003 · API-12-003 · ERR-12-004, ERR-12-005
    Biết U-T68-TA1; SIM-PH07 `DV-HET`.
    Khi `POST /users` với `unit=DV-HET`.
    Và `POST /users` với thư `x@gmail.com`.
    Thì bước 1 `422` ERR-12-004; bước 2 `422` ERR-12-005; không tạo bản ghi nào.

  @TC-12-010 @P1 @Âm @Biên
  Kịch bản: TC-12-010 Mật khẩu kích hoạt không đạt chính sách
    # Truy vết: FR-12-006 · BR-12-018 · UI-12-18 · ERR-12-015 · SEC-22
    Biết U-T68-NEW, liên kết kích hoạt còn hạn.
    Khi đặt mật khẩu 13 ký tự, rồi 14 ký tự trùng danh sách đã lộ, rồi chứa tên đăng nhập.
    Và đặt mật khẩu 14 ký tự đạt chuẩn; sau đó đặt lại bằng mật khẩu trùng 1 trong 5 gần nhất.
    Thì ba mật khẩu đầu bị từ chối với ERR-12-015 và thông báo tiếng Việt nêu quy tắc; mật khẩu 14 ký tự đạt chuẩn được nhận; mật khẩu trùng lịch sử bị từ chối.

  @TC-12-011 @P2 @Âm
  Kịch bản: TC-12-011 Liên kết kích hoạt hết hạn hoặc đã dùng
    # Truy vết: FR-12-006, FR-12-003 · API-12-009 · ERR-12-016 · UI-12-03
    Biết U-T68-NEW; đồng hồ nhảy qua hạn liên kết.
    Khi mở liên kết cũ; xác nhận trang báo hết hạn.
    Và TA bấm "Gửi lại" ở UI-12-03 (`POST /users/{id}:resend-activation`).
    Và dùng liên kết mới hai lần.
    Thì bước 1 ERR-12-016 (410); bước 2 `202`, liên kết cũ vô hiệu; lần dùng thứ hai ERR-12-016.

  @TC-12-012 @P1 @Dương
  Kịch bản: TC-12-012 Sửa thông tin và chuyển đơn vị
    # Truy vết: FR-12-004 · UC-12-03 · UI-12-02, 03 · API-12-004 · BR-12-036, BR-12-037
    Biết U-T68-TA1; U-T68-PH07 có vai trò phạm vi `DV-A`.
    Khi `GET` lấy `ETag`; `PATCH /users/{id}` với `If-Match`, đổi `unit=DV-B`.
    Thì `200`; vai trò phạm vi `DV-A` bị thu và hiệu lực ở OPA ≤ 60 giây; phiên của người đó bị thu; KT: có (user.update); SK: `user.updated`.

  @TC-12-013 @P2 @Âm
  Kịch bản: TC-12-013 Sửa với phiên bản cũ hoặc trường do LDAP quản lý
    # Truy vết: FR-12-004 · API-12-004 · ERR-12-044 · ERR-12-047 · ERR-12-001
    Biết U-T68-TA1; một người dùng nhập từ SIM-LDAP.
    Khi `PATCH` hai lần với cùng `If-Match` cũ.
    Và `PATCH` tên hiển thị của người dùng LDAP.
    Thì lần hai bước 1 `412` ERR-12-044; bước 2 `422` ERR-12-047.
