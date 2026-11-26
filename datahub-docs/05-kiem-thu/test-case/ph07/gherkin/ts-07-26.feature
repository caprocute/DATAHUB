# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-26
Tính năng: TS-07-26 · Giao diện E2E và yêu cầu dùng chung FR-00

  @TC-07-283 @P1 @Dương
  Kịch bản: TC-07-283 Luồng cập nhật danh mục địa phương theo văn bản mới
    # Truy vết: FR-07-011, 012, 015, 016 · UI-07-01, 02, 05, 06, 07 · LGC-DMDC-009…011
    Biết U-T68-DS-NV, U-T68-DA1; CAT-LH.
    Khi DS-NV tìm "loại hình", mở chi tiết, tạo bản nháp, sửa 2 bản ghi, nhập F-OK10, xem khác biệt, trình.
    Và DA1 vào "Việc của tôi", mở UI-07-07, duyệt và phát hành với ngày hiệu lực hôm sau.
    Thì mỗi bước hiển thị thông báo đúng D03-06-PH07; sau bước 2, UI-07-02 hiện phiên bản mới với nhãn "Hiệu lực từ {ngày}". Không có lỗi trong bảng điều khiển trình duyệt.

  @TC-07-284 @P1 @Dương
  Kịch bản: TC-07-284 Sửa bản ghi trên lưới bằng bàn phím
    # Truy vết: FR-07-018 · UI-07-05
    Biết bản nháp CAT-LH.
    Khi chỉ dùng bàn phím: di chuyển ô bằng mũi tên, F2 sửa tên, Tab sang ô kế, Ctrl+S lưu.
    Thì lưu được; vùng `role="status"` đọc "Đã lưu 1 bản ghi."

  @TC-07-285 @P1 @Âm
  Kịch bản: TC-07-285 Xung đột sửa đồng thời theo từng dòng
    # Truy vết: FR-07-018 · ERR-07-018 · UI-07-05
    Biết hai phiên trình duyệt của DS-NV và TA cùng mở bản nháp.
    Khi cả hai sửa cùng một bản ghi; TA lưu trước; DS-NV lưu sau cùng 3 dòng khác.
    Thì 3 dòng khác của DS-NV lưu được; dòng xung đột hiện dấu ⚠ với ba lựa chọn "Xem khác biệt", "Giữ của tôi", "Lấy bản mới".

  @TC-07-286 @P2 @Dương
  Kịch bản: TC-07-286 URL giữ trạng thái lọc, trang, tab
    # Truy vết: FR-00-021 · UI-07-01, 02
    Biết U-T68-VW.
    Khi lọc nguồn "Tỉnh", sang trang 2, mở danh mục, chọn tab Phiên bản; sao chép URL, mở tab mới.
    Và sửa URL `page=abc`.
    Thì bước 1 tab mới hiển thị đúng trạng thái. Bước 2 trang không lỗi, về trang 1.

  @TC-07-287 @P2 @Dương
  Kịch bản: TC-07-287 Định dạng Việt Nam
    # Truy vết: FR-00-022 · D03-06-PH07 mục 2.3
    Biết CAT-BIG.
    Khi xem số bản ghi, ngày hiệu lực, giá trị thập phân.
    Thì "100.000"; "01/12/2026"; "12,50"; giờ theo Asia/Ho_Chi_Minh.

  @TC-07-288 @P2 @Dương
  Kịch bản: TC-07-288 Khay tác vụ nền và thông báo khi xong
    # Truy vết: FR-00-054, 060 · UI-07-08
    Biết F-100K.
    Khi bắt đầu nhập F-100K, chuyển sang UI-07-01.
    Thì khay "1 tác vụ nền" cập nhật tiến độ; khi `VALIDATED`, có thông báo kèm liên kết quay lại bước 3 của trình hướng dẫn.

  @TC-07-289 @P1 @Dương
  Kịch bản: TC-07-289 Trình hướng dẫn nhập: ghép cột và khuôn Aita
    # Truy vết: FR-07-021, 022 · UI-07-06 · LGC-DMDC-005
    Biết F-AITA-X.
    Khi tải F-AITA-X ở chế độ tạo danh mục.
    Thì giao diện nhận dạng "Khuôn Aita", điền sẵn tên danh mục từ ô A2, đề xuất ghép cột từ dòng 4; người dùng sửa được trước khi xác nhận.

  @TC-07-290 @P2 @Âm
  Kịch bản: TC-07-290 Lỗi máy chủ hiển thị đúng thông điệp
    # Truy vết: D03-06-PH07 mục 5.3 · ERR-07-047
    Biết máy chủ giả lập (Prism) trả `503` `ERR-07-047`, `500` không mã.
    Khi tải UI-07-01 với hai phản hồi lỗi.
    Thì `503`: thông điệp tiếng Việt và nút "Thử lại"; `500`: thông điệp chung kèm mã theo dõi `traceId` để báo hỗ trợ; không hiện ngăn xếp lỗi.

  @TC-07-291 @P2 @Truy @cập
  Kịch bản: TC-07-291 Giảm trong suốt và tương phản cao
    # Truy vết: NFR-00-043 · D03-06-PH07 mục 20.5
    Biết playwright giả lập `prefers-reduced-transparency: reduce`, `prefers-reduced-motion: reduce`, `forced-colors: active`.
    Khi chụp UI-07-01, 05, 07 ở mỗi chế độ.
    Thì không còn `backdrop-filter`; mọi thông tin vẫn đọc được; ảnh khớp ảnh chuẩn đã duyệt.

  @TC-07-292 @P2 @Hiệu @năng
  Kịch bản: TC-07-292 Hiệu năng giao diện sửa 1.000 dòng
    # Truy vết: NFR-00-005 · UI-07-05
    Biết bản nháp CAT-BIG; máy thử 4 nhân, 8 GB.
    Khi mở UI-07-05, cuộn hết 1.000 dòng đầu, sửa 20 ô.
    Thì LCP ≤ 2,5 giây; INP ≤ 200 ms; không có khung hình dài quá 200 ms khi cuộn.
