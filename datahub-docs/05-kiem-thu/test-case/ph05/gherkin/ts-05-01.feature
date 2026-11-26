# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-01
Tính năng: TS-05-01 · Loại kết nối và khai báo kết nối

  @TC-05-001 @P2 @Dương
  Kịch bản: TC-05-001 Liệt kê loại kết nối và lược đồ tham số
    # Truy vết: FR-05-001 · API-05-001, 002 · UI-05-03
    Biết U-T68-IE1; U-T68-TA đã tắt loại `ldap` ở T68.
    Khi `GET /connection-types`.
    Và `GET /connection-types/oauth2-client`.
    Thì bước 1 trả `200`, có đủ các mã ở FRS FR-05-001 (`http-none`, `http-basic`, `http-apikey`, `oauth2-client`, `http-mtls`, `soap-wss`, `jdbc-*`, `db-flow`, `sftp`, `amqp-1`, `smtp`, `cdc-debezium`…); `ldap` có `enabled = false`. Bước 2 trả `paramsSchema` có `tokenUrl`, `clientId`, `scope`, `authMethod`, `secretKeys` gồm `clientSecret`, `privateKeyPem`; `paramsSchema` không chứa khóa nào trong `secretKeys`.

  @TC-05-002 @P1 @Dương
  Kịch bản: TC-05-002 Tạo kết nối REST hợp lệ ở trạng thái Nháp
    # Truy vết: FR-05-004 · API-05-004, 005 · UI-05-03 · UC-05-01 · LGC-BUS-011
    Biết U-T68-IE1; HTTT `HT-NDXP` `ACTIVE`.
    Khi mở UI-05-03, chọn loại REST/HTTP, nhập mã `tc-ndxp-moi`, tên, HTTT `HT-NDXP`, mục đích Chỉ đọc; bấm "Tạo".
    Và `GET /connections/tc-ndxp-moi`.
    Thì bước 1 gọi `POST /connections` trả `201`, `Location`, `ETag`; màn sang bước 3. Bước 2: `status = DRAFT`, `environments` rỗng, `allowedActions` có `updateConnection`, `putEnvironmentParams`; `disabledReasons` không rỗng cho `enableEnvironment`. KT: có (`CONNECTION_CREATE`). EVT: không.

  @TC-05-003 @P1 @Âm
  Kịch bản: TC-05-003 Tạo kết nối sai mã, trùng mã, HTTT không hoạt động, loại tắt
    # Truy vết: FR-05-004 · API-05-004 · ERR-05-002, 003, 004, 005, 012 · BR-05-004
    Biết U-T68-IE1; U-T68-VW; kết nối `tc-cu` đã `RETIRED`.
    Khi `POST /connections` với `connectionCode = "TC_Hoa"`.
    Và `POST /connections` với mã `ndxp-ho-tich`.
    Và `POST /connections` với mã `tc-cu`.
    Và `POST /connections` với `systemCode = "HT-DUNG"` (HTTT `SUSPENDED`).
    Và `POST /connections` với `typeCode = "ldap"`.
    Và U-T68-VW gửi thân hợp lệ.
    Thì bước 1 `400` ERR-05-003 `errors[0].path = connectionCode`. Bước 2, 3 `409` ERR-05-002 (mã đã ngừng dùng cũng không dùng lại). Bước 4 `422` ERR-05-005. Bước 5 `422` ERR-05-004. Bước 6 403-PQ. KT: không.

  @TC-05-004 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-004 Bí mật gửi qua trường tham số bị chặn
    # Truy vết: FR-05-005, 011 · API-05-011 · ERR-05-006 · BR-05-001
    Biết U-T68-IE1; `tc-ndxp-moi` từ TC-05-002.
    Khi `PUT /connections/tc-ndxp-moi/environments/TEST` với `params = {"baseUrl":"https://ndxp.sim.test","auth":"OAUTH2_CLIENT_CREDENTIALS","clientSecret":"DH-CANARY-TC-a1"}`.
    Và lặp với khóa `password`, `token`, `x-api-key` lồng trong `headers`.
    Thì mọi lần trả `422` ERR-05-006, `errors[]` chỉ chứa tên khóa, không chứa giá trị. Không có dòng nào trong `connection_environment` đổi. Mồi sạch với `DH-CANARY-TC-a1`.

  @TC-05-005 @P2 @Dương @Âm
  Kịch bản: TC-05-005 Sửa thông tin chung; mã, loại, HTTT bất biến
    # Truy vết: FR-05-006 · API-05-006 · ERR-05-003, 007 · BR-05-004
    Biết U-T68-IE1, U-T68-IE2; `tc-ndxp-moi`.
    Khi IE1 `PATCH` tên, mô tả, nhãn với `If-Match` đúng.
    Và IE2 `PATCH` với `If-Match` cũ của bước 1.
    Và IE1 `PATCH` với `{"typeCode":"soap"}`, rồi `{"systemCode":"HT-QLVB"}`.
    Thì bước 1 `200`, `ETag` mới, KT: có (`CONNECTION_UPDATE`, có khác biệt), EVT: `connection.changed`. Bước 2 `412` ERR-05-007. Bước 3 `400` ERR-05-003, dữ liệu không đổi.

  @TC-05-006 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-006 Máy chủ ngoài danh sách egress và dải nội bộ cấm
    # Truy vết: FR-05-005 · BR-05-013 · API-05-011 · ERR-05-003
    Biết U-T68-IE1; `tc-ndxp-moi`.
    Khi `PUT …/environments/TEST` với `baseUrl = https://ngoai.example.org`.
    Và với `baseUrl = https://169.254.169.254`, `https://10.96.0.1`, `https://localhost`.
    Thì bước 1 `200` nhưng `warnings[]` có "Cần mở egress cho ngoai.example.org" và có đề nghị bổ sung egress cho TA; bật môi trường bị chặn tới khi egress có. Bước 2 `400` ERR-05-003 rule `ssrf-blocked`.

  @TC-05-146 @P2 @Âm
  Kịch bản: TC-05-146 Loại kết nối không tồn tại; khóa chống trùng dùng lại với thân khác
    # Truy vết: FR-05-001, 004 · API-05-002, 004 · ERR-05-001, 039
    Biết U-T68-IE1.
    Khi `GET /connection-types/khong-co`.
    Và `POST /connections` với `Idempotency-Key: k1`, mã `tc-idem-1`; lặp lại cùng khóa, cùng thân; lặp lại cùng khóa, mã `tc-idem-2`.
    Thì bước 1 404-ẩn. Bước 2 lần một `201`; lần hai trả đúng phản hồi lần một (không tạo thêm); lần ba `422` ERR-05-039. Chỉ có một kết nối `tc-idem-1`.
