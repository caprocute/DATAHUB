# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-08
Tính năng: TS-20-08 · Khởi tạo bổ sung và khởi tạo cụm riêng

  @TC-20-037 @P2 @Dương
  Kịch bản: TC-20-037 Xem trước và tạo đợt khởi tạo bổ sung bước S15 cho phân hệ mới
    # Truy vết: FR-20-016 · UC-20-08 · API-20-033, 034, 013 · BR-20-006 · EVT-20-07 · UI-20-04, 20 · `PERM-20-provision`
    Biết `U-PA1`; `T90`, `T91`, `T92` (`SUSPENDED`), `T96` `ACTIVE`; phân hệ PH-19 mới thêm vào mẫu; `waveSize = 2`.
    Khi `POST P/supplement-plans:preview` với `steps = [S15_MODULES]`, `modules = [PH-19]`, `waveSize = 2`, `reason`, `ticketRef`
    Và `POST P/supplement-plans` cùng thân, kèm `Idempotency-Key`
    Và theo dõi `runIds[]` bằng `GET P/provisioning-runs/{runId}`
    Và gọi API dữ liệu của `T90` trong lúc chạy
    Thì bước 1 `200`, `candidates[]` gồm `T90`, `T91`, `T96`; `excluded[]` có `T92` lý do "tạm ngừng". Bước 2 `202`, `planId`, `runIds[]`. Bước 3 mỗi lần chạy `runKind = SUPPLEMENT`, chỉ `S15_MODULES` chạy, bước khác `SKIPPED`; tối đa 2 lần chạy cùng lúc; EVT: `module-enabled` cho PH-19 mỗi tenant. Bước 4 tenant giữ `ACTIVE`, API trả `200` suốt quá trình.

  @TC-20-038 @P2 @Âm
  Kịch bản: TC-20-038 Bổ sung khi không tenant nào cần, bước không hỗ trợ, tenant bị loại, lỗi một tenant
    # Truy vết: FR-20-016 · API-20-033, 034, 013 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-016, ERR-20-107
    Biết `U-PA1`; mọi tenant đã có PH-19; `T94` có lần chạy `RUNNING`; bản giả PH-19 trả lỗi cho `T91`.
    Khi `POST P/supplement-plans:preview` với phân hệ đã bật ở mọi tenant
    Và `POST P/supplement-plans` với `steps = [S03_REALM]`
    Và `POST P/supplement-plans` thiếu `reason`
    Và `POST P/tenants/T94/provisioning-runs` với `runKind = SUPPLEMENT` khi đang có lần chạy khác
    Và chạy đợt bổ sung khi PH-19 lỗi ở `T91`
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `400` `ERR-20-004` (`S01`, `S02`, `S03`, `S16`, `S17` không hỗ trợ bổ sung). Bước 3 `400` `ERR-20-004` (thiếu `reason`, `ticketRef`). Bước 4 `409` `ERR-20-016`. Bước 5 lần chạy của `T91` `FAILED` với `ERR-20-107` trên dòng bước, tenant khác không bị chặn, thử lại bằng `:retry`; bù trừ phần bổ sung giữ `T91` `ACTIVE`.

  @TC-20-039 @P3 @Dương
  Kịch bản: TC-20-039 Đăng ký, kiểm tra cụm riêng và sinh gói cấu hình (Đợt 2)
    # Truy vết: FR-20-017 · UC-20-08 · API-20-035, 036, 037, 038 · BR-20-035 · UI-20-02, 04 · `PERM-20-provision`
    Biết `U-PA1`; `20.dedicated-cluster.enabled = true`; cụm giả `cl-thu-01` đủ CRD, StorageClass, dung lượng; `secretRef` là `<bi-mat-mau>`.
    Khi `POST P/clusters` với `clusterCode`, `name`, `apiEndpoint`, `argoCdEndpoint`, `capabilities`, `secretRef`
    Và `POST P/clusters/cl-thu-01:verify`
    Và `GET P/clusters?state=VERIFIED`
    Và khai báo `T95` với `isolationMode = DEDICATED_CLUSTER`, `clusterCode = cl-thu-01`, rồi `POST P/tenants/T95/dedicated-bundle`
    Thì bước 1 `201`, cụm `REGISTERED`; thân và kho Git không chứa giá trị bí mật, chỉ tham chiếu. Bước 2 `200`, `VERIFIED`. Bước 3 liệt kê `cl-thu-01`. Bước 4 `202`, gói `tar.zst` có liên kết tải hạn 24 giờ và `sha256`; saga trên cụm đích ghi Git ở `clusters/cl-thu-01/`.

  @TC-20-040 @P3 @Âm
  Kịch bản: TC-20-040 Cụm không đạt, mã cụm trùng, Đợt 2 chưa bật, báo cáo sai chữ ký
    # Truy vết: FR-20-017 · API-20-036, 037, 038 · BR-20-035 · ERR-20-003, ERR-20-004, ERR-20-006, ERR-20-064
    Biết `U-PA1`; cụm `cl-thieu` thiếu CRD bắt buộc; `20.dedicated-cluster.enabled = false` ở lần chạy đầu.
    Khi `POST P/clusters:verify` với `cl-thieu`
    Và `POST P/clusters` với `clusterCode = cl-thu-01` đã có
    Và khai báo `DEDICATED_CLUSTER` khi `20.dedicated-cluster.enabled = false`
    Và tải tệp báo cáo tiến độ cụm với chữ ký sai
    Thì bước 1 `422` `ERR-20-064` kèm danh sách thiếu (CRD). Bước 2 `409` `ERR-20-003`. Bước 3 `409` `ERR-20-006`. Bước 4 `400` `ERR-20-004`.
