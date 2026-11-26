# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-43
Tính năng: TS-17-43 · Khả năng truy cập của bảng bên trợ lý

  @TC-17-156 @P1 @Truy_cập
  Kịch bản: TC-17-156 Bảng bên: role, aria-label, bàn phím, tiêu điểm, CMP-Drawer dưới bp-xl
    # Truy vết: NFR-17-024 · FR-17-022 · UI-17-01, 05
    # Mục đích: Chứng minh NFR-17-024 cho UI-17-01.
    Biết STAGING; Playwright, axe-core; IE đã xác nhận điều khoản.
    Khi chạy axe trên bảng bên ở ba trạng thái (rỗng, có hội thoại, lỗi) và chế độ sáng, tối.
    Và mở bằng Ctrl+K "Hỏi trợ lý AI", điều hướng chỉ bằng bàn phím tới ô nhập, chip, nút gửi, hủy, phản hồi, tab "Lịch sử".
    Và thu cửa sổ dưới `bp-xl`.
    Và đóng bằng Esc.
    Thì 0 lỗi axe mức nghiêm trọng; phần tử gốc `role="complementary"`, `aria-label="Trợ lý AI"`; thứ tự Tab hợp lý, tiêu điểm hiển thị; dưới `bp-xl` là `CMP-Drawer` nhốt tiêu điểm; Esc đóng và trả tiêu điểm về nút "Trợ lý"; tương phản đạt AA.

  @TC-17-157 @P1 @Truy_cập
  Kịch bản: TC-17-157 Câu trả lời phát trực tuyến đọc được qua aria-live polite, nhãn AI và trích dẫn có tên truy cập
    # Truy vết: NFR-17-024 · FR-17-026, 048, 025 · UI-17-01, 02
    # Mục đích: Chứng minh vùng `aria-live="polite"` và tên truy cập cho nhãn, trích dẫn, thẻ đề xuất.
    Biết playwright với trình đọc màn hình mô phỏng (cây truy cập); LLM-MOCK phát câu trả lời 5 câu có 2 trích dẫn; thẻ đề xuất ánh xạ.
    Khi gửi câu hỏi `:stream`, ghi các thông báo `aria-live`.
    Và duyệt cây truy cập của nhãn "Nội dung do AI tạo, cần kiểm tra lại", liên kết trích dẫn, nút "Áp dụng vào bản nháp".
    Thì vùng `aria-live="polite"` thông báo theo từng câu hoàn chỉnh (không đọc từng token); nhãn đọc được; liên kết trích dẫn có tên mô tả; nút "Áp dụng vào bản nháp" có tên và trạng thái; thẻ đề xuất dùng được bằng bàn phím.

  @TC-17-158 @P2 @Truy_cập
  Kịch bản: TC-17-158 Các màn quản trị trợ lý đạt WCAG 2.1 AA
    # Truy vết: NFR-17-024 · UI-17-06, 07, 08, 09, 10, 11, 13, 15, 16, 19 · ERR-00-403
    # Mục đích: Chứng minh UI-17-06…20 truy cập được và vai không phù hợp thấy 403 đúng.
    Biết STAGING; Playwright, axe-core; U-T90-TA1, SO, AU, VW; U-PA1.
    Khi duyệt từng route `/quan-tri/tro-ly-ai/...` và `/nen-tang/mo-hinh-ai/...` bằng vai phù hợp; chạy axe; chỉ bằng bàn phím.
    Và VW mở các route trên.
    Và nút "Tắt khẩn cấp" ở UI-17-06 và hộp thoại xác nhận.
    Thì 0 lỗi axe mức nghiêm trọng; VW thấy `403`; nút tắt khẩn có xác nhận bằng hộp thoại, đưa tiêu điểm vào ô lý do và thông báo kết quả cho trình đọc màn hình.
