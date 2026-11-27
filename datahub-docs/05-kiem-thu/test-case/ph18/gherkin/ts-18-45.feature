# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-45
Tính năng: TS-18-45 · Khả năng truy cập của các màn vận hành

  @TC-18-160 @P1 @Truy_cập
  Kịch bản: TC-18-160 Danh sách, chi tiết, sửa payload, lượt phát lại dùng bằng bàn phím và trình đọc màn hình
    # Truy vết: NFR-18-020 · UI-18-01, 02, 03, 04, 05
    # Mục đích: Chứng minh màn dùng hằng ngày đạt WCAG 2.2 AA.
    Biết STAGING; NVDA và VoiceOver; axe-core 4.x; `DLQ-SET-A`.
    Khi dùng Tab, Shift+Tab, Space chọn nhiều mục ở UI-18-01, phát lại loạt.
    Và mở UI-18-03, đọc trạng thái và khác biệt ở UI-18-04 bằng trình đọc.
    Và theo dõi tiến độ lượt ở UI-18-05.
    Và chạy axe trên năm màn ở ba điểm ngắt.
    Thì thứ tự tiêu điểm hợp lý, có viền tiêu điểm; trạng thái có chữ không chỉ dựa màu; khác biệt đọc được "đã thêm", "đã xóa"; tiến độ thông báo qua `aria-live="polite"`; axe 0 lỗi mức nghiêm trọng.

  @TC-18-161 @P1 @Truy_cập
  Kịch bản: TC-18-161 Hộp thoại duyệt bốn mắt, lý do bắt buộc và Việc của tôi
    # Truy vết: NFR-18-020 · UI-18-09, 15, 20, 23
    # Mục đích: Chứng minh hộp thoại xác nhận giữ tiêu điểm, thông báo lỗi gắn với ô nhập.
    Biết STAGING; một đề nghị khóa ★, một khôi phục, một cắt chuyển chờ duyệt.
    Khi mở việc duyệt bằng bàn phím, mở hộp thoại duyệt.
    Và gửi lý do 3 ký tự.
    Và nhấn Esc.
    Thì tiêu điểm nằm trong hộp thoại, tiêu đề được đọc; lỗi lý do gắn `aria-describedby`, đọc câu ERR-18-007; Esc đóng và trả tiêu điểm về nút mở.

  @TC-18-162 @P2 @Truy_cập
  Kịch bản: TC-18-162 Quét axe và kiểm tay mọi màn PH-18 ở thu phóng 200 %
    # Truy vết: NFR-18-020 · UI-18-06, 07, 08, 10, 11, 12, 13, 14, 16, 17, 18, 19, 21, 22, 24
    # Mục đích: Chứng minh phủ đủ 24 màn.
    Biết STAGING; dữ liệu mẫu cho từng màn.
    Khi chạy axe trên các màn ở ba điểm ngắt.
    Và thu phóng 200 %, kiểm không cuộn ngang ở 320 px.
    Và kiểm độ tương phản biểu đồ thống kê, bảng sao lưu.
    Thì axe 0 lỗi nghiêm trọng; không mất nội dung ở 200 %; tương phản ≥ 4,5:1 cho chữ, ≥ 3:1 cho thành phần đồ họa; biểu đồ có bảng số liệu thay thế.
