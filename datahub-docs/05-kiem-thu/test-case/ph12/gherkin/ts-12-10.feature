# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-10
Tính năng: TS-12-10 · Vai trò tùy biến của tenant (Đợt 2)

  @TC-12-037 @P2 @Dương
  Kịch bản: TC-12-037 Tạo, sửa, ngừng dùng vai trò tùy biến
    # Truy vết: FR-12-015 · UC-12-12 · UI-12-05 · API-12-022, 023, 024 · BR-12-008
    Biết U-T68-TA1, U-T68-SO.
    Khi `POST /roles` gói 3 quyền đọc; SO duyệt.
    Và `PATCH`; sau đó `:retire` khi chưa có ai dùng.
    Thì vai trò chỉ gán được sau khi duyệt; ngừng dùng khi không còn gán; KT: có.

  @TC-12-038 @P2 @Âm @Bảo @mật
  Kịch bản: TC-12-038 Vai trò tùy biến vượt trần quyền, tự duyệt, đang được dùng
    # Truy vết: FR-12-015 · BR-12-007, BR-12-008 · API-12-022, 024 · ERR-12-008, ERR-12-010, ERR-12-011
    Biết U-T68-TA1; vai trò tùy biến đã gán cho một người.
    Khi tạo vai trò chứa quyền `PERM-12-user-admin` ngoài trần của tenant.
    Và người soạn tự duyệt.
    Và `:retire` vai trò đang được gán.
    Thì bước 1 `422` ERR-12-010; bước 2 `403` ERR-12-008; bước 3 `409` ERR-12-011.
