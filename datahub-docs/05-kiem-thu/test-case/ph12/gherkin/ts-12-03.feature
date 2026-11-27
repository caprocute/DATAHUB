# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-03
Tính năng: TS-12-03 · Khóa, mở khóa, vô hiệu và kích hoạt lại tài khoản

  @TC-12-014 @P1 @Dương
  Kịch bản: TC-12-014 Khóa rồi mở khóa tài khoản thu phiên ngay
    # Truy vết: FR-12-005 · UC-12-04 · UI-12-02 · API-12-005, 006 · LGC-IAM-005 · BR-12-036
    Biết U-T68-TA1; U-T68-IE đang có hai phiên.
    Khi `POST /users/{id}:lock` kèm `reason`.
    Và IE gọi API bằng access token cũ.
    Và `POST …:unlock`.
    Thì sau bước 1 trạng thái `LOCKED`, hai phiên bị thu, token cũ bị từ chối ≤ 60 giây; sau bước 3 `ACTIVE`; KT: có (user.lock, user.unlock).

  @TC-12-015 @P1 @Dương
  Kịch bản: TC-12-015 Vô hiệu và kích hoạt lại, không xóa vật lý
    # Truy vết: FR-12-005 · API-12-007, 008 · BR-12-035 · UI-12-03
    Biết U-T68-TA1; `tc-an` đã `ACTIVE`.
    Khi `POST …:disable`; truy vấn bảng người dùng bằng DB.
    Và `POST …:enable`.
    Thì bản ghi còn nguyên với `DISABLED`; lịch sử truy vết giữ; sau bước 2 `ACTIVE`; không có `DELETE /users`.

  @TC-12-016 @P1 @Âm
  Kịch bản: TC-12-016 Chuyển trạng thái sai và thiếu lý do
    # Truy vết: FR-12-005 · API-12-005, 006, 008 · ERR-12-006 · ERR-12-014
    Biết U-T68-TA1; `tc-an` đang `ACTIVE`.
    Khi `POST …:unlock` khi đang `ACTIVE`.
    Và `POST …:enable` khi đang `ACTIVE`.
    Và `POST …:lock` thiếu `reason`.
    Thì bước 1, 2 `409` ERR-12-006; bước 3 `400` ERR-12-014.

  @TC-12-017 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-017 Không tự khóa, tenant luôn còn ít nhất hai TA
    # Truy vết: FR-12-005 · BR-12-033 · API-12-005, 007 · ERR-12-013 · ERR-12-046
    Biết U-T68-TA1, U-T68-TA2, U-T68-TA3 (ba TA hiệu lực của T68 đã kích hoạt).
    Khi TA1 khóa chính mình.
    Và TA1 vô hiệu TA3 (còn TA1, TA2).
    Và TA1 vô hiệu TA2 (sẽ còn một TA).
    Và khôi phục TA3 bằng U-PA.
    Thì bước 1 `403` ERR-12-013; bước 2 thành công vì tenant còn đúng hai TA; bước 3 `409` ERR-12-046 với câu "Tỉnh phải luôn có ít nhất hai quản trị tỉnh đang hoạt động; thao tác này làm chỉ còn 1."; sau bước 4 tenant có ba TA hiệu lực.

  @TC-12-128 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-128 Chặn gỡ vai trò, khóa, vô hiệu, hết hạn gán TA khi tenant còn hai TA
    # Truy vết: FR-12-005, FR-12-012 · UC-12-04, 09 · UI-12-02, 06 · BR-12-033 · API-12-005, 007, 027 · ERR-12-046
    Biết T68 đã kích hoạt và có đúng hai TA hiệu lực là U-T68-TA1, U-T68-TA2; gán `TENANT_ADMIN` của TA2 có `validTo` sau 2 phút.
    Khi TA1 gỡ vai trò `TENANT_ADMIN` của TA2 (`DELETE` bản gán, API-12-027).
    Và U-T68-SO khóa TA2 không kèm `incidentRef` (API-12-005).
    Và U-T68-SO vô hiệu TA2 (API-12-007).
    Và chờ quá `validTo` của gán TA2, chạy `AssignmentExpiryJob`.
    Và mở UI-12-02 của TA2 bằng TA1; sau đó bước bù: U-PA tạo TA3 (API-12-003 rồi API-12-026), TA1 gỡ vai trò của TA2.
    Và cập nhật bằng SQL trực tiếp (kiểm DB) gán `TENANT_ADMIN` của TA3 sang `REVOKED`.
    Thì bước 1, 2, 3 `409` ERR-12-046 với câu "Tỉnh phải luôn có ít nhất hai quản trị tỉnh đang hoạt động; thao tác này làm chỉ còn 1. Bổ sung quản trị tỉnh khác trước khi thực hiện.", trạng thái và gán của TA2 không đổi, không có EVT-12-02, EVT-12-03; bước 4 gán TA2 vẫn `ACTIVE`, tác vụ ghi cảnh báo cho TA, SO, PA, ở OPA TA2 vẫn có quyền cho tới khi gia hạn; không có đường xóa vật lý (không có `DELETE /users`, BR-12-035) nên "xóa tài khoản TA" chỉ là vô hiệu, đã bị chặn ở bước 3; bước 5 nút "Gỡ", "Vô hiệu", "Khóa" của TA2 tắt kèm tooltip (từ `disabledReasons`), sau khi có TA3 việc gỡ TA2 thành công `204`; bước 6 CSDL từ chối với `SQLSTATE` `P1246` khi tenant còn hai TA nhưng gỡ một TA làm còn một. KT: có (các lần bị chặn ghi `reject`).

  @TC-12-129 @P1 @Dương @Bảo @mật
  Kịch bản: TC-12-129 Ngoại lệ khóa do sự cố ATTT khi tenant còn hai TA
    # Truy vết: FR-12-005, FR-12-021, FR-12-059 · UC-12-04 · BR-12-033 · API-12-005 · ERR-12-046
    Biết T68 có đúng hai TA hiệu lực (U-T68-TA1, U-T68-TA2); mã sự cố ATTT `INC-2026-118` do SO mở.
    Khi U-T68-SO khóa TA2 kèm `incidentRef` = `INC-2026-118` (API-12-005).
    Và mô phỏng ba lần khóa tạm trong 24 giờ của TA1 ở Keycloak (EVT-12-16) để TA1 chuyển `BLOCKED`.
    Và kiểm thông báo và việc được tạo; mở khóa cả hai bằng U-PA sau sự cố.
    Thì bước 1 `200`, TA2 `BLOCKED`, phiên bị thu; bước 2 TA1 `BLOCKED` không bị ERR-12-046 chặn; SO và PA nhận cảnh báo khẩn trong 60 giây (nêu tenant còn 0 TA hiệu lực), PA có việc "Bổ sung quản trị tỉnh"; kiểm toán ghi mã lý do `TA_BELOW_MIN`; sau bước 3 cả hai về `ACTIVE`. Lần khóa không kèm `incidentRef` vẫn `409` ERR-12-046 (đã kiểm ở ca chặn gỡ, khóa).
