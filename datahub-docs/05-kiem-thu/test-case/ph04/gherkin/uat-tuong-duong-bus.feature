# language: vi
# Sinh tự động từ mục 7 của D05-02-PH04; không sửa tay.
@PH-04 @UAT
Tính năng: Nghiệm thu người dùng tương đương Bus tích hợp và Productivity Tooling

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và các chương trình tích hợp của tỉnh đã được chuyển từ Bus cũ

  @UAT-01
  Kịch bản: UAT-01 Tìm chương trình tích hợp theo tên, endpoint, hệ nguồn
    # Chức năng hệ cũ: LGC-BUS-001…005; FR: FR-04-001; TC: Danh sách, tìm theo endpoint (TS-04-02)
    Khi cán bộ tìm chương trình tích hợp theo tên, endpoint, hệ nguồn
    Thì tìm thấy trong 3 thao tác, có trạng thái từng môi trường

  @UAT-02
  Kịch bản: UAT-02 Xem chi tiết chương trình, route, endpoint
    # Chức năng hệ cũ: LGC-BUS-006, 008, 017, 018; FR: FR-04-002, 052; TC: TS-04-02, 19
    Khi cán bộ xem chi tiết chương trình, route, endpoint
    Thì đủ thông tin như Bus cũ, thêm sơ đồ và phiên bản

  @UAT-03
  Kịch bản: UAT-03 Tạo luồng mới từ khuôn REST và chạy thử
    # Chức năng hệ cũ: LGC-BUS-013, LGC-TOOL-001; FR: FR-04-003, 030; TC: TS-04-03, 12
    Khi cán bộ tạo luồng mới từ khuôn REST và chạy thử
    Thì luồng chạy thử đạt trong 30 phút với người đã dùng Tooling

  @UAT-04
  Kịch bản: UAT-04 Kéo thả chặng, cấu hình thuộc tính, xem mã
    # Chức năng hệ cũ: LGC-TOOL-002, 003, 004; FR: FR-04-012, 013, 014, 017; TC: TS-04-06, 07
    Khi cán bộ kéo thả chặng, cấu hình thuộc tính, xem mã
    Thì làm được như Tooling; không phải viết XML

  @UAT-05
  Kịch bản: UAT-05 Viết biểu thức điều kiện và xem kết quả
    # Chức năng hệ cũ: LGC-TOOL-006; FR: FR-04-015; TC: TS-04-08
    Khi cán bộ viết biểu thức điều kiện và xem kết quả
    Thì biết lỗi ngay khi gõ; xem trước trên bản tin mẫu

  @UAT-06
  Kịch bản: UAT-06 Ánh xạ bản tin hộ tịch sang mẫu dữ liệu chung
    # Chức năng hệ cũ: LGC-TOOL-008; FR: FR-04-020; TC: TS-04-09
    Khi cán bộ ánh xạ bản tin hộ tịch sang mẫu dữ liệu chung
    Thì không cần viết JQ tay

  @UAT-07
  Kịch bản: UAT-07 Gửi duyệt, người khác duyệt, phát hành TEST rồi PROD
    # Chức năng hệ cũ: LGC-BUS-012; FR: FR-04-040, 041, 042, 045; TC: TS-04-14, 15, 16
    Khi cán bộ gửi duyệt, người khác duyệt, phát hành TEST rồi PROD
    Thì đi hết quy trình trong một ngày làm việc; mọi bước có lý do và lịch sử

  @UAT-08
  Kịch bản: UAT-08 Tạm dừng và chạy lại một route khi HTTT đích bảo trì
    # Chức năng hệ cũ: LGC-BUS-009; FR: FR-04-050; TC: TS-04-18
    Khi cán bộ tạm dừng và chạy lại một route khi HTTT đích bảo trì
    Thì có hiệu lực trong 10 giây, có ghi nhận người, lý do

  @UAT-09
  Kịch bản: UAT-09 Quay lui phiên bản lỗi
    # Chức năng hệ cũ: — (Bus cũ không có); FR: FR-04-044; TC: TS-04-17
    Khi cán bộ quay lui phiên bản lỗi
    Thì về phiên bản trước trong 3 phút

  @UAT-10
  Kịch bản: UAT-10 Xem số liệu và lịch sử thao tác của luồng
    # Chức năng hệ cũ: LGC-BUS-007, 014, 015, 019, 033; FR: FR-04-051, 053, 083; TC: TS-04-19
    Khi cán bộ xem số liệu và lịch sử thao tác của luồng
    Thì có biểu đồ theo luồng, lịch sử ai làm gì

  @UAT-11
  Kịch bản: UAT-11 Xóa chương trình không còn dùng
    # Chức năng hệ cũ: LGC-BUS-010; FR: FR-04-006; TC: TS-04-04
    Khi cán bộ xóa chương trình không còn dùng
    Thì hệ thống chặn khi còn phụ thuộc và nói rõ phụ thuộc

  @UAT-12
  Kịch bản: UAT-12 Chuyển một chương trình Camel XML cũ sang hệ mới
    # Chức năng hệ cũ: LGC-BUS-020…029; FR: FR-04-082; TC: TS-04-26
    Khi cán bộ chuyển một chương trình Camel XML cũ sang hệ mới
    Thì có báo cáo chặng chuyển được và chặng cần làm tay
