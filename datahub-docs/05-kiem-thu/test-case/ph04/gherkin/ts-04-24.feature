# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-24
Tính năng: TS-04-24 · Ma trận phân quyền và phạm vi không gian làm việc

  @TC-04-143 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-04-143 Ma trận vai trò × thao tác
    # Truy vết: FR-04-001, 003, 024, 040, 041, 042, 045, 050, 006, 007, 080 · API-04-010, 011, 022, 050, 052, 054, 056, 061, 015, 002, 072.
    Biết mỗi vai trò PA, PO, TA, TO, SO, IE, IA, VW, AU một người dùng; `04.workspace.enforce = false` để chỉ kiểm quyền chức năng.
    Khi với mỗi cặp (vai trò, thao tác) trong bảng ngay sau khối này, gọi API tương ứng trên dữ liệu đúng trạng thái.
    Thì kết quả khớp bảng (✓ thành công, ✗ 403-PQ). Bộ kiểm thử sinh từ D02-08, không viết tay, để lệch ma trận là lỗi kiểm thử.

  @TC-04-144 @P1 @Bảo @mật
  Kịch bản: TC-04-144 Quyền đối tượng không lộ qua danh sách và tìm kiếm
    # Truy vết: FR-04-001, 007 · BR-04-021 · API-04-010, 053.
    Biết `04.workspace.enforce = true`; IE3 chỉ ở WS-DATDAI.
    Khi IE3 gọi `GET /flows?q=ho tich`, `GET /flows?endpoint=/ho-tich/`, `GET /reviews`.
    Và IE3 xem `facets`.
    Thì không phản hồi nào chứa luồng của WS-HOTICH; `facets` chỉ đếm luồng IE3 xem được (không lộ số lượng luồng ẩn).

  @TC-04-145 @P2 @Dương
  Kịch bản: TC-04-145 Giao diện ẩn và giải thích hành động bị khóa
    # Truy vết: FR-04-002 · UI-04-02, 04.
    Biết VW, IE1, IA1 lần lượt mở UI-04-02 của F-HT v4 `DRAFT`.
    Khi so sánh thanh công cụ của ba người.
    Thì hành động hiển thị khớp đúng `allowedActions` do máy chủ trả; hành động có quyền nhưng sai trạng thái hiện dạng khóa kèm tooltip lấy từ `disabledReasons`; giao diện không tự suy luận quyền (kiểm bằng cách sửa phản hồi giả qua `page.route`).
