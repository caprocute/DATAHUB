# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-36
Tính năng: TS-15-36 · Truy cập, 360 px và trình duyệt

  @TC-15-198 @P1 @Truy @cập
  Kịch bản: TC-15-198 Quét tự động mọi màn
    # Truy vết: NFR-15-014 · UI-15-01…28 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN, U-T68-OR, U-T68-TA; dữ liệu mục 2.
    Khi chạy axe-core trên 28 màn ở trạng thái rỗng, có dữ liệu, lỗi; chế độ sáng, tối, giảm trong suốt.
    Thì 0 vi phạm mức nghiêm trọng hoặc nghiêm trọng cao; mọi ảnh có chữ thay thế; mọi trường có nhãn.

  @TC-15-199 @P1 @Truy @cập
  Kịch bản: TC-15-199 Dùng được ở 360 px
    # Truy vết: NFR-15-014 · UI-15-01…28 · FR-15-009 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết viewport 360×640 và 320 px (zoom 400 %), Chrome và Safari iOS giả lập.
    Khi đi hết luồng: tìm → chi tiết → tài liệu → tạo ứng dụng → cấp credential → thử API.
    Và mở UI-15-05, UI-15-06, UI-15-13, UI-15-26.
    Thì không cuộn ngang trang (bảng, khối mã cuộn trong vùng riêng); mục lục tài liệu thành ngăn kéo; khung thử xếp dọc; hộp thoại bí mật vừa màn hình; vùng chạm ≥ 24×24 px (WCAG 2.2 mục 2.5.8) và nút hành động chính ≥ 44 px; chữ không bị cắt khi phóng 200 %.

  @TC-15-200 @P1 @Truy @cập
  Kịch bản: TC-15-200 Dùng bằng bàn phím
    # Truy vết: NFR-15-014 · UI-15-02, 05, 06, 13 · FR-15-029 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết chỉ bàn phím, không chuột.
    Khi thực hiện luồng của TC-15-199 chỉ bằng bàn phím.
    Thì thứ tự focus hợp lý, có "Bỏ qua tới nội dung", focus nhìn thấy; hộp thoại bí mật bẫy focus và trả focus; khung thử gửi được bằng Ctrl+Enter; không bẫy bàn phím.

  @TC-15-201 @P2 @Truy @cập
  Kịch bản: TC-15-201 Trình đọc màn hình và tương phản
    # Truy vết: NFR-15-014 · UI-15-02, 05, 06, 13 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết NVDA + Firefox, VoiceOver + Safari; nền kính sáng, tối.
    Khi đi luồng chính; nghe bí mật được hiển thị; đọc banner lỗi.
    Thì bí mật được thông báo bằng vùng `aria-live` một lần; trạng thái có chữ, không chỉ màu; tương phản ≥ 4,5:1 trên nền kính; tôn trọng giảm chuyển động.

  @TC-15-202 @P2 @Dương
  Kịch bản: TC-15-202 Ma trận trình duyệt
    # Truy vết: NFR-15-015 · NFR-15-021 · UI-15-01…28 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết chrome, Edge, Firefox, Safari (hai bản gần nhất).
    Khi chạy kịch bản khói E2E (tìm, tài liệu, tạo ứng dụng, cấp credential, thử API) trên từng trình duyệt.
    Thì đạt ở cả 8 bản; nhãn và ngày giờ tiếng Việt, ngày `dd/MM/yyyy`, múi giờ UTC+7.
