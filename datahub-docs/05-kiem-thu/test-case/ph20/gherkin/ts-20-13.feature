# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-13
Tính năng: TS-20-13 · Chuyển chế độ cách ly của tenant

  @TC-20-057 @P2 @Dương
  Kịch bản: TC-20-057 Đổi T95 từ SHARED lên DEDICATED_DB có duyệt bốn mắt
    # Truy vết: FR-20-025 · UC-20-13 · API-20-047, 075, 076, 079 · BR-20-008, 040 · EVT-20-04, 09 · UI-20-03 · `PERM-20-lifecycle`, `PERM-20-approve`
    Biết STAGING; `U-PA1`, `U-PA2`; `T95` `ACTIVE` `SHARED`, `DATABASE_GB` 40; công cụ chuyển dữ liệu của PH-18 giả (`ops-sim`); cửa sổ bảo trì thứ Bảy 22:00.
    Khi `U-PA1` `POST P/tenants/T95/isolation-changes` với `targetMode = DEDICATED_DB`, `scheduledAt` trong cửa sổ, `decisionDocNo`, `reason`, `ticketRef`
    Và `U-PA1` gửi duyệt `POST P/lifecycle-requests/{requestId}:submit`
    Và `U-PA2` `POST .../{requestId}:approve` với `comment`
    Và đẩy `clock-sim` tới giờ hẹn; theo dõi lần chạy `ISOLATION_CHANGE`
    Thì bước 1 `201`, `requestType = ISOLATION_CHANGE`, có ước thời gian và dung lượng. Bước 2 `PENDING_APPROVAL`. Bước 3 `200`, `APPROVED`. Bước 4 tới giờ hẹn tạo lần chạy `ISOLATION_CHANGE`: `S07_DATABASE` tạo cụm CloudNativePG, sao dữ liệu theo `tenant_id`, kiểm đếm từng bảng khớp, đổi `isolationMode = DEDICATED_DB`, đề nghị `DONE`; dữ liệu cũ giữ ở cụm chung `20.export.retention-days` ngày rồi xóa. EVT: `status-changed` và `config-changed`. Tenant phục vụ bình thường trong cửa sổ.

  @TC-20-058 @P2 @Âm
  Kịch bản: TC-20-058 Đổi cách ly: bỏ bậc, ngoài cửa sổ, kiểm đếm lệch, trạng thái sai
    # Truy vết: FR-20-025 · API-20-047, 079 · BR-20-040 · ERR-20-004, ERR-20-006, ERR-20-028, ERR-20-059, ERR-20-113
    Biết `U-PA1`; `T95` `SHARED`; `T90` có lần chạy đổi cách ly `RUNNING`; bản giả báo kiểm đếm lệch ở bảng `organization`.
    Khi `POST P/tenants/T95/isolation-changes` với `targetMode = DEDICATED_CLUSTER` (bỏ bậc)
    Và `POST` với `scheduledAt` thứ Hai 09:00 (ngoài cửa sổ bảo trì)
    Và `POST` thiếu `decisionDocNo`
    Và `POST P/tenants/T90/isolation-changes` khi đang có lần chạy khác
    Và chạy đổi cách ly khi bản giả kiểm đếm lệch
    Thì bước 1 `422` `ERR-20-028`. Bước 2 `422` `ERR-20-059`. Bước 3 `400` `ERR-20-004`. Bước 4 `409` `ERR-20-006`. Bước 5 lần chạy `FAILED` với `ERR-20-113` ("Kiểm đếm organization lệch: nguồn 40, đích 39"), định tuyến giữ cụm cũ, dữ liệu không mất.
