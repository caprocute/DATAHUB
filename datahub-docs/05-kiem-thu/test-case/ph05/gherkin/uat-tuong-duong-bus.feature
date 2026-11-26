# language: vi
# Sinh tự động từ mục 7 của D05-02-PH05; không sửa tay.
@PH-05 @UAT
Tính năng: Nghiệm thu người dùng tương đương Bus tích hợp và Productivity Tooling

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và các chương trình tích hợp của tỉnh đã được chuyển từ Bus cũ

  @UAT-01
  Kịch bản: UAT-01 Đổi địa chỉ, cổng của HTTT đích cho môi trường thử
    # Chức năng hệ cũ: LGC-BUS-011; FR: FR-05-005, 007; TC: TS-05-02, 04
    Khi cán bộ đổi địa chỉ, cổng của HTTT đích cho môi trường thử
    Thì đổi được trong 2 phút, có kiểm tra trước khi bật, không phải sửa luồng

  @UAT-02
  Kịch bản: UAT-02 Thêm kết nối mới và kiểm tra trước khi dùng
    # Chức năng hệ cũ: LGC-BUS-013; FR: FR-05-004, 010; TC: TS-05-01, 03
    Khi cán bộ thêm kết nối mới và kiểm tra trước khi dùng
    Thì biết ngay hỏng ở bước nào và cách khắc phục

  @UAT-03
  Kịch bản: UAT-03 Khai báo kết nối HTTP, SOAP, CSDL, SFTP, hàng đợi
    # Chức năng hệ cũ: LGC-BUS-040; FR: FR-05-001, 004, 031; TC: TS-05-01, 14
    Khi cán bộ khai báo kết nối HTTP, SOAP, CSDL, SFTP, hàng đợi
    Thì đủ loại như Bus cũ, cùng một mẫu thao tác

  @UAT-04
  Kịch bản: UAT-04 Cấu hình xác thực Basic, SSL, WS-Security
    # Chức năng hệ cũ: LGC-BUS-041, LGC-TOOL-012; FR: FR-05-005, 034; TC: TS-05-02, 16
    Khi cán bộ cấu hình xác thực Basic, SSL, WS-Security
    Thì làm được như Bus cũ, thêm OAuth2, mTLS

  @UAT-05
  Kịch bản: UAT-05 Kết nối CSDL cho luồng
    # Chức năng hệ cũ: LGC-TOOL-008; FR: FR-05-023, 024; TC: TS-05-11
    Khi cán bộ kết nối CSDL cho luồng
    Thì có tài khoản chỉ đọc theo luồng trong 5 phút, không phải xin mật khẩu CSDL

  @UAT-06
  Kịch bản: UAT-06 Dùng khối HTTP, tệp, hàng đợi trong trình thiết kế
    # Chức năng hệ cũ: LGC-TOOL-009, 010; FR: FR-05-054, 047; TC: TS-05-24, 27
    Khi cán bộ dùng khối HTTP, tệp, hàng đợi trong trình thiết kế
    Thì có khối Kamelet tương ứng, tham số tiếng Việt

  @UAT-07
  Kịch bản: UAT-07 Đặt lịch quét tệp
    # Chức năng hệ cũ: LGC-TOOL-011; FR: FR-05-036; TC: TS-05-18
    Khi cán bộ đặt lịch quét tệp
    Thì đặt được lịch, thấy 5 lần chạy kế

  @UAT-08
  Kịch bản: UAT-08 Đưa thành phần tự viết vào dùng
    # Chức năng hệ cũ: LGC-TOOL-027; FR: FR-05-056, 057; TC: TS-05-27
    Khi cán bộ đưa thành phần tự viết vào dùng
    Thì thay bằng đăng ký Kamelet có kiểm tra, được duyệt trong ngày

  @UAT-09
  Kịch bản: UAT-09 Tìm kết nối đang hỏng và nơi dùng nó
    # Chức năng hệ cũ: LGC-BUS-011, 013; FR: FR-05-002, 013, 022; TC: TS-05-07, 10
    Khi cán bộ tìm kết nối đang hỏng và nơi dùng nó
    Thì thấy trong 3 thao tác từ menu

  @UAT-10
  Kịch bản: UAT-10 Chuyển kết nối của một chương trình Bus cũ sang hệ mới
    # Chức năng hệ cũ: LGC-BUS-040; FR: FR-05-018; TC: TS-05-09
    Khi cán bộ chuyển kết nối của một chương trình Bus cũ sang hệ mới
    Thì có đề xuất kết nối từ tệp cũ; chỉ phải khai lại bí mật
