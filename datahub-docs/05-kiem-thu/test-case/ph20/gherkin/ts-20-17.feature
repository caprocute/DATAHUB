# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-17
Tính năng: TS-20-17 · Danh mục phân hệ, bật phân hệ và trạng thái cho menu

  @TC-20-074 @P1 @Dương
  Kịch bản: TC-20-074 Xem danh mục phân hệ, ma trận phụ thuộc và phân hệ của tenant
    # Truy vết: FR-20-033 · UC-20-17 · API-20-063, 064 · BR-20-017 · UI-20-07 · `PERM-20-read`
    Biết `U-PA1`; `T90` có PH-16, PH-19 bật, PH-17 tắt.
    Khi `GET P/modules?wave=1&core=true`
    Và `GET P/modules?q=PH-16`
    Và `GET P/tenants/T90/modules`
    Thì bước 1 có phân hệ lõi PH-03, PH-10, PH-12, PH-13, PH-18, PH-20 với `core = true`. Bước 2 có `PH-16`, kèm phụ thuộc. Bước 3 mỗi phân hệ có `state` (`ENABLED`, `DISABLED`), `core`, `runId`, `lastReportAt`. Ma trận phụ thuộc hiển thị ở UI-20-07.

  @TC-20-075 @P1 @Dương
  Kịch bản: TC-20-075 Bật phân hệ PH-17 cho T90 và nhận báo xong
    # Truy vết: FR-20-034 · UC-20-17 · API-20-065, 166, 064 · BR-20-017 · EVT-20-07 · UI-20-07 · `PERM-20-admin`
    Biết `U-PA1`; `T90`; PH-17 `DISABLED`; phụ thuộc của PH-17 đã bật; `S-PH17` (`mod-sim`) có scope báo tiến độ.
    Khi `POST P/tenants/T90/modules/PH-17:enable` với `reason`, `ticketRef`, `Idempotency-Key`
    Và `GET P/tenants/T90/modules`
    Và `mod-sim` báo `SUCCEEDED` qua `POST I/provisioning-runs/{runId}/steps/S15_MODULES:report`
    Và `GET T/context` bằng `U-T90-VW`
    Thì bước 1 `202`, `ModuleState = ENABLING`; EVT: `platform.tenant.module-enabled.v1` một lần. Bước 3 `ENABLED`. Bước 4 `modules` có PH-17 `ENABLED`, menu hiện mục PH-17. KT có `reason`, `ticketRef`.

  @TC-20-076 @P1 @Âm
  Kịch bản: TC-20-076 Bật thiếu phụ thuộc, đã bật, phân hệ chưa sẵn sàng, tenant đặc biệt
    # Truy vết: FR-20-034 · API-20-065 · BR-20-017 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-010, ERR-20-033, ERR-20-055
    Biết `U-PA1`; `T91` chưa bật PH-06; phân hệ PH-14 trạng thái `PLANNED` ở danh mục; `T90` có PH-16 `ENABLED`.
    Khi `POST P/tenants/T91/modules/PH-08:enable` khi PH-06 (phụ thuộc) chưa bật
    Và `POST P/tenants/T90/modules/PH-16:enable`
    Và `POST P/tenants/T90/modules/PH-14:enable`
    Và `POST P/tenants/T90/modules/PH-99:enable`
    Và `POST .../PH-17:enable` thiếu `reason`
    Và `POST P/tenants/PLATFORM/modules/PH-17:enable`
    Thì bước 1 `422` `ERR-20-033`. Bước 2 `409` `ERR-20-006`. Bước 3 `422` `ERR-20-055` (theo OpenAPI liệt kê `ERR-20-055` cho API-20-065; FRS chưa nêu, xem đề nghị ĐN-TC-04). Bước 4 `400` `ERR-20-004`. Bước 5 `422` `ERR-20-008`. Bước 6 `403` `ERR-20-010`.

  @TC-20-077 @P2 @Âm @Chịu @lỗi
  Kịch bản: TC-20-077 Phân hệ báo lỗi hoặc quá hạn khi bật rồi thử lại
    # Truy vết: FR-20-034 · API-20-065, 166 · UC-20-17 · ERR-20-106, ERR-20-107 · UI-20-07
    Biết `U-PA1`; `mod-sim` cài `REPORT_FAILED` rồi `NO_REPORT`; `clock-sim`.
    Khi bật PH-17 cho `T91`, `mod-sim` báo `FAILED` kèm `errorCode`
    Và bật lại PH-17, `mod-sim` không báo; đẩy `clock-sim` quá `20.provision.step-timeout-minutes` (15 phút)
    Và bật lại PH-17, `mod-sim` báo `SUCCEEDED`
    Thì bước 1 `ModuleState = FAILED`, `ERR-20-107` ("Bước S15_MODULES lỗi tại PH-17: khởi động phân hệ thất bại."). Bước 2 `FAILED` với `ERR-20-106` ("Bước S15_MODULES chưa nhận báo cáo từ PH-17 sau 15 phút."). Bước 3 `ENABLED`. Phân hệ khác không bị ảnh hưởng.

  @TC-20-078 @P1 @Dương
  Kịch bản: TC-20-078 Trạng thái tenant, phân hệ và dải cảnh báo cho menu
    # Truy vết: FR-20-037, 066 · UC-20-17 · API-20-142, 163 · UI-20-07 · NFR-20-004 · BR-20-036
    Biết `U-T90-VW`, `U-T92-TA` (`SUSPENDED`), `U-T91-TA` (`MERGED`); `S-PH03`.
    Khi `GET T/context` bằng `U-T90-VW`
    Và `GET T/context` bằng `U-T92-TA`
    Và `GET T/context` bằng `U-T91-TA`
    Và `S-PH03` gọi `GET I/tenants/T90`
    Và mở `dh-console` bằng từng tài khoản
    Thì bước 1 `status = ACTIVE`, `readOnly = false`, `modules[]`, `banner` rỗng. Bước 2 `status = SUSPENDED`, `readOnly = true`, `banner` `CRITICAL` "Tỉnh đang tạm ngừng hoạt động trên Datahub. Liên hệ quản trị tỉnh." Bước 3 `MERGED`, `readOnly = true`, banner kèm liên kết sang tỉnh đích. Bước 4 bản ghi registry có phân hệ đang bật. Bước 5 dải cảnh báo xuất hiện ngay dưới thanh trên, menu ẩn mục phân hệ chưa bật, làm mới mỗi 60 giây; API `context` luôn `200` kể cả khi tạm ngừng.

  @TC-20-079 @P3 @Âm
  Kịch bản: TC-20-079 Danh mục phân hệ: tham số sai, danh mục chưa nạp
    # Truy vết: FR-20-033 · API-20-063, 064 · ERR-20-004, ERR-20-062, ERR-20-002
    Biết `U-PA1`; `T90`; danh mục phân hệ chưa nạp (bản giả lỗi triển khai).
    Khi `GET P/modules?wave=abc`; `GET P/modules?core=maybe`
    Và `GET P/modules` khi danh mục chưa nạp
    Và `GET P/tenants/T-KHONG-CO/modules`
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `503` `ERR-20-062`. Bước 3 `404` `ERR-20-002`.

  @TC-20-080 @P2 @Âm
  Kịch bản: TC-20-080 Ngữ cảnh tenant: token không có tenant, tenant đã chấm dứt, tham số tenant giả
    # Truy vết: FR-20-037 · API-20-142, 163 · ERR-00-401 · ERR-20-102 · ERR-20-104
    Biết `U-T90-VW`; token không có tenant; `T88` `DECOMMISSIONED` (người dùng cũ); `S-NOSCOPE`.
    Khi `GET T/context` với token không có tenant hợp lệ
    Và `GET T/context` bằng người dùng của `T88`
    Và `GET T/context?tenantId=T91` bằng `U-T90-VW`
    Và `S-NOSCOPE` `GET I/tenants/T90`
    Thì bước 1 `401` `ERR-00-401` ("Phiên đăng nhập đã hết hạn. Đăng nhập lại."). Bước 2 `410` `ERR-20-102` ("Tỉnh đã chấm dứt sử dụng Datahub."). Bước 3 trả ngữ cảnh `T90` (tham số bị bỏ qua). Bước 4 `403` `ERR-20-104`.
