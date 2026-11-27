# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-03
Tính năng: TS-20-03 · Sửa hồ sơ, đầu mối, hợp đồng và bảo vệ tenant đặc biệt

  @TC-20-013 @P1 @Dương
  Kịch bản: TC-20-013 Sửa tên, quy mô, ghi chú của tenant có If-Match và lý do
    # Truy vết: FR-20-004 · UC-20-03 · API-20-004 · BR-20-009 · UI-20-03 · `PERM-20-admin`
    Biết `U-PA1`; `T90` `ACTIVE`; `ETag` lần đọc trước.
    Khi `GET P/tenants/T90` lấy `ETag`
    Và `PATCH P/tenants/T90` với `name`, `note` (chứa `DH-CANARY-prof-edit`), `scaleProfile = QM-LON`, `reason` 25 ký tự, `ticketRef`, kèm `If-Match`
    Và `GET P/tenants/T90`
    Và `GET P/tenants/T90/status-history`
    Thì bước 2 `200`, `ETag` mới. Bước 3 trả giá trị mới, `tenantCode`, `realm`, `kind` giữ nguyên. KT: có `reason`, `ticketRef`, người sửa, giá trị trước và sau, vào chuỗi `T90` và `PLATFORM`. Mồi sạch ở `note` không xuất hiện trong log, sự kiện. Lịch sử trạng thái không đổi (không phải đổi trạng thái).

  @TC-20-014 @P1 @Âm
  Kịch bản: TC-20-014 Sửa hồ sơ thiếu If-Match, lệch phiên bản, thiếu lý do, đổi thuộc tính bất biến
    # Truy vết: FR-20-004 · API-20-004 · BR-20-001, 009 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-068, ERR-00-428
    Biết `U-PA1`, `U-PA2`; `T90`; `T88` đã `DECOMMISSIONED` (bản ghi cài sẵn).
    Khi `PATCH P/tenants/T90` thiếu `If-Match`
    Và `U-PA1` và `U-PA2` cùng đọc `ETag`, `U-PA1` sửa trước, `U-PA2` sửa sau cùng `ETag` cũ
    Và `PATCH` với `reason` 10 ký tự và không `ticketRef`
    Và `PATCH` với thân có `tenantCode = T89` hoặc `realm = dh-khac`
    Và `PATCH P/tenants/T88` (đã `DECOMMISSIONED`)
    Thì bước 1 `428` `ERR-00-428`. Bước 2 người sau `412` `ERR-20-005`, không mất cập nhật. Bước 3 `422` `ERR-20-008`. Bước 4 `422` `ERR-20-068`, không đổi gì. Bước 5 `409` `ERR-20-006`. Không có bản ghi kiểm toán thành công cho các lần bị từ chối.

  @TC-20-015 @P1 @Âm @Bảo @mật
  Kịch bản: TC-20-015 PLATFORM và COMMON không bị sửa, tạm ngừng, chấm dứt, tắt phân hệ
    # Truy vết: FR-20-006 · API-20-004, 065, 066, 071, 047 · BR-20-003 · ERR-20-010 · `PERM-20-lifecycle`
    Biết `U-PA1`; `PLATFORM`, `COMMON`; khối DB của `ph20_isolation_test.sql` mục 1 (trigger bảo vệ tenant).
    Khi `PATCH P/tenants/PLATFORM` đổi `name`
    Và `POST P/tenants/COMMON/lifecycle-requests` với `requestType = SUSPEND`
    Và `POST P/tenants/COMMON/lifecycle-requests` với `requestType = TERMINATE`
    Và `POST P/tenants/PLATFORM/modules/PH-16:disable`
    Và `POST P/tenants/COMMON/isolation-changes` với `targetMode = DEDICATED_DB`
    Và chạy khối kiểm trigger bảo vệ tenant bằng `psql` dưới chủ schema
    Thì bước 1 đến 5 `403` `ERR-20-010`, tenant không đổi. Bước 6 trigger từ chối cập nhật trạng thái, xóa dòng `PLATFORM`, `COMMON` (PASS theo tệp kiểm). Không phát sự kiện đổi trạng thái.

  @TC-20-016 @P2 @Dương
  Kịch bản: TC-20-016 Thêm, sửa, ngừng đầu mối; thêm, gia hạn hợp đồng dịch vụ
    # Truy vết: FR-20-005 · API-20-007, 008, 009, 010, 011, 012 · BR-20-009 · UI-20-03 · `PERM-20-admin`
    Biết `U-PA1`; `T90` có ba đầu mối; hợp đồng `HD-T90-2026` hiệu lực đến 31/12/2026.
    Khi `GET P/tenants/T90/contacts`
    Và `POST P/tenants/T90/contacts` vai trò `SECURITY`, `fullName`, `officialEmail` (miền `example.vn`), `phone`
    Và `PATCH P/tenants/T90/contacts/{contactId}` đổi `position`, kèm `If-Match`
    Và `PATCH` đầu mối vừa thêm với `active = false`
    Và `POST P/tenants/T90/contracts` với `contractNo = HD-T90-2027`, `validFrom`, `validTo`, `serviceLevel = PREMIUM`
    Và `PATCH P/tenants/T90/contracts/{contractId}` gia hạn `validTo`
    Và `GET P/tenants/T90/contracts`
    Thì bước 1 có ba đầu mối. Bước 2 `201`. Bước 3, 4 `200` đổi đúng trường. Bước 5 `201`. Bước 6 `200`, `ETag` mới. Bước 7 liệt kê hai hợp đồng. Mọi thao tác ghi có KT kèm `reason`, `ticketRef`; email không xuất hiện trong log (mồi sạch).

  @TC-20-017 @P2 @Âm
  Kịch bản: TC-20-017 Ngừng đầu mối quản trị cuối cùng, hợp đồng sai thời hạn, trùng, sai định dạng
    # Truy vết: FR-20-005 · API-20-008, 009, 011, 012 · ERR-20-004, ERR-20-005, ERR-20-021, ERR-20-022, ERR-20-008
    Biết `U-PA1`; `T91` chỉ có một đầu mối `TENANT_ADMIN`.
    Khi `PATCH` đầu mối `TENANT_ADMIN` duy nhất của `T91` với `active = false`
    Và `POST P/tenants/T91/contacts` với `officialEmail = khong-phai-email`
    Và `POST P/tenants/T91/contracts` với `validTo` trước `validFrom`
    Và `POST P/tenants/T91/contracts` chồng khoảng hiệu lực lên hợp đồng đang `ACTIVE`
    Và `PATCH` hợp đồng với `If-Match` cũ
    Và `PATCH` đầu mối không có `reason`
    Thì bước 1 `422` `ERR-20-021`. Bước 2 `400` `ERR-20-004`. Bước 3, 4 `422` `ERR-20-022`. Bước 5 `412` `ERR-20-005`. Bước 6 `422` `ERR-20-008`. Không đổi dữ liệu.

  @TC-20-018 @P2 @Dương
  Kịch bản: TC-20-018 Tenant đặc biệt vẫn đọc được, registry luôn ACTIVE, tenant tỉnh sửa bình thường
    # Truy vết: FR-20-006 · API-20-003, 004, 162, 163 · BR-20-009 · UC-20-03
    Biết `U-PA1`, `S-PH03`; `PLATFORM`, `COMMON`, `T90` `ACTIVE`.
    Khi `GET P/tenants/PLATFORM` và `GET P/tenants/COMMON`
    Và `S-PH03` `GET I/tenants` và `GET I/tenants?kind=PROVINCE`
    Và `PATCH P/tenants/T90` đổi `displayName`, kèm `If-Match`, `reason`, `ticketRef`
    Thì bước 1 `200`, hiển thị `kind`, trạng thái `ACTIVE`. Bước 2 registry luôn trả `PLATFORM`, `COMMON` `ACTIVE`; lọc `kind=PROVINCE` không có hai tenant này. Bước 3 `200` (lớp chặn tenant đặc biệt không cản tenant tỉnh).
