# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-25
Tính năng: TS-04-25 · Catalog, chính sách thành phần, hồ sơ runtime

  @TC-04-146 @P2 @Dương
  Kịch bản: TC-04-146 Đề xuất cho phép thành phần và quyết định
    # Truy vết: FR-04-080 · API-04-074, 072 · UI-04-17 · UC-04-21.
    Biết `smb` có `policy = DENIED`; IE1, U-PA.
    Khi IE1 tạo đề xuất `ALLOW` `smb` với lý do 50 ký tự.
    Và U-PA `:decide` `ACCEPTED`, `policyDecision = PER_FLOW`.
    Và IE1 xem `GET /catalog`.
    Thì bước 1 trả `201`, `status = OPEN`. Bước 2 trả `200`; chính sách nền `smb` thành `PER_FLOW`, `policyVersion` tăng. Bước 3: `smb` hiện với nhãn "Cần duyệt từng luồng". KT: có (`INT_POLICY_CHANGE`).

  @TC-04-147 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-147 Tỉnh chỉ thu hẹp được chính sách
    # Truy vết: FR-04-080 · BR-04-014 · API-04-072.
    Biết U-T68-TA; `exec` bị cấm ở nền.
    Khi TA `PATCH /catalog/policies` với `{"changes":[{"kind":"COMPONENT","name":"ftp","decision":"DENIED","reason":"Tỉnh không dùng FTP thường"}]}`.
    Và TA `PATCH` với `exec` → `ALLOWED`.
    Và TA `PATCH` với `ftp` → `INHERIT`.
    Thì bước 1 trả `200`. Bước 2 trả 403-PQ (tỉnh không nới chính sách); kể cả khi gọi thẳng CSDL, ràng buộc `ck_component_policy_narrow` chặn. Bước 3 trả `200`, `ftp` theo nền.

  @TC-04-148 @P1 @Dương @Âm
  Kịch bản: TC-04-148 Khớp phiên bản catalog với runtime
    # Truy vết: FR-04-081 · BR-04-020 · API-04-073.
    Biết catalog designer 3.33.1 (Camel 4.18.2), runtime Camel Quarkus 3.33.2 (Camel 4.18), đúng trạng thái của mã sau PR #5.
    Khi gọi `GET /catalog/versions`.
    Và chạy `npm run catalog:check` trong CI với `pom.xml` runtime đổi sang Camel 4.19.
    Thì bước 1: `match = true`; mỗi hồ sơ có `camelQuarkusVersion`, `camelVersion`, `imageDigest`. Bước 2: job thất bại, chặn hợp nhất, thông điệp nêu hai phiên bản lệch.

  @TC-04-149 @P2 @Âm
  Kịch bản: TC-04-149 Nâng catalog: luồng soạn trên catalog cũ
    # Truy vết: FR-04-081 · BR-04-020 · UC-04-22 · ERR-04-042.
    Biết F-HT v4 soạn trên catalog `cv-1`; PA nâng T68 lên `cv-2`.
    Khi gọi `GET /catalog/versions`.
    Và IE1 `:submit` v4.
    Và IE1 mở v4, chọn "Nâng lên danh mục mới", kiểm, gửi lại.
    Thì bước 1: `pendingUpgrade.affectedFlows ≥ 1` trước khi nâng. Bước 2 trả `409` ERR-04-042. Bước 3: định nghĩa ghi `catalogVersion = cv-2`, kiểm tra lại trên catalog mới, gửi được. `system:int-catalog` đánh dấu luồng bị ảnh hưởng.

  @TC-04-150 @P2 @Hiệu @năng
  Kịch bản: TC-04-150 Ảnh native khởi động và nạp luồng
    # Truy vết: FR-04-075 · NFR-04-013.
    Biết ảnh `core-native` dựng ở CI-8.
    Khi khởi động pod không có luồng, đo tới `/q/health/ready`.
    Và khởi động với 50 ConfigMap luồng.
    Thì bước 1 < 1 giây. Bước 2 < 5 giây. Ảnh có chữ ký Cosign, SBOM, không có lỗ hổng mức Cao theo Trivy.

  @TC-04-200 @P3 @Dương @Âm
  Kịch bản: TC-04-200 Trạng thái màn Danh mục thành phần
    # Truy vết: FR-04-080 · UI-04-17 · ERR-04-025, 045.
    Biết U-T68-IE1 (không có quyền quản lý chính sách); U-T68-TA.
    Khi IE1 mở UI-04-17, lọc "Native: Không" và tìm "khong-co".
    Và IE1 chọn dòng `exec`.
    Và TA mở drawer `sftp`, đặt "Không được phép" mà để trống lý do, bấm "Lưu".
    Thì bước 1: skeleton cây 10 dòng, bảng 8 dòng; sau lọc là ST-04. Bước 2: cột "Được phép" hiện chữ, nút quản lý ẩn; drawer mở bằng `Enter`, đóng bằng `Esc`, `F6` chuyển giữa cây và bảng. Bước 3: ERR-04-025 tại trường lý do, chính sách không đổi. Dòng chân trang hiện phiên bản catalog và "khớp runtime".
