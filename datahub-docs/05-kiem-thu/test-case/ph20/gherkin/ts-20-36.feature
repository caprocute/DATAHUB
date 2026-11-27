# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-36
Tính năng: TS-20-36 · Tra nhật ký kiểm toán và tham số 20.*

  @TC-20-181 @P1 @Dương
  Kịch bản: TC-20-181 PA, PAU tra nhật ký toàn nền tảng; TA, AU tra theo tỉnh
    # Truy vết: FR-20-068 · UC-20-36 · API-20-130, 161 · BR-20-009 · UI-20-03 · `PERM-20-read`
    Biết `U-PA1`, `U-PAU`, `U-T90-TA`, `U-T90-AU`; nhật ký có thao tác của `T90` và `T91`; `obs-sim` (API-13-072).
    Khi `U-PAU` `GET P/audit-events?tenantCode=T90&action=TENANT_SUSPEND&from=2026-11-01&to=2026-11-27`
    Và `U-PA1` `GET P/audit-events?actor=U-PA2&ticketRef=TICKET-01`
    Và `U-T90-TA` `GET T/audit-events?from=2026-11-01&to=2026-11-27`
    Và `U-T90-AU` `GET T/audit-events`
    Thì bước 1, 2 `200`, `items[]` đúng bộ lọc, thao tác thay đổi có lý do và phiếu. Bước 3, 4 chỉ thao tác liên quan `T90`, không có bản ghi `T91`.

  @TC-20-182 @P1 @Âm
  Kịch bản: TC-20-182 Tra kiểm toán: khoảng quá dài, PH-13 lỗi, tham số sai, chéo tenant
    # Truy vết: FR-20-068 · API-20-130, 161 · ERR-20-032, ERR-20-062, ERR-20-004 · SEC-87
    Biết `U-PA1`, `U-T90-TA`; `obs-sim` `503`.
    Khi `GET P/audit-events?from=2025-01-01&to=2026-11-27` (> 366 ngày)
    Và `GET P/audit-events?from=2026-11-27&to=2026-11-01`
    Và `GET P/audit-events` khi `obs-sim` `503`
    Và `U-T90-TA` `GET T/audit-events?tenantCode=T91`
    Và `U-T90-TA` `GET P/audit-events`
    Thì bước 1 `400` `ERR-20-032` ("Khoảng thời gian tối đa là 366 ngày."). Bước 2 `400` `ERR-20-004`. Bước 3 `503` `ERR-20-062`. Bước 4 chỉ trả bản ghi của `T90` (tham số `tenantCode` không mở rộng phạm vi). Bước 5 `403` `ERR-00-403`.

  @TC-20-183 @P1 @Dương
  Kịch bản: TC-20-183 Xem tham số 20.* với giá trị hiệu lực và nguồn
    # Truy vết: FR-20-069 · UC-20-36 · API-20-131 · BR-20-004 · UI-20-03 · `PERM-20-read`
    Biết `U-PA1`; `ops-sim` đã đăng ký 29 khóa; `20.release.stable-soak-days` ghi đè 21 ngày.
    Khi `GET P/parameters?page=1&size=50`
    Và `GET P/parameters?q=release`
    Thì bước 1 đủ 29 khóa, mỗi khóa có miền, mặc định, giá trị hiệu lực, nguồn. Bước 2 các khóa `20.release.*`, `stable-soak-days = 21` nguồn ghi đè, còn lại nguồn mặc định.

  @TC-20-184 @P1 @Dương @Âm
  Kịch bản: TC-20-184 Đổi tham số qua PH-18 áp trong 60 giây; ngoài miền bị từ chối
    # Truy vết: FR-20-069 · UC-20-36 · BR-20-004 · ERR-20-060 · BR-20-037
    Biết `ops-sim` đẩy thay đổi tham số; `U-PO` đổi ở PH-18; tenant thật `T01` có mặt.
    Khi `ops-sim` đổi `20.release.wave-error-threshold-percent` từ 2 sang 3
    Và chờ ≤ 60 giây rồi `GET P/parameters?q=wave-error`
    Và đẩy giá trị 20 (ngoài miền 0,5…10)
    Và đẩy `20.smoke.enabled = false` khi nền tảng có tenant tỉnh thật
    Và `ops-sim` không khả dụng khi DU khởi động lại
    Thì bước 2 giá trị hiệu lực 3, nguồn ghi đè, đã áp ≤ 60 giây. Bước 3, 4 bị từ chối với `ERR-20-060` ("Giá trị 20 của tham số 20.release.wave-error-threshold-percent ngoài miền 0,5…10."); giá trị cũ giữ. Bước 5 DU dùng giá trị cuối đã nhận, rồi mặc định dự phòng.

  @TC-20-185 @P3 @Âm
  Kịch bản: TC-20-185 Tham số: tham số truy vấn sai, tenant xem chéo
    # Truy vết: FR-20-069 · API-20-131 · ERR-20-004
    Biết `U-PA1`, `U-T90-TA`.
    Khi `GET P/parameters?size=0`; `?size=1000`
    Và `U-T90-TA` `GET P/parameters`
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `403` `ERR-00-403`.
