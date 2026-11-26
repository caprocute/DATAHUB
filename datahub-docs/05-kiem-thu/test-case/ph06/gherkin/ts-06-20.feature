# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-20
Tính năng: TS-06-20 · Hoàn tác thao tác trên bản ghi vàng

  @TC-06-086 @P1 @Dương
  Kịch bản: TC-06-086 Hoàn tác hợp nhất và tách có cập nhật nguồn xen giữa
    # Truy vết: FR-06-039 · BR-06-005, 024 · API-06-060 · EVT-06-03, 04 · PERM-06-merge
    # Mục đích: Chứng minh tiêu chí chấp nhận 5: hợp nhất rồi hoàn tác, tách rồi hoàn tác khôi phục đúng trạng thái trước.
    Biết hợp nhất ca merge-manual; sau đó `HT-YTE` gửi cập nhật `phone`.
    Khi `POST /operations/{opId}:undo` thao tác hợp nhất.
    Và tách một bản ghi rồi `undo` thao tác tách.
    Và so thuộc tính, xref với ảnh chụp trước.
    Thì bản ghi bị gộp `ACTIVE`, xref về chỗ cũ, cập nhật `phone` đến sau vẫn được áp; thao tác gốc `UNDONE`, thao tác `UNDO` mới ghi trỏ gốc, lịch sử không xóa. Hoàn tác hợp nhất phát EVT-06-04, hoàn tác tách phát EVT-06-03. KT: có (undo).
    # Hậu điều kiện: Trạng thái như trước các thao tác.

  @TC-06-087 @P1 @Âm
  Kịch bản: TC-06-087 Thao tác phụ thuộc chưa xác nhận
    # Truy vết: FR-06-039 · API-06-060 · ERR-06-033
    # Mục đích: Chứng minh hoàn tác bị chặn khi có thao tác thủ công phụ thuộc, theo FR-06-039.
    Biết thao tác O1 hợp nhất, sau đó O2 `MANUAL_EDIT` trên bản ghi.
    Khi `undo` O1 với `confirmDependents = false`.
    Và `undo` O1 với `confirmDependents = true`.
    Thì bước 1 `409` ERR-06-033 liệt kê 1 thao tác phụ thuộc. Bước 2 hoàn tác cả chuỗi.
    # Hậu điều kiện: O1, O2 `UNDONE`.

  @TC-06-088 @P1 @Biên @Âm
  Kịch bản: TC-06-088 Hoàn tác quá hạn chuyển DA duyệt
    # Truy vết: FR-06-039 · BR-06-024 · API-06-060, 061 · ERR-06-005, 034
    # Mục đích: Chứng minh quá `06.undo.window-days` cần DA khác duyệt, theo BR-06-024.
    Biết T92 (30 ngày); thao tác cách 29 và 31 ngày.
    Khi `undo` thao tác 29 ngày.
    Và `undo` thao tác 31 ngày bằng DS1.
    Và DS1 tự duyệt rồi DA1 duyệt.
    Thì bước 1 áp ngay. Bước 2 `403` ERR-06-034, tạo đề nghị chờ DA. Bước 3 DS1 `403` ERR-06-005; DA1 áp.
    # Hậu điều kiện: Một thao tác quá hạn được hoàn tác.
