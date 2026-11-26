# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-35
Tính năng: TS-06-35 · Truy cập và giao diện

  @TC-06-149 @P1 @Dương
  Kịch bản: TC-06-149 Luồng người quản lý dữ liệu trên giao diện
    # Truy vết: UI-06-04, 05, 06 · FR-06-028, 029, 030, 037 · NFR-06-017
    # Mục đích: Chứng minh hành trình từ hàng đợi tới quyết định và hợp nhất, trung vị ≤ 60 giây mỗi mục (NFR-06-017).
    Biết 30 mục POSSIBLE_MATCH; DS1.
    Khi mở `/du-lieu/du-lieu-chu/hang-doi`, nhận mục đầu.
    Và quyết định theo bàn phím.
    Và lặp 30 mục, đo thời gian.
    Thì mỗi mục xong không rời trang; trung vị ≤ 60 giây; không chỉ dùng màu để phân biệt mức so sánh.
    # Hậu điều kiện: 30 mục xử lý.

  @TC-06-150 @P2 @Truy @cập
  Kịch bản: TC-06-150 Khả năng truy cập 18 màn hình
    # Truy vết: UI-06-01…18 · FR-06-029
    # Mục đích: Chứng minh axe-core 0 lỗi nghiêm trọng và thao tác bằng bàn phím ở mọi màn.
    Biết STAGING; ba trình duyệt.
    Khi chạy axe ở 18 màn, 4 trạng thái (tải, rỗng, lỗi, có dữ liệu).
    Và duyệt bằng Tab, phím tắt UI-06-05.
    Thì 0 lỗi mức serious, critical; thứ tự focus đúng; nhãn có chữ cho mọi trạng thái màu.
    # Hậu điều kiện: Báo cáo axe.

  @TC-06-151 @P2 @Âm @Bảo @mật
  Kịch bản: TC-06-151 Câu thông báo lỗi và che DLCN trên giao diện
    # Truy vết: UI-06-02, 03, 05, 07, 08, 09, 14 · ERR-06-005, 007, 010, 013, 023, 024, 027, 029, 030, 031, 033, 035, 038, 039, 040, 044, 107
    # Mục đích: Chứng minh 19 câu thông báo của FRS §9.2 hiển thị đúng vị trí và DLCN che mặc định.
    Biết đã gây từng lỗi ở các ca TS-06-02…25.
    Khi với từng mã, gây lỗi trên giao diện, chụp màn.
    Và mở màn chi tiết bản ghi vàng khi không có `PERM-09-unmask`.
    Thì câu và vị trí khớp bảng FRS §9.2 và D03-06-PH06 §5.3, có nút "Sao chép mã truy vết"; `idNumber` che, chỉ hiện khi có quyền và lý do.
    # Hậu điều kiện: Ảnh chụp lưu.
