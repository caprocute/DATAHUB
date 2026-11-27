# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-43
Tính năng: TS-20-43 · Giao diện: trạng thái, quyền hiển thị và WCAG 2.2 AA

  @TC-20-227 @P1 @Dương @Âm
  Kịch bản: TC-20-227 Bốn trạng thái của mọi màn: tải, rỗng, lỗi, không có quyền
    # Truy vết: NFR-20-022 · UI-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 · ERR-20-062 · ERR-00-403
    Biết playwright; `U-PA1`, `U-T90-TA`, `U-T90-VW`; chặn API chậm, trả rỗng, `503`, `403` theo màn.
    Khi với từng màn, làm API trả chậm 3 giây
    Và làm API trả danh sách rỗng
    Và làm API trả `503`
    Và mở màn bằng vai không có quyền
    Thì bước 1 khung xương tải, không nhảy bố cục. Bước 2 trạng thái rỗng có hướng dẫn tiếp theo. Bước 3 thông báo lỗi tiếng Việt có mã và nút "Thử lại", không lộ chi tiết kỹ thuật. Bước 4 trang "Không có quyền" (hoặc ẩn mục), không gọi API ghi.

  @TC-20-228 @P1 @Dương @Âm
  Kịch bản: TC-20-228 Nút và mục menu theo quyền; thao tác nguy hiểm gõ lại mã
    # Truy vết: UI-20-02, 03, 08, 09, 10, 12, 14, 15, 18, 19 · BR-20-008, 009 · ERR-20-007, ERR-20-008 · `PERM-20-lifecycle`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-org`, `PERM-20-settings`, `PERM-20-approve`
    Biết `U-PA1`, `U-PA2`, `U-PO`, `U-PAU`, `U-T90-TA`, `U-T90-VW`.
    Khi mỗi vai mở các màn, ghi lại nút ghi hiển thị
    Và mở "Chấm dứt", "Cutover", "Giải thể tổ chức"; để trống ô gõ lại mã
    Và mở đề nghị do chính mình lập bằng `U-PA1`
    Thì bước 1 vai chỉ đọc không thấy nút ghi; PO chỉ thấy "Dừng sóng". Bước 2 nút xác nhận vô hiệu đến khi gõ đúng mã; thiếu lý do hiện `ERR-20-008`. Bước 3 nút "Duyệt" ẩn, nếu gọi tay thì `403` `ERR-20-007`.

  @TC-20-229 @P1 @Dương
  Kịch bản: TC-20-229 WCAG 2.2 AA: bàn phím, tương phản, tiêu điểm, đọc màn hình, co dãn 200 %
    # Truy vết: NFR-20-022 · UI-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22
    Biết playwright với axe-core; NVDA ở STAGING cho ba màn (UI-20-02, 04, 10); trình duyệt Chrome, Firefox.
    Khi quét axe mọi màn ở trạng thái mặc định và có lỗi
    Và duyệt toàn bộ bằng bàn phím: thứ tự Tab, bẫy tiêu điểm hộp thoại, `Esc` đóng
    Và kiểm tương phản chữ ≥ 4,5:1, thành phần ≥ 3:1, phóng 200 % không cuộn ngang
    Và đọc bằng NVDA: nhãn trường, vùng thông báo `aria-live` khi tiến độ saga đổi
    Và kiểm trạng thái không chỉ dựa màu; mục tiêu bấm ≥ 24×24 px
    Thì không vi phạm mức nghiêm trọng hoặc cao của axe; mọi chức năng dùng được bằng bàn phím; thông báo tiến độ được đọc; trạng thái có chữ và biểu tượng.

  @TC-20-230 @P2 @Dương @Âm
  Kịch bản: TC-20-230 Wizard khai báo tenant: kiểm hợp lệ từng bước, giữ bản nháp
    # Truy vết: UI-20-02 · UI-20-09 · FR-20-001, 007 · ERR-20-004, ERR-20-003, ERR-20-011
    Biết `U-PA1`; mã `T93` đã dùng.
    Khi đi 5 bước của UI-20-02, để trống trường bắt buộc rồi bấm "Tiếp"
    Và nhập mã `T90` (đã dùng) rồi sang bước sau
    Và thoát giữa chừng rồi quay lại
    Thì bước 1 lỗi hiện ngay cạnh trường, tiêu điểm về trường lỗi. Bước 2 `ERR-20-003` hiện ở bước mã. Bước 3 bản nháp giữ lại (nếu có), không gửi khi chưa xác nhận.
