# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-25
Tính năng: TS-12-25 · Realm của tenant: khởi tạo, GitOps, vòng đời

  @TC-12-076 @P1 @Dương @Âm
  Kịch bản: TC-12-076 Khởi tạo realm T90 từ mẫu
    # Truy vết: FR-12-041 · UC-12-29 · UI-12-19 · API-12-080, 081 · ERR-12-041 · NFR-12-010 · LGC-IAM-002 · SEC-20
    Biết S-PH20; tenant T90 chưa có realm.
    Khi `POST /realms` cho T90; theo dõi đến `ACTIVE`; gọi lại lần hai cùng khóa.
    Và `POST /realms` cho tenant đã có realm hoặc tenant `SUSPENDED`.
    Thì `ACTIVE` ≤ 5 phút; có vai trò chuẩn, client `dh-console`, chính sách mật khẩu `argon2id` hoặc `pbkdf2-sha512` ≥ 210.000 vòng; lần hai không tạo bản sao; bước 2 `409` ERR-12-041.

  @TC-12-077 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-12-077 Phát hiện lệch cấu hình và áp lại, TA không sửa được cấu hình bảo mật
    # Truy vết: FR-12-042 · UC-12-29 · UI-12-19 · API-12-082, 083 · BR-12-038 · ERR-12-042 · THR-38
    Biết realm T90; sửa tay `password-min-length=8` bằng quản trị Keycloak; U-T68-TA1.
    Khi `GET …/drift`; `:reconcile`; gọi `:reconcile` thứ hai khi đang chạy.
    Và TA tìm quyền `manage-realm`, `manage-clients` trong Keycloak.
    Thì drift báo trường lệch; sau áp lại giá trị về mẫu; lần gọi chồng `409` ERR-12-042; TA không có ba quyền quản trị Keycloak.

  @TC-12-078 @P1 @Dương @Âm
  Kịch bản: TC-12-078 Tạm ngừng, khôi phục, chỉ đọc; thao tác sai trạng thái
    # Truy vết: FR-12-043 · UC-12-30 · UI-12-19 · API-12-084, 085 · ERR-12-041 · ERR-12-121
    Biết S-PH20; realm T90 `ACTIVE`.
    Khi `:suspend`; đăng nhập người dùng T90; `:resume`.
    Và `:resume` khi đang `ACTIVE`; `:suspend` realm đang `PROVISIONING`.
    Thì bước 1 đăng nhập bị từ chối ERR-12-121, sau khôi phục dùng lại được, dữ liệu nguyên vẹn; bước 2 `409` ERR-12-041.
