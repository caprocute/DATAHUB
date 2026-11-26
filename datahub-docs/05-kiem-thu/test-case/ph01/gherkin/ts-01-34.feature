# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-34
Tính năng: TS-01-34 · Truy cập và giao diện

  @TC-01-135 @P2 @Truycập
  Kịch bản: TC-01-135 Quét truy cập mười bảy màn hình
    # Truy vết: NFR-01-018 · UI-01-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17.
    Biết mỗi màn ở trạng thái có dữ liệu; axe-core; công cụ đọc màn hình thủ công cho UI-01-01, 09.
    Khi chạy quét axe trên từng màn; thao tác chỉ bằng bàn phím trọn luồng nộp hồ sơ và mở bàn giao.
    Và kiểm tương phản ở lớp kính và lớp nội dung (ADR-020).
    Thì 0 lỗi mức nghiêm trọng; thứ tự tab đúng; thông báo lỗi gắn với trường; tương phản đạt AA.

  @TC-01-136 @P2 @Dương @Âm
  Kịch bản: TC-01-136 Trạng thái chuẩn và đường dẫn trực tiếp
    # Truy vết: UI-01-03, 04, 05, 12, 14 · FR-01-001, 002, 016 · ERR-01-001, 052.
    Biết U-T68-VW; tenant không có dữ liệu `T90`.
    Khi mở UI-01-03 ở T90 (trống), khi API chậm, khi API lỗi.
    Và VW mở trực tiếp `/ket-noi/he-thong/tham-dinh` và `/ket-noi/ra-soat-quyen`; mở `/ket-noi/he-thong/khong-co`.
    Thì trạng thái trống, đang tải, lỗi (kèm `traceId`) theo D03-06-00; VW không thấy menu thẩm định; truy cập trực tiếp hiện trang `403` hoặc `404` (PTN-13).

  @TC-01-137 @P1 @Bảomật
  Kịch bản: TC-01-137 Trang bàn giao và phiếu xác nhận không làm rò bí mật
    # Truy vết: UI-01-09, 13 · FR-01-022, 041 · BR-01-006 · NFR-01-009.
    Biết liên kết bàn giao và phiếu xác nhận `PENDING`.
    Khi mở UI-01-09; xem tiêu đề phản hồi (`Cache-Control`, `Referrer-Policy`, ghi theo SDD), lịch sử trình duyệt, URL.
    Và nhấn "Sao chép"; tải lại trang; dùng nút Quay lại.
    Thì `no-store`, và chính sách tham chiếu không gửi đường dẫn đi nơi khác; bí mật không ở URL, lịch sử, bộ nhớ đệm; tải lại hoặc quay lại không hiện lại bí mật (`410`). Phiếu UI-01-13 tương tự.

  @TC-01-138 @P3 @Khảdụng
  Kịch bản: TC-01-138 Trình hướng dẫn năm bước dễ dùng
    # Truy vết: NFR-01-014 · UI-01-01 · UC-01-02.
    Biết năm cán bộ đầu mối chưa từng dùng; tài liệu hướng dẫn mục 6.
    Khi mỗi cán bộ hoàn thành hồ sơ mẫu `HT-HOTICH` từ đầu tới bước nộp, không có người hướng dẫn.
    Thì trung bình ≤ 30 phút; mọi thông báo lỗi nêu cách khắc phục; quay lại bước trước không mất dữ liệu.
