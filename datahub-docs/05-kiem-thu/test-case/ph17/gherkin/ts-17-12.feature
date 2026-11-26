# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-12
Tính năng: TS-17-12 · Khai báo nguồn tri thức và kiểm mức phân loại trước khi lập chỉ mục

  @TC-17-037 @P1 @Dương @Âm
  Kịch bản: TC-17-037 Khai báo nguồn tri thức hợp lệ, sai loại, trùng mã
    # Truy vết: FR-17-015 · API-17-062, 063, 064, 065, 066, 067 · BR-17-025 · ERR-17-041, 042 · EVT-17-13 · UI-17-08
    # Mục đích: Chứng minh bảy loại nguồn và từ chối loại lạ hoặc trùng.
    Biết T90 bật; U-T90-DS, U-T90-TA1; PH-02 có 40 API mẫu.
    Khi DS `POST /knowledge/sources` `type = API_SPEC`, `code = SRC-API`.
    Và DS `POST` với `type = EXCEL_FILE`.
    Và DS `POST` lại `code = SRC-API`.
    Và DS `POST /knowledge/sources/{id}:pause` rồi `:resume`.
    Và U-T90-VW `POST /knowledge/sources`.
    Thì bước 1 `201`, KT: có, EVT: `assist.source.state-changed`. Bước 2 `422` ERR-17-041. Bước 3 `409` ERR-17-042. Bước 4 `200` hai lần, nguồn tạm dừng không lập chỉ mục. Bước 5 `403` ERR-00-403 (thiếu `PERM-17-knowledge`).

  @TC-17-038 @P1 @Bảo_mật @Âm @Dương
  Kịch bản: TC-17-038 Chỉ PUBLIC, INTERNAL được lập chỉ mục; RESTRICTED, SENSITIVE, STATE_SECRET bị bỏ qua
    # Truy vết: FR-17-016, 015 · API-17-070, 071 · BR-17-026 · ERR-17-043 · UI-17-08
    # Mục đích: Chứng minh AC-17-06: không có đoạn nào ở mức cao hơn `INTERNAL` trong chỉ mục.
    Biết PH-09 WireMock trả mức: 10 API `PUBLIC`, 10 `INTERNAL`, 5 `RESTRICTED`, 5 `SENSITIVE`, 2 có nhãn `STATE_SECRET`; nguồn `SRC-API`.
    Khi DS `POST /knowledge/sources/{id}:check-class`.
    Và DS `POST /knowledge/sources/{id}:reindex`; chờ xong.
    Và truy vấn bảng `knowledge_chunk` theo `source_id` và đếm theo `class_level`.
    Và DS `GET /knowledge/classification-skips`.
    Thì bước 1 báo 20 đối tượng đủ điều kiện, 12 bị bỏ qua. Bước 2 `DocumentIndexStatus` 20 `INDEXED`, 12 `SKIPPED_CLASS`. Bước 3 chỉ có `PUBLIC`, `INTERNAL`; 0 đoạn của đối tượng `RESTRICTED`, `SENSITIVE`, `STATE_SECRET`. Bước 4 danh sách 12 đối tượng với lý do mức. Khai báo nguồn chỉ chứa dữ liệu mức cao thì `422` ERR-17-043.

  @TC-17-039 @P1 @Chịu_lỗi @Bảo_mật
  Kịch bản: TC-17-039 PH-09 không khả dụng hoặc không xác định được mức thì không lập chỉ mục
    # Truy vết: FR-17-016 · BR-17-026 · ERR-17-049, 009 · NFR-17-015
    # Mục đích: Chứng minh đóng an toàn: tài liệu mới `PENDING`, đối tượng không rõ mức bị bỏ qua.
    Biết T94; PH-09 trả `503`; PH-09 trả mức rỗng cho 3 đối tượng ở lượt khác.
    Khi tạo 5 API mới ở PH-02 khi PH-09 `503`; chờ sự kiện lập chỉ mục.
    Và khi PH-09 phục hồi nhưng trả mức rỗng cho 3 API, lập lại chỉ mục.
    Và gửi câu hỏi tìm dịch vụ liên quan 5 API mới.
    Thì bước 1 5 tài liệu `PENDING`, ghi ERR-17-009 vào lượt, không có đoạn mới, các tài liệu đã có giữ nguyên. Bước 2 3 đối tượng `SKIPPED_CLASS` ghi ERR-17-049, 2 đối tượng còn lại `INDEXED`. Bước 3 trả "không tìm thấy" cho 3 API bị bỏ qua.
