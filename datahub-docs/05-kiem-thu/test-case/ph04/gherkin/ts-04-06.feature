# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-06
Tính năng: TS-04-06 · Trình thiết kế: bảng thành phần, sơ đồ, cấu hình chặng

  @TC-04-037 @P1 @Dương
  Kịch bản: TC-04-037 Bảng thành phần chỉ hiện thành phần được phép
    # Truy vết: FR-04-012, 080 · BR-04-014 · API-04-070 · UI-04-04 · LGC-TOOL-002.
    Biết chính sách nền cấm `exec`, `ssh`; T68 thu hẹp cấm `ftp`. IE1 mở F-HT v4.
    Khi gọi `GET /catalog`.
    Và gọi lại với `If-None-Match` bằng ETag bước 1.
    Và trên giao diện, gõ "ftp", "exec", "kafka" vào ô tìm của bảng thành phần.
    Và lọc theo vai trò chặng "Gửi đích".
    Thì bước 1: `entries` không có `exec`, `ssh`, `ftp`; `sftp` có `policy = ALLOWED`. Bước 2 trả `304`. Bước 3: "ftp", "exec" ra "Không có thành phần phù hợp" kèm liên kết "Xem chính sách thành phần"; "kafka" ra `kafka` ở nhóm "Hàng đợi bản tin". Bước 4 chỉ còn thành phần producer. Mỗi lần gõ phản hồi < 50 ms (NFR-04-002, đo `performance.now`).

  @TC-04-038 @P1 @Dương
  Kịch bản: TC-04-038 Thao tác sơ đồ bằng chuột
    # Truy vết: FR-04-013 · UI-04-04 · UC-04-04 · LGC-TOOL-003, 004.
    Biết IE1 mở `tc-trong` v1.
    Khi kéo `log` từ bảng thành phần vào giữa chặng `transform` và `enrich`.
    Và kéo `choice` vào sau `route`, thêm hai nhánh `when` và một `otherwise`.
    Và chọn ba chặng bằng Shift + nhấp, nhấn Delete, rồi Ctrl+Z.
    Và nhấn "Tự sắp xếp".
    Và thu phóng bằng Ctrl + cuộn tới 25% và 200%.
    Thì bước 1: chặng chèn đúng vị trí, mũi tên nối lại, YAML cập nhật trong < 100 ms (NFR-04-005). Bước 2: nhánh hiện thành làn có nhãn điều kiện, `otherwise` luôn cuối. Bước 3: xóa rồi hoàn tác khôi phục đúng ba chặng và thuộc tính. Bước 4: bố cục dagre trái sang phải, không chồng khối. Bước 5: ở 25% nhãn chặng ẩn, chỉ còn biểu tượng và màu nhóm; minimap luôn hiện.

  @TC-04-039 @P2 @Âm
  Kịch bản: TC-04-039 Thao tác không hợp lệ trên sơ đồ
    # Truy vết: FR-04-013 · BR-04-002 · UI-04-04.
    Biết IE1 mở `tc-trong` v1 (đối ngoại).
    Khi kéo `kafka` (consumer) vào giữa route như một chặng thường.
    Và kéo thả chặng `otherwise` ra ngoài `choice`.
    Và xóa khối chặng chuẩn `authz`.
    Thì bước 1: vùng thả tô đỏ, tooltip "Thành phần này chỉ dùng làm điểm bắt đầu route"; không thêm. Bước 2: không cho thả. Bước 3: hộp xác nhận "Luồng đối ngoại phải có đủ chín chặng chuẩn. Xóa sẽ làm luồng không gửi duyệt được."; xác nhận thì xóa và bảng Vấn đề có VR-05 mức `WARN` (DESIGN).

  @TC-04-040 @P1 @Dương
  Kịch bản: TC-04-040 Cấu hình chặng bằng biểu mẫu sinh từ catalog
    # Truy vết: FR-04-014 · API-04-071 · UI-04-05 · UC-04-05.
    Biết IE1 mở F-HT v4, chọn chặng gửi đích `http`.
    Khi gọi `GET /catalog/components/http`.
    Và mở UI-04-05 của chặng; mở nhóm "Nâng cao".
    Và đổi `connectTimeout` sang `abc`, rồi `5000`.
    Và nhấn "Khôi phục giá trị gốc" trên trường `followRedirects`.
    Thì bước 1: `properties` có nhóm, kiểu, mặc định, `descriptionVi`. Bước 2: trường bắt buộc có dấu, trường `secret = true` không có ô nhập tự do mà chỉ có "Chọn kết nối" hoặc "Tham chiếu bí mật". Bước 3: `abc` báo "Phải là số nguyên" tại chỗ, không lưu; `5000` lưu. Bước 4: trường về mặc định và bị bỏ khỏi YAML (không ghi giá trị mặc định thừa). Cửa sổ có 154 thuộc tính mở trong < 400 ms (NFR-04-006).

  @TC-04-041 @P3 @Âm
  Kịch bản: TC-04-041 Lược đồ thành phần không có trong catalog
    # Truy vết: FR-04-014 · API-04-071 · ERR-04-035.
    Biết U-T68-IE1.
    Khi gọi `GET /catalog/components/khong-co`.
    Và gọi `GET /catalog/components/http?catalogVersion=0.0.0`.
    Thì cả hai trả `404` ERR-04-035.

  @TC-04-042 @P2 @Âm
  Kịch bản: TC-04-042 Thành phần đã dùng nhưng sau đó bị cấm
    # Truy vết: FR-04-012, 080 · BR-04-014 · UI-04-04 · ERR-04-011.
    Biết `tc-ftp` dùng `sftp`; TA thu hẹp chính sách cấm `sftp`.
    Khi IE1 mở `tc-ftp`.
    Và gửi duyệt.
    Thì bước 1: chặng `sftp` hiện huy hiệu "Không còn được phép" màu cảnh báo, vẫn sửa được thuộc tính. Bước 2 trả `422` ERR-04-009 có finding VR-04 → ERR-04-011.
