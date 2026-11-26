# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-10
Tính năng: TS-15-10 · Đăng nhập, phiên và hồ sơ

  @TC-15-061 @P1 @Dương
  Kịch bản: TC-15-061 Cán bộ đăng nhập SSO realm tenant
    # Truy vết: FR-15-019 · UC-15-10 · API-15-041 · UI-15-08 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-OR có tài khoản Keycloak realm T68; chưa có tài khoản cổng.
    Khi bấm Đăng nhập ở UI-15-08 (`/bff/dang-nhap`), xác thực ở Keycloak.
    Và `GET /me`.
    Thì chuyển về cổng bằng Authorization Code + PKCE; tạo tài khoản cổng `ACTIVE`, nguồn `TENANT_SSO`; cookie phiên `HttpOnly`, `Secure`, `SameSite`; hạng người xem `TENANT_USER`; đăng xuất `/bff/dang-xuat` hủy phiên.

  @TC-15-062 @P1 @Âm
  Kịch bản: TC-15-062 Tài khoản chưa duyệt, khóa, hết phiên
    # Truy vết: FR-15-019 · UC-15-10 · UI-15-08 · ERR-15-004, 011, 014 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tài khoản dh-dev PENDING_EMAIL, PENDING_APPROVAL, LOCKED, DISABLED; phiên đã hết hạn.
    Khi đăng nhập từng tài khoản.
    Và gọi `GET /me` với cookie hết hạn.
    Thì `422` ERR-15-011 cho hai tài khoản chưa duyệt; `403` ERR-15-014 cho LOCKED, DISABLED; `401` ERR-15-004 và UI đưa về đăng nhập rồi quay lại đường dẫn cũ.

  @TC-15-063 @P1 @Âm
  Kịch bản: TC-15-063 Keycloak lỗi nhưng trang công khai vẫn xem được
    # Truy vết: FR-15-019 · UC-15-10 · UI-15-08 · ERR-15-020 · NFR-15-008 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt Keycloak; `15.public.enabled = true`.
    Khi bấm Đăng nhập.
    Và khách mở `/dich-vu`, `/huong-dan`.
    Thì bước 1 `503` ERR-15-020 "Dịch vụ định danh tạm thời chưa phản hồi. Thử lại sau."; bước 2 (trang công khai vẫn xem được) `200`.

  @TC-15-064 @P2 @Dương
  Kịch bản: TC-15-064 Hồ sơ và thu hồi phiên của mình
    # Truy vết: FR-15-021 · UC-15-12 · API-15-041, 042, 043, 044 · UI-15-09 · BR-15-034 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN đăng nhập trên hai trình duyệt.
    Khi `PUT /me` đổi số điện thoại với `If-Match`.
    Và `GET /me/sessions`; `DELETE /me/sessions/{phiên kia}`.
    Thì hồ sơ đổi, KT; phiên kia bị hủy ngay (lệnh kế trả `401`); phiên hiện tại giữ.

  @TC-15-065 @P2 @Âm
  Kịch bản: TC-15-065 Sai ETag, giá trị sai, thu hồi phiên người khác
    # Truy vết: FR-15-021 · API-15-042, 044 · ERR-15-003, 005, 006 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN, U-T68-DEV-CU.
    Khi `PUT /me` với `If-Match` cũ; số điện thoại sai định dạng.
    Và cự `DELETE /me/sessions/{phiên của An}`.
    Thì `412` ERR-15-006; `400` ERR-15-003; `403` ERR-15-005 và phiên của An không đổi.
