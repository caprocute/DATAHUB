# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-37
Tính năng: TS-14-37 · Truy cập, giao diện, truy vết, hợp đồng API

  @TC-14-096 @P2 @Trợ @năng
  Kịch bản: TC-14-096 17 màn hình: axe-core, bàn phím, trạng thái chuẩn
    # Truy vết: NFR-14-023 · UI-14-01, UI-14-02, UI-14-03, UI-14-04, UI-14-05, UI-14-06, UI-14-07, UI-14-08, UI-14-09, UI-14-10, UI-14-11, UI-14-12, UI-14-13, UI-14-14, UI-14-15, UI-14-16, UI-14-17.
    Biết bộ dữ liệu mục 2; trình đọc màn hình NVDA.
    Khi chạy axe-core trên từng màn ở trạng thái rỗng, đang tải, lỗi, có dữ liệu.
    Và duyệt chỉ bằng bàn phím: tab, mở hộp thoại duyệt, chọn dòng.
    Và kiểm tương phản ở lớp kính điều hướng và nền đặc ở bảng dày.
    Thì 0 vi phạm mức nghiêm trọng, tương phản ≥ 4,5:1; thứ tự tab đúng, có bẫy tiêu điểm ở hộp thoại; trạng thái sức khỏe không chỉ dựa vào màu.

  @TC-14-097 @P2 @Dương @Biên
  Kịch bản: TC-14-097 Truy vết 100 % giao dịch, lưu giữ 5 năm, hợp đồng API v1
    # Truy vết: NFR-14-020, 021, 022 · FR-14-049, 052 · API-14-062, 065 · EVT-14-01.
    Biết 1.000 giao dịch qua PH-04; schema sự kiện ở Apicurio.
    Khi đối chiếu `transactionCode`, `traceId` của từng giao dịch với PH-04, PH-13.
    Và kiểm vòng đời lưu giữ: 12 tháng trực tuyến, phần còn lại ở kho WORM.
    Và chạy Schemathesis; thêm trường bắt buộc vào sự kiện.
    Và chạy Pact theo hợp đồng do bên dùng dẫn dắt: PH-04 (luồng gọi cổng quốc gia) và PH-07 (gọi cổng tiếp hợp danh mục dùng chung) viết kỳ vọng, PH-14 xác minh bên cung cấp; NDXP giả lập bằng WireMock sinh từ đặc tả bên cung cấp; sửa trường để làm vỡ kỳ vọng rồi chạy `can-i-deploy`.
    Thì 100 % có đủ ba mã; không xóa siêu dữ liệu trước 5 năm; API chỉ thêm trường tùy chọn; sự kiện đổi không BACKWARD bị Apicurio từ chối; xác minh Pact với PH-04, PH-07 đạt và thay đổi phá kỳ vọng bị `can-i-deploy` chặn.
