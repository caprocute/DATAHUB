# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-24
Tính năng: TS-20-24 · Lập kế hoạch và bảng ánh xạ sáp nhập

  @TC-20-108 @P1 @Dương
  Kịch bản: TC-20-108 Lập kế hoạch sáp nhập T91 vào T90, sửa và xem danh sách
    # Truy vết: FR-20-045 · UC-20-24 · API-20-086, 087, 088, 089 · BR-20-022, 025 · UI-20-09, 11 · `PERM-20-merge` · `20.merge.transition-months`
    Biết `U-PA1`, `U-PO`; `T90`, `T91` `ACTIVE` `PROVINCE`; F-MERGE; văn bản `TC/QĐ-SN-01`.
    Khi `POST P/merge-plans` với `name`, `sourceTenants = [T91]`, `targetTenant = T90`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `effectiveDate`, `transitionMonths = 6`, `modules`, kèm `Idempotency-Key`
    Và `GET P/merge-plans?status=DRAFT&tenantCode=T91` bằng `U-PO`
    Và `GET P/merge-plans/{mergePlanId}`
    Và `PATCH P/merge-plans/{mergePlanId}` đổi `name` và `transitionMonths = 8`, kèm `If-Match`
    Thì bước 1 `201`, mã `MG-2026-001`, `status = DRAFT`, phân hệ bật ở nguồn mà đích chưa bật được cảnh báo kèm gợi ý FR-20-034. Bước 2 có kế hoạch. Bước 3 `progress.modulesTotal` đúng số phân hệ, `allowedActions[]`. Bước 4 `200`, `transitionMonths = 8`. KT mọi thao tác ghi.

  @TC-20-109 @P1 @Âm
  Kịch bản: TC-20-109 Kế hoạch không hợp lệ: nguồn trùng đích, tenant không đủ điều kiện, thuộc kế hoạch khác, chuyển tiếp quá dài
    # Truy vết: FR-20-045 · API-20-086, 089 · BR-20-022, 025 · ERR-20-004, ERR-20-040, ERR-20-041, ERR-20-045
    Biết `U-PA1`; `T90`, `T91` `ACTIVE`; `T92` `SUSPENDED`; `T93` đã thuộc `MG-2026-001` chưa kết thúc.
    Khi `POST P/merge-plans` với `sourceTenants = [T90]`, `targetTenant = T90`
    Và `POST` với nguồn `T92` (`SUSPENDED`) hoặc `PLATFORM`
    Và `POST` với nguồn `T93` đang thuộc kế hoạch khác
    Và `POST` với `transitionMonths = 13`
    Và `POST` thiếu `decisionDocNo`, `effectiveDate`
    Thì bước 1, 2 `422` `ERR-20-040` (nguồn khác đích, đều `ACTIVE`, đều `PROVINCE`). Bước 3 `409` `ERR-20-041`. Bước 4 `422` `ERR-20-045`. Bước 5 `400` `ERR-20-004`. Không tạo kế hoạch.

  @TC-20-110 @P1 @Dương @Âm
  Kịch bản: TC-20-110 Hủy kế hoạch trước cutover và không hủy sau cutover
    # Truy vết: FR-20-045 · API-20-093, 089 · BR-20-024 · ERR-20-005, ERR-20-006, ERR-20-008, ERR-00-428 · EVT-20-04
    Biết `U-PA1`; kế hoạch A `APPROVED`; kế hoạch B `TRANSFERRING` (nguồn `MERGING`, đã chuyển một phần); kế hoạch C đã `TRANSITION`.
    Khi `POST .../merge-plans/{A}:cancel` với `reason`, kèm `If-Match`
    Và `POST .../{B}:cancel`
    Và `POST .../{C}:cancel`
    Và `POST .../{B}:cancel` thiếu `reason`, thiếu `If-Match`, `If-Match` cũ
    Thì bước 1 `200`, `CANCELLED`. Bước 2 `200`, `CANCELLED`, dữ liệu đã chuyển sang đích được PH-18 gỡ theo `origin_tenant_id`, nguồn về `ACTIVE` (EVT: `status-changed`). Bước 3 `409` `ERR-20-006` (hủy chỉ trước cutover). Bước 4 `422` `ERR-20-008`, `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-111 @P1 @Dương
  Kịch bản: TC-20-111 Sinh gợi ý, xem, sửa bảng ánh xạ sáu loại đối tượng
    # Truy vết: FR-20-046 · UC-20-24 · API-20-094, 095, 096 · BR-20-023 · UI-20-09 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `DRAFT` T91→T90 với F-MERGE; `rdm-sim`, `iam-sim`.
    Khi `POST P/merge-plans/{id}/mappings:suggest`
    Và `GET P/merge-plans/{id}/mappings?mappingType=ORGANIZATION&status=PROPOSED`
    Và `PUT P/merge-plans/{id}/mappings/{mappingId}` với `action = MAP`, `targetCode`, `note`, kèm `If-Match`
    Và `PUT` một dòng `action = CREATE` và một dòng `action = SKIP`
    Và `GET P/merge-plans/{id}/mappings?status=CONFLICT`
    Thì bước 1 `200`, sinh dòng cho 12 `ORGANIZATION`, 20 `MEMBER_SYSTEM`, 30 `CATALOG_CODE`, 4 `API_CONTEXT_PATH`, 150 `USER`, 6 `TOPIC`; mã trùng đánh `CONFLICT`. Bước 3, 4 `200`, dòng `CONFIRMED`. Bước 5 liệt kê dòng xung đột (3 mã tổ chức, 2 mã danh mục, 1 `contextPath`). Ánh xạ thay đổi làm chạy thử trước đó thành cũ.

  @TC-20-112 @P2 @Âm
  Kịch bản: TC-20-112 Ánh xạ: mã đích trùng, hành động sai, kế hoạch không ở DRAFT, PH-07 lỗi
    # Truy vết: FR-20-046 · API-20-095, 096 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-042, ERR-20-062, ERR-00-428
    Biết `U-PA1`; kế hoạch `DRAFT`; kế hoạch `APPROVED`; `rdm-sim` `503`.
    Khi `PUT .../mappings/{mappingId}` với `targetCode` đã có ở đích khi `action = CREATE`
    Và `PUT` với `action = XOA`
    Và `PUT` thiếu `If-Match`; `If-Match` cũ
    Và `POST .../mappings:suggest` ở kế hoạch `APPROVED`
    Và `POST .../mappings:suggest` khi `rdm-sim` `503`
    Và `POST .../:dry-run` khi còn dòng bắt buộc chưa quyết định
    Thì bước 1 `409` `ERR-20-003`. Bước 2 `400` `ERR-20-004`. Bước 3 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 4 `409` `ERR-20-006`. Bước 5 `503` `ERR-20-062`. Bước 6 `422` `ERR-20-042` ("Bảng ánh xạ còn 5 dòng bắt buộc chưa quyết định.").
