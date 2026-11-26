# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-32
Tính năng: TS-04-32 · Truy cập, bàn phím và bề rộng màn hình

  @TC-04-183 @P1 @Truy @cập
  Kịch bản: TC-04-183 Tạo luồng ba chặng chỉ bằng bàn phím
    # Truy vết: NFR-04-015 · FR-04-013 · UI-04-04.
    Biết IE1 mở `tc-trong` v1.
    Khi tab tới bảng thành phần, gõ "log", Enter để thêm vào chặng đang chọn.
    Và dùng phím mũi tên chọn chặng kế tiếp, `A` mở hộp thêm chặng, chọn `setHeader`.
    Và `Enter` mở cấu hình, điền, `Ctrl+S`.
    Và `Shift+F10` mở trình đơn ngữ cảnh, xóa chặng.
    Thì mọi bước làm được không dùng chuột; viền tiêu điểm luôn thấy rõ (tương phản ≥ 3:1); thứ tự tiêu điểm theo thứ tự chặng; trình đọc màn hình đọc "Chặng 3 trên 9, Chuyển đổi, đã cấu hình".

  @TC-04-184 @P1 @Truy @cập
  Kịch bản: TC-04-184 Quét axe-core trên mọi màn UI-04
    # Truy vết: NFR-04-016 · UI-04-01, 02, 03, 04, 05, 06, 07, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21.
    Biết giao diện sáng và tối; nền Liquid Glass bật.
    Khi chạy `@axe-core/playwright` với `wcag22aa` trên từng màn, từng trạng thái ST-01…11.
    Thì không vi phạm "serious" hoặc "critical". Lớp glass chỉ ở điều hướng và lớp nổi; chữ trên nền nội dung đặc đạt tương phản 4,5:1.

  @TC-04-185 @P2 @Truy @cập
  Kịch bản: TC-04-185 Bề rộng màn hình
    # Truy vết: NFR-04-017 · UI-04-04.
    Biết F-HT v4.
    Khi mở trình thiết kế ở 2560, 1280, 1100, 900 px.
    Thì 2560, 1280: đủ ba vùng (bảng thành phần, sơ đồ, Inspector). 1100: bảng thành phần và Inspector tự gập thành ngăn kéo. 900: chỉ xem YAML, banner "Màn hình quá hẹp để thiết kế"; không cuộn ngang trang.

  @TC-04-186 @P3 @Truy @cập
  Kịch bản: TC-04-186 Phóng to 200% và giảm chuyển động
    # Truy vết: NFR-04-016 · UI-04-04, 11.
    Biết trình duyệt phóng 200%; bật `prefers-reduced-motion`.
    Khi mở trình thiết kế và màn chạy thử.
    Thì không mất nội dung hay chức năng; hiệu ứng chạy dọc cạnh khi chạy thử tắt, thay bằng đổi màu tĩnh.
