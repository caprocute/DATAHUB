# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-21
Tính năng: TS-20-21 · Đề nghị, duyệt chấm dứt tenant và xuất gói bàn giao

  @TC-20-095 @P1 @Dương
  Kịch bản: TC-20-095 Lập, gửi, duyệt đề nghị chấm dứt bốn mắt
    # Truy vết: FR-20-040 · UC-20-21 · API-20-071, 073, 074, 075, 076, 077 · BR-20-008, 019 · UI-20-08 · `PERM-20-lifecycle`, `PERM-20-approve`
    Biết `U-PA1`, `U-PA2`; `T92` `SUSPENDED` từ 35 ngày trước (`clock-sim`); văn bản chấm dứt `TC/QĐ-02`.
    Khi `U-PA1` `POST P/tenants/T92/lifecycle-requests` với `requestType = TERMINATE`, `reasonText`, `ticketRef`, `decisionDocNo`, `decisionDocDate`, `decisionFileId`, `plannedAt` sau ngày nguội, `exportRequired = true`
    Và `U-PA1` `POST P/lifecycle-requests/{requestId}:submit`
    Và `U-PA2` `GET P/lifecycle-requests?status=PENDING_APPROVAL` và `GET .../{requestId}`
    Và `U-PA2` `POST .../{requestId}:approve` với `comment`
    Thì bước 1 `201`, `DRAFT`. Bước 2 `PENDING_APPROVAL`, nội dung khóa. Bước 3 `U-PA2` thấy tóm tắt dữ liệu sẽ mất (số HTTT, API, người dùng, dung lượng), trạng thái gói bàn giao, ngày sớm nhất được thực hiện (`coolingUntil`). Bước 4 `200`, `APPROVED`, hệ thống tự yêu cầu gói bàn giao nếu chưa có và báo đầu mối tỉnh. Không phát EVT-20-04 (chỉ khi thực hiện). Rút và từ chối: `U-PA1` `:cancel` rút về `DRAFT`, `U-PA2` `:reject` kèm ý kiến thì `REJECTED`.

  @TC-20-096 @P1 @Âm
  Kịch bản: TC-20-096 Chấm dứt: tenant chưa tạm ngừng, chưa hết nguội, tự duyệt, đề nghị trùng, thiếu văn bản
    # Truy vết: FR-20-040 · API-20-071, 075, 076, 078 · BR-20-008, 019 · ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-037, ERR-20-038
    Biết `U-PA1`, `U-PA2`, `U-PA3`; `T90` `ACTIVE`; `T92` `SUSPENDED` từ 10 ngày; đề nghị `TERMINATE` đang `PENDING_APPROVAL`.
    Khi `POST P/tenants/T90/lifecycle-requests` `TERMINATE`
    Và `POST P/tenants/T92/lifecycle-requests` `TERMINATE` với `plannedAt` sau 15 ngày (trước ngày nguội)
    Và `POST` thiếu `decisionDocNo`, `decisionDocDate`
    Và `POST P/tenants/T92/lifecycle-requests` `TERMINATE` lần hai khi đã có đề nghị chưa kết thúc
    Và `U-PA1` `:approve` đề nghị do chính mình lập; `U-PA3` (đủ cả hai quyền) lập rồi tự duyệt
    Và `U-PA2` `:approve` khi `DRAFT`; `:submit` khi `APPROVED`
    Thì bước 1 `422` `ERR-20-037`. Bước 2 `422` `ERR-20-038` ("Chưa hết thời gian chờ 30 ngày kể từ khi tạm ngừng (đến 14/12/2026)"). Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-006`. Bước 5 `403` `ERR-20-007` kể cả người giữ cả hai quyền. Bước 6 `409` `ERR-20-006`.

  @TC-20-097 @P1 @Dương
  Kịch bản: TC-20-097 Xuất gói bàn giao, ký bản kê, cấp liên kết, xác nhận đã bàn giao
    # Truy vết: FR-20-041 · UC-20-21 · API-20-080, 081, 082, 083, 084, 168 · BR-20-008, 019 · EVT-20-16 · UI-20-08 · `PERM-20-lifecycle`
    Biết `U-PA1`, `U-PA2`; `T92` `SUSPENDED`; đề nghị chấm dứt do `U-PA2` duyệt; `mod-sim` của PH-01, 02, 07, 16 xuất phần dữ liệu; `s3-sim`.
    Khi `POST P/tenants/T92/export-packages` với `format = JSONL`, `includeAudit = true`
    Và mỗi phân hệ báo `POST I/export-packages/{packageId}/items/{module}:report` với `status = DONE`, `rowCount`, `sizeBytes`, `sha256`, `fileId`
    Và `GET P/export-packages/{packageId}`
    Và `POST .../{packageId}:issue-link` với `recipientEmail`, `expiresHours = 48`
    Và `U-PA1` (không phải người duyệt) `POST .../{packageId}:confirm-delivery` với `handoverDocFileId`, `deliveredAt`, `deliveredTo`
    Thì bước 1 `202`, `REQUESTED` rồi `COLLECTING`. Bước 3 `READY`, có `manifestSha256` (bản kê `manifest.json` ký bằng khóa nền tảng) và EVT: `platform.tenant.export-ready.v1`; phân hệ chưa bật ghi "không có dữ liệu". Bước 4 `200`, `downloadUrl` hạn 48 giờ. Bước 5 `200`, `DELIVERED`. Liên kết và email người nhận không xuất hiện trong log (mồi sạch).

  @TC-20-098 @P1 @Âm
  Kịch bản: TC-20-098 Gói bàn giao: cấp liên kết khi chưa sẵn sàng, người duyệt tự xác nhận, gói hết hạn, phân hệ lỗi
    # Truy vết: FR-20-041 · API-20-080, 082, 083, 084, 168 · BR-20-008 · ERR-20-002, ERR-20-004, ERR-20-006, ERR-20-007, ERR-20-039, ERR-20-104, ERR-20-107
    Biết `U-PA1`, `U-PA2`; gói `COLLECTING`; gói `READY` của đề nghị do `U-PA2` duyệt; gói `EXPIRED` (sau 90 ngày, `clock-sim`); `S-NOSCOPE`.
    Khi `POST .../{packageId}:issue-link` khi `COLLECTING`
    Và `U-PA2` (người duyệt chấm dứt) `POST .../{packageId}:confirm-delivery`
    Và `GET P/export-packages/{packageId}` và `POST ...:issue-link` với gói `EXPIRED`
    Và `POST ...:issue-link` với `recipientEmail = khong-hop-le`
    Và `S-NOSCOPE` gọi `POST I/export-packages/{packageId}/items/PH-01:report`
    Và phân hệ không báo quá 24 giờ
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `403` `ERR-20-007`. Bước 3 `410` `ERR-20-039`. Bước 4 `400` `ERR-20-004`. Bước 5 `403` `ERR-20-104`. Bước 6 phần dữ liệu đó `FAILED` với `ERR-20-107`, gói chưa `READY`, PA chạy lại phần lỗi. Gói không có `packageId` thì `404` `ERR-20-002`.

  @TC-20-099 @P2 @Dương
  Kịch bản: TC-20-099 Hộp duyệt toàn nền tảng và lọc đề nghị vòng đời
    # Truy vết: FR-20-040, 043 · API-20-072, 073, 074 · UI-20-08 · `PERM-20-read`
    Biết `U-PA2`, `U-PO`; ba đề nghị `PENDING_APPROVAL`, một `DONE`.
    Khi `GET P/lifecycle-requests?status=PENDING_APPROVAL&requestType=TERMINATE`
    Và `GET P/lifecycle-requests?tenantCode=T92`
    Và `GET P/tenants/T92/lifecycle-requests?type=SUSPEND&from=2026-10-01&to=2026-11-27`
    Và `GET P/lifecycle-requests/{requestId}` và `GET P/lifecycle-requests/khong-co`
    Thì bước 1, 2, 3 trả đúng tập đã lọc, có `allowedActions[]` theo người xem (người lập không có hành động "duyệt"). Bước 4 `200` rồi `404` `ERR-20-002`.
