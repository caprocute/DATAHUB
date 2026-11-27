# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-06
Tính năng: TS-20-06 · Theo dõi saga, thử lại, bù trừ và hủy khởi tạo

  @TC-20-026 @P1 @Dương
  Kịch bản: TC-20-026 Xem danh sách lần chạy, chi tiết và luồng SSE kèm nối lại
    # Truy vết: FR-20-009 · UC-20-06 · API-20-014, 015, 016 · NFR-20-007 · UI-20-04 · `PERM-20-read`
    Biết `U-PA1`, `U-PO`; lần chạy `RUNNING` của `T97`.
    Khi `GET P/tenants/T97/provisioning-runs`
    Và `GET P/provisioning-runs/{runId}`
    Và mở `GET P/provisioning-runs/{runId}/stream` bằng `U-PO`, ghi `eventId`
    Và ngắt kết nối giữa chừng, nối lại với `Last-Event-ID`
    Và ngắt hơn 1 giờ rồi nối lại với `Last-Event-ID` cũ
    Thì bước 1, 2 `200`, có `currentStep`, `elapsedSeconds`, `etaSeconds`. Bước 3 nhận `step-changed` mỗi lần đổi bước, trễ ≤ 2 giây so với thời điểm bước đổi. Bước 4 nhận chuỗi bù, không mất, không lặp sự kiện. Bước 5 nhận ảnh chụp đầy đủ, không báo lỗi. UI-20-04 cập nhật dòng bước tại chỗ, giữ vị trí cuộn, hiện "Đang nối lại…" khi mất kết nối. `U-PO` thấy tiến độ nhưng không có nút ghi.

  @TC-20-027 @P1 @Dương
  Kịch bản: TC-20-027 Thử lại từ bước lỗi đầu tiên, bước đã xong không làm lại
    # Truy vết: FR-20-010 · UC-20-06 · API-20-017, 018 · BR-20-005, 007 · EVT-20-02 · UI-20-04 · `PERM-20-provision`
    Biết `T94`; F-SAGA: `S09_GATEWAY` `FAIL_ALWAYS` rồi đổi thành `OK`; lần chạy `FAILED`, `S01…S08` `SUCCEEDED`.
    Khi quan sát lần chạy `FAILED` sau 3 lần tự thử ở `S09_GATEWAY` (10, 30, 90 giây, dùng `clock-sim`)
    Và chuyển bản giả `S09_GATEWAY` sang `OK`
    Và `POST P/provisioning-runs/{runId}:retry` với `reason`, kèm `If-Match`, `Idempotency-Key`
    Và theo dõi tới khi kết thúc
    Thì bước 1 EVT: `platform.tenant.provisioning-failed.v1` (EVT-20-02) đúng một lần; tenant `FAILED`; việc báo PA ở PH-18. Bước 3 `202`, `status = RUNNING`, `attempt` tăng; tenant `PROVISIONING`; bước `S09_GATEWAY` gọi lại với cùng `Idempotency-Key = {runId}:S09_GATEWAY`, `S01…S08` không bị làm lại (bản giả đếm đúng một lần gọi mỗi bước). Bước 4 lần chạy `SUCCEEDED`. KT có lần thử lại, người thử, lý do.

  @TC-20-028 @P1 @Dương @Âm
  Kịch bản: TC-20-028 Thử lại một bước, bỏ qua bước không bắt buộc, từ chối bỏ qua bước bắt buộc
    # Truy vết: FR-20-010 · API-20-018, 019 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-008, ERR-20-018, ERR-20-009
    Biết `T94`; lần chạy `FAILED` với `S12_SEED_MDM` `FAILED` rồi `S03_REALM` `FAILED` ở lần chạy khác.
    Khi `POST .../steps/S12_SEED_MDM:retry`
    Và `POST .../steps/S12_SEED_MDM:skip` với `reason` 25 ký tự, `ticketRef`
    Và `POST .../steps/S03_REALM:skip` (bước bắt buộc)
    Và `POST .../steps/S12_SEED_MDM:skip` với `reason` 8 ký tự
    Và `POST .../steps/S01_RECORD:retry` khi bước đã `SUCCEEDED`
    Và `POST .../steps/S12_SEED_MDM:skip` với `If-Match` cũ
    Thì bước 1 `202`. Bước 2 `202`, bước `SKIPPED` kèm lý do, saga tiếp tục. Bước 3 `409` `ERR-20-018`. Bước 4 `422` `ERR-20-008`. Bước 5 `409` `ERR-20-018`. Bước 6 `412` `ERR-20-005`. Chỉ `S12_SEED_MDM`, `S14_KPI` và từng phân hệ của `S15_MODULES` bỏ qua được.

  @TC-20-029 @P2 @Âm
  Kịch bản: TC-20-029 Thử lại lần chạy không ở FAILED, thiếu If-Match
    # Truy vết: FR-20-010 · API-20-017 · ERR-20-006, ERR-20-018, ERR-20-005, ERR-00-428
    Biết `T93` lần chạy `SUCCEEDED`; `T94` lần chạy `RUNNING`.
    Khi `POST P/provisioning-runs/{runId-T93}:retry`
    Và `POST P/provisioning-runs/{runId-T94}:retry` khi đang `RUNNING`
    Và `POST .../{runId-T94 FAILED}:retry` thiếu `If-Match`
    Thì bước 1, 2 `409` `ERR-20-006`. Bước 3 `428` `ERR-00-428`.

  @TC-20-030 @P1 @Dương
  Kịch bản: TC-20-030 Bù trừ ngược và hủy khởi tạo, bucket còn đối tượng để dọn tay
    # Truy vết: FR-20-011 · UC-20-06 · API-20-020, 021 · BR-20-001, 005 · EVT-20-04 · UI-20-04 · `PERM-20-provision`
    Biết `T94` `FAILED` ở `S09_GATEWAY` sau khi `S01…S08` xong; bucket `dh-t94-files` còn một đối tượng thử.
    Khi `POST P/provisioning-runs/{runId}:cancel` với `reason`, `ticketRef`, `confirmTenantCode = T94`
    Và theo dõi thứ tự gọi bù trừ ở các bản giả
    Và đọc `steps[]`, trạng thái tenant
    Và khai báo lại tenant với `tenantCode = T94`
    Thì bước 1 `202`, lần chạy `COMPENSATING`. Bước 2 thứ tự bù ngược `S08` (đóng chuỗi API-13-073), `S07` không áp dụng, `S06` (EVT-20-04 `DECOMMISSIONED` để PH-10 gỡ), `S05` bucket rỗng thì xóa, bucket có đối tượng thì để lại đánh dấu `MANUAL_CLEANUP`, `S04` xóa đường dẫn và KEK chưa dùng, `S03` xóa realm `PROVISIONING`, `S02` revert commit, `S01` xóa bản ghi chỉ khi chưa có bước nào xong; mỗi lời gọi mang `Idempotency-Key = {runId}:{stepCode}:compensate`. Bước 3 lần chạy `COMPENSATED` rồi `CANCELLED`, tenant `DECOMMISSIONED`, danh sách việc dọn tay hiện ở UI-20-04. Bước 4 `409` `ERR-20-003` (mã không tái dùng, BR-20-001). EVT: `status-changed` đúng một lần.

  @TC-20-031 @P1 @Âm
  Kịch bản: TC-20-031 Bù trừ tenant đã từng hoạt động, sai mã xác nhận, sai trạng thái, bù trừ lỗi
    # Truy vết: FR-20-011 · API-20-020, 021 · ERR-20-004, ERR-20-006, ERR-20-008, ERR-20-019, ERR-20-107
    Biết `T90` đã từng `ACTIVE`; `T94` lần chạy `FAILED`; `T97` lần chạy `SUCCEEDED`; bản giả `S03_REALM` trả lỗi khi bù.
    Khi `POST P/provisioning-runs/{runId-T90}:compensate` (lần chạy `INITIAL` cũ của tenant đã `ACTIVE`)
    Và `POST .../{runId-T94}:cancel` với `confirmTenantCode = T99`
    Và `POST .../{runId-T97}:compensate` khi `SUCCEEDED`
    Và `POST .../{runId-T94}:cancel` không có `reason`
    Và bù trừ `T94` khi `iam-sim` lỗi ở `S03_REALM`
    Thì bước 1 `409` `ERR-20-019`. Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-006`. Bước 4 `422` `ERR-20-008`. Bước 5 bước `S03_REALM` giữ `COMPENSATING` với `ERR-20-107` ("Bước S03_REALM lỗi tại PH-12: không tạo được realm."), lần chạy `FAILED`, PA thử bù lại được; không xóa bản ghi tenant.
