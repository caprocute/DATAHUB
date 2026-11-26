# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-36
Tính năng: TS-05-36 · Truy cập và giao diện

  @TC-05-143 @P1 @Truy @cập
  Kịch bản: TC-05-143 Quét tự động truy cập mọi màn
    # Truy vết: NFR-05-014 · UI-05-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17
    Biết U-T68-IE1; dữ liệu mục 2.
    Thì 0 vi phạm mức nghiêm trọng, nghiêm trọng vừa; tương phản chữ ≥ 4,5:1, mã ≥ 7:1.

  @TC-05-144 @P1 @Truy @cập
  Kịch bản: TC-05-144 Đi hết luồng khai báo thao tác ở UI-05-10 chỉ bằng bàn phím
    # Truy vết: NFR-05-014 · UI-05-10 · FR-05-032
    Biết U-T68-IE1; bản nháp `tc-qlvb`; NVDA trên Windows (thủ công).
    Thì hoàn thành được; tiêu điểm luôn thấy rõ; trình đọc màn hình đọc đúng vùng mốc và thông báo lưu, kết quả xem trước; không bẫy tiêu điểm trong khung mã.

  @TC-05-145 @P2 @Truy @cập
  Kịch bản: TC-05-145 Trạng thái không chỉ bằng màu; thu phóng 200 %
    # Truy vết: NFR-05-014 · UI-05-01, 07, 10, 13
    Biết U-T68-TO.
    Thì mọi trạng thái sức khỏe, khác biệt lược đồ có chữ hoặc ký hiệu; UI-05-10 chuyển R4, R5 thành tab trong R3, không cuộn ngang.
