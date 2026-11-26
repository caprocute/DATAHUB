# language: vi
# Sinh tự động từ mục 7 của D05-02-PH02; không sửa tay.
@PH-02 @UAT
Tính năng: Nghiệm thu người dùng tương đương Bus tích hợp và Productivity Tooling

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và các chương trình tích hợp của tỉnh đã được chuyển từ Bus cũ

  @UAT-01
  Kịch bản: UAT-01 Xem danh sách API, lọc theo trạng thái, tìm theo tên
    # Chức năng hệ cũ: LGC-APIM-001; FR: FR-02-001, 003; TC: TS-02-01
    Khi cán bộ xem danh sách API, lọc theo trạng thái, tìm theo tên
    Thì tìm ra API trong 3 thao tác, không chậm hơn hệ cũ

  @UAT-02
  Kịch bản: UAT-02 Tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend
    # Chức năng hệ cũ: LGC-APIM-002; FR: FR-02-010, 022, 024; TC: TS-02-04, 08
    Khi cán bộ tạo API từ đầu: tên, phiên bản, mô tả, context-path, URL backend
    Thì làm được trong 10 phút với wizard, thêm đặc tả bắt buộc

  @UAT-03
  Kịch bản: UAT-03 Tạo API bằng cách nạp Swagger hoặc OpenAPI
    # Chức năng hệ cũ: LGC-APIM-003; FR: FR-02-011, 016, 017; TC: TS-02-04, 05
    Khi cán bộ tạo API bằng cách nạp Swagger hoặc OpenAPI
    Thì nạp được cả Swagger 2.0 và OpenAPI 3.1, thấy lỗi theo dòng

  @UAT-04
  Kịch bản: UAT-04 Lưu nháp rồi gửi duyệt và thử TEST
    # Chức năng hệ cũ: LGC-APIM-004; FR: FR-02-010, 034, 035; TC: TS-02-04, 11
    Khi cán bộ lưu nháp rồi gửi duyệt và thử TEST
    Thì có nút "Lưu nháp", "Lưu và gửi duyệt"; người duyệt khác người gửi

  @UAT-05
  Kịch bản: UAT-05 Tạm ngừng và tiếp tục API
    # Chức năng hệ cũ: LGC-APIM-005; FR: FR-02-037; TC: TS-02-12
    Khi cán bộ tạm ngừng và tiếp tục API
    Thì thao tác có lý do, gateway áp dụng trong 30 giây

  @UAT-06
  Kịch bản: UAT-06 Công bố API lên cổng nhà phát triển và gỡ xuống
    # Chức năng hệ cũ: LGC-APIM-006; FR: FR-02-041, 036; TC: TS-02-15, 11
    Khi cán bộ công bố API lên cổng nhà phát triển và gỡ xuống
    Thì đặt mức hiển thị, có thông báo khi gỡ

  @UAT-07
  Kịch bản: UAT-07 Xóa API không còn dùng
    # Chức năng hệ cũ: LGC-APIM-008; FR: FR-02-038, 039, 040; TC: TS-02-14
    Khi cán bộ xóa API không còn dùng
    Thì chỉ xóa được khi hết đăng ký; có ngừng dùng báo trước

  @UAT-08
  Kịch bản: UAT-08 Tạo gói, chọn Keyless hoặc API key, công bố, ngừng khuyến nghị, đóng
    # Chức năng hệ cũ: LGC-APIM-009; 010, 011; FR: FR-02-027, 028, 030, 031, 032; TC: TS-02-09, 10
    Khi cán bộ tạo gói, chọn Keyless hoặc API key, công bố, ngừng khuyến nghị, đóng
    Thì đủ bốn trạng thái, thêm OAuth2, mTLS

  @UAT-09
  Kịch bản: UAT-09 Xem đăng ký theo API và theo ứng dụng, duyệt, thu hồi
    # Chức năng hệ cũ: LGC-APIM-016; 021; FR: FR-02-046, 047, 049, 050, 051; TC: TS-02-16, 17, 18
    Khi cán bộ xem đăng ký theo API và theo ứng dụng, duyệt, thu hồi
    Thì thấy đủ trong 3 thao tác, thu hồi có hiệu lực ngay

  @UAT-10
  Kịch bản: UAT-10 Xem đường dẫn sử dụng và mẫu gọi
    # Chức năng hệ cũ: LGC-APIM-017; FR: FR-02-005, 002; TC: TS-02-01
    Khi cán bộ xem đường dẫn sử dụng và mẫu gọi
    Thì có URL gateway, mẫu `curl`

  @UAT-11
  Kịch bản: UAT-11 Quản lý nhiều endpoint backend của API
    # Chức năng hệ cũ: LGC-APIM-018; FR: FR-02-022, 023, 025; TC: TS-02-08
    Khi cán bộ quản lý nhiều endpoint backend của API
    Thì có cân bằng tải, kiểm tra sức khỏe

  @UAT-12
  Kịch bản: UAT-12 Chuyển API, gói, đăng ký từ APIM cũ sang hệ mới; xem API sinh từ luồng PH-04
    # Chức năng hệ cũ: LGC-APIM-002; 003, 009, LGC-BUS-028; FR: FR-02-061, 013; TC: TS-02-23, 07
    Khi cán bộ chuyển API, gói, đăng ký từ APIM cũ sang hệ mới; xem API sinh từ luồng PH-04
    Thì nhập có xem trước, không phải nhập lại khóa; API từ luồng hiện trong danh mục

  @UAT-13
  Kịch bản: UAT-13 Với tư cách đại diện HTTT khai thác: gửi đăng ký sử dụng, chờ duyệt, nhận phạm vi và gọi thử
    # Chức năng hệ cũ: — (mới, thay quy trình xin khóa thủ công); FR: FR-02-046, 047, 048; TC: TS-02-16, 17
    Khi cán bộ với tư cách đại diện HTTT khai thác: gửi đăng ký sử dụng, chờ duyệt, nhận phạm vi và gọi thử
    Thì đăng ký có mục đích, khối lượng; duyệt đúng cấp; sau duyệt gọi được trong 30 giây, không ai cấp tay

  @UAT-14
  Kịch bản: UAT-14 Công bố phiên bản mới có duyệt bốn mắt; ngừng khuyến nghị phiên bản cũ và thông báo bên dùng
    # Chức năng hệ cũ: — (mới); FR: FR-02-035, 038, 042, 057; TC: TS-02-11, 13, 14, 21
    Khi cán bộ công bố phiên bản mới có duyệt bốn mắt; ngừng khuyến nghị phiên bản cũ và thông báo bên dùng
    Thì người duyệt khác người gửi; bên đăng ký nhận thông báo; lộ trình ≥ 180 ngày

  @UAT-15
  Kịch bản: UAT-15 Theo dõi đồng bộ danh mục lên Nền tảng quốc gia và xử lý bản ghi bị từ chối
    # Chức năng hệ cũ: — (mới, đáp ứng CMP-LAW-03, 19); FR: FR-02-053, 054; TC: TS-02-19
    Khi cán bộ theo dõi đồng bộ danh mục lên Nền tảng quốc gia và xử lý bản ghi bị từ chối
    Thì thấy trạng thái từng API, thử lại được, cảnh báo khi quá hạn

  @UAT-16
  Kịch bản: UAT-16 Khai báo cam kết chất lượng (SLA) và xem tuân thủ theo kỳ
    # Chức năng hệ cũ: — (mới); FR: FR-02-055, 056; TC: TS-02-20
    Khi cán bộ khai báo cam kết chất lượng (SLA) và xem tuân thủ theo kỳ
    Thì SLA cam kết cạnh số liệu thực tế; kỳ thiếu dữ liệu không bị kết luận
