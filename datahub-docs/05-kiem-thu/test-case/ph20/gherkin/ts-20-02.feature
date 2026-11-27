# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-02
Tính năng: TS-20-02 · Khai báo tenant mới và kiểm tra sẵn sàng

  @TC-20-005 @P1 @Dương
  Kịch bản: TC-20-005 Khai báo tenant T93 với hồ sơ đầy đủ
    # Truy vết: FR-20-001 · UC-20-02 · API-20-002 · BR-20-001, 002, 009 · UI-20-02 · `PERM-20-provision`
    Biết `U-PA1`; F-HS-93; mẫu `tinh-chuan` v3 `PUBLISHED`; ĐVHC của `T93` còn hiệu lực, chưa có tenant.
    Khi `POST P/tenants` thân F-HS-93 (`tenantCode = T93`, `testTenant = true`, `modulesExcluded = [PH-17]`), kèm `Idempotency-Key`, `reason`, `ticketRef` chuẩn
    Và `GET P/tenants/T93`
    Và `GET P/tenants/T93/contacts`
    Thì bước 1 `201`, `Location` trỏ `P/tenants/T93`, `status = PROVISIONING`, `kind = PROVINCE`, `realm = dh-t93`, `templateVersion = 3`, `isolationMode = SHARED`. Bước 2 `200` khớp hồ sơ. Bước 3 có ba đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL`. Chưa tạo lần chạy saga, chưa phát EVT-20-01 (chỉ phát sau `S05_BUCKETS`). KT: bản ghi khai báo vào chuỗi `PLATFORM` kèm `reason`, `ticketRef`. Mồi sạch với chuỗi `DH-CANARY-reg-ok` đặt ở `note`.

  @TC-20-006 @P1 @Âm
  Kịch bản: TC-20-006 Mã tenant sai mẫu, trong dải kiểm thử, trùng hoặc đã dùng
    # Truy vết: FR-20-001 · API-20-002 · BR-20-001 · ERR-20-003, ERR-20-004 · UI-20-02
    Biết `U-PA1`; `T93` đã khai báo ở ca trước; `T88` từng `DECOMMISSIONED` (bản ghi cài sẵn).
    Khi khai báo với `tenantCode = X93`
    Và khai báo với `tenantCode = T7`
    Và khai báo `tenantCode = T95` với `testTenant = false`
    Và khai báo lại `tenantCode = T93`
    Và khai báo `tenantCode = T88` (mã đã `DECOMMISSIONED`)
    Thì bước 1, 2, 3 `400` `ERR-20-004` (mẫu `^T\d{2}$`; dải `T90…T99` chỉ với `testTenant = true`), `errors[]` trỏ `tenantCode`. Bước 4, 5 `409` `ERR-20-003`; mã đã dùng không được cấp lại kể cả tenant đã chấm dứt. Không tạo bản ghi nào.

  @TC-20-007 @P1 @Âm
  Kịch bản: TC-20-007 ĐVHC đã có tenant, không phải cấp tỉnh hoặc hết hiệu lực
    # Truy vết: FR-20-001, 007 · API-20-002 · BR-20-002 · ERR-20-011, ERR-20-012
    Biết `U-PA1`; ĐVHC `adm-t90` đã gắn `T90`; ĐVHC cấp xã `adm-xa-01`; ĐVHC cấp tỉnh đã hết hiệu lực `adm-cu`.
    Khi khai báo `tenantCode = T96` với `adminUnitId = adm-t90`
    Và khai báo `T96` với `adminUnitId = adm-xa-01`
    Và khai báo `T96` với `adminUnitId = adm-cu`
    Thì bước 1 `409` `ERR-20-011`. Bước 2, 3 `422` `ERR-20-012`. Mỗi tỉnh có tối đa một tenant không ở trạng thái cuối. Không tạo bản ghi.

  @TC-20-008 @P1 @Âm
  Kịch bản: TC-20-008 Mẫu không dùng được, thiếu đầu mối, cụm đích chưa đạt
    # Truy vết: FR-20-001, 007 · API-20-002 · ERR-20-015, ERR-20-021, ERR-20-064
    Biết `U-PA1`; mẫu `tinh-nho` v1 `DRAFT`; mẫu `tinh-chuan` v2 `RETIRED`; cụm `cl-thu-01` đã đăng ký nhưng chưa `verify`.
    Khi khai báo với `templateCode = tinh-nho`, `templateVersion = 1`
    Và khai báo với `templateCode = tinh-chuan`, `templateVersion = 2`
    Và khai báo với `contacts` chỉ có vai trò `TECHNICAL`
    Và khai báo `isolationMode = DEDICATED_CLUSTER`, `clusterCode = cl-thu-01`
    Thì bước 1, 2 `422` `ERR-20-015` (mẫu chưa phát hành, đã ngừng). Bước 3 `422` `ERR-20-021` (thiếu `TENANT_ADMIN`). Bước 4 `422` `ERR-20-064` (cụm chưa đạt, FR-20-017 đợt 2). Không tạo bản ghi.

  @TC-20-009 @P1 @Biên
  Kịch bản: TC-20-009 Khai báo lặp cùng khóa chống lặp và khóa dùng cho yêu cầu khác
    # Truy vết: FR-20-001 · API-20-002 · ERR-20-009, ERR-20-004 · NFR-20-020
    Biết `U-PA1`; F-HS-93 với mã `T94`; khóa `ik-reg-1`.
    Khi `POST P/tenants` hồ sơ `T94` với `Idempotency-Key = ik-reg-1`
    Và gửi lại đúng thân, đúng khóa
    Và gửi `Idempotency-Key = ik-reg-1` với thân khác (`tenantCode = T95`)
    Và gửi không có `Idempotency-Key`
    Thì bước 1 `201`. Bước 2 `201` cùng thân, cùng `Location`, chỉ có một bản ghi `T94`. Bước 3 `409` `ERR-20-009`. Bước 4 `400` `ERR-20-004`, `errors[]` trỏ tiêu đề `Idempotency-Key` (đề nghị ĐN-TC-03 xác nhận mã). Chỉ một bản ghi kiểm toán khai báo.

  @TC-20-010 @P1 @Dương
  Kịch bản: TC-20-010 Kiểm tra sẵn sàng cho hồ sơ chưa lưu và hồ sơ đã lưu
    # Truy vết: FR-20-007 · UC-20-02 · API-20-005, 006 · UI-20-02 · `PERM-20-provision`
    Biết `U-PA1`; F-HS-93; sức chứa còn trống; PH-12, PH-13, PH-07 giả lập sẵn sàng.
    Khi `POST P/tenants:check-readiness` với thân hồ sơ chưa lưu (`tenantCode = T96`)
    Và `POST P/tenants/T93:check-readiness`
    Thì bước 1, 2 `200`, `ready = true`, `items[]` có đủ mười mục `CODE_UNIQUE`, `ADMIN_UNIT`, `CAPACITY`, `CLUSTER_RESOURCES`, `TEMPLATE`, `CONTACTS`, `HOST_PREFIX`, `DEPENDENCIES`, `CLUSTER_TARGET`, `CONTRACT` với mức qua; `CLUSTER_TARGET` không áp dụng ở chế độ `SHARED`. Không tạo bản ghi, không có kiểm toán ghi.

  @TC-20-011 @P1 @Âm
  Kịch bản: TC-20-011 Hết sức chứa nền tảng và thiếu tài nguyên cụm
    # Truy vết: FR-20-007 · API-20-005, 006 · BR-20-002 · ERR-20-013, ERR-20-014, ERR-20-017 · NFR-20-005
    Biết `U-PA1`; `obs-sim` báo `EVT-13-14` cảnh báo sức chứa: nền tảng đã có 34 tenant tỉnh (trần giả định theo NFR-00-060); cụm `HT-A` thiếu 8 CPU ảo.
    Khi `POST P/tenants:check-readiness` với hồ sơ `T96`
    Và `POST P/tenants:check-readiness` với `deploymentProfile = HT-A`
    Và `POST P/tenants/T93:check-readiness` khi còn hai mục `BLOCKER`
    Thì bước 1 `422` `ERR-20-013` ở mục `CAPACITY` và `ERR-20-017` tổng. Bước 2 `422` `ERR-20-014` ở `CLUSTER_RESOURCES` (thiếu 8 CPU ảo). Bước 3 `422` `ERR-20-017` với `items[]` nêu hai mục cần xử lý. Cảnh báo sức chứa nhận từ `EVT-13-14` hiển thị ở UI-20-20.

  @TC-20-012 @P2 @Âm @Chịu @lỗi
  Kịch bản: TC-20-012 Kiểm tra sẵn sàng khi phụ thuộc không khả dụng
    # Truy vết: FR-20-007 · API-20-005, 006 · ERR-20-062 · NFR-20-017
    Biết `U-PA1`; `iam-sim` trả `503` cho API-12-080 thăm dò.
    Khi `POST P/tenants:check-readiness` với hồ sơ `T96`
    Và bật lại `iam-sim`, lặp bước 1
    Thì bước 1 `503` `ERR-20-062` với tên dịch vụ PH-12, mục `DEPENDENCIES` ở mức `BLOCKER`, thân không mất dữ liệu đã nhập. Bước 2 `200`, `ready = true`.
