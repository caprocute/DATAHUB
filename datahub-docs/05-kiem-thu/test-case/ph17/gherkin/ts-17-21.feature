# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-21
Tính năng: TS-17-21 · Giải thích mã lỗi đang hiển thị

  @TC-17-069 @P1 @Dương
  Kịch bản: TC-17-069 Giải thích mã lỗi ERR có nguyên nhân, cách xử lý, liên kết hướng dẫn
    # Truy vết: FR-17-036, 025 · API-17-113, 116 · BR-17-050 · UI-17-03
    # Mục đích: Chứng minh luồng bấm "Giải thích lỗi này" ở `CMP-Alert`.
    Biết T90 bật `EXPLAIN`; danh mục ERR đã lập chỉ mục có `ERR-04-012`; U-T90-TO; màn hiển thị lỗi `ERR-04-012`.
    Khi TO bấm "Giải thích lỗi này" cạnh mã.
    Và xem thân `POST /explanations/error-codes` và kết quả.
    Và `GET /explanations/{id}`.
    Thì bước 1 bảng bên mở và gửi `errorCode = ERR-04-012` (không có dữ liệu khác). Bước 2 `200`: nguyên nhân, cách xử lý, liên kết hướng dẫn vận hành, trích dẫn dòng danh mục ERR, nhãn "Nội dung do AI tạo, cần kiểm tra lại". Bước 3 lấy lại đúng nội dung.

  @TC-17-070 @P1 @Âm @Chất_lượng
  Kịch bản: TC-17-070 Mã lỗi không có trong danh mục: chưa có mô tả, không bịa
    # Truy vết: FR-17-036 · API-17-113 · BR-17-050 · NFR-17-013
    # Mục đích: Chứng minh BR-17-050.
    Biết danh mục ERR không có `ERR-99-999`; LLM-MOCK được cài sẵn câu trả lời bịa khi không có ngữ cảnh.
    Khi IE `POST /explanations/error-codes` với `ERR-99-999`.
    Và IE gửi `errorCode = "abc"`.
    Thì bước 1 `200` kết quả "chưa có mô tả", không có nguyên nhân suy đoán, không trích dẫn. Bước 2 `422` ERR-17-003 nêu định dạng mã.

  @TC-17-071 @P2 @Âm
  Kịch bản: TC-17-071 Giải thích không vượt quyền, lối vào theo năng lực
    # Truy vết: FR-17-036 · API-17-113 · BR-17-003 · ERR-17-011 · UI-17-03
    # Mục đích: Chứng minh người dùng không có năng lực `EXPLAIN` không thấy nút và bị `403`.
    Biết T90 `EXPLAIN` bật chỉ cho nhóm `TO`; U-T90-VW; màn lỗi.
    Khi VW mở màn có `CMP-Alert` lỗi.
    Và VW `POST /explanations/error-codes`.
    Thì bước 1 không có nút "Giải thích lỗi này". Bước 2 `403` ERR-17-011.
