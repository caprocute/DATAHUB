# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-22
Tính năng: TS-20-22 · Thực hiện chấm dứt tenant

  @TC-20-100 @P1 @Dương
  Kịch bản: TC-20-100 Thực hiện chấm dứt T92 và nhận xác nhận xóa mật mã
    # Truy vết: FR-20-042 · UC-20-22 · API-20-079 · BR-20-019, 020 · EVT-20-04 · ERR-20-102 · UI-20-08 · `PERM-20-lifecycle`
    Biết STAGING; `U-PA1`, `U-PA2`; `T92` `SUSPENDED` từ 35 ngày, đề nghị `TERMINATE` `APPROVED` do `U-PA2` duyệt, gói bàn giao `DELIVERED`; `iam-sim`, `obs-sim`, `crypto-sim`, `vault-sim`, `s3-sim`, `git-sim`.
    Khi `POST P/lifecycle-requests/{requestId}:execute` với `confirmTenantCode = T92`, kèm `If-Match`, `Idempotency-Key`
    Và theo dõi từng bước, kiểm các bản giả
    Và `crypto-sim` phát `EVT-09-21`
    Và gọi API bằng token `T92`
    Thì bước 1 `202`, `EXECUTING`. Bước 2 EVT: `platform.tenant.status-changed.v1` (`DECOMMISSIONED`) để phân hệ gỡ tài nguyên; PH-12 xóa realm; API-13-073 đóng chuỗi kiểm toán (chuỗi WORM giữ theo thời hạn); bucket, đường dẫn OpenBao gỡ, thư mục Git commit xóa có ký; gọi FR-09-043 xóa KEK `dh-t92-pii`. Bước 3 tenant `DECOMMISSIONED`, đề nghị `DONE`, lịch sử trạng thái có người duyệt và người thực hiện. Bước 4 `410` `ERR-20-102`. Mã `T92` không cấp lại được.

  @TC-20-101 @P1 @Âm
  Kịch bản: TC-20-101 Thực hiện chấm dứt khi thiếu điều kiện
    # Truy vết: FR-20-042 · API-20-079 · BR-20-008, 019 · ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-007, ERR-20-037, ERR-20-038 · ERR-00-428 · `20.terminate.cooling-days`
    Biết `U-PA1`, `U-PA2`; đề nghị A (gói bàn giao `READY` chưa `DELIVERED`), đề nghị B (`DELIVERED` nhưng mới tạm ngừng 20 ngày), đề nghị C (`PENDING_APPROVAL`).
    Khi `POST .../{A}:execute` với `confirmTenantCode` đúng
    Và `POST .../{B}:execute`
    Và `POST .../{C}:execute`
    Và `POST .../{A}:execute` với `confirmTenantCode = T99`
    Và `POST .../{A}:execute` thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `422` `ERR-20-037` (gói chưa `DELIVERED`). Bước 2 `422` `ERR-20-038`. Bước 3 `409` `ERR-20-006` (chưa duyệt). Bước 4 `400` `ERR-20-004`. Bước 5 `428` `ERR-00-428`, `412` `ERR-20-005`. Không phát EVT-20-04. Người xác nhận bàn giao trùng người duyệt: `403` `ERR-20-007` ở bước xác nhận (xem ca export-neg).

  @TC-20-102 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-20-102 Không nhận xác nhận xóa mật mã sau 24 giờ
    # Truy vết: FR-20-042 · API-20-079 · BR-20-020 · ERR-20-116 · UC-20-22
    Biết `T92` ở bước xóa mật mã; `crypto-sim` không phát `EVT-09-21`; `clock-sim`.
    Khi thực hiện chấm dứt `T92`, `crypto-sim` im lặng
    Và đẩy `clock-sim` 24 giờ
    Và kiểm tra trạng thái tenant và đề nghị
    Thì cảnh báo SO nền tảng với `ERR-20-116` ("Chưa nhận xác nhận xóa mật mã của T92"), tenant giữ `SUSPENDED`, đề nghị giữ `EXECUTING`; khi `EVT-09-21` tới sau đó thì chuyển `DECOMMISSIONED`.

  @TC-20-103 @P2 @Âm @Chịu @lỗi
  Kịch bản: TC-20-103 Phân hệ chưa báo gỡ xong sau 24 giờ, PH-12 lỗi khi xóa realm
    # Truy vết: FR-20-042 · API-20-079 · ERR-20-062 · ERR-20-102 · UC-20-22 · UI-20-08
    Biết `T92`; `mod-sim` PH-04 không báo gỡ; `iam-sim` `503` lần đầu.
    Khi thực hiện chấm dứt `T92` khi `iam-sim` `503`
    Và bật `iam-sim`, thực hiện lại
    Và đẩy `clock-sim` 24 giờ khi PH-04 chưa báo gỡ
    Thì bước 1 `503` `ERR-20-062`, đề nghị về `APPROVED`, thử lại được, chưa xóa gì không đảo ngược. Bước 2 thành công. Bước 3 tenant vẫn `DECOMMISSIONED` (data plane đã trả `ERR-20-102`), mở việc dọn cho PH-04 ở PH-18.
