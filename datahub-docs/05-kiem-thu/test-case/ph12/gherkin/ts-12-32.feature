# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-32
Tính năng: TS-12-32 · Hành vi chung của API quản trị

  @TC-12-102 @P1 @Dương @Âm
  Kịch bản: TC-12-102 Idempotency-Key và hợp đồng lỗi RFC 9457
    # Truy vết: FR-12-003 · UC-12-02 · API-12-003, 058 · ERR-12-045 · ERR-12-007 · NFR-12-032
    Biết U-T68-TA1, U-T68-VW.
    Khi `POST /users` hai lần cùng `Idempotency-Key` cùng thân; rồi cùng khóa khác thân.
    Và gọi thao tác thiếu quyền; kiểm thân lỗi.
    Thì lần hai cùng thân trả lại kết quả cũ, không tạo thêm; khác thân `422` ERR-12-045; lỗi có `type`, `title`, `status`, `code`, `traceId` (RFC 9457) và ERR-12-007 cho thiếu quyền.

  @TC-12-103 @P2 @Biên
  Kịch bản: TC-12-103 Giới hạn tần suất thao tác quản trị
    # Truy vết: FR-12-003 · API-12-003 · ERR-12-037 · ERR-12-043
    Biết U-T68-TA1; vượt ngưỡng tần suất của tenant.
    Khi bắn yêu cầu tạo người dùng vượt ngưỡng; tạo vượt giới hạn số lượng (10.000 người dùng).
    Thì `429` ERR-12-037 kèm `Retry-After`; vượt giới hạn số lượng `422` ERR-12-043.

  @TC-12-104 @P1 @Âm @Chaos
  Kịch bản: TC-12-104 Keycloak, OpenBao hoặc phân hệ phụ thuộc không khả dụng
    # Truy vết: FR-12-003, 030, 034 · API-12-003, 058, 066 · ERR-12-038 · ERR-12-039 · ERR-12-040 · NFR-12-013
    Biết chaos Mesh tắt lần lượt Keycloak, OpenBao, PH-01, PH-07.
    Khi tạo người dùng khi Keycloak tắt; xoay bí mật khi OpenBao tắt; cấp client khi PH-01 tắt.
    Thì `503` với ERR-12-038, ERR-12-039, ERR-12-040 tương ứng; không có dữ liệu nửa chừng; sau khi phục hồi gọi lại thành công.
