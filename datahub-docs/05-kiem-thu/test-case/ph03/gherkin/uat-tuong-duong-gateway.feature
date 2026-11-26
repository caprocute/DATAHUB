# language: vi
# Sinh tự động từ mục 7 của D05-02-PH03; không sửa tay.
@PH-03 @UAT
Tính năng: Nghiệm thu người dùng tương đương API Management cũ (Gravitee) và Bus cũ

  Bối cảnh:
    Biết cán bộ vận hành API của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và các API của tỉnh đã được chuyển từ gateway cũ (Gravitee) sang APISIX

  @UAT-01
  Kịch bản: UAT-01 Dừng rồi mở lại một API đang chạy
    # Chức năng hệ cũ: LGC-APIM-005; FR: FR-03-036, 047; TC: TS-03-12, 08
    Khi cán bộ dừng rồi mở lại một API đang chạy
    Thì làm được trong 3 thao tác, hiệu lực ≤ 60 giây, lượt gọi trong lúc dừng nhận thông báo rõ

  @UAT-02
  Kịch bản: UAT-02 Đặt kiểu bảo mật của gói: khóa API hoặc Keyless, thêm OAuth hoặc mTLS
    # Chức năng hệ cũ: LGC-APIM-011; LGC-APIM-016; LGC-BUS-041; FR: FR-03-015, 016, 002, 012, 014; TC: TS-03-06, 07, 01
    Khi cán bộ đặt kiểu bảo mật của gói: khóa API hoặc Keyless, thêm OAuth hoặc mTLS
    Thì giữ đủ kiểu của hệ cũ, thêm OAuth 2.1 và mTLS; Keyless chỉ cho dữ liệu mở

  @UAT-03
  Kịch bản: UAT-03 Đặt giới hạn tần suất theo giây, phút cho một HTTT
    # Chức năng hệ cũ: LGC-APIM-012; FR: FR-03-021, 024, 025; TC: TS-03-09, 10
    Khi cán bộ đặt giới hạn tần suất theo giây, phút cho một HTTT
    Thì đặt trong 2 phút, có tiêu đề hạn mức, thấy mức đang dùng

  @UAT-04
  Kịch bản: UAT-04 Đặt hạn ngạch theo giờ, ngày, tháng và nhận cảnh báo ngưỡng
    # Chức năng hệ cũ: LGC-APIM-013; FR: FR-03-022; TC: TS-03-09
    Khi cán bộ đặt hạn ngạch theo giờ, ngày, tháng và nhận cảnh báo ngưỡng
    Thì cảnh báo ở 80 % và 100 %, đặt lại đúng chu kỳ

  @UAT-05
  Kịch bản: UAT-05 Cho phép hoặc chặn đường dẫn trong gói
    # Chức năng hệ cũ: LGC-APIM-014; FR: FR-03-020; TC: TS-03-07
    Khi cán bộ cho phép hoặc chặn đường dẫn trong gói
    Thì chặn đường dẫn chuẩn hóa, báo lỗi rõ

  @UAT-06
  Kịch bản: UAT-06 Gắn chính sách cho gói và chạy thử trước khi phát
    # Chức năng hệ cũ: LGC-APIM-015; FR: FR-03-048, 057; TC: TS-03-19
    Khi cán bộ gắn chính sách cho gói và chạy thử trước khi phát
    Thì chọn từ mẫu được duyệt, chạy thử không ảnh hưởng hạn mức thật

  @UAT-07
  Kịch bản: UAT-07 Xem địa chỉ gọi API, thêm backend, kiểm tra cân bằng tải
    # Chức năng hệ cũ: LGC-APIM-017; LGC-APIM-018; FR: FR-03-028, 029, 030; TC: TS-03-12, 13
    Khi cán bộ xem địa chỉ gọi API, thêm backend, kiểm tra cân bằng tải
    Thì thấy host, đường dẫn, các backend và sức khỏe trong 3 thao tác

  @UAT-08
  Kịch bản: UAT-08 Tra nhật ký lượt gọi của một HTTT và xem chi tiết một lượt
    # Chức năng hệ cũ: LGC-APIM-022; FR: FR-03-050, 051; TC: TS-03-20
    Khi cán bộ tra nhật ký lượt gọi của một HTTT và xem chi tiết một lượt
    Thì tìm trong 3 thao tác, p95 ≤ 3 giây, không lộ thân bản tin

  @UAT-09
  Kịch bản: UAT-09 Xem danh sách gateway, trạng thái đồng bộ và tổng quan lưu lượng
    # Chức năng hệ cũ: LGC-APIM-023…026; FR: FR-03-045, 052, 055; TC: TS-03-18, 21
    Khi cán bộ xem danh sách gateway, trạng thái đồng bộ và tổng quan lưu lượng
    Thì thấy nút, phiên bản cấu hình, sức khỏe, biểu đồ lưu lượng

  @UAT-10
  Kịch bản: UAT-10 Quan sát gateway tự từ chối khi quá tải, cô lập lỗi, hết thời hạn chờ
    # Chức năng hệ cũ: LGC-NFR-006; FR: FR-03-021, 026, 031; TC: TS-03-09, 11, 13
    Khi cán bộ quan sát gateway tự từ chối khi quá tải, cô lập lỗi, hết thời hạn chờ
    Thì hạn mức, ngắt mạch, thời hạn chờ có hiệu lực và có cảnh báo

  @UAT-11
  Kịch bản: UAT-11 Chuyển cấu hình từ gateway cũ sang Datahub
    # Chức năng hệ cũ: LGC-APIM-002…005, LGC-APIM-009…015, LGC-APIM-019…021; FR: FR-03-059, 046; TC: TS-03-23, 18
    Khi cán bộ chuyển cấu hình từ gateway cũ sang Datahub
    Thì có đề xuất cho mọi plan và Application; chỉ phải bổ sung lược đồ, chính sách OPA, bí mật
