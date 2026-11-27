# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-12
Tính năng: TS-20-12 · Chính sách tiếp nhận và nhật ký truy cập liên tenant

  @TC-20-053 @P1 @Dương
  Kịch bản: TC-20-053 Quản trị tỉnh đặt chính sách tiếp nhận; SO, AU xem; PH-12 đọc
    # Truy vết: FR-20-023 · UC-20-12 · API-20-137, 138, 165 · BR-20-012 · EVT-20-09 · UI-20-22 · `PERM-20-settings`
    Biết `U-T90-TA`, `U-T90-SO`, `U-T90-AU`; `S-PH12`; `20.cross-tenant.max-hours` = 4.
    Khi `GET T/cross-tenant-policy` bằng `U-T90-TA`, lấy `ETag`
    Và `PUT T/cross-tenant-policy` với `allowRead = true`, `allowWrite = false`, `requirePriorApproval = true`, `maxHours = 2`, `notifyContacts` (hai đầu mối hợp lệ), `blockedReasons = [MAINTENANCE]`, kèm `If-Match`
    Và `GET T/cross-tenant-policy` bằng `U-T90-SO` và `U-T90-AU`
    Và `S-PH12` gọi `GET I/tenants/T90/cross-tenant-policy`
    Thì bước 2 `200`, phiên bản chính sách mới; EVT: `platform.tenant.config-changed.v1` với `changeKind = CROSS_TENANT_POLICY` để PH-12 vô hiệu đệm. Bước 3 SO, AU đọc được, không sửa được. Bước 4 `200` trả đúng giá trị mới. KT có người sửa.

  @TC-20-054 @P1 @Âm
  Kịch bản: TC-20-054 Chính sách vượt trần, người nhận không hợp lệ, vai trò không đủ, tỉnh tạm ngừng
    # Truy vết: FR-20-023 · API-20-138 · BR-20-012 · ERR-20-001, ERR-20-004, ERR-20-005, ERR-20-027, ERR-00-403, ERR-00-428
    Biết `U-T90-TA`, `U-T90-SO`, `U-T90-VW`, `U-T92-TA` (`SUSPENDED`); người dùng `U-T91-TA` thuộc tenant khác.
    Khi `PUT T/cross-tenant-policy` với `maxHours = 6`
    Và `PUT` với `notifyContacts` chứa địa chỉ của `U-T91-TA`
    Và `U-T90-SO` và `U-T90-VW` gọi `PUT`
    Và `PUT` thiếu `If-Match`; `If-Match` cũ
    Và `U-T92-TA` gọi `PUT`
    Thì bước 1 `422` `ERR-20-027`. Bước 2 `400` `ERR-20-004` (người nhận không phải đầu mối hay người dùng `ACTIVE` của tỉnh). Bước 3 `403` `ERR-00-403`. Bước 4 `428` `ERR-00-428`; `412` `ERR-20-005`. Bước 5 `403` `ERR-20-001`. Chính sách cũ giữ nguyên.

  @TC-20-055 @P2 @Dương
  Kịch bản: TC-20-055 Xem nhật ký truy cập liên tenant và lọc
    # Truy vết: FR-20-024 · UC-20-12 · API-20-139 · UI-20-22 · `PERM-20-settings`
    Biết `U-T90-SO`, `U-T90-AU`, `U-T90-TA`; `obs-sim` có ba phiên liên tenant vào `T90` (hai đọc, một ghi) và một phiên vào `T91`.
    Khi `GET T/cross-tenant-access-log?from=2026-11-01&to=2026-11-27`
    Và `GET T/cross-tenant-access-log?access=WRITE&reasonType=INCIDENT`
    Và `GET T/cross-tenant-access-log?actor=U-PA1&ticketRef=TC-PH20-001`
    Và mở một phiên để xem chi tiết thao tác
    Thì bước 1 ba phiên của `T90`, không có phiên của `T91` (truy vấn theo tenant ngữ cảnh). Mỗi phiên có người (tenant nhà `PLATFORM`), lý do, phiếu, người duyệt, bắt đầu, kết thúc, số thao tác đọc, ghi. Bước 2 chỉ phiên có thao tác ghi. Bước 3 lọc đúng. Bước 4 chi tiết đường dẫn API, thời điểm, kết quả. SO, AU, TA cùng đọc được.

  @TC-20-056 @P2 @Âm
  Kịch bản: TC-20-056 Khoảng thời gian quá dài, tham số sai, PH-13 không khả dụng, vai trò không đủ
    # Truy vết: FR-20-024 · API-20-139 · ERR-20-004, ERR-20-032, ERR-20-062, ERR-00-403
    Biết `U-T90-SO`, `U-T90-VW`; `obs-sim` ngừng ở bước 3.
    Khi `GET T/cross-tenant-access-log?from=2025-01-01&to=2026-11-27`
    Và `GET T/cross-tenant-access-log?access=DELETE`
    Và `obs-sim` ngừng, `GET T/cross-tenant-access-log`
    Và `U-T90-VW` gọi `GET T/cross-tenant-access-log`
    Thì bước 1 `400` `ERR-20-032`. Bước 2 `400` `ERR-20-004`. Bước 3 `503` `ERR-20-062`. Bước 4 `403` `ERR-00-403`.
