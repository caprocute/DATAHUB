# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-05
Tính năng: TS-20-05 · Chạy saga khởi tạo tenant

  @TC-20-022 @P1 @Dương
  Kịch bản: TC-20-022 Chạy saga INITIAL của T93 tới ACTIVE qua 17 bước
    # Truy vết: FR-20-008, 012, 013 · UC-20-05 · API-20-013, 015, 166 · BR-20-004, 005, 006, 042 · EVT-20-01, 03, 07 · UI-20-04 · `PERM-20-provision`
    Biết STAGING; `U-PA1`; `T93` `PROVISIONING` (ca reg-ok); F-SAGA toàn `OK`; PH-06, PH-16, PH-19 bật theo mẫu, PH-17 tắt.
    Khi `POST P/tenants/T93/provisioning-runs` với `runKind = INITIAL`
    Và theo dõi `GET P/provisioning-runs/{runId}` cho tới khi kết thúc
    Và đọc `steps[]` và `smokeResults[]`
    Và đọc sự kiện trên `platform.tenant.created.v1`, `platform.tenant.module-enabled.v1`, `platform.tenant.activated.v1`
    Thì bước 1 `202`, `Location` trỏ lần chạy, `status = PENDING`, 17 bước theo thứ tự. Bước 2 kết thúc `SUCCEEDED`, `durationSeconds` ≤ 3.600; tenant `ACTIVE`. Bước 3: `S07_DATABASE` `SKIPPED` (chế độ `SHARED`); các bước còn lại `SUCCEEDED`, mỗi bước có `outputRef`; bốn ca khói `PASS`. EVT: `created` đúng một lần ngay sau `S05_BUCKETS`; `module-enabled` cho mỗi phân hệ không lõi bật theo mẫu (PH-19, PH-16, PH-06; không có PH-17); `activated` một lần ở `S17_ACTIVATE`. Phân hệ lõi `ENABLED` ngay. KT: mỗi bước bắt đầu, kết thúc, kết quả, `templateVersion = 3`, vào chuỗi `PLATFORM` và chuỗi `T93` khi đã có.

  @TC-20-023 @P2 @Dương
  Kịch bản: TC-20-023 Bước không áp dụng: S07 theo chế độ cách ly, S12 và S14 theo phân hệ bật
    # Truy vết: FR-20-008 · API-20-013 · UC-20-05 · BR-20-042
    Biết `T95` hồ sơ `DEDICATED_DB`; `T93` hồ sơ không bật PH-06, PH-16 (mẫu `mau-thu-90` bản không có hai phân hệ này); CNPG giả.
    Khi chạy saga `INITIAL` cho `T95` (`DEDICATED_DB`)
    Và chạy saga `INITIAL` cho tenant dùng mẫu không bật PH-06 và PH-16
    Và so sánh trạng thái `S07_DATABASE`, `S12_SEED_MDM`, `S14_KPI`
    Thì `T95`: `S07_DATABASE` chạy và `SUCCEEDED` (tạo cụm CloudNativePG, migration, bảng định tuyến), các bước sau dùng chuỗi kết nối mới. Tenant không bật PH-06: `S12_SEED_MDM` `SKIPPED`; không bật PH-16: `S14_KPI` `SKIPPED`; cả hai lần chạy vẫn `SUCCEEDED`.

  @TC-20-024 @P1 @Âm
  Kịch bản: TC-20-024 Chạy saga khi tenant sai trạng thái, đang có lần chạy, chưa sẵn sàng, tenant đặc biệt
    # Truy vết: FR-20-008, 016 · API-20-013 · BR-20-006 · ERR-20-006, ERR-20-010, ERR-20-016, ERR-20-017, ERR-20-009
    Biết `U-PA1`; `T90` `ACTIVE`; `T94` có một lần chạy `RUNNING`; `T96` có `BLOCKER` sức chứa.
    Khi `POST P/tenants/T90/provisioning-runs` với `runKind = INITIAL`
    Và `POST P/tenants/T94/provisioning-runs` lần hai khi lần chạy đầu chưa kết thúc
    Và `POST P/tenants/T96/provisioning-runs` khi kiểm tra sẵn sàng có `BLOCKER`
    Và `POST P/tenants/PLATFORM/provisioning-runs`
    Và gửi lại cùng `Idempotency-Key` khác thân
    Thì bước 1 `409` `ERR-20-006`. Bước 2 `409` `ERR-20-016` kèm `runId` đang chạy. Bước 3 `422` `ERR-20-017`. Bước 4 `403` `ERR-20-010`. Bước 5 `409` `ERR-20-009`. Mỗi tenant có tối đa một lần chạy chưa kết thúc.

  @TC-20-025 @P1 @Dương @Âm
  Kịch bản: TC-20-025 Phân hệ báo tiến độ bước chờ báo: hợp lệ, báo trùng, sai trạng thái, thiếu scope
    # Truy vết: FR-20-008, 009 · API-20-166 · BR-20-005 · ERR-20-002, ERR-20-004, ERR-20-104, ERR-20-105
    Biết `T94` có lần chạy với `S06_EVENTING` `WAITING_REPORT`, `S10_INTEGRATION` `PENDING`; `S-PH10` (scope `tenant:provision-report`), `S-NOSCOPE`, `S-PH03`.
    Khi `S-PH10` gọi `POST I/provisioning-runs/{runId}/steps/S06_EVENTING:report` với `status = SUCCEEDED`, `outputRef`, kèm `Idempotency-Key = {runId}:S06_EVENTING:report`
    Và `S-PH10` gửi lại đúng báo cáo, đúng khóa
    Và `S-PH10` báo cho `S10_INTEGRATION` đang `PENDING`
    Và `S-NOSCOPE` báo cho `S06_EVENTING`
    Và `S-PH10` báo `status = FAILED` thiếu `errorCode`
    Và báo cho `runId` không tồn tại
    Thì bước 1 `200`, `S06_EVENTING` `SUCCEEDED`. Bước 2 `200` trả lại đúng kết quả lần đầu, không đổi bước hai lần. Bước 3 `409` `ERR-20-105`. Bước 4 `403` `ERR-20-104`. Bước 5 `400` `ERR-20-004`. Bước 6 `404` `ERR-20-002`. SSE của UI-20-04 nhận `step-changed` cho bước 1.
