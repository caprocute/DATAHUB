# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-28
Tính năng: TS-20-28 · Chuyển định danh, cấp song song thông tin xác thực và cutover

  @TC-20-126 @P1 @Dương
  Kịch bản: TC-20-126 Chuyển định danh và cấp song song thông tin xác thực
    # Truy vết: FR-20-050 · UC-20-28 · API-20-104, 105 · API-12-045, API-12-046 · BR-20-024, 025 · UI-20-10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `IDENTITY_TRANSFER` không còn xung đột; `iam-sim` (hợp đồng API-12-045, 046), `ops-sim`; ánh xạ `USER`: 150 người, 6 `SKIP`.
    Khi `POST P/merge-plans/{id}:transfer-identity` với `notifyUsers = true`, `Idempotency-Key`, `If-Match`
    Và `iam-sim` trả kế hoạch định danh: 120 tạo mới, 24 gộp, 6 bỏ qua
    Và `GET P/merge-plans/{id}/credentials`
    Và kiểm thư hướng dẫn gửi đầu mối kỹ thuật từng HTTT qua `ops-sim`
    Thì bước 1 `202`. Bước 3 `items[]` mỗi HTTT có `memberSystemCode`, `newClientId`, `status = ISSUED`, `lastCallOld`, `lastCallNew`; không có giá trị bí mật trong phản hồi hay kiểm toán (chỉ `<bi-mat-mau>` ở bản giả). Hạn client mới bằng `transitionEndsAt`. Bước 4 mỗi đầu mối nhận một thư. Kế hoạch sẵn sàng `CUTOVER`.

  @TC-20-127 @P1 @Âm
  Kịch bản: TC-20-127 Chuyển định danh khi còn xung đột, PH-12 lỗi, sai trạng thái
    # Truy vết: FR-20-050 · API-20-104 · ERR-20-044, ERR-20-062, ERR-20-006, ERR-20-005, ERR-00-428
    Biết `U-PA1`; kế hoạch còn 2 xung đột mở; kế hoạch `DRAFT`; `iam-sim` `503`.
    Khi `:transfer-identity` khi còn 2 xung đột
    Và `:transfer-identity` khi kế hoạch `DRAFT`
    Và `:transfer-identity` khi `iam-sim` `503` (đã hết xung đột)
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `409` `ERR-20-044` ("Còn 2 xung đột sáp nhập chưa xử lý."). Bước 2 `409` `ERR-20-006`. Bước 3 `503` `ERR-20-062`, kế hoạch giữ `IDENTITY_TRANSFER`, thử lại được. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-128 @P1 @Dương
  Kịch bản: TC-20-128 Cutover: nguồn MERGED, bật chuyển tiếp, header Deprecation
    # Truy vết: FR-20-051 · UC-20-28 · API-20-106, 164 · BR-20-024, 025, 026 · NFR-20-015 · EVT-20-11, EVT-20-04, EVT-03-10 · UI-20-10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `CUTOVER` sẵn sàng; hai tỉnh trong cửa sổ bảo trì; `mod-sim` (PH-03) đọc API-20-164; `ops-sim`.
    Khi `POST P/merge-plans/{id}:cutover` với `confirmCode = {mã kế hoạch}`, `reason`, `ticketRef`, kèm `If-Match`, `Idempotency-Key`
    Và `ops-sim` chạy lượt bù cuối, báo kiểm đếm khớp
    Và `GET I/tenants/T91/enforcement` bằng `S-PH03`
    Và `mod-sim` gọi địa chỉ cũ của `T91` qua chuyển tiếp
    Và `mod-sim` báo EVT-03-10 xác nhận
    Thì bước 1 `202`, kế hoạch `TRANSITION`, `transitionEndsAt = hiện tại + 8 tháng` (theo kế hoạch đã sửa), phát EVT-20-11 và EVT-20-04. Bước 3 nguồn `MERGED`, `mergedInto = T90`, bảng chuyển tiếp `API_CONTEXT_PATH`. Bước 4 phản hồi từ `T90` kèm `Deprecation` và `Sunset = transitionEndsAt`. Bước 5 xác nhận chuyển tiếp bật được ghi (EVT-03-10). Ghi vào `T91` sau cutover bị chặn (xem TS-20-37).

  @TC-20-129 @P1 @Âm
  Kịch bản: TC-20-129 Cutover sai xác nhận, ngoài cửa sổ bảo trì, còn xung đột, lệch kiểm đếm
    # Truy vết: FR-20-051 · API-20-106 · BR-20-024 · ERR-20-044, ERR-20-006, ERR-20-059, ERR-20-008, ERR-20-113, ERR-20-004, ERR-20-005, ERR-00-428
    Biết `U-PA1`; kế hoạch `CUTOVER`; kế hoạch còn xung đột; ngoài cửa sổ bảo trì; `ops-sim` báo lượt bù lệch.
    Khi `:cutover` gõ sai `confirmCode`
    Và `:cutover` thiếu `reason` hoặc `ticketRef`
    Và `:cutover` ngoài cửa sổ bảo trì
    Và `:cutover` khi còn xung đột; khi kế hoạch không ở trạng thái cho phép
    Và trong cửa sổ, lượt bù cuối lệch kiểm đếm
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `422` `ERR-20-008`. Bước 3 `422` `ERR-20-059`. Bước 4 `409` `ERR-20-044`, `409` `ERR-20-006`. Bước 5 cutover dừng, `ERR-20-113`, nguồn bỏ chỉ đọc, kế hoạch giữ `IDENTITY_TRANSFER`. Bước 6 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-130 @P2 @Biên
  Kịch bản: TC-20-130 Tenant nguồn MERGED chỉ đọc và cảnh báo lỗi chuyển tiếp trên 1 %
    # Truy vết: FR-20-051, 066 · API-20-106, 164 · ERR-20-115 · UC-20-28 · NFR-20-015
    Biết nguồn `T91` `MERGED` sau cutover; `mod-sim` đẩy 100 lượt chuyển tiếp trong 60 phút đầu, 2 lượt lỗi.
    Khi `U-T91-TA` ghi (`PATCH T/settings`)
    Và `U-T91-TA` đọc lịch sử (`GET T/settings`)
    Và theo dõi 60 phút đầu của chuyển tiếp
    Thì bước 1 `409` `ERR-20-115` ("Tỉnh đã sáp nhập vào T90. Dữ liệu chỉ còn để tra cứu."). Bước 2 `200`. Bước 3 tỷ lệ lỗi 2 % vượt 1 % thì cảnh báo PA, không tự quay lui.

  @TC-20-131 @P3 @Biên
  Kịch bản: TC-20-131 Không nhận xác nhận chuyển tiếp từ PH-03 sau 15 phút
    # Truy vết: FR-20-051 · API-20-164 · EVT-03-10 · UC-20-28
    Biết sau cutover; `mod-sim` không gửi EVT-03-10.
    Khi chờ 15 phút (đồng hồ giả lập)
    Thì cảnh báo PO; chưa ghi xác nhận chuyển tiếp bật; cutover không bị hoàn tác.
