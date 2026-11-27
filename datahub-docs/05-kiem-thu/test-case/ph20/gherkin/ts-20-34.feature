# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-34
Tính năng: TS-20-34 · Theo dõi nâng cấp, dừng sóng và quay lui

  @TC-20-167 @P1 @Dương
  Kịch bản: TC-20-167 Nâng cấp sóng 1 và 2 thành công, kiểm tra sau nâng cấp đạt
    # Truy vết: FR-20-062 · UC-20-34 · API-20-119, 126 · BR-20-032, 033 · EVT-20-15 · ERR-20-118 · UI-20-19 · `PERM-20-release`
    Biết STAGING; kế hoạch `SCHEDULED` ba sóng (F-REL); `git-sim`, `argo-sim` `Synced`; bộ smoke giả đạt; `20.release.verify-minutes = 30`.
    Khi đồng hồ giả lập tới cửa sổ của `T90`
    Và trong lúc nâng cấp, `U-T90-TA` gọi một thao tác ghi (`PUT T/settings`) và một thao tác đọc
    Và chờ `argo-sim` `Synced` và bộ smoke chạy
    Và `GET P/upgrade-plans/{planId}/tenant-upgrades`
    Và sóng 1 xong, theo dõi 48 giờ, sóng 2 bắt đầu
    Thì bước 1 kế hoạch `RUNNING`, `T90` `UPGRADING`, banner bảo trì, `release.yaml` ghi phiên bản. Bước 2 ghi `503` `ERR-20-118` ("Tỉnh đang bảo trì nâng cấp đến 02:00. Thao tác ghi tạm dừng."), đọc `200`. Bước 3 kiểm tra đạt, `T90` `DONE`, bỏ banner. Bước 4 trạng thái từng tenant. Bước 5 sóng 2 chỉ bắt đầu sau 48 giờ theo dõi sóng 1. Phát EVT-20-15 theo từng thay đổi.

  @TC-20-168 @P1 @Biên
  Kịch bản: TC-20-168 Sóng dừng khi tỷ lệ 5xx vượt 2 % hoặc có tenant FAILED
    # Truy vết: FR-20-062 · UC-20-34 · API-20-119, 123, 126 · BR-20-032 · ERR-20-057, ERR-20-112, ERR-20-109 · EVT-20-15 · NFR-20-016
    Biết kế hoạch `RUNNING` sóng 2 gồm `T91`, `T92`; `mod-sim` đẩy tỷ lệ 5xx của sóng; `20.release.wave-error-threshold-percent = 2`.
    Khi cho tỷ lệ 5xx của sóng 2 bằng 2,0 % (đúng ngưỡng)
    Và cho tỷ lệ 5xx lên 2,1 %
    Và với sóng 2 khác: bộ smoke của `T92` báo 3 ca lỗi
    Và `POST P/upgrade-plans/{planId}:resume` khi sóng dừng, chưa xác nhận
    Và với sóng khác: `argo-sim` trả `Degraded` cho `T91`
    Thì bước 1 không dừng (`>` mới dừng). Bước 2 sóng dừng, kế hoạch `PAUSED`, cảnh báo PA, sóng 3 không chạy. Bước 3 `T92` `FAILED` với `ERR-20-112` ("Kiểm tra sau nâng cấp của T92 không đạt: 3 ca lỗi."), sóng dừng. Bước 4 `409` `ERR-20-057` ("Sóng 2 đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục."). Bước 5 `ERR-20-109` ghi vào tiến trình.

  @TC-20-169 @P1 @Dương @Âm
  Kịch bản: TC-20-169 Dừng tay và tiếp tục sóng, PO dừng được nhưng không tiếp tục
    # Truy vết: FR-20-062 · API-20-122, 123 · BR-20-032 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-20-007, ERR-00-428 · `PERM-20-release`
    Biết `U-PA1`, `U-PO`; kế hoạch `RUNNING`; kế hoạch `COMPLETED`.
    Khi `U-PO` `POST P/upgrade-plans/{planId}:pause` với `reason`, `ticketRef`
    Và `U-PA1` `:resume` sau khi xử lý
    Và `:pause` kế hoạch đã `COMPLETED`; `:resume` kế hoạch `RUNNING` (không dừng)
    Và `:pause` thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
    Và `U-PO` `:resume`
    Thì bước 1 `200`, `PAUSED`. Bước 2 `200`, `RUNNING`. Bước 3 `409` `ERR-20-006`. Bước 4 `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-00-403` (PO chỉ theo dõi và dừng sóng; ghi nhận theo UC).

  @TC-20-170 @P1 @Dương
  Kịch bản: TC-20-170 Quay lui tenant đã nâng cấp khi chỉ có thay đổi EXPAND
    # Truy vết: FR-20-062 · UC-20-34 · API-20-124, 119 · BR-20-032 · EVT-20-15 · UI-20-19 · `PERM-20-release`
    Biết `U-PA1`; kế hoạch `PAUSED`, `T91` `DONE` ở `2.4.0` (thay đổi lược đồ chỉ `EXPAND`), phiên bản trước `2.3.1`.
    Khi `POST P/upgrade-plans/{planId}:rollback` với `tenantCodes = [T91]`, `reason`, `ticketRef`
    Và chờ `argo-sim` đồng bộ và kiểm tra
    Và `GET P/upgrade-plans/{planId}/tenant-upgrades?status=ROLLED_BACK`
    Thì bước 1 `202`. Bước 2 `release.yaml` ghi lại `2.3.1`, banner bảo trì tạm, kiểm tra đạt. Bước 3 `T91` `ROLLED_BACK`. EVT-20-15.

  @TC-20-171 @P1 @Âm
  Kịch bản: TC-20-171 Quay lui bị chặn khi có CONTRACT, sai trạng thái, thiếu phiếu
    # Truy vết: FR-20-062 · API-20-124 · ERR-20-058, ERR-20-006, ERR-20-004, ERR-20-009, ERR-20-005, ERR-00-428
    Biết `U-PA1`; kế hoạch của bản có `schemaChanges` kind `CONTRACT`; `T92` `PENDING` (chưa nâng cấp); `Idempotency-Key` đã dùng.
    Khi `:rollback` `T90` của bản có `CONTRACT`
    Và `:rollback` `T92` chưa nâng cấp
    Và `:rollback` thiếu `ticketRef`, `tenantCodes` rỗng
    Và `:rollback` dùng lại `Idempotency-Key` cho yêu cầu khác
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `422` `ERR-20-058` ("Không quay lui được phiên bản 2.4.0 vì có thay đổi lược đồ không tương thích ở PH-02."). Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-009`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-172 @P2 @Dương @Âm
  Kịch bản: TC-20-172 Hủy kế hoạch chưa chạy và không hủy khi đang chạy
    # Truy vết: FR-20-062 · API-20-125 · ERR-20-006, ERR-20-004, ERR-20-005, ERR-00-428 · UC-20-34
    Biết `U-PA1`; kế hoạch A `SCHEDULED`; kế hoạch B `RUNNING`.
    Khi `:cancel` A với `reason`
    Và `:cancel` B
    Và `:cancel` A lần nữa; thiếu `reason`; thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `CANCELLED`, thông báo hủy gửi tỉnh. Bước 2 `409` `ERR-20-006` (đang chạy thì dừng rồi quay lui, không hủy). Bước 3 `409` `ERR-20-006`, `400` `ERR-20-004`, `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-173 @P2 @Dương @Âm
  Kịch bản: TC-20-173 Thử lại nâng cấp của một tenant lỗi
    # Truy vết: FR-20-062 · API-20-127, 126 · ERR-20-006, ERR-20-057, ERR-20-004, ERR-20-002, ERR-20-058
    Biết `U-PA1`; `T92` `FAILED` ở sóng 2, kế hoạch `PAUSED` do ngưỡng; `T93` `PENDING`.
    Khi `POST .../tenant-upgrades/T92:retry` khi sóng chưa được xác nhận
    Và xác nhận xử lý (`:resume`), rồi `retry` `T92` với `reason`
    Và `retry` `T93` (`PENDING`); `retry` thiếu `reason`; `retry` tenant không thuộc kế hoạch
    Thì bước 1 `409` `ERR-20-057`. Bước 2 `202`, `T92` về `UPGRADING` rồi `DONE`. Bước 3 `409` `ERR-20-006`, `400` `ERR-20-004`, `404` `ERR-20-002`.

  @TC-20-174 @P3 @Dương @Âm
  Kịch bản: TC-20-174 Danh sách nâng cấp theo tenant: lọc, mã không có, tham số sai
    # Truy vết: FR-20-062 · API-20-119, 126 · ERR-20-002, ERR-20-004 · UI-20-19
    Biết `U-PA1`, `U-PO`; kế hoạch ba sóng.
    Khi `GET .../tenant-upgrades?waveNo=2&status=DONE&page=1&size=20`
    Và `GET .../tenant-upgrades?waveNo=abc`
    Và `GET P/upgrade-plans/pl-khong-co`; `GET .../pl-khong-co/tenant-upgrades`
    Và `U-PO` `GET P/upgrade-plans/{planId}`
    Thì bước 1 `200` lọc đúng. Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `200` (PO xem được).
