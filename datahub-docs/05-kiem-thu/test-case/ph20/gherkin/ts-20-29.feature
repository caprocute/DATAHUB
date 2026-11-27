# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-29
Tính năng: TS-20-29 · Kết thúc sáp nhập sau thời gian chuyển tiếp

  @TC-20-132 @P1 @Dương @Âm
  Kịch bản: TC-20-132 Gia hạn chuyển tiếp trong trần 12 tháng và vượt trần
    # Truy vết: FR-20-052 · UC-20-29 · API-20-107 · BR-20-025 · ERR-20-045, ERR-20-008, ERR-20-004, ERR-20-005, ERR-20-006, ERR-00-428 · UI-20-10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `TRANSITION` đã 8 tháng; tham số `20.merge.transition-max-months = 12`.
    Khi `POST P/merge-plans/{id}:extend-transition` với `extendMonths = 2`, `reason`, `ticketRef`, kèm `If-Match`
    Và gia hạn thêm `extendMonths = 3`
    Và gia hạn thiếu `reason`
    Và gia hạn kế hoạch `COMPLETED`; thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `200`, `transitionEndsAt` dời hai tháng (tổng 10). Bước 2 `422` `ERR-20-045` ("Thời gian chuyển tiếp tối đa 12 tháng."). Bước 3 `422` `ERR-20-008`. Bước 4 `409` `ERR-20-006`, `428` `ERR-00-428`, `412` `ERR-20-005`. Header `Sunset` đổi theo.

  @TC-20-133 @P1 @Dương
  Kịch bản: TC-20-133 Kết thúc sáp nhập đúng hạn và sớm khi không còn OLD_ONLY
    # Truy vết: FR-20-052 · UC-20-29 · API-20-108 · BR-20-020, 025 · EVT-20-12, EVT-20-04 · UI-20-10 · `PERM-20-merge`
    Biết kế hoạch `TRANSITION` đến hạn; `iam-sim` thu hồi client cũ; `obs-sim` (API-13-073); kế hoạch thứ hai kết thúc sớm.
    Khi đồng hồ giả lập tới `transitionEndsAt`, theo dõi tự động
    Và kế hoạch thứ hai: `POST .../:complete` với `confirmCode` khi không còn HTTT `OLD_ONLY`
    Và gọi địa chỉ cũ của nguồn sau khi kết thúc
    Thì nguồn `DECOMMISSIONED`, kế hoạch `COMPLETED`, chuyển tiếp tắt (EVT-20-12), client cũ thu hồi, chuỗi kiểm toán nguồn đóng (API-13-073), dữ liệu nguồn chỉ đọc rồi xóa mật mã theo FR-20-042. Kết thúc sớm `202`. Bước 3 `410` `ERR-20-102`. PH-16 nhận EVT-20-12.

  @TC-20-134 @P1 @Âm
  Kịch bản: TC-20-134 Kết thúc khi chưa hết chuyển tiếp và còn HTTT dùng địa chỉ cũ
    # Truy vết: FR-20-052 · API-20-108 · ERR-20-046, ERR-20-004, ERR-20-005, ERR-20-006, ERR-00-428
    Biết `U-PA1`; kế hoạch `TRANSITION` còn 3 tháng và 4 HTTT `OLD_ONLY`; kế hoạch `DRAFT`.
    Khi `POST .../:complete` khi còn `OLD_ONLY`
    Và `:complete` sai `confirmCode`
    Và `:complete` kế hoạch `DRAFT`
    Và thiếu `If-Match`; `If-Match` cũ
    Thì bước 1 `409` `ERR-20-046` ("Chưa hết thời gian chuyển tiếp (đến 2027-05-27) và còn 4 HTTT dùng địa chỉ cũ."). Bước 2 `400` `ERR-20-004`. Bước 3 `409` `ERR-20-006`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`.

  @TC-20-135 @P2 @Dương
  Kịch bản: TC-20-135 Nhắc 30, 7, 1 ngày trước khi hết chuyển tiếp
    # Truy vết: FR-20-052 · UC-20-29 · BR-20-025
    Biết kế hoạch `TRANSITION`; `ops-sim` thu thư; 3 HTTT `OLD_ONLY`.
    Khi đồng hồ giả lập tới T-30, T-7, T-1 ngày
    Và một HTTT chuyển xong (`IN_USE_NEW`) trước T-7
    Thì ba đợt thư đến đầu mối đúng 3 HTTT còn `OLD_ONLY` (đợt T-7 và T-1 chỉ 2 HTTT sau khi một cái đã chuyển); mỗi đợt gửi một lần.
