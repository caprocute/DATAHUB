# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-33
Tính năng: TS-20-33 · Lập kế hoạch nâng cấp theo sóng và thông báo lịch bảo trì

  @TC-20-159 @P1 @Dương
  Kịch bản: TC-20-159 Lập kế hoạch nâng cấp ba sóng, sửa, xem
    # Truy vết: FR-20-061 · UC-20-33 · API-20-118, 119, 120 · BR-20-032, 033 · UI-20-19 · `PERM-20-release` · `20.release.wave-soak-hours-patch`
    Biết `U-PA1`; F-REL (`2.3.1` `STABLE`); sóng `T90`; `T91`, `T92`; `T93` (F-REL); mọi tenant chạy bản ≥ `minFromVersion`.
    Khi `POST P/releases/2.3.1/upgrade-plans` không có `waves[]` (hệ thống gợi ý), kèm `Idempotency-Key`
    Và `POST` với `waves[]` tự chọn: sóng 1 `T90`; sóng 2 `T91`, `T92`; sóng 3 `T93`; `soakHours` mặc định
    Và `GET P/upgrade-plans/{planId}`
    Và `PATCH P/upgrade-plans/{planId}` đổi tenant sóng 3, kèm `If-Match`
    Thì bước 1 `201`, gợi ý: sóng 1 tenant kênh `PREVIEW`, sóng 2 tối đa 5 tenant nhỏ, sóng 3 phần còn lại. Bước 2 `201`, `DRAFT`, `soakHours` 48 (bản phụ) hoặc 24 (bản vá). Bước 3 lịch từng tenant. Bước 4 `200`.

  @TC-20-160 @P1 @Âm
  Kịch bản: TC-20-160 Kế hoạch không hợp lệ: tenant ở hai kế hoạch, bản không dùng được, dưới minFromVersion
    # Truy vết: FR-20-061 · API-20-118, 120 · ERR-20-056, ERR-20-055, ERR-20-004, ERR-20-006, ERR-20-005, ERR-20-002, ERR-00-428
    Biết `U-PA1`; `T92` đã trong kế hoạch khác; `2.4.0-rc.1` `DRAFT`; `T94` chạy bản 2.0.0 nhỏ hơn `minFromVersion`.
    Khi `POST .../2.3.1/upgrade-plans` có `T92` ở hai sóng
    Và `POST` có `T92` đang thuộc kế hoạch khác
    Và `POST` có `T94` dưới `minFromVersion`
    Và `POST .../2.4.0-rc.1/upgrade-plans` (bản `DRAFT`); `POST .../2.0.0/...` không có
    Và `PATCH` kế hoạch đang `RUNNING`; thiếu `If-Match`; `If-Match` cũ
    Thì bước 1, 2, 3 `422` `ERR-20-056` ("Kế hoạch nâng cấp không hợp lệ: T92 đã thuộc kế hoạch khác."). Bước 4 `422` `ERR-20-055`, `404` `ERR-20-002`. Bước 5 `409` `ERR-20-006`, `428` `ERR-00-428`, `412` `ERR-20-005`. Thiếu `waves[]` và `waveNo` sai kiểu `400` `ERR-20-004`.

  @TC-20-161 @P1 @Dương
  Kịch bản: TC-20-161 Lên lịch: thời điểm mỗi tenant là cửa sổ đầu tiên sau soak của sóng trước
    # Truy vết: FR-20-061, 063 · UC-20-33 · API-20-121, 119 · BR-20-032, 033 · EVT-20-15 · UI-20-19 · `PERM-20-release`
    Biết `U-PA1`; kế hoạch `DRAFT` ba sóng; `20.release.wave-soak-hours-minor = 48`; cửa sổ `T90` thứ Bảy 22:00 (3 giờ), `T91` thứ Bảy 23:00 (2 giờ), `T92` mặc định; đồng hồ giả lập thứ Tư.
    Khi `POST P/upgrade-plans/{planId}:schedule` với `startAfter`, kèm `If-Match`
    Và `GET P/upgrade-plans/{planId}/tenant-upgrades`
    Thì bước 1 `200`, `SCHEDULED`, EVT-20-15, thông báo (FR-20-063) được kích hoạt. Bước 2 `T90` thứ Bảy gần nhất 22:00; sóng 2 là cửa sổ đầu tiên sau khi sóng 1 hết 48 giờ theo dõi, tức thứ Bảy kế tiếp (không sớm hơn 48 giờ sau xong sóng 1); sóng 3 sau sóng 2 cùng quy tắc.

  @TC-20-162 @P1 @Âm
  Kịch bản: TC-20-162 Lên lịch sai trạng thái, cửa sổ trùng giờ cao điểm
    # Truy vết: FR-20-061 · API-20-121 · ERR-20-006, ERR-20-059, ERR-20-005, ERR-00-428
    Biết `U-PA1`; kế hoạch đã `SCHEDULED`; kế hoạch `DRAFT` có tenant cửa sổ cài sai trùng giờ cao điểm.
    Khi `:schedule` kế hoạch đã `SCHEDULED`
    Và `:schedule` kế hoạch có tenant cửa sổ thứ Tư 09:00 (giờ cao điểm 7:00–17:00 ngày làm việc)
    Và `:schedule` thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `422` `ERR-20-059` ("Cửa sổ bảo trì không hợp lệ: trùng giờ cao điểm."). Bước 3 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-163 @P2 @Biên
  Kịch bản: TC-20-163 Nâng cấp khẩn bỏ chờ cửa sổ, báo trước tối thiểu 2 giờ
    # Truy vết: FR-20-061, 063 · API-20-118, 121, 128 · BR-20-033 · ERR-20-004 · UC-20-33
    Biết `U-PA1`; bản vá bảo mật `2.3.2` `STABLE`; `20.upgrade.emergency-notice-hours = 2`; `ops-sim`.
    Khi `POST .../2.3.2/upgrade-plans` với `emergency = true`; `:schedule` với `startAfter` sau 1 giờ
    Và `:schedule` với `startAfter` sau 3 giờ
    Thì bước 1 `400` `ERR-20-004` hoặc `422` `ERR-20-056` (báo trước dưới 2 giờ; ghi nhận ở Phụ lục đề nghị về mã lỗi). Bước 2 `200`, bỏ chờ cửa sổ, thông báo gửi ngay nêu lý do.

  @TC-20-164 @P1 @Dương
  Kịch bản: TC-20-164 Thông báo phát hành và lịch bảo trì, banner 72 giờ trước
    # Truy vết: FR-20-063 · UC-20-33 · API-20-128 · UI-20-12, 19 · `PERM-20-release`
    Biết `U-PA1`; kế hoạch `SCHEDULED`; `ops-sim` (NotificationApi); `U-T90-TA`.
    Khi `POST P/releases/2.3.1:announce` với `planId`, `audience = TA`, `message`
    Và `POST ...:announce` với `audience = ALL_USERS`
    Và kiểm banner tại `dh-console` của `T90` ở 73 giờ và 71 giờ trước lịch
    Thì bước 1 `202`, thư và thông báo trong ứng dụng gửi tới TA, ghi trạng thái gửi. Bước 2 gửi mọi người dùng tỉnh. Bước 3 banner chỉ hiện từ 72 giờ trước.

  @TC-20-165 @P2 @Âm
  Kịch bản: TC-20-165 Thông báo khi PH-18 lỗi, kế hoạch chưa lên lịch
    # Truy vết: FR-20-063 · API-20-128 · ERR-20-062, ERR-20-006, ERR-20-004, ERR-20-002
    Biết `U-PA1`; `ops-sim` `503`; kế hoạch `DRAFT`.
    Khi `:announce` khi `ops-sim` `503`
    Và `:announce` kế hoạch `DRAFT`
    Và `:announce` với `audience = KHAC`; bản không có
    Thì bước 1 `503` `ERR-20-062` ("Dịch vụ PH-18 tạm thời không khả dụng. Thử lại sau."), trạng thái gửi `FAILED` thử lại được. Bước 2 `409` `ERR-20-006`. Bước 3 `400` `ERR-20-004`, `404` `ERR-20-002`.

  @TC-20-166 @P2 @Dương
  Kịch bản: TC-20-166 TA đặt cửa sổ bảo trì ngoài giờ cao điểm, áp cho kế hoạch lập sau
    # Truy vết: FR-20-061, 064 · API-20-160, 159 · BR-20-033 · UI-20-12 · `PERM-20-settings`
    Biết `U-T90-TA`; kế hoạch của `T90` đã `SCHEDULED` với cửa sổ cũ.
    Khi `PUT T/maintenance-window` với `dayOfWeek = SATURDAY`, `startTime = 22:00`, `durationHours = 4`
    Và `GET T/release-info`
    Thì bước 1 `200`. Bước 2 cửa sổ hiện hành mới; kế hoạch `SCHEDULED` không đổi, chỉ kế hoạch lập sau dùng cửa sổ mới.
