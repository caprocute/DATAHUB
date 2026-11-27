# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-09
Tính năng: TS-20-09 · Cấu hình nền tảng của tenant và ghi vào kho GitOps

  @TC-20-041 @P1 @Dương
  Kịch bản: TC-20-041 Sửa cấu hình nền tảng, commit ký, Argo CD áp, phát sự kiện
    # Truy vết: FR-20-019, 020 · UC-20-09 · API-20-039, 040 · BR-20-010 · NFR-20-011 · EVT-20-09 · UI-20-03 · `PERM-20-admin`
    Biết `U-PA1`; `T90` `IN_SYNC`; `git-sim` ký commit bằng khóa dịch vụ `svc-ph20-gitops` (`<bi-mat-mau>`); `argo-sim` `Synced`, `Healthy`.
    Khi `GET P/tenants/T90/platform-config` lấy `ETag`
    Và `PUT P/tenants/T90/platform-config` đổi `publicHost`, `apiPathPrefix = /t90`, `drRegion`, `reason`, `ticketRef`, kèm `If-Match`
    Và theo dõi `syncStatus` bằng `GET P/tenants/T90/platform-config`
    Và đọc commit mới nhất ở `tenants/T90/` trong `git-sim`
    Thì bước 2 `200`, `ETag` và `configVersionNo` tăng, `syncStatus = COMMITTED`. Bước 3 chuyển `APPLIED` trong ≤ 5 phút, có `commitSha`, `appliedAt`. Bước 4 thông điệp theo mẫu `ph20(T90): ... [TC-PH20-001]`, có chữ ký, tệp `tenant.yaml` đúng lược đồ, không chứa bí mật hay `DH-CANARY`. EVT: `platform.tenant.config-changed.v1` (EVT-20-09) đúng một lần sau `APPLIED`, kèm `configVersionNo`, `commitSha`. PH-03 dựng lại route.

  @TC-20-042 @P1 @Âm
  Kịch bản: TC-20-042 Sửa cấu hình: host trùng, đổi realm, đang lệch, thiếu quyền, thiếu If-Match
    # Truy vết: FR-20-019 · API-20-040 · BR-20-001, 009 · ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-025, ERR-20-067, ERR-20-068, ERR-00-428
    Biết `U-PA1`; `T90` host `api.t90.example.vn`, `T91` host `api.t91.example.vn`; `T96` đang `DRIFTED`.
    Khi `PUT P/tenants/T90/platform-config` với `publicHost = api.t91.example.vn`
    Và `PUT` với `apiPathPrefix = /T 90` (sai mẫu)
    Và `PUT` thân có `realm = dh-t99`
    Và `PUT P/tenants/T96/platform-config` khi cấu hình đang lệch
    Và `PUT` thiếu `If-Match`; `PUT` với `If-Match` cũ; `PUT` thiếu `reason`
    Và `PUT P/tenants/PLATFORM/platform-config`
    Thì bước 1 `409` `ERR-20-067`. Bước 2 `400` `ERR-20-004` (mẫu `^/[a-z0-9-]{2,30}$`). Bước 3 `422` `ERR-20-068`. Bước 4 `409` `ERR-20-025`. Bước 5 lần lượt `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`. Không đổi dữ liệu, không commit.

  @TC-20-043 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-20-043 Ghi Git lỗi, xung đột đẩy, Argo CD không áp được
    # Truy vết: FR-20-020 · API-20-040, 039 · BR-20-010 · ERR-20-024, ERR-20-109 · NFR-20-011 · UI-20-03, 17
    Biết `U-PA1`; `T90`; `git-sim` kịch bản từ chối đẩy; kịch bản commit xen kẽ; `argo-sim` `Degraded` quá 10 phút.
    Khi `PUT P/tenants/T90/platform-config` khi `git-sim` từ chối đẩy
    Và bật lại `git-sim`, quan sát outbox thử lại
    Và chèn commit khác vào `tenants/T90/` rồi lưu cấu hình
    Và `argo-sim` trả `Degraded` hơn 10 phút
    Thì bước 1 `502` `ERR-20-024`; giao dịch nghiệp vụ đã lưu, `syncStatus = PENDING`, UI-20-17 hiện "chờ ghi Git". Bước 2 outbox thử lại và `APPLIED`, sự kiện EVT-20-09 phát một lần. Bước 3 hệ thống kéo lại, sinh lại tệp từ CSDL, thử tối đa 3 lần, kết quả đúng. Bước 4 `syncStatus = SYNC_FAILED`, `ERR-20-109` ("Argo CD không áp được cấu hình 8: kho Git từ chối kết nối.") ở nhật ký, cảnh báo PO.

  @TC-20-044 @P1 @Bảo @mật
  Kịch bản: TC-20-044 Không lưu bí mật trong CSDL hay kho Git
    # Truy vết: FR-20-020 · NFR-20-024 · BR-20-010 · API-20-040, 036 · UC-20-09
    Biết `U-PA1`; `T90`; chuỗi mồi `DH-CANARY-cfg-secret`; công cụ quét bí mật trên kho `dh-tenant-config`.
    Khi đặt cấu hình có tham chiếu bí mật `<bi-mat-mau>` ở trường `note` và đăng ký cụm kèm `secretRef`
    Và quét kho Git, bảng `tenant_platform_config`, `tenant_config_version` bằng công cụ quét bí mật
    Và tìm chuỗi mồi trong log, vết OTel, sự kiện EVT-20-09
    Thì chỉ có tham chiếu đường dẫn `kv/dh/{ma}/...`, không có giá trị bí mật; quét 0 phát hiện; chuỗi mồi không xuất hiện ngoài bản ghi nhập.
