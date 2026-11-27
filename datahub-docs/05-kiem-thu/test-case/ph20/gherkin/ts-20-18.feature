# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-18
Tính năng: TS-20-18 · Tắt, tạm ngừng, tiếp tục phân hệ và đặt cờ tính năng

  @TC-20-081 @P1 @Dương
  Kịch bản: TC-20-081 Tạm ngừng, tiếp tục và tắt phân hệ, dữ liệu giữ nguyên
    # Truy vết: FR-20-035 · UC-20-18 · API-20-066, 067, 068, 064 · BR-20-018 · EVT-20-08 · ERR-20-103 · UI-20-07 · `PERM-20-admin`
    Biết `U-PA1`; `T90` có PH-17 `ENABLED` và dữ liệu thử; `mod-sim` báo xong.
    Khi `POST P/tenants/T90/modules/PH-17:suspend` với `reason`, `ticketRef`
    Và gọi API của PH-17 bằng token `T90`
    Và `POST .../PH-17:resume`
    Và `POST .../PH-17:disable`; `mod-sim` báo xong; `GET P/tenants/T90/modules`
    Và bật lại PH-17 và đọc dữ liệu cũ
    Thì bước 1 `202`, `SUSPENDED`, EVT: `platform.tenant.module-disabled.v1`; menu hiện chỉ đọc. Bước 2 `503` `ERR-20-103` ("Chức năng này chưa được bật cho tỉnh."). Bước 3 `ENABLED`. Bước 4 `DISABLING` rồi `DISABLED`, EVT `module-disabled` một lần. Bước 5 dữ liệu của phân hệ còn nguyên (BR-20-018).

  @TC-20-082 @P1 @Âm
  Kịch bản: TC-20-082 Tắt phân hệ lõi, phân hệ đang bị phụ thuộc, sai trạng thái
    # Truy vết: FR-20-035 · API-20-066, 067, 068 · BR-20-003, 017 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-034, ERR-20-035
    Biết `U-PA1`; `T90` có PH-06 là phụ thuộc của PH-08; PH-17 `DISABLED`; `PLATFORM`.
    Khi `POST P/tenants/T90/modules/PH-12:disable`
    Và `POST P/tenants/T90/modules/PH-06:disable` khi PH-08 đang bật
    Và `POST .../PH-17:suspend` khi `DISABLED`
    Và `POST .../PH-16:resume` khi `ENABLED`
    Và `POST .../PH-16:disable` thiếu `reason`; `PH-99:disable`
    Và `POST P/tenants/PLATFORM/modules/PH-16:suspend`
    Thì bước 1 `403` `ERR-20-035`. Bước 2 `409` `ERR-20-034`. Bước 3, 4 `409` `ERR-20-006`. Bước 5 `422` `ERR-20-008`, rồi `400` `ERR-20-004`. Bước 6 `403` `ERR-20-010`.

  @TC-20-083 @P2 @Dương
  Kịch bản: TC-20-083 Đặt và xem cờ tính năng theo tenant
    # Truy vết: FR-20-036 · UC-20-18 · API-20-069, 070 · UI-20-07 · `PERM-20-admin`
    Biết `U-PA1`; `T90` PH-19 `ENABLED` có cờ `ph19.tinh-nang-thu`.
    Khi `GET P/tenants/T90/feature-flags?moduleCode=PH-19`
    Và `PUT P/tenants/T90/feature-flags/ph19.tinh-nang-thu` với `enabled = true`, `validTo`, `reason`, `ticketRef`, kèm `If-Match`
    Và `GET T/context` bằng `U-T90-VW`
    Thì bước 2 `200`. Bước 3 `featureFlags` có cờ bật đến `validTo`; sau hạn tự tắt. KT có `reason`, `ticketRef`.

  @TC-20-084 @P2 @Âm
  Kịch bản: TC-20-084 Cờ không áp dụng, cờ không có, thiếu If-Match, thiếu lý do
    # Truy vết: FR-20-036 · API-20-070 · ERR-20-002, ERR-20-004, ERR-20-005, ERR-20-008, ERR-20-010, ERR-20-036, ERR-00-428
    Biết `U-PA1`; cờ `ph17.tro-ly-thu` thuộc PH-17 đang `DISABLED`; `PLATFORM`.
    Khi `PUT .../feature-flags/ph17.tro-ly-thu` với `enabled = true`
    Và `PUT .../feature-flags/khong-co`
    Và `PUT .../feature-flags/ph19.tinh-nang-thu` với `validTo` trong quá khứ
    Và `PUT` thiếu `If-Match`; `If-Match` cũ; thiếu `reason`
    Và `PUT P/tenants/PLATFORM/feature-flags/ph19.tinh-nang-thu`
    Thì bước 1 `422` `ERR-20-036` (phân hệ chưa bật). Bước 2 `404` `ERR-20-002`. Bước 3 `400` `ERR-20-004`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`, `422` `ERR-20-008`. Bước 5 `403` `ERR-20-010`.
