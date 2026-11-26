# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-35
Tính năng: TS-10-35 · Truy cập và giao diện

  @TC-10-155 @P1 @Truy @cập
  Kịch bản: TC-10-155 Quét tự động truy cập mọi màn
    # Truy vết: UI-10-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
    # Mục đích: Chứng minh mọi màn UI-10 không có vi phạm truy cập khi quét tự động.
    Biết U-T68-TA; dữ liệu mục 2.
    Khi chạy axe-core trên mọi màn, mọi trạng thái chính (rỗng, có dữ liệu, lỗi, đang tải), chế độ sáng, tối, giảm trong suốt.
    Thì 0 vi phạm mức nghiêm trọng và nghiêm trọng vừa; tương phản chữ ≥ 4,5:1, tên topic, mã ≥ 7:1 trên nền đặc.
    # Hậu điều kiện: Dữ liệu không đổi.

  @TC-10-156 @P1 @Truy @cập
  Kịch bản: TC-10-156 Đăng ký nhận sự kiện và duyệt chỉ bằng bàn phím
    # Truy vết: UI-10-11, 13 · FR-10-035, 037
    # Mục đích: Chứng minh màn dùng được bằng bàn phím và trình đọc màn hình, theo FR-10-035 (Đề nghị subscription).
    Biết U-T68-IE1, U-T68-IA1; NVDA trên Windows (thủ công).
    Khi đi hết trình hướng dẫn UI-10-11 (chọn topic, chế độ, URI, xác minh, tham số, gửi), rồi duyệt ở UI-10-13 không dùng chuột.
    Thì hoàn thành được; tiêu điểm luôn thấy; kết quả xác minh endpoint, lỗi trường được đọc qua vùng `aria-live`; không bẫy tiêu điểm trong khung soạn lược đồ.
    # Hậu điều kiện: Dữ liệu không đổi.

  @TC-10-157 @P2 @Truy @cập
  Kịch bản: TC-10-157 Sơ đồ kết nối có phương án thay thế dạng bảng
    # Truy vết: UI-10-14 · FR-10-058
    # Mục đích: Chứng minh sơ đồ kết nối có phương án thay thế dạng bảng cho người dùng trình đọc màn hình, theo FR-10-058 (Sơ đồ kết nối tương tác).
    Biết U-T68-VW; P-DKKD.
    Khi dùng Tab và phím mũi tên đi qua các nút; bật chế độ "Xem dạng bảng".
    Thì mỗi nút, cạnh có nhãn đọc được (loại, mã, trạng thái, lag); bảng thay thế liệt kê đủ cạnh với cùng thông tin; trạng thái lag không chỉ bằng màu.
    # Hậu điều kiện: Dữ liệu không đổi.

  @TC-10-158 @P2 @Truy @cập
  Kịch bản: TC-10-158 Thu phóng 200 % và trạng thái không chỉ bằng màu
    # Truy vết: UI-10-05, 12, 15, 17
    # Mục đích: Chứng minh giao diện dùng được khi thu phóng 200 % và trạng thái không chỉ truyền bằng màu.
    Biết U-T68-TO.
    Khi bật mô phỏng mù màu; thu phóng 200 % ở 1280 px và ở 390 px.
    Thì mọi `alertState`, trạng thái topic, mục DLQ có chữ hoặc ký hiệu; bảng chuyển dạng thẻ ở 390 px, không cuộn ngang trang.
    # Hậu điều kiện: Dữ liệu không đổi.
