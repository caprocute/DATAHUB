# language: vi
# Sinh tự động từ mục 7 của D05-02-PH18; không sửa tay.
@PH-18 @UAT
Tính năng: Nghiệm thu người dùng Vận hành và xử lý lỗi

  Bối cảnh:
    Biết cán bộ của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-18-01
  Kịch bản: UAT-18-01 TA sửa một thông số của luồng trên màn tham số, xem lịch sử và khôi phục giá trị cũ
    # Liên quan hệ cũ: LGC-BUS-031; FR: FR-18-003, 004, 005; TC: TS-18-02, 03, 04
    Khi cán bộ thực hiện việc: TA sửa một thông số của luồng trên màn tham số, xem lịch sử và khôi phục giá trị cũ
    Thì lưu có lý do, có phiên bản, khôi phục tạo phiên bản mới; khóa ★ cần SO duyệt

  @UAT-18-02
  Kịch bản: UAT-18-02 TO lọc bản tin lỗi của luồng thuế, xem chi tiết và nội dung có lý do, phân loại
    # Liên quan hệ cũ: LGC-BUS-037; FR: FR-18-019, 021, 022, 023; TC: TS-18-12, 13
    Khi cán bộ thực hiện việc: TO lọc bản tin lỗi của luồng thuế, xem chi tiết và nội dung có lý do, phân loại
    Thì lọc đúng, chi tiết có chẩn đoán, nội dung chỉ hiện sau khi nhập lý do

  @UAT-18-03
  Kịch bản: UAT-18-03 TO thực hiện lại một bản tin và một loạt 800 bản tin, TA duyệt loạt lớn
    # Liên quan hệ cũ: LGC-BUS-037; FR: FR-18-027, 028, 029, 030; TC: TS-18-16, 17
    Khi cán bộ thực hiện việc: TO thực hiện lại một bản tin và một loạt 800 bản tin, TA duyệt loạt lớn
    Thì bản tin phát lại qua nguồn, không xử lý trùng; loạt lớn chờ TA duyệt

  @UAT-18-04
  Kịch bản: UAT-18-04 TO bỏ qua bản tin thử nghiệm và mở lại một bản tin bỏ nhầm
    # Liên quan hệ cũ: LGC-BUS-037; FR: FR-18-031, 032; TC: TS-18-18
    Khi cán bộ thực hiện việc: TO bỏ qua bản tin thử nghiệm và mở lại một bản tin bỏ nhầm
    Thì bỏ qua có lý do, mở lại được trong hạn

  @UAT-18-05
  Kịch bản: UAT-18-05 TA soạn mẫu thư kích hoạt HTTT, TA khác duyệt; người dùng đặt giờ yên lặng
    # Liên quan hệ cũ: —; FR: FR-18-035, 038; TC: TS-18-20, 22
    Khi cán bộ thực hiện việc: TA soạn mẫu thư kích hoạt HTTT, TA khác duyệt; người dùng đặt giờ yên lặng
    Thì mẫu có biến cấm bị từ chối; thư chỉ có liên kết; giờ yên lặng giữ thư thường

  @UAT-18-06
  Kịch bản: UAT-18-06 TO mở sự cố từ cảnh báo, thêm mốc, liên kết bản tin lỗi, đóng có nguyên nhân và bài học
    # Liên quan hệ cũ: LGC-NFR-004; FR: FR-18-047, 048, 049, 051; TC: TS-18-28
    Khi cán bộ thực hiện việc: TO mở sự cố từ cảnh báo, thêm mốc, liên kết bản tin lỗi, đóng có nguyên nhân và bài học
    Thì sự cố có mốc thời gian, liên kết, chỉ đóng được khi đủ nguyên nhân và bài học

  @UAT-18-07
  Kịch bản: UAT-18-07 TA yêu cầu khôi phục tỉnh về thời điểm hôm qua, PA duyệt, theo dõi tám bước
    # Liên quan hệ cũ: —; FR: FR-18-054, 055; TC: TS-18-31
    Khi cán bộ thực hiện việc: TA yêu cầu khôi phục tỉnh về thời điểm hôm qua, PA duyệt, theo dõi tám bước
    Thì có người thứ hai duyệt, tỉnh tạm ngừng trong lúc thay dữ liệu, thông báo kết quả

  @UAT-18-08
  Kịch bản: UAT-18-08 TA chạy thử di trú danh mục Aita, xem đối chiếu, PA duyệt chạy thật, cắt chuyển nhóm thuế rồi quay lui
    # Liên quan hệ cũ: LGC-HUB-008, LGC-DMDC-001; FR: FR-18-061, 062, 064, 068; TC: TS-18-35, 36, 38
    Khi cán bộ thực hiện việc: TA chạy thử di trú danh mục Aita, xem đối chiếu, PA duyệt chạy thật, cắt chuyển nhóm thuế rồi quay lui
    Thì chạy thử không ghi; chạy thật không trùng; cắt chuyển chỉ khi đạt danh sách kiểm tra, quay lui ≤ 15 phút
