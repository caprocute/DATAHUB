# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-03
Tính năng: TS-04-03 · Tạo luồng từ luồng trống, khuôn, API, YAML

  @TC-04-013 @P1 @Dương
  Kịch bản: TC-04-013 Tạo luồng trống
    # Truy vết: FR-04-003 · API-04-011 · UI-04-03 · UC-04-03 · EVT-04-01 · LGC-BUS-013
    Biết U-T68-IE1; mã `tc-trong`.
    Khi gọi `POST /flows` với `{"code":"tc-trong","name":"Thử luồng trống","workspaceCode":"ho-tich","resourceKind":"ROUTE","origin":"BLANK"}` và `Idempotency-Key`.
    Và gọi `GET /flows/tc-trong/versions/1`.
    Và đếm commit trên kho `dh-flows-t68`.
    Thì bước 1 trả `201`, `ETag`, `status = DRAFT`, `openVersionNo = 1`. Bước 2: YAML có khung chín chặng rỗng với `routeConfigurationId: dh-default-config`, `catalogVersion` bằng catalog hiện hành. Bước 3: Git: không. EVT-04-01 trong outbox cùng giao dịch, khóa `T68:{flowId}`. KT: có (`INT_FLOW_CREATE`).

  @TC-04-014 @P2 @Dương
  Kịch bản: TC-04-014 Tạo luồng từ khuôn có tham số
    # Truy vết: FR-04-003, 025 · API-04-080, 081, 011 · UI-04-19 · UC-04-03
    Biết TPL-REST.
    Khi gọi `GET /templates?resourceKind=ROUTE`.
    Và gọi `GET /templates/tpl-rest-proxy-9-chang`.
    Và gọi `POST /flows` với `origin = TEMPLATE`, `templateCode`, `templateParams = {"path":"/tc/khuon","connection":"CONN-HT","schemaRef":"hotich-yeucau-v1"}`.
    Thì bước 1 có TPL-REST, `scope = PLATFORM`. Bước 3 trả `201`; YAML có `path: /tc/khuon`, tham chiếu `{{conn:CONN-HT}}`; bố cục lấy `previewLayout` của khuôn. `origin = TEMPLATE`, `templateCode` lưu ở luồng.

  @TC-04-015 @P2 @Dương
  Kịch bản: TC-04-015 Tạo luồng từ OpenAPI của API công bố
    # Truy vết: FR-04-003 · API-04-011
    Biết PH-02 stub trả OpenAPI có 3 operation.
    Khi gọi `POST /flows` với `origin = OPENAPI`, `apiRef = "ho-tich-tra-cuu"`.
    Thì `201`; YAML có khối `rest` với 3 operation, mỗi operation một route `direct:` có khung chín chặng; `transport = SYNC`, `exposure = EXTERNAL`.

  @TC-04-016 @P2 @Dương
  Kịch bản: TC-04-016 Tạo luồng từ tệp YAML
    # Truy vết: FR-04-003, 027 · API-04-031, 011
    Biết YAML-OK đổi mã route và đường dẫn sang `tc-`.
    Khi gọi `POST /validation:check` với YAML.
    Và gọi `POST /flows` với `origin = YAML_FILE`, `yaml`.
    Thì bước 1 trả `200`, `errorCount = 0`, không ghi gì (EVT: không). Bước 2 trả `201`; băm chuẩn hóa của định nghĩa đã lưu bằng băm chuẩn hóa của tệp tải lên.

  @TC-04-017 @P1 @Âm @Biên
  Kịch bản: TC-04-017 Mã luồng sai định dạng hoặc trùng
    # Truy vết: FR-04-003 · BR-04-001 · API-04-011 · ERR-04-002, 049
    Biết U-T68-IE1; luồng `tc-da-go` đã gỡ 10 ngày trước; luồng `tc-go-cu` đã gỡ 31 ngày trước.
    Khi tạo với `code = "tra-cuu-ho-tich"`.
    Và tạo với `code = "Tra_Cuu"`, `"ab"`, chuỗi 64 ký tự.
    Và tạo với `code = "tc-da-go"`.
    Và tạo với `code = "tc-go-cu"`.
    Thì bước 1, 3 trả `409` ERR-04-002. Bước 2 trả `400` ERR-04-049 (mẫu `^[a-z][a-z0-9-]{2,62}$`). Bước 4 trả `201` (mã giải phóng sau 30 ngày). Mã trùng với F-T01 ở T01 không bị chặn ở T68 (đã có ở dữ liệu).

  @TC-04-018 @P1 @Âm
  Kịch bản: TC-04-018 Tạo luồng với nội dung không hợp lệ
    # Truy vết: FR-04-003 · BR-04-003 · API-04-011 · ERR-04-008, 009, 010, 027, 033, 039
    Biết YAML-SECRET, YAML-BIG; YAML cú pháp hỏng; YAML Kamelet nhưng `resourceKind = ROUTE`.
    Khi tạo `origin = YAML_FILE` với YAML cú pháp hỏng.
    Và tạo với YAML Kamelet, `resourceKind = ROUTE`.
    Và tạo với YAML-SECRET.
    Và tạo với YAML-BIG.
    Và tạo với `workspaceCode = "khong-co"`.
    Và tạo `origin = TEMPLATE` với `templateCode = "tpl-khong-co"`.
    Thì lần lượt `422` ERR-04-008 (có dòng, cột), `422` ERR-04-009, `422` ERR-04-010 (`findings[].path` trỏ tới URI, `message` không chứa `Abc@12345678`), `413` ERR-04-033, `404` ERR-04-027, `404` ERR-04-039. Không bản ghi nào được tạo. EVT: không.

  @TC-04-019 @P2 @Âm @Biên
  Kịch bản: TC-04-019 Chống trùng khi tạo luồng
    # Truy vết: FR-04-003 · API-04-011 · ERR-04-018
    Biết khóa `tc-idem-0000000001`.
    Khi tạo `tc-idem` với khóa.
    Và gửi lại cùng khóa, cùng thân.
    Và gửi cùng khóa, đổi `name`.
    Và gửi không có `Idempotency-Key`.
    Và gửi khóa 15 ký tự.
    Thì bước 2 trả lại phản hồi `201` đã lưu. Bước 3 trả `409` ERR-04-018. Bước 4 trả `400` ERR-04-049. Bước 5 trả `400` ERR-04-049. Chỉ một luồng được tạo.

  @TC-04-020 @P3 @Âm @Dương
  Kịch bản: TC-04-020 Bắt buộc căn cứ pháp lý cho luồng đối ngoại
    # Truy vết: FR-04-003, 084 · API-04-011 · UI-04-03
    Biết `04.flow.require-legal-basis = true`.
    Khi tạo luồng `origin = OPENAPI` (đối ngoại) không có `legalBasisRef`.
    Và tạo lại có `legalBasisRef = "ND-278-2025"`.
    Thì bước 1 trả `422` ERR-04-009 với finding "Luồng đối ngoại phải khai căn cứ pháp lý". Bước 2 trả `201`. Trên UI-04-03 ô căn cứ hiện dấu bắt buộc khi tham số bật.
