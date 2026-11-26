# language: vi
# Sinh tự động từ mục 7 của D05-02-PH17; không sửa tay.
@PH-17 @UAT
Tính năng: Nghiệm thu người dùng Trợ lý AI và quản trị AI

  Bối cảnh:
    Biết cán bộ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-17-01
  Kịch bản: UAT-17-01 TA đề nghị bật trợ lý với số quyết định, SO xác nhận, người dùng thấy nút Trợ lý và xác nhận điều khoản
    # Liên quan hệ cũ: —; FR: FR-17-001, 005; TC: TS-17-01, 04
    Khi cán bộ thực hiện việc: TA đề nghị bật trợ lý với số quyết định, SO xác nhận, người dùng thấy nút Trợ lý và xác nhận điều khoản
    Thì trợ lý bật sau bốn mắt, nút hiện ≤ 60 giây, điều khoản xác nhận lần đầu, tắt được ngay

  @UAT-17-02
  Kịch bản: UAT-17-02 Người dùng hỏi "API tra cứu hộ gia đình" và mở liên kết trích dẫn
    # Liên quan hệ cũ: LGC-BUS-002, 003, 004; FR: FR-17-023, 024, 025; TC: TS-17-17
    Khi cán bộ thực hiện việc: Người dùng hỏi "API tra cứu hộ gia đình" và mở liên kết trích dẫn
    Thì kết quả có trích dẫn tới màn đối tượng, hỏi ngoài phạm vi được trả lời "không tìm thấy", không thấy API ngoài quyền

  @UAT-17-03
  Kịch bản: UAT-17-03 IE nhận gợi ý ánh xạ, xem trước, sửa một biểu thức và bấm áp dụng vào bản nháp
    # Liên quan hệ cũ: LGC-TOOL-007, LGC-TOOL-028; FR: FR-17-030, 032, 033, 035; TC: TS-17-19, 20
    Khi cán bộ thực hiện việc: IE nhận gợi ý ánh xạ, xem trước, sửa một biểu thức và bấm áp dụng vào bản nháp
    Thì gợi ý có điểm tin cậy và lý do, chỉ ghi bản nháp khi bấm áp dụng, thẻ hết hạn bị từ chối

  @UAT-17-04
  Kịch bản: UAT-17-04 TO bấm "Giải thích lỗi này" và giải thích theo trace_id, nhận danh sách kiểm khắc phục
    # Liên quan hệ cũ: LGC-BUS-027, 029, 037; FR: FR-17-036, 037, 039, 041; TC: TS-17-21, 22, 23
    Khi cán bộ thực hiện việc: TO bấm "Giải thích lỗi này" và giải thích theo trace_id, nhận danh sách kiểm khắc phục
    Thì giải thích có nguyên nhân, cách xử lý, liên kết; log đã che; danh sách kiểm không có bước tự thực hiện

  @UAT-17-05
  Kịch bản: UAT-17-05 SO bấm tắt khẩn cấp và quan sát người dùng bị chặn
    # Liên quan hệ cũ: —; FR: FR-17-006; TC: TS-17-05
    Khi cán bộ thực hiện việc: SO bấm tắt khẩn cấp và quan sát người dùng bị chặn
    Thì mọi người dùng nhận thông báo tạm ngừng khẩn cấp trong 60 giây, gỡ cần hai người

  @UAT-17-06
  Kịch bản: UAT-17-06 SO chạy bộ ca đỏ cho một phiên bản mô hình mới và xem cổng phát hành
    # Liên quan hệ cũ: —; FR: FR-17-051, 009; TC: TS-17-29, 37
    Khi cán bộ thực hiện việc: SO chạy bộ ca đỏ cho một phiên bản mô hình mới và xem cổng phát hành
    Thì 66 ca bị chặn, cổng mở; thử với một ca lọt thì cổng đỏ và không duyệt được

  @UAT-17-07
  Kịch bản: UAT-17-07 SO khai lý do, mở nhật ký một hội thoại và xem báo cáo sử dụng
    # Liên quan hệ cũ: —; FR: FR-17-055, 056, 058; TC: TS-17-32, 33
    Khi cán bộ thực hiện việc: SO khai lý do, mở nhật ký một hội thoại và xem báo cáo sử dụng
    Thì phiếu 60 phút, nội dung đã che, có kiểm toán người xem; báo cáo chỉ số liệu tổng hợp

  @UAT-17-08
  Kịch bản: UAT-17-08 TA thử bật mô hình ngoài khi chưa có cam kết, rồi bật đúng quy trình
    # Liên quan hệ cũ: —; FR: FR-17-003, 007, 010; TC: TS-17-03, 09
    Khi cán bộ thực hiện việc: TA thử bật mô hình ngoài khi chưa có cam kết, rồi bật đúng quy trình
    Thì bị từ chối đúng thông báo, sau đó bật được bằng đề nghị bốn mắt riêng và danh sách trắng

  @UAT-17-09
  Kịch bản: UAT-17-09 DS tải tài liệu hướng dẫn của tỉnh, TA duyệt và người dùng hỏi nội dung tài liệu
    # Liên quan hệ cũ: —; FR: FR-17-020, 019; TC: TS-17-15
    Khi cán bộ thực hiện việc: DS tải tài liệu hướng dẫn của tỉnh, TA duyệt và người dùng hỏi nội dung tài liệu
    Thì tài liệu qua kiểm mã độc và DLCN, chỉ lập chỉ mục sau duyệt, ngừng thì biến mất khỏi kết quả
