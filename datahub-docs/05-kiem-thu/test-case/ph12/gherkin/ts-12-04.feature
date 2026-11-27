# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-04
Tính năng: TS-12-04 · Đặt lại mật khẩu, tác vụ định kỳ và đồng bộ đơn vị

  @TC-12-018 @P1 @Bảo @mật @Âm
  Kịch bản: TC-12-018 Quên mật khẩu không phân biệt tài khoản có hay không
    # Truy vết: FR-12-007 · UC-12-06 · UI-12-18 · BR-12-017 · SEC-22 · LGC-IAM-002
    Biết `tc-an` có thật; `khong-co` không có; SIM-SMTP.
    Khi gửi yêu cầu quên mật khẩu cho cả hai, đo thời gian phản hồi 50 lần.
    Thì thông báo giống hệt; chênh lệch thời gian trung vị < 50 ms; chỉ `tc-an` nhận thư; liên kết hết hạn thì ERR-12-016.

  @TC-12-019 @P1 @Dương
  Kịch bản: TC-12-019 Đặt lại mật khẩu thu phiên và áp chính sách lịch sử
    # Truy vết: FR-12-007 · UI-12-18 · BR-12-018, BR-12-022 · ERR-12-015
    Biết `tc-an` có hai phiên.
    Khi đặt lại bằng mật khẩu mới đạt chuẩn qua liên kết.
    Thì mọi phiên cũ bị thu; đăng nhập bằng mật khẩu cũ thất bại; KT: có (user.password-reset); không ghi mật khẩu vào log.

  @TC-12-020 @P1 @Dương @Âm @Biên
  Kịch bản: TC-12-020 Tự vô hiệu tài khoản không đăng nhập 45 ngày
    # Truy vết: FR-12-008 · UC-12-07 · UI-12-15 · BR-12-020 · BR-12-035 · CMP-LAW-08
    Biết U-T68-OLD (44 ngày), một VW khác 46 ngày, một PA 31 ngày.
    Khi chạy tác vụ ở ngày 45; chạy lại ở ngày 46.
    Thì VW 46 ngày và PA 31 ngày (ngưỡng quản trị 30) thành `DISABLED` không quá 24 giờ sau ngưỡng; U-T68-OLD còn `ACTIVE` ở ngày 44; báo cáo lượt chạy ở UI-12-15; chạy lại không đổi thêm.

  @TC-12-130 @P1 @Dương @Biên @Bảo
  Kịch bản: TC-12-130 Tự vô hiệu TA không dùng quá ngưỡng khi tenant còn hai TA
    # Truy vết: FR-12-008 · UC-12-07 · UI-12-15 · BR-12-020 · BR-12-033 · ERR-12-046 · CMP-LAW-08
    Biết T68 có đúng hai TA hiệu lực; TA2 có đăng nhập cuối cách đây 31 ngày (ngưỡng quản trị 30), TA1 vừa đăng nhập.
    Khi chạy tác vụ tự vô hiệu; kiểm trạng thái TA2 và thư cảnh báo bảy ngày trước ngưỡng.
    Và kiểm cảnh báo khẩn và việc bổ sung TA sau lượt chạy.
    Và cập nhật bằng SQL trực tiếp TA1 sang `DISABLED` với lý do `MANUAL` (kiểm DB).
    Thì bước 1 TA2 thành `DISABLED` (lý do `INACTIVE_30D_ADMIN`) không bị ERR-12-046 chặn dù tenant xuống còn một TA; hệ thống đã gửi trước đó cảnh báo bảy ngày tới SO và PA nêu việc vô hiệu làm tenant dưới hai TA; bước 2 SO và PA nhận cảnh báo khẩn, PA có việc "Bổ sung quản trị tỉnh", kiểm toán ghi mã lý do `TA_BELOW_MIN`, chỉ số `iam_inactive_disabled_total` tăng; bước 3 CSDL từ chối `P1246` (vô hiệu thủ công không có ngoại lệ).

  @TC-12-021 @P2 @Biên
  Kịch bản: TC-12-021 Tạm ngừng client không gọi 90 ngày
    # Truy vết: FR-12-008 · BR-12-020 · UC-12-07 · API-12-060
    Biết C-T68-B; đồng hồ nhảy 91 ngày không lượt gọi.
    Khi chạy tác vụ.
    Thì C-T68-B `SUSPENDED`, token đang có bị từ chối ≤ 60 giây; thông báo tới đầu mối HTTT; KT: có.

  @TC-12-022 @P2 @Dương @Âm
  Kịch bản: TC-12-022 Đồng bộ thuộc tính người dùng từ danh mục đơn vị
    # Truy vết: FR-12-010 · UC-12-07 · UI-12-07 · ADR-055
    Biết SIM-PH07; U-T68-PH07 ở `DV-A`.
    Khi đổi tên `DV-A` và đóng `DV-B` ở SIM-PH07; chạy tác vụ đồng bộ.
    Và cho SIM-PH07 lỗi `503`; chạy lại.
    Thì tên đơn vị cập nhật, người dùng ở đơn vị đóng được đánh dấu cần chuyển đơn vị; bước 2 giữ nguyên dữ liệu cũ, ghi cảnh báo, không xóa gì.
