# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-07
Tính năng: TS-20-07 · Kiểm tra khói, kích hoạt, bàn giao và đo thời gian khởi tạo

  @TC-20-032 @P1 @Dương
  Kịch bản: TC-20-032 Chạy lại kiểm tra khói trên tenant đang hoạt động
    # Truy vết: FR-20-012 · UC-20-07 · API-20-022, 015 · BR-20-004 · UI-20-04 · `PERM-20-provision`
    Biết `U-PA1`; `T93` `ACTIVE`; `iam-sim`, `mod-sim` sẵn sàng; `T99` có tài nguyên mồi.
    Khi `POST P/tenants/T93/smoke-tests`
    Và `GET P/provisioning-runs/{runId}` đọc `smokeResults[]`
    Thì bước 1 `202`. Bước 2 có bốn ca `LOGIN_ADMIN`, `API_SAMPLE`, `EVENT_SAMPLE`, `CROSS_TENANT_LEAK` đều `PASS`, mỗi ca có `durationMs`, `evidence`; ca `CROSS_TENANT_LEAK` đọc tài nguyên mồi của `T99` bằng token `T93` và nhận `404`. Tài khoản máy tạm `smoke-{runId}` hết hạn 30 phút và bị xóa; HTTT giả lập bị xóa; trạng thái tenant không đổi.

  @TC-20-033 @P1 @Âm
  Kịch bản: TC-20-033 Ca khói lỗi, rò rỉ phát hiện, tắt khói, chạy chồng
    # Truy vết: FR-20-012 · API-20-022, 023 · BR-20-004 · ERR-20-006, ERR-20-016, ERR-20-020, ERR-20-111, ERR-20-117
    Biết `T94` ở `S16_SMOKE`; `mod-sim` cài `EVENT_SAMPLE` lỗi; kịch bản khác cài `CROSS_TENANT_LEAK` trả `200`; `T92` `SUSPENDED`.
    Khi chạy saga `T94` tới `S16_SMOKE` với `EVENT_SAMPLE` lỗi
    Và cài `T99` đọc được từ token `T94` (rò rỉ giả lập) rồi chạy lại khói
    Và đặt `20.smoke.enabled = false` cho `T94` (tenant kiểm thử), chạy lại; thử đặt `false` ở nền tảng có tenant tỉnh thật
    Và `POST P/tenants/T92/smoke-tests` khi `SUSPENDED`; `POST` khi đang có lần chạy khác
    Thì bước 1 ca `EVENT_SAMPLE` ghi `ERR-20-117` ("Ca kiểm tra khói EVENT_SAMPLE lỗi: không nhận lại sự kiện mẫu sau 30 giây."), bước `S16_SMOKE` và lần chạy `FAILED`. Bước 2 `ERR-20-111` ("Phát hiện rò rỉ chéo tenant ở GET /api/tenant/v1/context."), sự cố mức 1 mở ở PH-18, báo PO, kích hoạt bị chặn. Bước 3 tenant kiểm thử: `S16_SMOKE` `SKIPPED` kèm cảnh báo; đặt `false` khi có tenant tỉnh thật bị từ chối (BR-20-004). Bước 4 `409` `ERR-20-006`, rồi `409` `ERR-20-016`.

  @TC-20-034 @P1 @Dương
  Kịch bản: TC-20-034 Kích hoạt tenant, bàn giao qua thư, hẹn giờ kích hoạt
    # Truy vết: FR-20-013, 014 · UC-20-07 · API-20-023, 015 · BR-20-004 · EVT-20-03 · UI-20-04 · `PERM-20-provision`
    Biết `T97` `PROVISIONING`, bước `S16_SMOKE` đạt; `T93` hẹn giờ; `ops-sim` nhận thư; `kpi-sim` sẵn sàng.
    Khi `POST P/tenants/T97:activate` kèm `If-Match`, `Idempotency-Key`
    Và `POST P/tenants/T96:activate` với `activateAt` sau 5 ngày; sau đó dùng `clock-sim` đẩy tới giờ hẹn
    Và đọc thư bàn giao ở `ops-sim`, đọc quan sát ở `kpi-sim`
    Thì bước 1 `200`, tenant `ACTIVE`, `activatedAt` có giá trị, `handoverDelivery = SENT`, máy khách kiểm thử ở realm bị xóa; EVT: `platform.tenant.activated.v1` đúng một lần; registry vô hiệu đệm. Bước 2 `S17_ACTIVATE` chờ tới giờ hẹn rồi `ACTIVE`; hủy hẹn thì kích hoạt ngay. Bước 3 thư mẫu `ph20-handover` tới ba đầu mối `TENANT_ADMIN`, `LEADER`, `TECHNICAL`; PH-16 nhận quan sát `thoi-gian-khoi-tao-tenant` (KPI-12) kèm tham chiếu chống lặp là `runId`. KT kích hoạt.

  @TC-20-035 @P1 @Âm
  Kịch bản: TC-20-035 Kích hoạt khi khói chưa đạt, sai trạng thái, thiếu đầu mối, thư và KPI lỗi
    # Truy vết: FR-20-013, 014 · API-20-023 · ERR-20-006, ERR-20-020, ERR-20-021, ERR-20-062, ERR-20-005
    Biết `T94` khói còn 1 ca lỗi; `T90` `ACTIVE`; tenant không còn đầu mối `TENANT_ADMIN`; `ops-sim` và `kpi-sim` trả `503`.
    Khi `POST P/tenants/T94:activate`
    Và `POST P/tenants/T90:activate`
    Và `POST P/tenants/T97:activate` khi thiếu đầu mối `TENANT_ADMIN`
    Và kích hoạt tenant có khói đạt khi `ops-sim` và `kpi-sim` đều `503`
    Và `POST ...:activate` với `If-Match` cũ
    Thì bước 1 `422` `ERR-20-020`. Bước 2 `409` `ERR-20-006`. Bước 3 `422` `ERR-20-021`. Bước 4 tenant vẫn `ACTIVE`, `handoverDelivery = FAILED`, UI-20-04 hiện `ERR-20-062` kèm nút "Gửi lại" (tối đa 3 lần mỗi ngày); quan sát KPI giữ ở outbox chuyên dụng, thử lại mỗi giờ. Bước 5 `412` `ERR-20-005`.

  @TC-20-036 @P2 @Dương @Âm
  Kịch bản: TC-20-036 Thống kê thời gian khởi tạo theo giờ làm việc và khoảng thời gian
    # Truy vết: FR-20-014 · API-20-024 · BR-20-041 · NFR-20-002 · ERR-20-004, ERR-20-032 · UI-20-20 · `PERM-20-read`
    Biết `U-PA1`; `T93`: `declaredAt` thứ Sáu 15:00, `activatedAt` thứ Hai 10:00 sau; ngày làm việc 08:00 đến 17:00, thứ Bảy và Chủ nhật nghỉ (lịch do PH-18 quản, Q20-19).
    Khi `GET P/provisioning-metrics?tenantCode=T93`
    Và `GET P/provisioning-metrics?from=2025-01-01&to=2026-11-27`
    Và `GET P/provisioning-metrics?from=2024-01-01&to=2026-11-27`
    Và `GET P/provisioning-metrics?from=khong-phai-ngay`
    Thì bước 1 `leadTimeWorkingHours` = 4 (thứ Sáu 15:00 đến 17:00 được 2 giờ, thứ Hai 08:00 đến 10:00 được 2 giờ, cuối tuần không tính), `provisionMinutes` ≤ 60, có `slowestStep`. Bước 2 trả `median`, `p95`. Bước 3 `400` `ERR-20-032`. Bước 4 `400` `ERR-20-004`. Chỉ số `dh_tenant_provision_duration_seconds` có nhãn `tenant`.
