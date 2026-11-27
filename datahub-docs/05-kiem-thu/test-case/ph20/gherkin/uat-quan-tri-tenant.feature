# language: vi
# Sinh tự động từ mục 7 của D05-02-PH20; không sửa tay.
@PH-20 @UAT
Tính năng: Nghiệm thu người dùng Quản trị tenant và phát hành sản phẩm

  Bối cảnh:
    Biết quản trị nền tảng đã đăng nhập môi trường UAT
    Và các tenant kiểm thử T90…T99 đã được nạp theo mục 2 của tài liệu

  @UAT-01
  Kịch bản: UAT-01 Khai báo tỉnh mới `T93`, kiểm tra sẵn sàng, chạy khởi tạo và theo dõi 17 bước tới kích hoạt
    # Liên quan hệ cũ: LGC-IAM-002, LGC-BUS-031; FR: FR-20-001, 007, 008, 012, 013; TC: TS-20-02, 05, 07, 44
    Khi người dùng khai báo tỉnh mới `T93`, kiểm tra sẵn sàng, chạy khởi tạo và theo dõi 17 bước tới kích hoạt
    Thì tenant `ACTIVE` trong 60 phút, kiểm tra khói đạt, quản trị tỉnh đầu tiên đăng nhập được, hạn mức theo mẫu

  @UAT-02
  Kịch bản: UAT-02 Xử lý một bước lỗi: thử lại, bỏ qua theo luật, bù trừ và hủy khởi tạo
    # Liên quan hệ cũ: —; FR: FR-20-010, 011; TC: TS-20-06, 40
    Khi người dùng xử lý một bước lỗi: thử lại, bỏ qua theo luật, bù trừ và hủy khởi tạo
    Thì bước lỗi thử lại được; bù trừ ngược không để tài nguyên mồ côi; không bỏ qua bước bắt buộc

  @UAT-03
  Kịch bản: UAT-03 Tạm ngừng một tỉnh do sự cố, kiểm tỉnh chỉ đọc rồi khôi phục
    # Liên quan hệ cũ: —; FR: FR-20-038, 039; TC: TS-20-20, 23, 41
    Khi người dùng tạm ngừng một tỉnh do sự cố, kiểm tỉnh chỉ đọc rồi khôi phục
    Thì lượt ghi bị chặn trong 60 giây, đọc vẫn dùng được, khôi phục trở lại bình thường, có lịch sử và thư báo

  @UAT-04
  Kịch bản: UAT-04 Đặt hạn mức hợp đồng, ghi đè tạm thời, xem sử dụng và xử lý cảnh báo 80 %
    # Liên quan hệ cũ: —; FR: FR-20-026, 027, 028, 029, 032; TC: TS-20-14, 15, 16
    Khi người dùng đặt hạn mức hợp đồng, ghi đè tạm thời, xem sử dụng và xử lý cảnh báo 80 %
    Thì hạn mức hiệu lực đúng, cảnh báo một lần, đặt lại khi dưới 75 %, hạ dưới mức đang dùng cần người duyệt khác

  @UAT-05
  Kịch bản: UAT-05 Đề nghị chấm dứt, duyệt bốn mắt, xuất gói bàn giao, xác nhận và thực hiện sau thời gian nguội
    # Liên quan hệ cũ: —; FR: FR-20-040, 041, 042; TC: TS-20-21, 22
    Khi người dùng đề nghị chấm dứt, duyệt bốn mắt, xuất gói bàn giao, xác nhận và thực hiện sau thời gian nguội
    Thì chấm dứt bị chặn khi thiếu bàn giao hoặc chưa hết nguội; hai người khác nhau; xóa mật mã được xác nhận

  @UAT-06
  Kịch bản: UAT-06 Sáp nhập hai tỉnh: lập kế hoạch, chạy thử, duyệt, chuyển, xử lý xung đột, cutover, hoàn tất
    # Liên quan hệ cũ: —; FR: FR-20-045…052; TC: TS-20-24…29, 44
    Khi người dùng sáp nhập hai tỉnh: lập kế hoạch, chạy thử, duyệt, chuyển, xử lý xung đột, cutover, hoàn tất
    Thì kiểm đếm khớp 100 %, địa chỉ cũ vẫn dùng kèm `Deprecation`, nguồn `MERGED` rồi đóng hẳn

  @UAT-07
  Kịch bản: UAT-07 Quản trị tỉnh nhập danh mục tổ chức, giải thể một tổ chức có kế thừa, xử lý đề xuất sắp xếp ĐVHC
    # Liên quan hệ cũ: LGC-IAM-002; FR: FR-20-053, 054, 055, 056; TC: TS-20-30, 31
    Khi người dùng quản trị tỉnh nhập danh mục tổ chức, giải thể một tổ chức có kế thừa, xử lý đề xuất sắp xếp ĐVHC
    Thì xem trước đúng, dòng lỗi chặn xác nhận, giải thể buộc chọn kế thừa, tổ chức con chuyển cha

  @UAT-08
  Kịch bản: UAT-08 Đăng ký phiên bản, đưa lên `PREVIEW` và `STABLE`, lập kế hoạch ba sóng, theo dõi, dừng sóng và quay lui
    # Liên quan hệ cũ: —; FR: FR-20-059…064; TC: TS-20-32, 33, 34, 44
    Khi người dùng đăng ký phiên bản, đưa lên `PREVIEW` và `STABLE`, lập kế hoạch ba sóng, theo dõi, dừng sóng và quay lui
    Thì sóng tự dừng khi lỗi vượt 2 %, tiếp tục cần xác nhận, quay lui bị chặn khi có `CONTRACT`, tỉnh được báo lịch
