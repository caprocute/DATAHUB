# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-05
Tính năng: TS-18-05 · Xuất, nhập gói tham số giữa môi trường

  @TC-18-016 @P3 @Dương
  Kịch bản: TC-18-016 Xuất gói từ STAGING, nhập chạy thử và áp vào TEST, khóa ★ chờ duyệt
    # Truy vết: FR-18-008 · API-18-017, 018, 019 · BR-18-004, 048 · EVT-18-01, 02 · UI-18-08
    # Mục đích: Chứng minh đường đi của gói: xuất có SHA-256, nhập `dryRun = true` chỉ so khớp, áp gói ghi khóa thường và tạo đề nghị cho khóa ★.
    Biết T68 ở STAGING có 12 khóa `04.` trong đó 2 khóa ★; T90 ở TEST; U-PA1, U-PA2 (`PERM-18-admin`, `PERM-18-approve`).
    Khi U-PA1 `POST /param-bundles:export` cho `ns = 04.` của T68.
    Và kiểm nội dung gói: không có giá trị bí mật, chỉ tham chiếu `kv/dh/t68/...`.
    Và U-PA1 `POST /param-bundles:import` vào T90 (mặc định `dryRun = true`).
    Và U-PA1 `POST /param-bundles/{bundleId}:apply`; U-PA2 duyệt hai đề nghị khóa ★.
    Thì bước 1 `200`, gói có `manifestSha256` và chữ ký. Bước 2 đạt. Bước 3 `200`, báo 10 khóa đổi, 2 khóa ★, không có giá trị nào ghi. Bước 4 10 khóa có phiên bản mới, EVT-18-01 phát; 2 đề nghị `PENDING_APPROVAL` (EVT-18-02), sau khi U-PA2 duyệt mới `ACTIVE`.

  @TC-18-017 @P3 @Âm @Bảo_mật
  Kịch bản: TC-18-017 Gói bị sửa, giá trị ngoài miền đích và người áp tự duyệt khóa ★
    # Truy vết: FR-18-008 · API-18-018, 019, 010 · BR-18-002, 004, 048 · ERR-18-005, 013, 020
    # Mục đích: Chứng minh gói bị đổi một byte bị từ chối, so khớp chặn giá trị ngoài miền của môi trường đích, và bốn mắt của gói không có đường vòng.
    Biết gói `BUNDLE-T68-04` từ ca trước; bản sửa tay đổi một giá trị; gói có `04.retry.max-attempts = 9` trong khi trần của T92 là 5.
    Khi nhập bản đã sửa tay vào T90.
    Và nhập gói gốc vào T92.
    Và U-PA1 áp gói vào T90 rồi tự duyệt đề nghị khóa ★ vừa sinh.
    Thì bước 1 `422` ERR-18-020 (tổng kiểm tra lệch). Bước 2 `422` ERR-18-013 liệt kê khóa ngoài miền, không ghi khóa nào. Bước 3 `403` ERR-18-005.
