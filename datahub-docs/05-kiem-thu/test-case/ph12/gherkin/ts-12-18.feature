# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-18
Tính năng: TS-12-18 · Đăng nhập một lần SAML 2 và liên kết LDAP, AD

  @TC-12-055 @P1 @Dương
  Kịch bản: TC-12-055 Đăng ký ứng dụng SAML và đăng nhập một lần
    # Truy vết: FR-12-025 · UC-12-19 · UI-12-11 · API-12-051, 052, 053 · LGC-IAM-001, LGC-IAM-008 · SEC-20
    Biết U-T68-TA1; SIM-SAML-SP.
    Khi `POST /saml-clients` với metadata hợp lệ; `PATCH` đổi URL ACS.
    Và người dùng mở SIM-SAML-SP và đăng nhập bằng Keycloak.
    Thì assertion có chữ ký, `NameID` và thuộc tính đúng, đích khớp ACS; `GET /saml-clients` thấy ứng dụng.

  @TC-12-056 @P2 @Âm
  Kịch bản: TC-12-056 Cấu hình SAML sai
    # Truy vết: FR-12-025 · API-12-052 · ERR-12-033
    Biết U-T68-TA1; metadata thiếu chứng thư; ACS không HTTPS.
    Khi `POST /saml-clients` hai lần với hai cấu hình sai.
    Thì `422` ERR-12-033 kèm lý do từng trường.

  @TC-12-057 @P1 @Dương
  Kịch bản: TC-12-057 Liên kết LDAP: khai báo, kiểm tra, đồng bộ
    # Truy vết: FR-12-026 · UC-12-19 · UI-12-11 · API-12-047, 048, 049, 050 · LGC-IAM-004 · BR-12-029
    Biết U-T68-TA1, U-T68-SO duyệt; SIM-LDAP.
    Khi `PUT /ldap-federations/ldap-t68` với cơ sở tìm kiếm `ou=cntt`; `:test`.
    Và SO duyệt; `:sync`; xem báo cáo.
    Thì chỉ người dùng thuộc cơ sở đã duyệt được nhập, không tự gán vai trò đặc quyền; người trùng thư không tạo bản trùng mà được báo cáo; mật khẩu bind ở OpenBao.

  @TC-12-058 @P2 @Âm
  Kịch bản: TC-12-058 LDAP kiểm tra hỏng, trường chỉ đọc
    # Truy vết: FR-12-026 · API-12-048, 049 · ERR-12-032 · ERR-12-047
    Biết SIM-LDAP tắt hoặc sai mật khẩu bind.
    Khi `:test` liên kết sai; `PUT` với cơ sở tìm kiếm ngoài phạm vi.
    Và sửa trường do LDAP quản lý trên tài khoản đã đồng bộ.
    Thì `422` ERR-12-032 nêu nguyên nhân, không kèm mật khẩu; bước 2 `422` ERR-12-047.
