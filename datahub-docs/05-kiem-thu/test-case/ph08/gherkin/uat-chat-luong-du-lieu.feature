# language: vi
# Sinh tự động từ mục 7 của D05-02-PH08; không sửa tay.
@PH-08 @UAT
Tính năng: Nghiệm thu người dùng Chất lượng dữ liệu

  Bối cảnh:
    Biết người quản lý dữ liệu của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-01
  Kịch bản: UAT-01 Xem tổng quan chất lượng của tỉnh và thẻ điểm một đối tượng
    # Liên quan hệ cũ: —; FR: FR-08-050, 051; TC: TS-08-24
    Khi người dùng xem tổng quan chất lượng của tỉnh và thẻ điểm một đối tượng
    Thì điểm tỉnh, thẻ miền, xu hướng đúng; bấm vào ra danh sách đã lọc

  @UAT-02
  Kịch bản: UAT-02 Đăng ký đối tượng đo từ domain dữ liệu chủ và khai CDE
    # Liên quan hệ cũ: —; FR: FR-08-002, 005; TC: TS-08-02
    Khi người dùng đăng ký đối tượng đo từ domain dữ liệu chủ và khai CDE
    Thì đối tượng `DRAFT`, trường CDE che đúng theo phân loại

  @UAT-03
  Kịch bản: UAT-03 Soạn bộ quy tắc sáu chiều, chạy thử, gửi duyệt, DA duyệt
    # Liên quan hệ cũ: —; FR: FR-08-012, 013, 016, 017; TC: TS-08-05, 06, 07
    Khi người dùng soạn bộ quy tắc sáu chiều, chạy thử, gửi duyệt, DA duyệt
    Thì bộ quy tắc `ACTIVE`, DA khác người soạn

  @UAT-04
  Kịch bản: UAT-04 Chạy đo theo yêu cầu, đọc điểm sáu chiều và so với kỳ trước
    # Liên quan hệ cũ: —; FR: FR-08-024, 028, 029; TC: TS-08-10, 12
    Khi người dùng chạy đo theo yêu cầu, đọc điểm sáu chiều và so với kỳ trước
    Thì điểm, kết luận, xu hướng, cờ thiếu chiều hiển thị đúng

  @UAT-05
  Kịch bản: UAT-05 Đo chất lượng mã ĐVHC sau khi nhập danh mục
    # Liên quan hệ cũ: LGC-DMDC-006; FR: FR-08-027; TC: TS-08-11
    Khi người dùng đo chất lượng mã ĐVHC sau khi nhập danh mục
    Thì số mã không hợp lệ và gợi ý mã mới, không có bảng mã ở PH-08

  @UAT-06
  Kịch bản: UAT-06 Giao và xử lý phiếu khắc phục, đo kiểm chứng
    # Liên quan hệ cũ: —; FR: FR-08-041…044; TC: TS-08-19, 20, 21
    Khi người dùng giao và xử lý phiếu khắc phục, đo kiểm chứng
    Thì phiếu tới `VERIFIED`, chủ quản không tự xác nhận

  @UAT-07
  Kịch bản: UAT-07 Lập và công bố báo cáo năm
    # Liên quan hệ cũ: —; FR: FR-08-054; TC: TS-08-25
    Khi người dùng lập và công bố báo cáo năm
    Thì báo cáo năm bị chặn khi thiếu `FULL`, công bố sau khi đủ

  @UAT-08
  Kịch bản: UAT-08 Kiểm tra trực tuyến một luồng và xem thống kê lỗi theo luồng
    # Liên quan hệ cũ: LGC-BUS-027; FR: FR-08-032, 033, 034; TC: TS-08-15, 16
    Khi người dùng kiểm tra trực tuyến một luồng và xem thống kê lỗi theo luồng
    Thì bản tin lỗi vào DLQ hoặc đi tiếp kèm tiêu đề, thống kê theo phút
