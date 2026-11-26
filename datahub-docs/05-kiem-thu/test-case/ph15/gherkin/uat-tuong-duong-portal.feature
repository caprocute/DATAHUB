# language: vi
# Sinh tự động từ mục 7 của D05-02-PH15; không sửa tay.
@PH-15 @UAT
Tính năng: Nghiệm thu người dùng tương đương portal Gravitee cũ

  Bối cảnh:
    Biết cán bộ quản trị portal cũ và nhà phát triển của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và nội dung portal Gravitee đã được nhập vào cổng mới

  @UAT-01
  Kịch bản: UAT-01 Thấy API mới phát hành ở PH-02 xuất hiện trên cổng
    # Chức năng hệ cũ: LGC-APIM-006; FR: FR-15-001, 002, 004; TC: TS-15-01, 02
    Khi cán bộ thấy API mới phát hành ở PH-02 xuất hiện trên cổng
    Thì hiện trong ≤ 30 giây, không ai cập nhật tay

  @UAT-02
  Kịch bản: UAT-02 Gỡ một API khỏi cổng rồi đăng lại
    # Chức năng hệ cũ: LGC-APIM-006; FR: FR-15-001, 002; TC: TS-15-02, 04
    Khi cán bộ gỡ một API khỏi cổng rồi đăng lại
    Thì cờ ở PH-02 đổi thì cổng đổi theo trong ≤ 30 giây, kể cả tìm kiếm

  @UAT-03
  Kịch bản: UAT-03 Công khai một API cho mọi người
    # Chức năng hệ cũ: LGC-APIM-007; FR: FR-15-002, 008, 056, 057; TC: TS-15-02, 27
    Khi cán bộ công khai một API cho mọi người
    Thì bật công khai theo tenant, API vừa PUBLIC vừa dữ liệu công khai mới hiện cho khách, thêm mức NATIONAL

  @UAT-04
  Kịch bản: UAT-04 Xem đường dẫn sử dụng của một API
    # Chức năng hệ cũ: LGC-APIM-017; FR: FR-15-006, 012; TC: TS-15-05, 06
    Khi cán bộ xem đường dẫn sử dụng của một API
    Thì gateway URL, context path, mẫu gọi ở một màn, đúng tenant

  @UAT-05
  Kịch bản: UAT-05 Xem tài liệu API và tải đặc tả
    # Chức năng hệ cũ: LGC-APIM-017; FR: FR-15-009, 011, 013; TC: TS-15-06
    Khi cán bộ xem tài liệu API và tải đặc tả
    Thì tài liệu đọc được, chọn phiên bản, tải YAML, JSON, so sánh phiên bản

  @UAT-06
  Kịch bản: UAT-06 Lấy token và gọi thử API
    # Chức năng hệ cũ: LGC-IAM-006; FR: FR-15-012, 027, 035; TC: TS-15-14, 18, 37
    Khi cán bộ lấy token và gọi thử API
    Thì làm trong ≤ 15 phút bằng `client_credentials`, không dùng grant `password`

  @UAT-07
  Kịch bản: UAT-07 Tạo ứng dụng và cấp credential tự phục vụ
    # Chức năng hệ cũ: LGC-IAM-006, LGC-APIM-019, LGC-APIM-020; FR: FR-15-025, 027, 029; TC: TS-15-13, 14
    Khi cán bộ tạo ứng dụng và cấp credential tự phục vụ
    Thì ứng dụng sandbox và credential trong ≤ 3 giây, bí mật hiện một lần, giới hạn số lượng rõ ràng

  @UAT-08
  Kịch bản: UAT-08 Xem nhật ký lời gọi của ứng dụng mình
    # Chức năng hệ cũ: LGC-APIM-022; FR: FR-15-049, 050; TC: TS-15-24
    Khi cán bộ xem nhật ký lời gọi của ứng dụng mình
    Thì thấy trong 3 thao tác, dữ liệu nhạy cảm đã che, chỉ ứng dụng của mình

  @UAT-09
  Kịch bản: UAT-09 Chuyển trang hướng dẫn của portal cũ sang cổng mới
    # Chức năng hệ cũ: LGC-APIM-006; FR: FR-15-062, 015; TC: TS-15-09, 08
    Khi cán bộ chuyển trang hướng dẫn của portal cũ sang cổng mới
    Thì nhập từ gói xuất, trang vào dạng nháp, duyệt bốn mắt rồi đăng

  @UAT-10
  Kịch bản: UAT-10 Gửi đăng ký sử dụng API production từ cổng
    # Chức năng hệ cũ: LGC-APIM-019, LGC-APIM-020; FR: FR-15-044, 045; TC: TS-15-23
    Khi cán bộ gửi đăng ký sử dụng API production từ cổng
    Thì gửi và theo dõi ở một nơi, không phải gửi yêu cầu tay cho quản trị
