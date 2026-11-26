# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-36
Tính năng: TS-16-36 · Vòng đầy đủ và truy cập giao diện

  @TC-16-122 @P1 @Dương
  Kịch bản: TC-16-122 Vòng đầy đủ một kỳ tháng
    # Truy vết: FR-16-010, 014, 015, 018, 023, 024, 026, 028, 029, 034 · API-16-030, 032, 040, 050, 057, 065, 071, 072, 074 · UI-16-06, 07, 08, 10, 12 · EVT-16-05, EVT-16-08
    Biết T90 đã kế thừa 24 chỉ tiêu; nguồn đầy đủ; TO1, SO, TA1, TA2, VW.
    Khi phát quan sát từ sự kiện và API đẩy
    Và TO nhập số tay có bằng chứng, SO xác nhận
    Và TO chạy tổng hợp
    Và đẩy một số trễ, đợi tính lại
    Và TA chốt kỳ
    Và TO lập báo cáo, giải trình, gửi duyệt
    Và TA1 duyệt, TA2 công bố ký số lưu WORM
    Và phân phối tới danh sách, VW xem báo cáo
    Thì mọi bước thành công đúng trạng thái: kỳ `CLOSED`, báo cáo `PUBLISHED` có `contentHash`, chữ ký, `wormRef`; phân phối `SENT`; VW tra được bằng chứng; kiểm toán đủ ở mọi bước; điểm và trạng thái đúng bảng 2.4.

  @TC-16-123 @P1 @Chịu @lỗi @Dương
  Kịch bản: TC-16-123 Diễn tập thiếu nguồn: STALE, PARTIAL, báo cáo chính thức bị chặn
    # Truy vết: FR-16-013, 020, 026, 028 · API-16-023, 051, 071 · ERR-16-107, ERR-16-111, ERR-16-029 · BR-16-007, BR-16-008 · UI-16-05, UI-16-09
    Biết T94; tắt nguồn PH-13 một ngày (`clock-sim`); chỉ tiêu bắt buộc phụ thuộc PH-13.
    Khi đẩy đồng hồ 27 giờ không có số PH-13
    Và chạy tổng hợp
    Và lập báo cáo `PERIODIC` và gửi duyệt
    Và bật PH-13, đẩy số, tính lại, gửi duyệt lại
    Thì nguồn `STALE`, cờ `STALE_SOURCE`, chỉ tiêu liên quan `NO_DATA`, lần tổng hợp `PARTIAL`, không điền số; gửi duyệt báo cáo bị `422` ERR-16-029. Sau khi có số, tính lại đủ, gửi duyệt thành công. Bảng điều khiển luôn có nhãn `PARTIAL` trong thời gian thiếu.

  @TC-16-124 @P2 @Truy @cập
  Kịch bản: TC-16-124 Khả năng truy cập WCAG 2.2 AA trên UI-16-01…20
    # Truy vết: NFR-16-021 · UI-16-01…20
    Biết playwright, axe-core; NVDA; dữ liệu F-KY-1, F-KT.
    Khi chạy axe-core trên 20 màn ở chế độ sáng và tối
    Và duyệt bằng bàn phím UI-16-01, 04, 07, 12, 16, 17
    Và đọc biểu đồ chỉ tiêu bằng NVDA
    Và kiểm bảng số thay thế và nhãn trạng thái
    Thì 0 lỗi mức nghiêm trọng của axe-core; mọi thao tác chính dùng được bằng bàn phím, thứ tự tab đúng; mọi biểu đồ có bảng số thay thế; trạng thái `ON_TRACK`, `AT_RISK`, `OFF_TRACK`, `NO_DATA` có nhãn chữ, không chỉ dùng màu.
