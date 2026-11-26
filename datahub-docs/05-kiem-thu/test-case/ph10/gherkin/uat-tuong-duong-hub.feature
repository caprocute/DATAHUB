# language: vi
# Sinh tự động từ mục 7 của D05-02-PH10; không sửa tay.
@PH-10 @UAT
Tính năng: Nghiệm thu người dùng tương đương Hub Pulsar

  Bối cảnh:
    Biết cán bộ nghiệp vụ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và kiểm kê Hub cũ của tỉnh đã được nhập vào môi trường UAT

  @UAT-01
  Kịch bản: UAT-01 Xem tổng số publisher, subscriber, project, topic
    # Chức năng hệ cũ: LGC-HUB-001…004; FR: FR-10-057; TC: TS-10-23
    Khi cán bộ xem tổng số publisher, subscriber, project, topic
    Thì bốn thẻ đếm ngay trên màn tổng quan, bấm vào ra danh sách đã lọc

  @UAT-02
  Kịch bản: UAT-02 Xem tài nguyên CPU, bộ nhớ của cụm
    # Chức năng hệ cũ: LGC-HUB-005, 006; FR: FR-10-057; TC: TS-10-23
    Khi cán bộ xem tài nguyên CPU, bộ nhớ của cụm
    Thì một thao tác từ màn tổng quan sang bảng chỉ số cụm PH-13

  @UAT-03
  Kịch bản: UAT-03 Xem sơ đồ kết nối của một dự án
    # Chức năng hệ cũ: LGC-HUB-007; FR: FR-10-058; TC: TS-10-23
    Khi cán bộ xem sơ đồ kết nối của một dự án
    Thì sơ đồ ba lớp lọc theo dự án, thấy cạnh đang lag, có DLQ

  @UAT-04
  Kịch bản: UAT-04 Tạo, sửa, lưu trữ dự án tích hợp
    # Chức năng hệ cũ: LGC-HUB-008; FR: FR-10-003, 004, 005; TC: TS-10-01
    Khi cán bộ tạo, sửa, lưu trữ dự án tích hợp
    Thì làm được như hệ cũ; thay "xóa" bằng lưu trữ có lý do

  @UAT-05
  Kịch bản: UAT-05 Tạo topic với phân vùng, cấu trúc, chế độ định tuyến
    # Chức năng hệ cũ: LGC-HUB-009; FR: FR-10-008, 017; TC: TS-10-02, 06
    Khi cán bộ tạo topic với phân vùng, cấu trúc, chế độ định tuyến
    Thì tạo được trong 5 phút; cấu trúc thành lược đồ có kiểm tra

  @UAT-06
  Kịch bản: UAT-06 Thêm publisher, subscriber, đánh dấu subscriber là luồng
    # Chức năng hệ cũ: LGC-HUB-010, 011; FR: FR-10-026, 027; TC: TS-10-08
    Khi cán bộ thêm publisher, subscriber, đánh dấu subscriber là luồng
    Thì chọn HTTT, luồng từ danh sách, giữ khóa tham chiếu cũ

  @UAT-07
  Kịch bản: UAT-07 Cho một publisher phát lên topic
    # Chức năng hệ cũ: LGC-HUB-012; FR: FR-10-030, 031; TC: TS-10-10
    Khi cán bộ cho một publisher phát lên topic
    Thì đề nghị, được duyệt và phát được trong ngày

  @UAT-08
  Kịch bản: UAT-08 Khai báo subscription với URI, số worker, số lần thử lại, thời điểm bắt đầu
    # Chức năng hệ cũ: LGC-HUB-013; FR: FR-10-035, 036, 040; TC: TS-10-13
    Khi cán bộ khai báo subscription với URI, số worker, số lần thử lại, thời điểm bắt đầu
    Thì đủ bốn tham số cũ; thêm xác minh endpoint, khóa ký

  @UAT-09
  Kịch bản: UAT-09 Xem, sửa danh mục kiểu giao tiếp, chế độ định tuyến
    # Chức năng hệ cũ: LGC-HUB-014; FR: FR-10-060, 061; TC: TS-10-24
    Khi cán bộ xem, sửa danh mục kiểu giao tiếp, chế độ định tuyến
    Thì thấy mã hệ cũ bên cạnh mã mới

  @UAT-10
  Kịch bản: UAT-10 Chuyển một project từ Hub cũ sang Datahub
    # Chức năng hệ cũ: LGC-HUB-008…014, LGC-TOOL-010; FR: FR-10-072, 073, 075; TC: TS-10-28, 29
    Khi cán bộ chuyển một project từ Hub cũ sang Datahub
    Thì có đề xuất ánh xạ từ kiểm kê, cầu nối chạy, subscriber cũ không gián đoạn
