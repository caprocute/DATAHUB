# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-10
Tính năng: TS-20-10 · Xem phiên bản, so sánh, khôi phục cấu hình và xử lý lệch

  @TC-20-045 @P2 @Dương
  Kịch bản: TC-20-045 Liệt kê, so sánh và khôi phục phiên bản cấu hình
    # Truy vết: FR-20-021 · UC-20-10 · API-20-041, 042, 043 · BR-20-010 · EVT-20-09 · UI-20-17 · `PERM-20-admin`
    Biết `U-PA1`, `U-PO`; `T90` có phiên bản cấu hình 1…7; phiên bản 5 khác 7 ở `apiPathPrefix` và `drRegion`.
    Khi `GET P/tenants/T90/config-versions?scope=PLATFORM_CONFIG`
    Và `GET P/tenants/T90/config-versions/7?compareTo=5`
    Và `POST P/tenants/T90/config-versions/5:restore` với `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
    Và `GET P/tenants/T90/config-versions` bằng `U-PO`
    Thì bước 1 danh sách có số phiên bản, thời điểm, người, tệp đổi, lý do, `syncStatus`. Bước 2 khác biệt theo khóa YAML đúng hai khóa `apiPathPrefix`, `drRegion` (UI hiển thị bằng `CMP-DiffViewer` có ký hiệu thêm, đổi, xóa). Bước 3 `202`, tạo phiên bản 8 mang nội dung của 5, lịch sử 1…7 còn nguyên, `APPLIED` sau Argo CD, EVT-20-09. Bước 4 `U-PO` xem được, không có nút khôi phục.

  @TC-20-046 @P2 @Âm
  Kịch bản: TC-20-046 Khôi phục phiên bản không tương thích, không có phiên bản, thiếu lý do
    # Truy vết: FR-20-021 · API-20-042, 043 · ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-026, ERR-00-428
    Biết `U-PA1`; phiên bản 1 của `T90` có lược đồ cũ không chuyển đổi được; `PLATFORM`.
    Khi `POST P/tenants/T90/config-versions/1:restore`
    Và `POST P/tenants/T90/config-versions/99:restore`
    Và `GET P/tenants/T90/config-versions/5?compareTo=khong-so`
    Và `POST .../5:restore` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
    Và `POST P/tenants/PLATFORM/config-versions/1:restore`
    Thì bước 1 `422` `ERR-20-026`, chỉ cho xem tệp gốc. Bước 2 `404` `ERR-20-002`. Bước 3 `400` `ERR-20-004`. Bước 4 lần lượt `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-20-010`. Không có commit mới.

  @TC-20-047 @P2 @Dương
  Kịch bản: TC-20-047 Phát hiện lệch, cảnh báo khóa an ninh, REAPPLY và ACCEPT
    # Truy vết: FR-20-022 · UC-20-10 · API-20-044, 045, 046 · BR-20-010 · NFR-20-010 · UI-20-17 · `PERM-20-admin`
    Biết `U-PA1`, `U-PO`; `T90` `IN_SYNC`; `argo-sim` `OutOfSync` ở ứng dụng `t90-gateway` (khóa thường) và `iam-sim` báo lệch chính sách realm (khóa an ninh); `clock-sim` đẩy 1 giờ.
    Khi tạo hai lệch; đẩy `clock-sim` tới chu kỳ `20.drift.check-interval` (PT1H)
    Và `GET P/tenants/T90/config-drifts?status=DRIFTED`
    Và `POST P/tenants/T90/config-drifts/{driftId-thường}:resolve` với `action = ACCEPT`, `reason`, `ticketRef`
    Và `POST .../{driftId-an-ninh}:resolve` với `action = REAPPLY`
    Và `POST P/tenants/T90/config:reconcile`
    Thì bước 1 hai bản ghi `DRIFTED` trong ≤ 1 giờ; lệch khóa an ninh cảnh báo PO ngay qua PH-13, khóa thường gộp báo hằng ngày. Bước 3 `202`, giá trị thực ghi vào CSDL và Git, lệch `IN_SYNC`. Bước 4 `202`, Argo CD đồng bộ lại hoặc gọi API-12-083, lệch `IN_SYNC`. Bước 5 `202`, `driftStatus = IN_SYNC` sau lần đối chiếu.

  @TC-20-048 @P2 @Âm
  Kịch bản: TC-20-048 ACCEPT khóa an ninh, đối chiếu chồng, thiếu lý do, Argo CD không khả dụng
    # Truy vết: FR-20-022 · API-20-044, 045, 046 · ERR-20-002, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-004
    Biết `U-PA1`; `T90` có lệch khóa an ninh; `T91` đang có đối chiếu chạy; `argo-sim` ngừng.
    Khi `POST .../config-drifts/{driftId-an-ninh}:resolve` với `action = ACCEPT`
    Và `POST P/tenants/T91/config:reconcile` khi đang đối chiếu
    Và `POST .../:resolve` không có `reason`
    Và `POST .../config-drifts/khong-co:resolve`; `action = XOA`
    Và `argo-sim` ngừng, chạy chu kỳ đối chiếu
    Và `POST P/tenants/COMMON/config:reconcile`
    Thì bước 1 `409` `ERR-20-006` (khóa an ninh chỉ `REAPPLY`). Bước 2 `409` `ERR-20-006` (đang đối chiếu). Bước 3 `422` `ERR-20-008`. Bước 4 `404` `ERR-20-002`, rồi `400` `ERR-20-004`. Bước 5 `driftStatus = UNKNOWN`, không sinh lệch giả. Bước 6 `403` `ERR-20-010`.
