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
  Kịch bản: TC-12-017 Không tự khóa, không bỏ TA cuối cùng
    # Truy vết: FR-12-005 · BR-12-033 · API-12-005, 007 · ERR-12-013 · ERR-12-046
    Biết U-T68-TA1, U-T68-TA2 (hai TA duy nhất của T68).
    Khi TA1 khóa chính mình.
    Và TA1 vô hiệu TA2 (thành công), rồi TA1 vô hiệu chính mình khi là TA cuối.
    Và khôi phục TA2 bằng U-PA.
    Thì bước 1 `403` ERR-12-013; lần vô hiệu cuối ở bước 2 `409` ERR-12-046; tenant còn ít nhất một TA.
