# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-23
Tính năng: TS-18-23 · Cấu hình quy tắc thông báo theo sự kiện

  @TC-18-078 @P1 @Dương @Lũy_đẳng
  Kịch bản: TC-18-078 Quy tắc EVT-02-04 sang mẫu và vai TA, sự kiện lặp chỉ gửi một lần
    # Truy vết: FR-18-039 · API-18-099, 100, 101 · BR-18-028 · UI-18-11
    # Mục đích: Chứng minh BR-18-028: thông báo từ quy tắc dùng khóa `eventId:ruleId`, sự kiện trùng không gửi lại.
    Biết T90; U-T90-TA1; `TPL-API-DUYET` `ACTIVE`; WireMock PH-02 phát EVT-02-04.
    Khi TA1 `POST /notification-rules` sự kiện EVT-02-04, điều kiện `visibility = PUBLIC`, mẫu `TPL-API-DUYET`, người nhận `ROLE:TA`.
    Và phát một EVT-02-04 hai lần cùng `eventId`.
    Và TA1 `PATCH /notification-rules/{ruleId}` tắt quy tắc, phát sự kiện mới.
    Thì bước 1 `201`. Bước 2 đúng một thông báo mỗi người nhận. Bước 3 `200`, không thông báo mới.

  @TC-18-079 @P2 @Âm @Chịu_lỗi
  Kịch bản: TC-18-079 Sự kiện chưa tiêu thụ, mẫu chưa ACTIVE, điều kiện sai, bộ tiêu thụ lỗi
    # Truy vết: FR-18-039 · API-18-100 · ERR-18-003, 041, 045, 124
    # Mục đích: Chứng minh quy tắc chỉ tạo cho sự kiện có trong bảng 9.3b của FRS và lỗi tiêu thụ đi vào DLQ của PH-18.
    Biết T90; `TPL-DRAFT` nháp.
    Khi tạo quy tắc cho EVT-03-01.
    Và tạo quy tắc dùng `TPL-DRAFT`.
    Và tạo quy tắc có điều kiện `visibility ==`.
    Và làm bộ xử lý quy tắc lỗi năm lần với một EVT-02-04.
    Thì bước 1 `422` ERR-18-045. Bước 2 `409` ERR-18-041. Bước 3 `400` ERR-18-003. Bước 4 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.
