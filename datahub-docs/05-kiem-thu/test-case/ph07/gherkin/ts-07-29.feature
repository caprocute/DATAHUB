# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-29
Tính năng: TS-07-29 · Khả năng truy cập

  @TC-07-316 @P1 @Truy @cập
  Kịch bản: TC-07-316 Quét axe-core mọi route PH-07
    # Truy vết: NFR-00-040 · UI-07-01…12
    Biết dữ liệu chuẩn; mỗi màn ở trạng thái có dữ liệu và trạng thái lỗi.
    Khi chạy `@axe-core/playwright` với bộ luật `wcag2a`, `wcag2aa`, `wcag22aa`.
    Thì không vi phạm mức "serious" hoặc "critical".

  @TC-07-317 @P1 @Truy @cập
  Kịch bản: TC-07-317 Lưới và cây theo mẫu WAI-ARIA
    # Truy vết: NFR-00-041 · D03-06-PH07 mục 20.1, 20.2
    Biết UI-07-05 bản nháp CAT-BIG; UI-07-11.
    Khi kiểm thuộc tính `role`, `aria-rowcount`, `aria-rowindex`, `aria-level`, `aria-expanded`; điều hướng bằng phím.
    Thì `aria-rowcount` bằng tổng thật; dòng 1.205 có `aria-rowindex = 1206` (tính dòng tiêu đề); mọi phím ở mục 20.1, 20.2 hoạt động.

  @TC-07-318 @P2 @Truy @cập
  Kịch bản: TC-07-318 Khác biệt không chỉ dựa vào màu
    # Truy vết: WCAG 1.4.1 · D03-06-PH07 mục 20.3
    Biết UI-07-07.
    Khi chụp ảnh ở chế độ thang xám; đọc cột Loại bằng cây truy cập.
    Thì mỗi dòng có chữ "Thêm mới", "Đã sửa", "Ngừng dùng", "Phá vỡ"; `<del>`, `<ins>` có văn bản ẩn "Giá trị cũ:", "Giá trị mới:".

  @TC-07-319 @P2 @Truy @cập
  Kịch bản: TC-07-319 Kích thước đích chạm và focus nhìn thấy
    # Truy vết: WCAG 2.5.8, 2.4.11, 2.4.13
    Biết UI-07-01, 05, 07.
    Khi đo kích thước mọi nút; Tab qua toàn trang, chụp vòng focus.
    Thì đích ≥ 24 × 24 px; vòng focus không bị che bởi thanh dính hoặc ngăn kéo glass.

  @TC-07-320 @P1 @Truy @cập
  Kịch bản: TC-07-320 Ba luồng chính với NVDA
    # Truy vết: NFR-00-040…045 · mục 6.4
    Biết NVDA + Firefox; người kiểm thử không nhìn màn hình khi thực hiện.
    Khi thực hiện ba luồng ở mục 6.4.
    Thì hoàn thành cả ba luồng; ghi nhận mọi chỗ NVDA đọc sai hoặc thiếu vào phiếu kết quả mục 6.4.
