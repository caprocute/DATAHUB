# language: vi
# Sinh tự động từ mục 7 của D05-02-PH16; không sửa tay.
@PH-16 @UAT
Tính năng: Nghiệm thu người dùng Báo cáo chỉ tiêu và sổ kiến trúc

  Bối cảnh:
    Biết quản trị tỉnh của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-01
  Kịch bản: UAT-01 Xem bảng điều khiển, mở chi tiết một chỉ tiêu và truy tới quan sát
    # Liên quan hệ cũ: LGC-APIM-026, LGC-PAY-013, LGC-PAY-020; FR: FR-16-038, 039, 040; TC: TS-16-20
    Khi người dùng xem bảng điều khiển, mở chi tiết một chỉ tiêu và truy tới quan sát
    Thì điểm, năm nhóm, trạng thái đúng; chỉ tiêu thiếu số có nhãn; truy tới quan sát gốc

  @UAT-02
  Kịch bản: UAT-02 Kế thừa bộ chỉ tiêu mẫu, soạn và duyệt bốn mắt một chỉ tiêu
    # Liên quan hệ cũ: —; FR: FR-16-002…005, 008; TC: TS-16-02, 03, 04
    Khi người dùng kế thừa bộ chỉ tiêu mẫu, soạn và duyệt bốn mắt một chỉ tiêu
    Thì chỉ tiêu `ACTIVE`, người duyệt khác người soạn, bản mẫu không sửa trực tiếp

  @UAT-03
  Kịch bản: UAT-03 Đăng ký nguồn, theo dõi độ tươi, nhập số tay kèm bằng chứng và xác nhận
    # Liên quan hệ cũ: LGC-BUS-027; FR: FR-16-009, 013, 014, 015; TC: TS-16-05, 08
    Khi người dùng đăng ký nguồn, theo dõi độ tươi, nhập số tay kèm bằng chứng và xác nhận
    Thì nguồn đúng trạng thái; số tay `ACCEPTED` do người khác xác nhận, vào tính toán

  @UAT-04
  Kịch bản: UAT-04 Chạy tổng hợp, đọc nhãn `PARTIAL`, tính lại khi có số trễ, chốt kỳ
    # Liên quan hệ cũ: —; FR: FR-16-018, 020, 023, 024; TC: TS-16-09, 10, 11
    Khi người dùng chạy tổng hợp, đọc nhãn `PARTIAL`, tính lại khi có số trễ, chốt kỳ
    Thì kết quả, cờ thiếu nguồn, kỳ `CLOSED`, số trễ không đổi kỳ đã chốt

  @UAT-05
  Kịch bản: UAT-05 Lập báo cáo, giải trình chỉ tiêu chệch, duyệt bốn mắt và công bố ký số
    # Liên quan hệ cũ: —; FR: FR-16-026, 027, 028, 029; TC: TS-16-13, 14, 15
    Khi người dùng lập báo cáo, giải trình chỉ tiêu chệch, duyệt bốn mắt và công bố ký số
    Thì báo cáo `PUBLISHED` có mã băm, chữ ký; bị chặn khi thiếu số bắt buộc

  @UAT-06
  Kịch bản: UAT-06 Đính chính báo cáo đã công bố và tải bằng chứng
    # Liên quan hệ cũ: —; FR: FR-16-030, 031, 036; TC: TS-16-16, 17
    Khi người dùng đính chính báo cáo đã công bố và tải bằng chứng
    Thì phiên bản mới, bản cũ `SUPERSEDED` còn tra được; bằng chứng kiểm chứng được

  @UAT-07
  Kịch bản: UAT-07 Xem sổ kiến trúc, đánh giá tuân thủ bốn mắt, đối chiếu thành phần mồ côi
    # Liên quan hệ cũ: LGC-HUB-001…004; FR: FR-16-043, 044, 047, 048; TC: TS-16-23, 24, 26
    Khi người dùng xem sổ kiến trúc, đánh giá tuân thủ bốn mắt, đối chiếu thành phần mồ côi
    Thì thành phần tự đăng ký, mức tuân thủ đổi sau xác nhận, mồ côi được tìm ra

  @UAT-08
  Kịch bản: UAT-08 Lập và gửi gói báo cáo, sổ kiến trúc qua PH-14 và gửi lại khi lỗi
    # Liên quan hệ cũ: LGC-NGSP-004; FR: FR-16-051, 052, 053; TC: TS-16-28, 29
    Khi người dùng lập và gửi gói báo cáo, sổ kiến trúc qua PH-14 và gửi lại khi lỗi
    Thì có biên nhận; gửi lại không tạo bản trùng; nhật ký nộp đủ
