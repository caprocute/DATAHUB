# language: vi
# Sinh tự động từ mục 7 của D05-02-PH13; không sửa tay.
@PH-13 @UAT
Tính năng: Nghiệm thu người dùng tương đương Bus tích hợp và Productivity Tooling

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và các chương trình tích hợp của tỉnh đã được chuyển từ Bus cũ

  @UAT-01
  Kịch bản: UAT-01 Xem tổng quan hệ thống: bao nhiêu agent (đơn vị triển khai) hoạt động trên tổng số
    # Chức năng hệ cũ: LGC-BUS-014, LGC-APIM-026; FR: FR-13-031, 032; TC: TS-13-18, 19
    Khi cán bộ xem tổng quan hệ thống: bao nhiêu agent (đơn vị triển khai) hoạt động trên tổng số
    Thì thấy ngay ở trang đầu, thêm trạng thái từng thành phần

  @UAT-02
  Kịch bản: UAT-02 Xem histogram bản tin thành công và thất bại theo thời gian
    # Chức năng hệ cũ: LGC-BUS-007; FR: FR-13-033; TC: TS-13-19
    Khi cán bộ xem histogram bản tin thành công và thất bại theo thời gian
    Thì thấy theo giây đến theo ngày, chọn khoảng bất kỳ

  @UAT-03
  Kịch bản: UAT-03 Xem CPU, bộ nhớ từng đơn vị triển khai và chi tiết route
    # Chức năng hệ cũ: LGC-BUS-015, 016, 017, 019; FR: FR-13-032, 033; TC: TS-13-19
    Khi cán bộ xem CPU, bộ nhớ từng đơn vị triển khai và chi tiết route
    Thì đủ số liệu của Bus cũ, bấm từ luồng xuống route

  @UAT-04
  Kịch bản: UAT-04 Xem thống kê theo endpoint và API gọi nhiều nhất
    # Chức năng hệ cũ: LGC-BUS-027; FR: FR-13-034; TC: TS-13-19
    Khi cán bộ xem thống kê theo endpoint và API gọi nhiều nhất
    Thì thấy lưu lượng, bản tin gần nhất, lỗi

  @UAT-05
  Kịch bản: UAT-05 Tìm log của một luồng trong giờ qua và đọc ngữ cảnh
    # Chức năng hệ cũ: LGC-BUS-029, 038, LGC-NFR-004; FR: FR-13-026, 027, 028; TC: TS-13-15, 16
    Khi cán bộ tìm log của một luồng trong giờ qua và đọc ngữ cảnh
    Thì tìm được trong 3 thao tác, bấm `trace_id` sang trace

  @UAT-06
  Kịch bản: UAT-06 Xem biểu đồ CPU, bộ nhớ của Hub và cụm Kafka
    # Chức năng hệ cũ: LGC-HUB-005, 006; FR: FR-13-038; TC: TS-13-21
    Khi cán bộ xem biểu đồ CPU, bộ nhớ của Hub và cụm Kafka
    Thì thấy cùng màn hạ tầng, có cảnh báo ngưỡng

  @UAT-07
  Kịch bản: UAT-07 Xem danh sách gateway, chi tiết và tài nguyên
    # Chức năng hệ cũ: LGC-APIM-023; 024, 025; FR: FR-13-036, 037; TC: TS-13-21
    Khi cán bộ xem danh sách gateway, chi tiết và tài nguyên
    Thì đủ nút, CPU, heap, kết nối như APIM cũ

  @UAT-08
  Kịch bản: UAT-08 Tra mọi request vào một API của ứng dụng và xem chi tiết
    # Chức năng hệ cũ: LGC-APIM-022; LGC-PAY-021; FR: FR-13-030; TC: TS-13-17
    Khi cán bộ tra mọi request vào một API của ứng dụng và xem chi tiết
    Thì lọc theo HTTT, API, mã lỗi trong 3 giây; không lộ nội dung

  @UAT-09
  Kịch bản: UAT-09 Tra "ai đã làm gì" một đối tượng trong một tuần
    # Chức năng hệ cũ: LGC-APIM-027; FR: FR-13-020, 021, 022; TC: TS-13-11, 12
    Khi cán bộ tra "ai đã làm gì" một đối tượng trong một tuần
    Thì có lý do, thấy trước sau, xác minh băm

  @UAT-10
  Kịch bản: UAT-10 Nhận thông báo khi mất kết nối nhà cung cấp thanh toán
    # Chức năng hệ cũ: LGC-PAY-009; FR: FR-13-043, 046; TC: TS-13-24, 25
    Khi cán bộ nhận thông báo khi mất kết nối nhà cung cấp thanh toán
    Thì cảnh báo có runbook, gửi đúng người trực ≤ 60 giây

  @UAT-11
  Kịch bản: UAT-11 Lấy log của một tháng đã lưu để kiểm tra lại
    # Chức năng hệ cũ: LGC-NFR-005; FR: FR-13-018; TC: TS-13-10
    Khi cán bộ lấy log của một tháng đã lưu để kiểm tra lại
    Thì truy vết lại được; log cũ trên WORM; không phải sao lưu thủ công

  @UAT-12
  Kịch bản: UAT-12 Xuất bằng chứng ký số cho thanh tra
    # Chức năng hệ cũ: LGC-APIM-027; FR: FR-13-024; TC: TS-13-13
    Khi cán bộ xuất bằng chứng ký số cho thanh tra
    Thì gói tự xác minh ngoại tuyến, kiểm toán viên tự làm được
