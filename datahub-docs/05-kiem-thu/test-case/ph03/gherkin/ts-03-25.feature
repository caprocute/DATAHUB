# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-25
Tính năng: TS-03-25 · Giao diện quản trị cổng API (E2E)

  @TC-03-099 @P1 @Dương @Truy @cập
  Kịch bản: TC-03-099 Tổng quan, danh sách và chi tiết route (UI-03-01, 02, 03)
    # Truy vết: UI-03-01, 02, 03 · FR-03-055, 028, 036 · API-03-077, 001, 002, 003 · UC-03-27, 09.
    Biết U-T68-TO; 1.000 route; U-T68-VW.
    Khi mở UI-03-01; đổi khoảng thời gian.
    Và mở UI-03-02 với `?trang=2&co=20&sap-xep=ten:tang&q=ho-tich`.
    Và mở UI-03-03 của `r-ho-tich`; bấm "Dừng"; xác nhận; bấm "Mở".
    Và đăng nhập U-T68-VW mở lại UI-03-03.
    Thì bước 1 biểu đồ lưu lượng, lỗi, độ trễ, thẻ cảnh báo; trạng thái đang tải, rỗng, lỗi đủ. Bước 2 danh sách đúng 20 dòng, URL phản ánh bộ lọc. Bước 3 thao tác thành công, banner trạng thái đổi. Bước 4 nút "Dừng", "Mở" bị ẩn hoặc vô hiệu kèm lý do.

  @TC-03-100 @P2 @Dương
  Kịch bản: TC-03-100 Consumer, hạn mức và hạn ngạch (UI-03-04, 05, 06)
    # Truy vết: UI-03-04, 05, 06 · FR-03-046, 047, 022, 023, 024 · API-03-011, 012, 017, 018, 029, 024, 026 · UC-03-23, 25.
    Biết U-T68-SO1; U-T68-TA; `ht-mini` ở 85 % hạn ngạch.
    Khi mở UI-03-04 lọc theo nhóm `ESSENTIAL`.
    Và mở UI-03-05 của `ht-ndxp`; bấm "Tạm ngừng khẩn cấp" rồi "Mở lại".
    Và mở UI-03-06; sửa hạn mức toàn tenant; thêm ghi đè theo route.
    Thì bước 2 hộp xác nhận có ô lý do bắt buộc; thông báo thành công và trạng thái đổi. Bước 3 thanh mức dùng đổi màu theo ngưỡng 80 % và 100 % (kèm chữ, không chỉ màu); hạ hạn mức toàn tenant hiện "Đã gửi yêu cầu, chờ người duyệt".

  @TC-03-101 @P1 @Dương
  Kịch bản: TC-03-101 Nhật ký WAF, ngoại lệ, duyệt thay đổi (UI-03-07, 08, 17)
    # Truy vết: UI-03-07, 08, 17 · FR-03-005, 006, 007, 008 · API-03-039, 041, 042, 043, 044, 071, 072 · UC-03-13, 14, 15.
    Biết U-T68-TO; U-T68-SO1; U-T68-SO2.
    Khi TO mở UI-03-07, chọn một sự kiện bị chặn nhầm, bấm "Đề nghị ngoại lệ".
    Và SO1 mở UI-03-17 duyệt.
    Và SO1 đề nghị đổi chế độ WAF; SO1 thử duyệt chính mình.
    Và SO2 duyệt.
    Thì bước 1 mở biểu mẫu điền sẵn route, mã luật; ngoại lệ ở UI-03-08 trạng thái "Chờ duyệt" rồi "Hiệu lực". Bước 3 nút "Duyệt" vô hiệu kèm "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." Bước 4 chế độ đổi sau duyệt.

  @TC-03-102 @P2 @Dương @Truy @cập
  Kịch bản: TC-03-102 Nhật ký lượt gọi và nút gateway (UI-03-09, 11)
    # Truy vết: UI-03-09, 11 · FR-03-051, 045 · API-03-074, 075, 076, 063, 064 · UC-03-26, 22.
    Biết U-T68-AU; U-T68-TO.
    Khi AU mở UI-03-09, lọc theo `traceId`; mở chi tiết; bấm "Xuất".
    Và TO mở UI-03-11; mở một nút.
    Thì bước 1 danh sách, chi tiết, tiến trình xuất; không hiển thị thân hay giá trị tiêu đề. Bước 2 bảng nút có phiên bản, trạng thái đồng bộ, màu kèm nhãn chữ.

  @TC-03-103 @P2 @Dương
  Kịch bản: TC-03-103 Ảnh chụp, chứng thư, mẫu chính sách, chạy thử (UI-03-10, 12, 13, 14)
    # Truy vết: UI-03-10, 12, 13, 14 · FR-03-039…044, 049, 048, 057 · API-03-056, 059, 060, 061, 062, 068, 070, 065, 067, 088 · UC-03-19, 21, 24, 17.
    Biết U-T68-TA; U-T68-TO; U-PA.
    Khi TA mở UI-03-10: "Tổng hợp và ký", xem diff, "Phát".
    Và TO quay lui về bản trước.
    Và PA mở UI-03-12 gia hạn chứng thư; TA mở UI-03-13 bật mẫu; mở UI-03-14 chạy thử.
    Thì bước 1 lỗi kiểm tra hiển thị theo `findings[]` với từng đối tượng bấm nhảy tới được. Bước 2 ảnh chụp mới xuất hiện ở danh sách. Bước 3 kết quả mô phỏng hiện từng chốt. Mọi bảng có chú thích và điều hướng bàn phím.

  @TC-03-104 @P2 @Dương
  Kịch bản: TC-03-104 Địa chỉ bị chặn, tham số, chuyển tiếp tenant, nhập hệ cũ (UI-03-15, 16, 18)
    # Truy vết: UI-03-15, 16, 18 · FR-03-003, 004, 056, 037, 059 · API-03-036, 037, 038, 086, 087, 095, 091, 092, 093 · UC-03-12, 29, 30, 31.
    Biết U-T68-SO1; U-T68-TA; U-PA; `F-LEGACY-OK`.
    Khi SO1 mở UI-03-15, chặn một địa chỉ, bỏ chặn.
    Và TA mở UI-03-16 sửa tham số; PA tạo chuyển tiếp tenant.
    Và TA chạy trình hướng dẫn UI-03-18 với `F-LEGACY-OK`.
    Thì bước 1 danh sách cập nhật, hộp xác nhận. Bước 2 giá trị ngoài miền báo lỗi theo trường. Bước 3 wizard qua các bước tải lên, xem trước, áp dụng; kết thúc ở màn đối tượng nháp.
