# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-28
Tính năng: TS-15-28 · Khóa, mở khóa và khu quản trị

  @TC-15-159 @P1 @Dương
  Kịch bản: TC-15-159 Khóa và mở khóa tài khoản dh-dev
    # Truy vết: FR-15-059 · UC-15-30 · API-15-124, 125 · UI-15-24 · EVT-15-07 · BR-15-028 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an ACTIVE có phiên đang mở; Hà.
    Khi `POST /admin/dev-accounts/{An}:lock` {lý do}.
    Và an gọi API, đăng nhập lại.
    Và `:unlock`.
    Thì `LOCKED`, phiên bị cắt, Keycloak vô hiệu người dùng; An `403` ERR-15-014; EVT-15-07; KT: có (`LOCK_ACCOUNT`, `UNLOCK_ACCOUNT`); sau mở khóa `ACTIVE`.

  @TC-15-160 @P1 @Dương
  Kịch bản: TC-15-160 Tạm ngừng và tiếp tục ứng dụng
    # Truy vết: FR-15-059 · UC-15-30 · API-15-126, 127 · EVT-15-02 · ERR-15-017, 102 · NFR-15-007 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ứng dụng ACTIVE đang gọi sandbox liên tục; Khánh (SO).
    Khi `POST /admin/apps/app-tra-cuu-ho-tich:suspend` {lý do}.
    Và an thử, cấp, xoay credential; gọi trực tiếp sandbox.
    Và `:resume`.
    Thì `SUSPENDED`, EVT-15-02; thử `403` ERR-15-102, cấp/xoay `409` ERR-15-017, gọi trực tiếp bị chặn ≤ 60 giây; sau `:resume` hoạt động, credential cũ vẫn `ACTIVE`.

  @TC-15-161 @P2 @Âm
  Kịch bản: TC-15-161 Sai trạng thái, thiếu lý do, thiếu quyền
    # Truy vết: FR-15-059 · API-15-124, 126 · ERR-15-003, 005, 017, 022 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản LOCKED; ứng dụng ARCHIVED; Bình.
    Khi `:lock` tài khoản LOCKED.
    Và `:suspend` ứng dụng ARCHIVED.
    Và `:lock` không lý do.
    Và bình `:lock`.
    Thì `409` ERR-15-022; `409` ERR-15-017; `400` ERR-15-003; `403` ERR-15-005.

  @TC-15-162 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-162 Khu quản trị chỉ từ mạng quản trị, có MFA
    # Truy vết: FR-15-056, 057, 060 · UI-15-25, 26 · ERR-15-036 · BR-15-031 · LGC-APIM-007.
    Biết hà có WebAuthn; cổng ở tên miền công khai và ở mạng quản trị.
    Khi từ tên miền công khai mở `/quan-tri-cong/nhan-dien`.
    Và từ mạng ngoài quản trị gọi `GET /admin/settings`.
    Và từ mạng quản trị đăng nhập không MFA; rồi có WebAuthn.
    Thì bước 1 `404`; bước 2 `403` ERR-15-036; bước 3 buộc xác thực lại bằng WebAuthn, sau đó `200`; DEV không thấy menu quản trị.
