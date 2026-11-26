# language: vi
# Sinh tự động từ mục 7 của D05-02-PH11; không sửa tay.
@PH-11 @UAT
Tính năng: Nghiệm thu người dùng Quy trình liên thông

  Bối cảnh:
    Biết người quản lý dữ liệu của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-01
  Kịch bản: UAT-01 Kỹ sư IE vẽ, cấu hình, kiểm tra và gửi duyệt `LT_KHAI_SINH` v4; IA duyệt
    # Liên quan hệ cũ: —; FR: FR-11-003, 005, 007, 008; TC: TC-11-010, TC-11-014, TC-11-028, TC-11-030
    Khi người dùng kỹ sư IE vẽ, cấu hình, kiểm tra và gửi duyệt `LT_KHAI_SINH` v4; IA duyệt
    Thì phát hành thành công, phiên cũ vẫn chạy v3

  @UAT-02
  Kịch bản: UAT-02 Cán bộ Tư pháp nhận hồ sơ, hoàn thành, trả về hoặc yêu cầu bổ sung
    # Liên quan hệ cũ: LGC-NGSP-002; FR: FR-11-036, 038, 044, 049; TC: TC-11-060, TC-11-064, TC-11-070
    Khi người dùng cán bộ Tư pháp nhận hồ sơ, hoàn thành, trả về hoặc yêu cầu bổ sung
    Thì hồ sơ đi đúng bước, hạn dừng khi chờ bổ sung

  @UAT-03
  Kịch bản: UAT-03 Lãnh đạo xem việc sắp hạn, quá hạn; cán bộ ủy quyền khi vắng
    # Liên quan hệ cũ: —; FR: FR-11-041, 047, 048; TC: TC-11-086, TC-11-088, TC-11-077
    Khi người dùng lãnh đạo xem việc sắp hạn, quá hạn; cán bộ ủy quyền khi vắng
    Thì nhắc và leo thang đúng, ủy quyền có hiệu lực

  @UAT-04
  Kịch bản: UAT-04 Nhân viên Cổng DVC tra tiến độ hồ sơ của công dân
    # Liên quan hệ cũ: LGC-NGSP-002; FR: FR-11-055; TC: TC-11-112, TC-11-113
    Khi người dùng nhân viên Cổng DVC tra tiến độ hồ sơ của công dân
    Thì thấy ba bước công khai, không thấy thông tin nội bộ

  @UAT-05
  Kịch bản: UAT-05 Vận hành xử lý hồ sơ BHYT lỗi: bù trừ tự động rồi thủ công
    # Liên quan hệ cũ: LGC-BUS-037; FR: FR-11-051, 053; TC: TC-11-103, TC-11-109, TC-11-165
    Khi người dùng vận hành xử lý hồ sơ BHYT lỗi: bù trừ tự động rồi thủ công
    Thì hồ sơ về nhất quán, không bước lệch nào bị bỏ sót

  @UAT-06
  Kịch bản: UAT-06 Vận hành xử lý sự cố engine và thử lại
    # Liên quan hệ cũ: LGC-BUS-037; FR: FR-11-060; TC: TC-11-121
    Khi người dùng vận hành xử lý sự cố engine và thử lại
    Thì sự cố mở, thử lại, đóng đúng

  @UAT-07
  Kịch bản: UAT-07 Quản trị tỉnh khai lịch, đổi tham số, xem hạn qua ngày lễ
    # Liên quan hệ cũ: LGC-NGSP-004; FR: FR-11-045, 046, 062; TC: TC-11-081, TC-11-083, TC-11-124
    Khi người dùng quản trị tỉnh khai lịch, đổi tham số, xem hạn qua ngày lễ
    Thì hạn đúng theo lịch tỉnh, tham số có hiệu lực

  @UAT-08
  Kịch bản: UAT-08 Kiểm toán viên xuất lịch sử và bằng chứng BPMN 2.0
    # Liên quan hệ cũ: —; FR: FR-11-057, 064; TC: TC-11-128, TC-11-130, TC-11-164
    Khi người dùng kiểm toán viên xuất lịch sử và bằng chứng BPMN 2.0
    Thì gói có băm, thuyết minh WS-BPEL, ranh giới PH-11 và PH-04 xác nhận
