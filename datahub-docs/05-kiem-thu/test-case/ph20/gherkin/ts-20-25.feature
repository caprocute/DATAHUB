# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-25
Tính năng: TS-20-25 · Chạy thử, gửi duyệt và duyệt kế hoạch sáp nhập

  @TC-20-113 @P1 @Dương
  Kịch bản: TC-20-113 Chạy thử sáp nhập đạt, ghi băm ánh xạ
    # Truy vết: FR-20-047 · UC-20-25 · API-20-097, 167 · BR-20-023 · UI-20-09, 10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `DRAFT` T91→T90 đã đủ ánh xạ; `ops-sim` (bản giả hợp đồng `merge-transfers`, API-18-150, `dryRun = true`).
    Khi `POST P/merge-plans/{id}:dry-run` với `modules` mặc định
    Và `ops-sim` báo từng phân hệ `POST I/merge-plans/{id}/participants/{module}:report` với `phase = DRY_RUN`, `status = SUCCEEDED`, `exportedCount`, `conflictCount`
    Và `GET P/merge-plans/{id}`
    Thì bước 1 `202`, kế hoạch `DRY_RUN`. Bước 3 kế hoạch về `DRAFT`, `dryRun.result = PASSED`, `dryRun.mappingHash` có giá trị, `stale = false`, xung đột dự kiến theo loại khớp F-MERGE (3 + 2 + 1), không ghi dữ liệu thật ở đích. Có xung đột dự kiến vẫn `PASSED`.

  @TC-20-114 @P1 @Âm
  Kịch bản: TC-20-114 Chạy thử: ánh xạ chưa đủ, đang chạy, phân hệ lỗi, chạy thử cũ
    # Truy vết: FR-20-047, 045 · API-20-097, 090 · ERR-20-004, ERR-20-006, ERR-20-042, ERR-20-043, ERR-20-107, ERR-20-113
    Biết `U-PA1`; kế hoạch thiếu dòng ánh xạ; kế hoạch đang `DRY_RUN`; `ops-sim` báo lệch kiểm đếm ở PH-01.
    Khi `POST .../:dry-run` khi còn dòng bắt buộc chưa quyết định
    Và `POST .../:dry-run` khi đang chạy thử
    Và chạy thử khi `ops-sim` báo PH-01 lệch kiểm đếm, và khi báo `FAILED` với `errorCode` ở PH-07
    Và sửa một dòng ánh xạ sau chạy thử `PASSED`, rồi `POST .../:submit`
    Thì bước 1 `422` `ERR-20-042`. Bước 2 `409` `ERR-20-006`. Bước 3 `dryRun.result = FAILED` với `ERR-20-113` ("Kiểm đếm PH-01 lệch: nguồn 120, đích 119.") và `ERR-20-107`. Bước 4 `dryRun.stale = true`, `422` `ERR-20-043`.

  @TC-20-115 @P1 @Dương
  Kịch bản: TC-20-115 Gửi duyệt và duyệt bốn mắt kế hoạch sáp nhập
    # Truy vết: FR-20-045 · UC-20-25 · API-20-090, 091, 092 · BR-20-008 · UI-20-09, 10, 08 · `PERM-20-merge`, `PERM-20-approve`
    Biết `U-PA1`, `U-PA2`, `U-T90-TA`, `U-T91-TA`; kế hoạch `DRAFT` có chạy thử `PASSED` còn hiệu lực.
    Khi `U-PA1` `POST .../merge-plans/{id}:submit`
    Và `U-PA2` `POST .../{id}:approve` với `comment`
    Và tạo kế hoạch khác, `U-PA2` `:reject` với `comment`
    Và `U-T90-TA` và `U-T91-TA` mở UI-20-10 của kế hoạch
    Thì bước 1 `PENDING_APPROVAL`. Bước 2 `200`, `APPROVED`, báo TA hai tỉnh. Bước 3 `REJECTED` về `DRAFT` kèm ý kiến. Bước 4 mỗi TA chỉ đọc phần tỉnh mình, không thấy dữ liệu tỉnh kia.

  @TC-20-116 @P1 @Âm
  Kịch bản: TC-20-116 Gửi duyệt khi chạy thử cũ, tự duyệt, trạng thái sai, từ chối thiếu ý kiến
    # Truy vết: FR-20-045 · API-20-090, 091, 092 · BR-20-008 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-043, ERR-00-428
    Biết `U-PA1`, `U-PA2`, `U-PA3`; kế hoạch chưa chạy thử; kế hoạch `PENDING_APPROVAL` do `U-PA1` gửi.
    Khi `U-PA1` `:submit` khi chưa chạy thử đạt
    Và `U-PA1` `:approve` kế hoạch của chính mình
    Và `U-PA3` (đủ hai quyền) lập, gửi rồi `:approve`
    Và `U-PA2` `:approve` kế hoạch còn `DRAFT`
    Và `U-PA2` `:reject` thiếu `comment`; `:approve` thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `422` `ERR-20-043`. Bước 2, 3 `403` `ERR-20-007`. Bước 4 `409` `ERR-20-006`. Bước 5 `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-117 @P1 @Dương @Âm
  Kịch bản: TC-20-117 Phân hệ tham gia báo tiến độ chuyển: hợp lệ, sai trạng thái, thiếu scope
    # Truy vết: FR-20-047, 048 · API-20-167 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-114
    Biết `S-PH18` (scope `tenant:provision-report`), `S-NOSCOPE`; kế hoạch `TRANSFERRING`, phân hệ PH-07 `RUNNING`, phân hệ PH-02 `PENDING`.
    Khi `S-PH18` báo PH-07 `phase = TRANSFER`, `status = SUCCEEDED`, `exportedCount`, `importedCount`, `verifiedCount`
    Và báo lặp đúng nội dung
    Và báo cho PH-02 `phase = CUTOVER` khi kế hoạch chưa tới cutover
    Và `S-NOSCOPE` báo
    Và báo `phase = KHONG-CO`; báo cho `mergePlanId` không có
    Thì bước 1 `200`, PH-07 `SUCCEEDED`. Bước 2 `200` kết quả cũ, không đổi hai lần. Bước 3 `409` `ERR-20-114`. Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`, rồi `404` `ERR-20-002`.
