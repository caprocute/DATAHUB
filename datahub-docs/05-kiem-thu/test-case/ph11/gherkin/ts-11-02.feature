# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-02
Tính năng: TS-11-02 · Thiết kế BPMN, thuộc tính bước, kiểm tra tĩnh và chạy thử

  @TC-11-010 @P1 @Dương
  Kịch bản: TC-11-010 Khóa soạn, danh mục phần tử và lưu sơ đồ
    # Truy vết: FR-11-003 · API-11-010, 012, 013, 028 · UI-11-04 · BR-11-005 · PERM-11-model
    Biết v4 `DRAFT` của `M-KS`; IE1, IE2; `11.designer.lockMinutes = 30`.
    Khi IE1 gọi `POST /versions/4:lock`
    Và IE1 gọi `GET /element-catalog`
    Và IE1 kéo thả một service task, lưu bằng `PUT /versions/4/bpmn` kèm `If-Match`; giao diện tự lưu sau `11.designer.autosaveSeconds` giây
    Và IE1 gọi `:unlock`, IE2 gọi `:lock`
    Thì bước 1 `200`, `lockOwner = IE1`, `lockUntil` sau 30 phút; `:lock` lần nữa của IE1 làm mới `lockUntil`. Bước 2 liệt kê nhóm phần tử hỗ trợ, không có script task. Bước 3 `200`, `checksum` mới, `validationSummary`. Bước 4 hai lệnh `200`.

  @TC-11-011 @P1 @Âm
  Kịch bản: TC-11-011 Lưu lệch ETag, XML sai, khóa người khác, quyền xem
    # Truy vết: FR-11-003 · API-11-010, 012, 136 · EVT-11-20 · ERR-11-004, 008, 009, 016 · ERR-00-403
    Biết IE1 đang giữ khóa v4; IE2, VW.
    Khi IE1 `PUT /bpmn` với `If-Match` cũ
    Và IE1 `PUT /bpmn` với `X-SAI`
    Và IE1 `PUT /bpmn` với `X-LON`
    Và IE2 `PUT /bpmn` khi IE1 đang giữ khóa
    Và VW `POST :lock` và `GET /versions/4`
    Và IE2 `POST :request-lock`, rồi IE1 `:lock` lại
    Thì bước 1 `409` ERR-11-004. Bước 2 `400` ERR-11-008. Bước 3 `413` ERR-11-009. Bước 4 `409` ERR-11-016, nêu người đang giữ khóa. Bước 5 `403` ERR-00-403 rồi `200` xem được. Bước 6 `200`, IE1 nhận thông báo, khóa không tự nhả, `lockUntil` dời.

  @TC-11-012 @P1 @Dương
  Kịch bản: TC-11-012 Cấu hình thuộc tính service task, user task, timer, cổng
    # Truy vết: FR-11-004 · API-11-011 · UI-11-04 · BR-11-002, 003, 008, 019, 034
    Biết v4 `DRAFT`; ý định `capTheBHYT` `ACTIVE`; biểu mẫu `BIEU_MAU_TIEP_NHAN` `PUBLISHED`.
    Khi IE1 `PUT /elements/capTheBHYT` `{intentCode, inputMapping, outputMapping, timeout:120, businessErrors:["BHXH_TU_CHOI"]}`
    Và IE1 `PUT /elements/nhanHoSo` `{assignment:{type:"CANDIDATE_GROUP", value:"TU_PHAP"}, formKey, due:{value:2, unit:"WORKING_DAY"}}`
    Và IE1 `PUT` một timer biên `PT120S`
    Và IE1 đọc lại `GET /versions/4`
    Thì ba `PUT` trả `200`; bản đọc lại giữ đủ thuộc tính; không có địa chỉ hay giao thức HTTT trong cấu hình (BR-11-002).

  @TC-11-013 @P1 @Âm
  Kịch bản: TC-11-013 Thuộc tính bước sai: ý định, biểu mẫu, biến
    # Truy vết: FR-11-004 · API-11-011 · ERR-11-001, 011, 014, 015 · BR-11-003
    Biết v4 `DRAFT`; IE1; biểu mẫu `BIEU_MAU_LA` ở `DRAFT`.
    Khi IE1 đặt `intentCode = khongCo`
    Và IE1 đặt `formKey = BIEU_MAU_LA`
    Và IE1 đặt điều kiện cổng `${soTienLa > 5}`
    Và IE1 `PUT /elements/khongCoId`
    Thì bước 1 `422` ERR-11-011. Bước 2 `422` ERR-11-014. Bước 3 `422` ERR-11-015. Bước 4 `404` ERR-11-001.

  @TC-11-014 @P1 @Dương
  Kịch bản: TC-11-014 Kiểm tra tĩnh mô hình hợp lệ
    # Truy vết: FR-11-005 · API-11-014 · UI-11-04 · NFR-11-013 · BR-11-003
    Biết v4 hợp lệ; một mô hình 200 phần tử hợp lệ.
    Khi IE1 gọi `POST /versions/4:validate?mode=FAST`
    Và IE1 gọi `:validate?mode=FULL`
    Và IE1 gọi `:validate?mode=FULL` trên mô hình 200 phần tử, đo thời gian
    Thì `200`, `errors = 0`, có thể có WARNING; bản `FULL` kiểm ánh xạ luồng PH-04 đã phát hành, không `INTENT_NO_FLOW`; bước 3 xong ≤ 2 giây (không tính lần gọi PH-04).

  @TC-11-015 @P1 @Âm
  Kịch bản: TC-11-015 Bộ mô hình lỗi mẫu: mỗi ruleCode một tệp
    # Truy vết: FR-11-005 · API-11-014 · ERR-11-012, 013 · BR-11-003, 008, 014, 015, 034, 035
    Biết `M-LOI` (20 tệp); IE1.
    Khi với mỗi tệp `M-LOI` mức ERROR, nhập rồi gọi `:validate?mode=FULL`
    Và so `ruleCode`, `severity`, `elementId` với kỳ vọng của tệp
    Và chạy lại với `X-OK`
    Thì mỗi tệp trả đúng một `ruleCode` kỳ vọng, `severity = ERROR`, có `elementId`, câu mô tả. `INTENT_NO_FLOW` kèm ERR-11-012; `RISKY_NO_COMPENSATION` kèm ERR-11-013. `X-OK` không báo lỗi nào (0 dương tính giả).

  @TC-11-016 @P2 @Dương @Biên
  Kịch bản: TC-11-016 Cảnh báo và thông tin không chặn, biên 200 phần tử
    # Truy vết: FR-11-005 · API-11-014, 016 · UI-11-04
    Biết ba tệp `M-LOI` mức WARNING; mô hình 200 phần tử và 201 phần tử; PH-04 danh mục không trả lời trong 5 giây.
    Khi kiểm tra từng tệp WARNING
    Và kiểm tra mô hình 200 rồi 201 phần tử
    Và đặt PH-04 danh mục im lặng, chạy `FAST` rồi `FULL`
    Và IE1 gửi duyệt bản chỉ có WARNING
    Thì `TASK_NO_DUE`, `SERVICE_NO_TIMEOUT_BOUNDARY`, `NO_PUBLIC_NAME` ở WARNING; `LARGE_MODEL` INFO chỉ ở 201. `FAST` ghi INFO "Chưa kiểm được ánh xạ luồng"; `FULL` chặn ở bước triển khai. Gửi duyệt bản chỉ WARNING được chấp nhận.

  @TC-11-017 @P2 @Dương
  Kịch bản: TC-11-017 Chạy thử với service task giả lập
    # Truy vết: FR-11-011 · API-11-025, 026, 027 · UI-11-06 · BR-11-036
    Biết v4 hợp lệ; IE1; kịch bản `capTheBHYT = BUSINESS_ERROR BHXH_TU_CHOI`; `11.test.retentionDays = 7`.
    Khi IE1 gọi `POST /versions/4/test-runs` `{scenario, clock:"ACCELERATED"}`
    Và IE1 gọi `POST /test-runs/{id}:step` đến kết thúc
    Và IE1 gọi `GET /test-runs/{id}`
    Và đếm bản tin trên `t90.bpm.*` và `GET /instances`
    Và CLK +8 ngày
    Thì `test_run` `PASSED` hoặc `FAILED` theo kịch bản, có dòng thời gian từng bước và Saga. Không bản tin Kafka, không dòng outbox, không lệnh PH-04, `GET /instances` không có phiên thử. Sau 8 ngày phiên thử bị dọn.

  @TC-11-018 @P2 @Âm
  Kịch bản: TC-11-018 Chạy thử lỗi: còn lỗi tĩnh, thiếu kịch bản, thiếu quyền
    # Truy vết: FR-11-011 · API-11-025 · ERR-11-010, 042 · ERR-00-403
    Biết một nháp còn lỗi `ERROR`; v4 hợp lệ; IE1, VW.
    Khi IE1 chạy thử nháp còn lỗi
    Và IE1 chạy thử v4 mà không khai kịch bản cho `guiTuPhap`
    Và VW chạy thử
    Thì bước 1 `422` ERR-11-010. Bước 2 `422` ERR-11-042. Bước 3 `403` ERR-00-403.
