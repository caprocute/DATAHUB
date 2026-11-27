# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-11
Tính năng: TS-20-11 · Cài đặt tỉnh, xem phiên bản và lịch bảo trì của tỉnh

  @TC-20-049 @P1 @Dương
  Kịch bản: TC-20-049 Quản trị tỉnh xem và sửa cài đặt tỉnh trong giới hạn
    # Truy vết: FR-20-018 · UC-20-11 · API-20-135, 136 · BR-20-011 · EVT-20-09 · UI-20-12 · `PERM-20-settings`
    Biết `U-T90-TA`; `U-T90-VW`; `T90` `ACTIVE`; tổ chức `SO-KHCN` `ACTIVE`.
    Khi `GET T/settings` bằng `U-T90-TA`, lấy `ETag`
    Và `PUT T/settings` với `displayName`, `itOwnerOrgCode = SO-KHCN`, `sessionIdleMinutes = 15`, `passwordMinLength = 14`, `mfaRequiredRoles = [ROLE-TENANT_ADMIN, ROLE-SECURITY_OFFICER]`, `maintenanceWindowPref` thứ Bảy 22:00 dài 4 giờ, `supportContactEmail`, kèm `If-Match`
    Và `GET T/settings` bằng `U-T90-VW`
    Thì bước 1 có giới hạn nền tảng cho từng trường. Bước 2 `200`, `ETag` mới, ghi `settings.yaml` qua GitOps, EVT: `platform.tenant.config-changed.v1` (`changeKind` cài đặt tỉnh) để PH-12 áp chính sách phiên, mật khẩu. Bước 3 `200` phần hiển thị, không có nút sửa. KT: không cần mã phiếu (tỉnh tự quản), có người sửa, giá trị trước và sau.

  @TC-20-050 @P1 @Âm
  Kịch bản: TC-20-050 Cài đặt vượt giới hạn nền tảng, tổ chức không hợp lệ, vai trò thấp, tỉnh bị tạm ngừng hoặc đã sáp nhập
    # Truy vết: FR-20-018 · API-20-136 · BR-20-011, 026 · ERR-20-001, ERR-20-002, ERR-20-005, ERR-20-023, ERR-20-115, ERR-00-403, ERR-00-428
    Biết `U-T90-TA`, `U-T90-TO`; `T92` `SUSPENDED` (`U-T92-TA`); `T91` `MERGED` (`U-T91-TA`); tổ chức `SO-CU` `DISSOLVED`.
    Khi `PUT T/settings` với `sessionIdleMinutes = 30`
    Và `PUT` với `passwordMinLength = 8`; `mfaRequiredRoles` thiếu `ROLE-TENANT_ADMIN`; `maintenanceWindowPref` dài 8 giờ
    Và `PUT` với `itOwnerOrgCode = SO-CU`
    Và `U-T90-TO` gọi `PUT T/settings`; gọi thiếu `If-Match`; `If-Match` cũ
    Và `U-T92-TA` gọi `PUT T/settings`; `U-T91-TA` gọi `PUT T/settings`
    Thì bước 1, 2 `422` `ERR-20-023` ("sessionIdleMinutes vượt giới hạn của nền tảng (15)"). Bước 3 `404` `ERR-20-002` (tổ chức không `ACTIVE`). Bước 4 `403` `ERR-00-403`; `428` `ERR-00-428`; `412` `ERR-20-005`. Bước 5 `T92` `403` `ERR-20-001`; `T91` `409` `ERR-20-115`. Không đổi gì.

  @TC-20-051 @P2 @Dương
  Kịch bản: TC-20-051 Xem phiên bản, ghi chú, lịch bảo trì và đặt cửa sổ bảo trì ưa thích
    # Truy vết: FR-20-064, 018 · UC-20-11 · API-20-159, 160 · BR-20-033 · UI-20-12 · `PERM-20-settings`, `PERM-20-org-read`
    Biết `U-T90-TA`, `U-T90-TO`, `U-T90-AU`; `T90` chạy 2.3.1; kế hoạch nâng cấp 2.4.0 đã `SCHEDULED` cho `T90`; ghi chú 3 bản gần nhất.
    Khi `GET T/release-info` bằng `U-T90-TO`, `U-T90-AU`
    Và `PUT T/maintenance-window` với `dayOfWeek = SAT`, `startTime = 22:00`, `durationHours = 4`, `timezone = Asia/Ho_Chi_Minh`, kèm `If-Match`
    Và `GET T/release-info` lại
    Thì bước 1 `200` có phiên bản đang chạy, ghi chú ba bản gần nhất, lịch nâng cấp sắp tới, cửa sổ hiện hành; kênh có chữ "Chưa có lịch bảo trì" khi không có kế hoạch (tenant khác). Bước 2 `200`; cửa sổ mới áp cho kế hoạch lập sau, không đổi kế hoạch đã `SCHEDULED`. Bước 3 phản ánh cửa sổ mới. TO, AU không có nút đặt cửa sổ.

  @TC-20-052 @P2 @Âm
  Kịch bản: TC-20-052 Cửa sổ bảo trì ngoài giới hạn, trùng giờ cao điểm, tỉnh tạm ngừng
    # Truy vết: FR-20-064, 018 · API-20-160 · BR-20-033 · ERR-20-001, ERR-20-059, ERR-20-005, ERR-00-428
    Biết `U-T90-TA`; `U-T92-TA` (`SUSPENDED`).
    Khi `PUT T/maintenance-window` với `durationHours = 9`
    Và `PUT` với `dayOfWeek = MON`, `startTime = 09:00` (giờ cao điểm 7:00 đến 17:00 ngày làm việc)
    Và `PUT` với `timezone = UTC+99`
    Và `U-T92-TA` gọi `PUT T/maintenance-window`
    Và `PUT` thiếu `If-Match`
    Thì bước 1, 2, 3 `422` `ERR-20-059`. Bước 4 `403` `ERR-20-001`. Bước 5 `428` `ERR-00-428`. Cửa sổ cũ giữ nguyên.
