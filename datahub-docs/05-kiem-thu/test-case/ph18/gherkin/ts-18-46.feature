# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-46
Tính năng: TS-18-46 · Tương đương hệ cũ và chức năng cũ của SRS repo

  @TC-18-163 @P2 @Dương
  Kịch bản: TC-18-163 Lấy và cập nhật thông số hệ thống như hệ cũ qua kho tham số
    # Truy vết: LGC-BUS-031 · FR-18-003, 007, 005 · API-18-004, 006, 013 · UI-18-08
    # Mục đích: Chứng minh LGC-BUS-031: thao tác "lấy, cập nhật thông số" của hệ cũ làm được bằng API-18-004, 006 và màn UI-18-08, có thêm lý do, phiên bản, bốn mắt.
    Biết T68 ở STAGING; danh sách 15 thông số hệ cũ ánh xạ sang khóa mới (giả định theo kiểm kê D00-03).
    Khi với từng thông số hệ cũ, đọc giá trị bằng khóa mới.
    Và cập nhật ba thông số, xem lịch sử.
    Thì mọi thông số có khóa tương ứng; cập nhật có phiên bản và lịch sử; khóa ★ đi qua bốn mắt.

  @TC-18-164 @P2 @Dương
  Kịch bản: TC-18-164 Thực hiện lại hoặc bỏ qua bản tin lỗi như hệ cũ, kèm chẩn đoán và lũy đẳng
    # Truy vết: LGC-BUS-037 · FR-18-019, 027, 031, 034 · API-18-041, 064, 077 · UI-18-01, 03
    # Mục đích: Chứng minh LGC-BUS-037 và đối chiếu 20 FR cũ ở mục 7.2.
    Biết T68; 30 bản tin lỗi của luồng thuế giả lập.
    Khi người vận hành mở danh sách, chọn 10 mục "thực hiện lại", 5 mục "bỏ qua".
    Và mở thống kê.
    Thì mục phát lại qua nguồn, kết quả hiện từng mục; mục bỏ qua có lý do; thống kê và xu hướng hiện đúng như chức năng thống kê cũ.
