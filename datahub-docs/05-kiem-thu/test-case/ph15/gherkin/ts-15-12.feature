# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-12
Tính năng: TS-15-12 · Điều khoản, nhóm, vô hiệu hóa và xóa tài khoản

  @TC-15-073 @P1 @Âm
  Kịch bản: TC-15-073 Chưa chấp nhận điều khoản thì chặn tạo ứng dụng và thử
    # Truy vết: FR-15-023 · UC-15-12 · API-15-047, 048, 056, 072 · ERR-15-010 · BR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết điều khoản v2 hiện hành; U-T68-DEV-BI chưa chấp nhận.
    Khi bi `POST /apps`, `POST /try/requests`.
    Và bi `GET /catalog/apis`, `GET /catalog/apis/tra-cuu-ho-tich/versions/1.0.0/spec`.
    Thì bước 1 `409` ERR-15-010 "Cần chấp nhận điều khoản sử dụng hiện hành trước khi tiếp tục."; bước 2 `200` (vẫn đọc danh mục, tài liệu).

  @TC-15-074 @P1 @Dương
  Kịch bản: TC-15-074 Chấp nhận và điều khoản mới bắt buộc chấp nhận lại
    # Truy vết: FR-15-023 · UC-15-12 · API-15-047, 048 · UI-15-09 · BR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-BI; U-T68-TA đăng điều khoản v3.
    Khi `GET /terms/current`; `POST /terms/acceptances` với v2; `POST /apps`.
    Và với v1 (cũ).
    Và TA đăng v3 (xem TC-15-055); Bi `POST /apps`.
    Thì v2 `201`, tạo ứng dụng được; v1 `400` ERR-15-003; sau v3 người dùng đang hoạt động nhận thông báo bắt buộc và bị chặn `409` ERR-15-010 đến khi chấp nhận lại; KT lưu phiên bản, thời điểm.

  @TC-15-075 @P2 @Dương
  Kịch bản: TC-15-075 Tạo nhóm, mời, chấp nhận
    # Truy vết: FR-15-022 · UC-15-13 · API-15-049, 050, 051, 052 · UI-15-09 · EVT-15-13 · LGC-APIM-020.
    Biết U-T68-DEV-AN, U-T68-DEV-BI.
    Khi an `POST /teams` `nhom-thau-a`; mời Bi.
    Và bi `POST /me/invitations/{id}:respond` chấp nhận.
    Thì nhóm có An `OWNER`, Bi thành viên; EVT-15-13; Bi thấy nhóm ở `GET /teams`; lời mời hết hạn chuyển `EXPIRED`.

  @TC-15-076 @P2 @Âm
  Kịch bản: TC-15-076 Trùng mã, trùng lời mời, rời nhóm khi là chủ duy nhất
    # Truy vết: FR-15-022 · API-15-050, 051, 053 · ERR-15-002, 027, 028 · BR-15-007 · LGC-APIM-020.
    Biết nhóm `nhom-thau-a` (An OWNER, Bi thành viên).
    Khi tạo lại `nhom-thau-a`; mời Bi lần hai.
    Và `DELETE /teams/nhom-thau-a/members/{An}`.
    Và cự (không thuộc nhóm) `POST /teams/nhom-thau-a/invitations`.
    Thì `409` ERR-15-002; `409` ERR-15-027; `422` ERR-15-028 "Phải còn ít nhất một chủ sở hữu."; Cự `403` ERR-15-005.

  @TC-15-077 @P2 @Dương
  Kịch bản: TC-15-077 Vô hiệu hóa sau 45 ngày và kích hoạt lại
    # Truy vết: FR-15-024 · UC-15-12 · API-15-041 · EVT-15-07 · ERR-15-014 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản An ACTIVE; đồng hồ giả lập; tài khoản Bi đăng nhập ngày 44.
    Khi đẩy đồng hồ 45 ngày không hoạt động.
    Và an đăng nhập; yêu cầu kích hoạt lại; TA duyệt.
    Thì an `DISABLED` (EVT-15-07), đăng nhập `403` ERR-15-014; sau yêu cầu `PENDING_APPROVAL`, TA duyệt thì `ACTIVE`; bộ đếm của Bi được đặt lại, không bị vô hiệu.

  @TC-15-078 @P2 @Dương
  Kịch bản: TC-15-078 Xóa tài khoản theo yêu cầu và ẩn danh tự động
    # Truy vết: FR-15-024 · UC-15-12 · API-15-054 · ERR-15-003, 028 · BR-15-029 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản dh-dev Cự có ứng dụng, lượt thử; tài khoản An là chủ duy nhất nhóm còn thành viên; tài khoản dh-dev `du.khong-hd` không hoạt động 24 tháng (đồng hồ giả lập).
    Khi cự `POST /me:request-erasure` sai cụm xác nhận, rồi đúng.
    Và an làm cùng việc.
    Và đẩy đồng hồ 24 tháng cho tài khoản không hoạt động.
    Thì sai cụm `400` ERR-15-003; đúng: `ERASED`, họ tên, thư ẩn danh, credential bị thu hồi, lượt thử giữ ở dạng ẩn danh; An `422` ERR-15-028; sau 24 tháng tài khoản tự ẩn danh.
