# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-40
Tính năng: TS-13-40 · Truy cập và giao diện

  @TC-13-117 @P1 @Truy @cập
  Kịch bản: TC-13-117 axe-core mọi màn, không lỗi mức A, AA
    # Truy vết: NFR-13-029 · FR-13-031 · UI-13-01…18
    Biết U-T68-SO có đủ quyền; dữ liệu SIT.
    Khi chạy axe-core ở mọi route UI-13-01…18 ở sáng, tối, độ thu phóng 200 %.
    Thì 0 lỗi mức A, AA; tương phản chữ nền kính, nội dung dày dùng nền đặc (ADR-020).

  @TC-13-118 @P2 @Truy @cập
  Kịch bản: TC-13-118 Mười luồng chính bằng bàn phím và NVDA
    # Truy vết: NFR-13-029 · FR-13-020, 026, 028, 031, 047 · UI-13-01, 07, 08, 10, 13
    Biết NVDA; U-T68-TO; U-T68-AU.
    Khi đi các luồng: xem tổng quan, tra log, mở trace, xử lý cảnh báo, tra kiểm toán, xuất bằng chứng.
    Thì hoàn tất không dùng chuột; biểu đồ có bảng thay thế và nhãn chữ; trạng thái không chỉ biểu thị bằng màu; thông báo lỗi đọc được.
