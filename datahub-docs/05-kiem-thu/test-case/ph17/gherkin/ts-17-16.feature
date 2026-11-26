# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-16
Tính năng: TS-17-16 · Mở bảng bên trợ lý, ngữ cảnh màn hình, câu hỏi gợi ý và hỏi từ CommandPalette

  @TC-17-050 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-050 Mở bảng bên với ngữ cảnh màn hình đúng và không mang giá trị dữ liệu
    # Truy vết: FR-17-022 · API-17-090, 103, 092 · BR-17-032 · UI-17-01
    # Mục đích: Chứng minh BR-17-032 và hành vi `role="complementary"` của UI-17-01.
    Biết T90 bật; IE đã xác nhận điều khoản; ở route `/tich-hop/luong/LUONG-01` có bảng dữ liệu chứa canary `DH-CANARY-ngucanh`.
    Khi IE bấm "Trợ lý" trên thanh trên.
    Và xem thân `POST /screen-contexts:resolve` và `POST /conversations`.
    Và thu hẹp cửa sổ dưới `bp-xl`.
    Và gửi câu hỏi "luồng này làm gì" và đọc thân yêu cầu.
    Thì bước 1 bảng bên rộng 400px nền `glass-chrome`, thân hội thoại nền đặc, `role="complementary"`, `aria-label="Trợ lý AI"`. Bước 2 ngữ cảnh chỉ có `route`, `objectId = LUONG-01`, `errorCode` (nếu có), `tab`; không có giá trị dữ liệu, canary không xuất hiện ở bất kỳ yêu cầu mạng nào. Bước 3 bảng thành `CMP-Drawer`. Bước 4 câu trả lời nhận biết `LUONG-01` qua ngữ cảnh.

  @TC-17-051 @P1 @Âm
  Kịch bản: TC-17-051 Ngữ cảnh không hợp lệ, tenant tắt thì ẩn nút
    # Truy vết: FR-17-022, 029 · API-17-103, 090, 001 · ERR-17-052, ERR-17-008 · UI-17-01
    # Mục đích: Chứng minh từ chối ngữ cảnh lạ và ẩn lối vào khi tắt.
    Biết T90 bật; U-T90-IE; T93 tắt.
    Khi IE `POST /screen-contexts:resolve` với ngữ cảnh có trường `rows` chứa mảng giá trị.
    Và IE `POST /screen-contexts:resolve` với route không thuộc danh sách.
    Và IE ở T93 mở thanh trên, mở CommandPalette và gọi `GET /status`.
    Thì bước 1 `422` ERR-17-052 (trường lạ). Bước 2 `422` ERR-17-052. Bước 3 không có nút "Trợ lý", nhóm "Hỏi trợ lý AI" không có ở CommandPalette, `POST /conversations` `403` ERR-17-008.

  @TC-17-052 @P3 @Dương @Âm
  Kịch bản: TC-17-052 Câu hỏi gợi ý theo màn và vai trò, thêm sửa câu hỏi mẫu
    # Truy vết: FR-17-028 · API-17-100, 101, 102 · BR-17-040 · UI-17-01
    # Mục đích: Chứng minh BR-17-040: gợi ý lấy từ danh mục, không sinh bằng mô hình, chỉ năng lực đang bật.
    Biết T90 bật `SEARCH`, `MAPPING` tắt; câu hỏi mẫu: 3 cho route trình ánh xạ (năng lực `MAPPING`), 4 cho `/danh-muc`; U-T90-IE, U-T90-VW, U-T90-TA1.
    Khi IE ở `/danh-muc` `GET /suggested-questions`.
    Và IE ở trình ánh xạ `GET /suggested-questions`.
    Và TA1 `POST /suggested-questions` thêm câu hỏi; `PUT` ngừng câu hỏi; VW `POST /suggested-questions`.
    Và quan sát nhật ký gọi mô hình khi lấy gợi ý.
    Thì bước 1 4 chip. Bước 2 không có chip `MAPPING` (năng lực tắt). Bước 3 TA1 `201`, `200`; VW `403` ERR-00-403. Bước 4 không có lời gọi mô hình nào.

  @TC-17-053 @P2 @Dương @Biên
  Kịch bản: TC-17-053 Hỏi từ CommandPalette chuyển chữ vào ô nhập, không tự gửi, không tính lượt
    # Truy vết: FR-17-029 · BR-17-041 · UI-17-01
    # Mục đích: Chứng minh BR-17-041.
    Biết T90 bật; IE đã xác nhận điều khoản; `17.quota.user-turns-per-day = 200`.
    Khi IE bấm Ctrl+K, chọn nhóm "Hỏi trợ lý AI", gõ "API tra cứu hộ gia đình".
    Và kiểm ô nhập của bảng bên và số lượt còn lại (`GET /usage/me`).
    Và bấm "Gửi".
    Thì bước 2 bảng bên mở, ô nhập chứa đúng chữ đã gõ, không dữ liệu khác, chưa có lời gọi mô hình, số lượt không đổi. Bước 3 `200` và số lượt giảm 1.
