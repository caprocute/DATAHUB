# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-44
Tính năng: TS-20-44 · Đầu cuối: khởi tạo tỉnh, sáp nhập hai tỉnh, phát hành theo sóng

  @TC-20-231 @P1 @Dương
  Kịch bản: TC-20-231 Khai báo, kiểm sẵn sàng, saga 17 bước, kiểm tra khói, ACTIVE, KPI-12
    # Truy vết: FR-20-001, 007, 008, 012, 013, 014 · UC-20-01, 05, 06, 07 · NFR-00-057 · NFR-20-002 · EVT-20-01, 03
    Biết STAGING; `U-PA1`; F-HS-93, F-TPL, F-SAGA `OK`; mọi giả lập.
    Khi khai báo `T93` bằng wizard UI-20-02
    Và kiểm sẵn sàng đạt; chạy saga; theo dõi UI-20-04
    Và kích hoạt; quản trị tỉnh đầu tiên của `T93` (`T93-TA`) đăng nhập
    Và kiểm KPI-12, tổ chức gieo, hạn mức, phân hệ
    Thì `T93` `ACTIVE` trong ≤ 60 phút; EVT-20-01 và EVT-20-03; quản trị tỉnh đổi mật khẩu, bật MFA; hạn mức theo mẫu; tổ chức cấp tỉnh có; KPI-12 ghi nhận ≤ 1 ngày làm việc.

  @TC-20-232 @P1 @Dương
  Kịch bản: TC-20-232 Sáp nhập T91 vào T90: lập, chạy thử, duyệt, chuyển, xử lý xung đột, định danh, cutover, hoàn tất
    # Truy vết: FR-20-045, 046, 047, 048, 049, 050, 051, 052 · UC-20-24, 25, 26, 27, 28, 29 · BR-20-023, 024, 025, 026 · NFR-20-014, 015 · EVT-20-04, 10, 11, 12
    Biết STAGING; `U-PA1`, `U-PA2`; F-MERGE, F-ORG, F-HTTT (120 HTTT của `T91`); `iam-sim`, `ops-sim`, `mod-sim`.
    Khi lập kế hoạch, sinh ánh xạ, xử lý 6 xung đột, chạy thử `PASSED`
    Và `U-PA1` gửi, `U-PA2` duyệt; bắt đầu chuyển; kiểm đếm
    Và chuyển định danh; cấp thông tin xác thực song song
    Và cutover trong cửa sổ bảo trì; gọi địa chỉ cũ của `T91`
    Và trước hết chuyển tiếp: gia hạn một lần; tới hạn kết thúc
    Thì mỗi bước đúng trạng thái; đích giữ `id` gốc và `origin_tenant_id`; kiểm đếm 100 %; sau cutover địa chỉ cũ có `Deprecation`, `Sunset`; nguồn `MERGED` rồi `DECOMMISSIONED`; EVT-20-10, 11, 12 phát đúng một lần; 120 HTTT thuộc `T90` sau kết thúc.

  @TC-20-233 @P1 @Dương @Biên
  Kịch bản: TC-20-233 Phát hành 2.4.0 theo ba sóng, sóng 2 dừng do ngưỡng, xử lý, tiếp tục, hoàn tất
    # Truy vết: FR-20-059, 060, 061, 062, 063 · UC-20-32, 33, 34 · BR-20-031, 032, 033 · NFR-20-016 · ERR-20-057 · EVT-20-14, 15
    Biết STAGING; `U-PA1`, `U-PO`; F-REL (`2.4.0` `PREVIEW` 15 ngày); ba sóng (`T90`; `T91`, `T92`; `T93`).
    Khi `:promote` `2.4.0` sang `STABLE`; lập kế hoạch ba sóng; lên lịch; thông báo
    Và sóng 1 chạy, theo dõi 48 giờ
    Và sóng 2: tỷ lệ 5xx 3 % thì dừng; tiếp tục chưa xác nhận bị chặn
    Và xác nhận xử lý rồi tiếp tục; sóng 3 chạy
    Thì sóng 2 dừng ≤ 5 phút sau khi vượt ngưỡng, sóng 3 không chạy; `ERR-20-057` khi tiếp tục chưa xác nhận; sau xử lý mọi tenant `DONE`, kế hoạch `COMPLETED`; EVT-20-14 hai lần (PREVIEW, STABLE), EVT-20-15 theo từng tenant.
