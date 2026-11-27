# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-01
Tính năng: TS-18-01 · Đăng ký lược đồ tham số và đọc tham số có bộ đệm

  @TC-18-001 @P1 @Dương
  Kịch bản: TC-18-001 Phân hệ chủ đăng ký lược đồ `02.` rồi phân hệ khác đọc lô có ETag
    # Truy vết: FR-18-001, 002 · API-18-027, 028, 029, 001, 002, 003 · BR-18-001, 002 · EVT-18-01 · UI-18-08
    # Mục đích: Chứng minh đăng ký lược đồ của không gian tên được cấp thành công, giá trị mặc định có hiệu lực ngay và đọc lô trả `ETag` để bên gọi dùng `304`.
    Biết T90; S-PH02 có `ops:param-register`, `ops:param-read`; lược đồ `SCH-02-V1` gồm 6 khóa (`02.review.sla-days` kiểu INT miền 1…30 mặc định 5, có một khóa ★); U-T90-TA1.
    Khi S-PH02 `PUT /ops/internal/v1/param-namespaces/02./schema` với `SCH-02-V1`, kèm `Idempotency-Key`.
    Và S-PH02 `POST /ops/internal/v1/params:batch-get` cho T90 với 6 khóa vừa đăng ký.
    Và S-PH02 gọi lại bước 2 kèm `If-None-Match` bằng `ETag` vừa nhận.
    Và S-PH02 `GET /ops/internal/v1/params/T90/02.` để lấy ảnh chụp không gian tên.
    Và U-T90-TA1 `GET /param-definitions?ns=02.` và mở UI-18-08.
    Thì bước 1 `200`, không gian tên `02.` có 6 khóa, chủ sở hữu `PH-02`; EVT-18-01 phát với `scope = SCHEMA`, không mang giá trị. Bước 2 `200`, mỗi khóa có `value`, `source = DEFAULT`, `version`; có `ETag`. Bước 3 `304`, không có thân. Bước 4 `200` với cùng `ETag`. Bước 5 thấy 6 khóa, khóa ★ có biểu tượng khóa, cột mức `TENANT`.

  @TC-18-002 @P1 @Âm
  Kịch bản: TC-18-002 Đăng ký không gian tên không thuộc mình, lược đồ sai và lược đồ xung đột
    # Truy vết: FR-18-001 · API-18-027 · BR-18-001, 002 · ERR-18-003, 016, 017
    # Mục đích: Chứng minh BR-18-001 không có đường vòng: phân hệ không ghi được lược đồ của phân hệ khác, không lưu được `19.*` và lược đồ mới không làm hỏng giá trị đang dùng.
    Biết T90, T91 đã có `02.review.sla-days = 20` từ TC trước; S-PH02, S-PH04 (scope `ops:param-register`).
    Khi S-PH04 `PUT /ops/internal/v1/param-namespaces/02./schema`.
    Và S-PH02 gửi lược đồ có khóa kiểu `INTEGER` (không có trong danh mục kiểu) và khóa thiếu `default`.
    Và S-PH02 gửi `SCH-02-V2` thu miền `02.review.sla-days` về 1…10.
    Và S-PH02 `PUT /ops/internal/v1/param-namespaces/19./schema`.
    Thì bước 1 `403` ERR-18-017. Bước 2 `400` ERR-18-003, thân nêu từng khóa lỗi. Bước 3 `409` ERR-18-016, chi tiết liệt kê 2 tenant (T90, T91) đang dùng giá trị ngoài miền mới; lược đồ giữ `SCH-02-V1`. Bước 4 `403` ERR-18-017 vì `19.*` do PH-19 tự giữ. Không có EVT-18-01 nào phát ở các bước.

  @TC-18-003 @P2 @Âm @Biên
  Kịch bản: TC-18-003 Đọc khóa không tồn tại và vượt giới hạn tần suất đọc
    # Truy vết: FR-18-002 · API-18-005, 028 · BR-18-007 · ERR-18-001, 010
    # Mục đích: Chứng minh đọc tham số trả lỗi rõ khi khóa chưa có và giới hạn tần suất bảo vệ PH-18 mà không làm phân hệ gọi mất giá trị đệm.
    Biết T90; S-PH02; giới hạn tần suất đọc giả định 50 yêu cầu mỗi giây cho mỗi danh tính ở môi trường TEST.
    Khi U-T90-TA1 `GET /params/02.khong-co`.
    Và S-PH02 `POST /ops/internal/v1/params:batch-get` có một khóa lạ lẫn trong 5 khóa đúng.
    Và S-PH02 gửi 80 yêu cầu đọc lô trong một giây.
    Và kiểm bộ đệm `dh-ops-client` của S-PH02 sau bước 3.
    Thì bước 1 `404` ERR-18-001. Bước 2 `200`, 5 khóa có giá trị, khóa lạ nằm ở `missing[]`. Bước 3 có yêu cầu nhận `429` ERR-18-010 kèm `Retry-After`. Bước 4 thư viện tiếp tục dùng bản đệm, không có lỗi ở phía PH-02.

  @TC-18-004 @P1 @Dương
  Kịch bản: TC-18-004 Đổi tham số phát EVT-18-01 trong 5 giây và mọi bản sao dùng giá trị mới trong 60 giây
    # Truy vết: FR-18-006, 003 · EVT-18-01, 03 · BR-18-006 · NFR-18-005 · UI-18-24
    # Mục đích: Chứng minh BR-18-006: commit giá trị phát sự kiện ≤ 5 giây, bộ đệm phía phân hệ làm mới ≤ `18.param.cache-ttl-seconds`, sự kiện không mang giá trị khóa ★.
    Biết T90; ba bản sao của DU giả lập dùng `dh-ops-client` đọc `02.review.sla-days`; đồng hồ thật; consumer `kcat` trên `t90.ops.param.changed.v1`.
    Khi U-T90-TA1 `PUT /params/02.review.sla-days` giá trị 7, lý do 20 ký tự, `If-Match`.
    Và ghi thời điểm commit, thời điểm EVT-18-01 xuất hiện ở Kafka và thời điểm từng bản sao báo phiên bản đệm mới.
    Và đổi một khóa ★ đã duyệt (TC ở TS-18-03) và đọc thân EVT-18-01.
    Và bật cờ `ff.ph02.tim-kiem-moi` và đọc EVT-18-03.
    Thì bước 2 sự kiện ≤ 5 giây sau commit, cả ba bản sao dùng giá trị 7 ≤ 60 giây. Bước 3 thân sự kiện có `ns`, `key`, `version`, `scope`, `changedBy`, không có trường giá trị. Bước 4 EVT-18-03 có `flagKey`, `enabled`, `owner`, `retireBy`. Không bản sao nào cần khởi động lại.

  @TC-18-005 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-005 Kafka chậm thì EVT-18-01 nằm ở outbox, bộ đệm hết hạn tự đọc lại; bộ tiêu thụ lỗi vào DLQ PH-18
    # Truy vết: FR-18-006, 002 · BR-18-006, 007 · ERR-18-124 · EVT-18-01
    # Mục đích: Chứng minh FR-18-006 không mất thay đổi khi đường sự kiện gián đoạn: giá trị đã commit vẫn tới mọi bản sao nhờ hết hạn đệm, sự kiện gửi bù từ outbox, lỗi xử lý sự kiện của chính PH-18 đi vào DLQ.
    Biết T94; Chaos Mesh làm trễ Kafka 3 phút; ba bản sao DU giả lập dùng `dh-ops-client` với `18.param.cache-ttl-seconds = 60`.
    Khi làm trễ Kafka, U-T94-TA1 đổi `02.review.sla-days` thành 9.
    Và đo thời điểm từng bản sao dùng giá trị 9.
    Và bỏ trễ Kafka, đọc topic `t94.ops.param.changed.v1`.
    Và làm bộ tiêu thụ EVT-18-01 nội bộ của PH-18 (làm mới đệm màn tham số) lỗi năm lần.
    Thì bước 2 mọi bản sao dùng giá trị 9 trong ≤ 60 giây nhờ hết hạn đệm và đọc lại có `ETag`. Bước 3 đúng một EVT-18-01 được gửi bù từ outbox, không trùng. Bước 4 inbox `FAILED`, ghi ERR-18-124, mục DLQ nguồn `PH18_INBOX`.
