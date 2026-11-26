# language: vi
# Sinh tự động từ mục 7 của D05-02-PH01; không sửa tay.
@PH-01 @UAT
Tính năng: Nghiệm thu người dùng tương đương Application của APIM và publisher, subscriber của Hub

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và HTTT của tỉnh đã được nhập từ hệ cũ

  @UAT-01
  Kịch bản: UAT-01 Xem danh sách HTTT, lọc theo trạng thái, nhóm, tổ chức
    # Chức năng hệ cũ: LGC-APIM-019; FR: FR-01-001, 050; TC: TS-01-01
    Khi cán bộ xem danh sách HTTT, lọc theo trạng thái, nhóm, tổ chức
    Thì thấy đủ Application cũ dưới dạng HTTT, tìm một HTTT trong 3 thao tác

  @UAT-02
  Kịch bản: UAT-02 Xem chi tiết một HTTT, định danh, người liên hệ
    # Chức năng hệ cũ: LGC-APIM-019; FR: FR-01-002, 028; TC: TS-01-01, 19
    Khi cán bộ xem chi tiết một HTTT, định danh, người liên hệ
    Thì thấy định danh và hạn dùng, không thấy bí mật; đầu mối kỹ thuật rõ

  @UAT-03
  Kịch bản: UAT-03 Tạo hồ sơ cho một ứng dụng mới thay "Tạo Application"
    # Chức năng hệ cũ: LGC-APIM-020; FR: FR-01-003, 004, 011, 012; TC: TS-01-02, 06
    Khi cán bộ tạo hồ sơ cho một ứng dụng mới thay "Tạo Application"
    Thì hoàn thành hồ sơ trong 30 phút, biết thiếu gì trước khi nộp

  @UAT-04
  Kịch bản: UAT-04 Khai một HTTT là bên phát dữ liệu (publisher)
    # Chức năng hệ cũ: LGC-HUB-010; FR: FR-01-003, 037, 038; TC: TS-01-02, 24
    Khi cán bộ khai một HTTT là bên phát dữ liệu (publisher)
    Thì có vai trò `PUBLISHER` và nhu cầu cung cấp; PH-10 chỉ nhận khi HTTT hoạt động

  @UAT-05
  Kịch bản: UAT-05 Khai một HTTT là bên nhận (subscriber)
    # Chức năng hệ cũ: LGC-HUB-011; FR: FR-01-003, 037, 038; TC: TS-01-02, 24
    Khi cán bộ khai một HTTT là bên nhận (subscriber)
    Thì có vai trò `SUBSCRIBER`; luồng nhận khai ở PH-04, PH-10

  @UAT-06
  Kịch bản: UAT-06 Nhận Client ID và bí mật cho ứng dụng
    # Chức năng hệ cũ: LGC-APIM-020; FR: FR-01-020, 021, 022; TC: TS-01-13, 14, 15
    Khi cán bộ nhận Client ID và bí mật cho ứng dụng
    Thì nhận qua liên kết một lần trong vài phút, không phải chờ công văn

  @UAT-07
  Kịch bản: UAT-07 Kiểm thử ở môi trường thử rồi chuyển sang môi trường thật
    # Chức năng hệ cũ: LGC-APIM-020; FR: FR-01-023, 024; TC: TS-01-16, 17
    Khi cán bộ kiểm thử ở môi trường thử rồi chuyển sang môi trường thật
    Thì thấy kết quả kiểm thử từng lượt; TA kích hoạt trong ngày

  @UAT-08
  Kịch bản: UAT-08 Chặn ngay một ứng dụng đang gây sự cố
    # Chức năng hệ cũ: LGC-APIM-019; FR: FR-01-029, 032, 033; TC: TS-01-20, 22
    Khi cán bộ chặn ngay một ứng dụng đang gây sự cố
    Thì HTTT bị chặn ở cổng trong 60 giây, có lý do và thời điểm

  @UAT-09
  Kịch bản: UAT-09 Nhập các Application, publisher, subscriber của hệ cũ
    # Chức năng hệ cũ: LGC-APIM-019; LGC-APIM-020; LGC-HUB-010, LGC-HUB-011; FR: FR-01-048; TC: TS-01-28
    Khi cán bộ nhập các Application, publisher, subscriber của hệ cũ
    Thì có đề xuất hồ sơ nháp từ tệp cũ; chỉ phải cấp lại định danh

  @UAT-10
  Kịch bản: UAT-10 Rà soát quyền định kỳ và xử lý phản hồi của đơn vị
    # Chức năng hệ cũ: LGC-APIM-019; FR: FR-01-039, 040, 041, 042; TC: TS-01-25, 26
    Khi cán bộ rà soát quyền định kỳ và xử lý phản hồi của đơn vị
    Thì mở kỳ, thấy mức dùng thật, quyết định thu hẹp có lý do; hệ cũ không có việc này

  @UAT-11
  Kịch bản: UAT-11 Tra danh bạ đầu mối của một tổ chức
    # Chức năng hệ cũ: LGC-HUB-010, LGC-HUB-011; FR: FR-01-045; TC: TS-01-27
    Khi cán bộ tra danh bạ đầu mối của một tổ chức
    Thì tìm được đầu mối kỹ thuật trong 3 thao tác, không thấy đầu mối an ninh
