# language: vi
# Sinh tự động từ mục 7 của D05-02-PH19; không sửa tay.
@PH-19 @UAT
Tính năng: Nghiệm thu người dùng tương đương phân hệ thanh toán trung gian cũ

  Bối cảnh:
    Biết cán bộ vận hành, kế toán của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và danh mục, giao dịch của hệ cũ đã được nhập theo TS-19-29

  @UAT-01
  Kịch bản: UAT-01 Thêm nhà cung cấp thanh toán, nhập thông tin kết nối, kiểm tra kết nối
    # Chức năng hệ cũ: LGC-PAY-001, 004, 007; FR: FR-19-001, 002, 003, 004, 005; TC: TS-19-01, 02, 03
    Khi cán bộ thêm nhà cung cấp thanh toán, nhập thông tin kết nối, kiểm tra kết nối
    Thì làm được như hệ cũ, thêm bước kiểm tra kết nối, không phải nhập bí mật vào màn hình

  @UAT-02
  Kịch bản: UAT-02 Đưa nhà cung cấp vào hoạt động qua phê duyệt
    # Chức năng hệ cũ: LGC-PAY-005, 008; FR: FR-19-006, 010; TC: TS-19-04
    Khi cán bộ đưa nhà cung cấp vào hoạt động qua phê duyệt
    Thì người thứ hai duyệt; checklist cho biết còn thiếu gì

  @UAT-03
  Kịch bản: UAT-03 Tạm ngừng, cho hoạt động lại nhà cung cấp; xem tình trạng kênh
    # Chức năng hệ cũ: LGC-PAY-002, 003, 006, 009; FR: FR-19-007, 008, 011; TC: TS-19-05, 06
    Khi cán bộ tạm ngừng, cho hoạt động lại nhà cung cấp; xem tình trạng kênh
    Thì đổi trạng thái có lý do; tình trạng kết nối hiện trong 1 phút

  @UAT-04
  Kịch bản: UAT-04 Khai nhóm dịch vụ và dịch vụ thu, gắn mã thủ tục
    # Chức năng hệ cũ: LGC-PAY-022; FR: FR-19-013, 014, 015; TC: TS-19-07, 08
    Khi cán bộ khai nhóm dịch vụ và dịch vụ thu, gắn mã thủ tục
    Thì làm được như hệ cũ; mã thủ tục, cơ quan thu chọn từ danh mục dùng chung

  @UAT-05
  Kịch bản: UAT-05 Đăng ký hệ thống đối tác, gán dịch vụ, đặt hạn mức
    # Chức năng hệ cũ: LGC-PAY-022; FR: FR-19-017, 018, 020; TC: TS-19-09, 10
    Khi cán bộ đăng ký hệ thống đối tác, gán dịch vụ, đặt hạn mức
    Thì đối tác nhận thông tin client và hướng dẫn tích hợp

  @UAT-06
  Kịch bản: UAT-06 Người nộp thanh toán một lệ phí trên điện thoại và quay về
    # Chức năng hệ cũ: LGC-PAY-012, 024; FR: FR-19-022, 025; TC: TS-19-11, 12
    Khi cán bộ người nộp thanh toán một lệ phí trên điện thoại và quay về
    Thì hoàn tất dưới 3 phút; trang kết quả rõ ràng, không lộ thông tin cá nhân

  @UAT-07
  Kịch bản: UAT-07 Tra cứu giao dịch theo mã, theo người nộp, theo khoảng thời gian
    # Chức năng hệ cũ: LGC-PAY-014, 015, 016, 017, 018; FR: FR-19-049, 050; TC: TS-19-22
    Khi cán bộ tra cứu giao dịch theo mã, theo người nộp, theo khoảng thời gian
    Thì tìm thấy trong 3 thao tác, có đủ chín cột như hệ cũ

  @UAT-08
  Kịch bản: UAT-08 Xem chi tiết giao dịch và lịch sử trao đổi với ngân hàng
    # Chức năng hệ cũ: LGC-PAY-010, 011, 019, 021; FR: FR-19-028, 051, 054; TC: TS-19-13, 23, 24
    Khi cán bộ xem chi tiết giao dịch và lịch sử trao đổi với ngân hàng
    Thì đủ thông tin như hệ cũ, thêm dòng thời gian và mở vết

  @UAT-09
  Kịch bản: UAT-09 Xử lý một giao dịch treo: đồng bộ, xem IPN cách ly
    # Chức năng hệ cũ: LGC-PAY-010; FR: FR-19-032, 036, 037; TC: TS-19-16
    Khi cán bộ xử lý một giao dịch treo: đồng bộ, xem IPN cách ly
    Thì biết vì sao giao dịch treo và xử lý được không cần đội kỹ thuật

  @UAT-10
  Kịch bản: UAT-10 Đối soát một ngày, xử lý chênh lệch, chốt phiên, in biên bản
    # Chức năng hệ cũ: LGC-PAY-019; FR: FR-19-042…048; TC: TS-19-19, 20, 21
    Khi cán bộ đối soát một ngày, xử lý chênh lệch, chốt phiên, in biên bản
    Thì hệ cũ không có; kế toán chốt được trong một buổi với 1% chênh lệch

  @UAT-11
  Kịch bản: UAT-11 Lập, duyệt, ghi nhận một yêu cầu hoàn tiền
    # Chức năng hệ cũ: LGC-PAY-025; FR: FR-19-038, 039, 040, 041; TC: TS-19-17, 18
    Khi cán bộ lập, duyệt, ghi nhận một yêu cầu hoàn tiền
    Thì hệ cũ chỉ có trạng thái; nay đi hết quy trình với ba người

  @UAT-12
  Kịch bản: UAT-12 Xem hai dashboard và báo cáo tháng
    # Chức năng hệ cũ: LGC-PAY-013, 020, 023, 026; FR: FR-19-056, 057, 058; TC: TS-19-25, 26
    Khi cán bộ xem hai dashboard và báo cáo tháng
    Thì đủ chỉ tiêu như hệ cũ; số liệu mới trong 1 phút thay vì 10 phút
