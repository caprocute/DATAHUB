# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-12
Tính năng: TS-04-12 · Chạy thử trên sandbox

  @TC-04-071 @P1 @Dương
  Kịch bản: TC-04-071 Chạy thử MOCK đạt
    # Truy vết: FR-04-030, 033 · API-04-040, 042 · UI-04-11 · UC-04-08 · EVT-04-10 · NFR-04-008.
    Biết F-HT v4 hợp lệ; IE1; MSG-OK; đích mô phỏng trả `{"ketQua":"OK"}`.
    Khi gọi `POST .../versions/4/test-runs` với `{"mode":"MOCK","body":MSG-OK,"assertions":[{"kind":"STATUS","expected":200},{"kind":"STEP_VISITED","nodeId":"deliver-ht"}]}` và `Idempotency-Key`.
    Và mở SSE `GET .../test-runs/{runId}/events`.
    Và trên UI-04-11, quan sát sơ đồ.
    Thì bước 1 trả `202`, `Location`, `status = QUEUED`, `definitionHash = contentHash` của v4. Bước 2 nhận `status` → `RUNNING`, chín sự kiện `step` (một cho mỗi chặng chuẩn) có `stage`, `durationMs`, rồi `completed` với `status = PASSED`. Vết OpenTelemetry của lần chạy có span `camel` trong pod sandbox (chứng minh chạy thật). Bước 3: các chặng đã đi tô xanh, nhãn thời gian trên cạnh. EVT-04-10 phát. Từ gửi tới kết quả p95 < 5 giây (NFR-04-008). KT: có (`INT_TESTRUN_START`).

  @TC-04-072 @P1 @Âm
  Kịch bản: TC-04-072 Chạy thử không đạt và chặng lỗi
    # Truy vết: FR-04-030, 032, 033 · API-04-040, 042 · UI-04-11, 12.
    Biết F-HT v4; MSG-NOID.
    Khi chạy `MOCK` với MSG-NOID, khẳng định `STATUS = 200`.
    Và mở UI-04-12 (nhật ký) của lần chạy.
    Thì bước 1: `status = FAILED`; `assertionResults[0].passed = false`, `actual = 400`; chặng `schema` có `status = FAILED`, `errorClass = VALIDATION`; chặng sau `schema` có `SKIPPED`. Trên UI-04-11 chặng `schema` tô đỏ, các chặng sau tô xám "Không chạy" (FR-04-033). Bước 2: dòng chặng `schema` đỏ, thông điệp "Thiếu trường soDinhDanh", không có giá trị của trường khác (BR-04-013).

  @TC-04-073 @P1 @Âm
  Kịch bản: TC-04-073 Chạy thử với định nghĩa lỗi, kết nối thiếu TEST, bản tin lớn
    # Truy vết: FR-04-030 · API-04-040 · ERR-04-009, 013, 021.
    Biết `tc-loi-cu-phap` (VR-02 `ERROR`); `tc-notest` dùng CONN-NOTEST.
    Khi chạy thử `tc-loi-cu-phap`.
    Và chạy `SANDBOX_LIVE` với `tc-notest`.
    Và chạy F-HT v4 với MSG-BIG.
    Và chạy với `timeoutSeconds = 121`.
    Thì lần lượt `422` ERR-04-009 (kèm `findings`), `422` ERR-04-013, `413` ERR-04-021, `400` ERR-04-049. Không có lần chạy nào vào hàng đợi.

  @TC-04-074 @P2 @Biên
  Kịch bản: TC-04-074 Quá thời gian và chặng treo
    # Truy vết: FR-04-030 · API-04-042 · ERR-04-020.
    Biết đích mô phỏng của F-HT trễ 10 giây.
    Khi chạy `MOCK` với `timeoutSeconds = 5`.
    Thì sau khoảng 5 giây: `status = TIMED_OUT`, `errorCode = ERR-04-020`, `hungNodeId = "deliver-ht"`. Sandbox dừng exchange và giải phóng chỗ trong hạn mức; lần chạy kế tiếp bắt đầu ngay.

  @TC-04-075 @P2 @Biên
  Kịch bản: TC-04-075 Hạn mức chạy thử đồng thời
    # Truy vết: FR-04-030, 084 · API-04-040 · ERR-04-019.
    Biết `04.test.max-concurrent = 5`; đích trễ 10 giây.
    Khi gửi đồng thời 6 lần chạy thử của T68.
    Và cùng lúc gửi 1 lần của T01.
    Thì năm lần đầu `202`. Lần thứ sáu `429` ERR-04-019 kèm `retryAfterSeconds` và tiêu đề `Retry-After`. Lần của T01 `202` (hạn mức tính theo tenant).

  @TC-04-076 @P3 @Dương @Âm
  Kịch bản: TC-04-076 Hủy lần chạy thử
    # Truy vết: FR-04-030 · API-04-043 · ERR-04-005.
    Biết một lần chạy đang `QUEUED`, một lần đã `PASSED`.
    Khi `:cancel` lần `QUEUED`.
    Và `:cancel` lần `PASSED`.
    Thì bước 1 trả `200`, `status = CANCELLED`. Bước 2 trả `409` ERR-04-005.

  @TC-04-077 @P1 @Khả @dụng
  Kịch bản: TC-04-077 Sandbox không sẵn sàng và chế độ mô phỏng
    # Truy vết: FR-04-030 · BR-04-004 · ERR-04-019.
    Biết thu nhỏ `dh-runtime-sandbox` về 0 bản sao.
    Khi chạy thử với `04.test.allow-simulation = false`.
    Và bật `allow-simulation`, chạy lại.
    Thì bước 1 trả `503` ERR-04-019. Bước 2 trả `202`, kết quả `mode = SIMULATED`, giao diện hiện nhãn "Mô phỏng, không dùng để gửi duyệt". Lần chạy này không được tính cho BR-04-004 (xem ca gửi duyệt với lần mô phỏng ở TS-04-14).

  @TC-04-078 @P2 @Dương
  Kịch bản: TC-04-078 Nhật ký chạy thử: xem lại, so sánh, dọn
    # Truy vết: FR-04-032 · API-04-041, 042 · UI-04-12 · BR-04-013.
    Biết F-HT có 3 lần chạy; một lần bật `captureBodies`.
    Khi gọi `GET /flows/tra-cuu-ho-tich/test-runs?versionNo=4`.
    Và gọi `GET .../test-runs/{id}/steps/3/body?side=out` cho lần có `captureBodies`.
    Và trên UI-04-12, chọn hai lần chạy, bấm "So sánh".
    Và đặt đồng hồ hệ thống tới 8 ngày sau, chạy job dọn.
    Thì bước 1: ba lần chạy, mỗi lần có `matchesCurrentHash`. Bước 2: thân đã che theo BR-04-013 (trường phân loại Cá nhân thay bằng `*`). Bước 3: bảng so sánh theo chặng, tô khác biệt thời gian và trạng thái. Bước 4: thân bị xóa khỏi RGW bucket `dh-int-testrun` (`04.test.body-retention-days = 7`), bước 2 nay trả `404`; metadata còn tới 90 ngày.

  @TC-04-079 @P2 @Dương
  Kịch bản: TC-04-079 Chạy thử SANDBOX_LIVE gọi đích TEST
    # Truy vết: FR-04-030 · UC-04-08.
    Biết CONN-HT có giá trị TEST trỏ WireMock `OK`.
    Khi chạy `SANDBOX_LIVE` với MSG-OK.
    Thì `PASSED`; WireMock ghi nhận đúng một lệnh gọi tới URL TEST; không lệnh gọi nào tới URL PROD (kiểm bằng WireMock PROD không nhận yêu cầu). Sandbox chỉ đọc được giá trị TEST của kết nối (OpenBao policy).

  @TC-04-192 @P1 @Dương
  Kịch bản: TC-04-192 Đầu cuối một lần chạy thử MOCK theo trình tự SDD
    # Truy vết: FR-04-030, 032 · UC-04-08 · API-04-040, 042 · UI-04-11 · EVT-04-10 · NFR-04-008.
    Biết U-T68-IE1; F-HT v4 `DRAFT`, `captureBodies = true`; WireMock CONN-HT đếm lượt gọi; theo dõi Valkey Stream `dh:int:testrun:queue`, Ceph RGW `dh-int-testrun`, nhật ký truy cập của sandbox (D03-02-PH04 §8.2, hình chạy thử MOCK).
    Khi IE1 bấm "Chạy thử" với MSG-OK ở UI-04-04 (`mode = MOCK`).
    Và đọc hàng đợi Valkey và bảng `test_run`.
    Và theo dõi lượt gọi của sandbox tới `dh-integration`.
    Và theo dõi SSE tới khi `completed`.
    Và đọc `s3://dh-int-testrun/T68/{runId}/`.
    Thì bước 1 trả `202` có `runId`, SSE mở ngay. Bước 2: `test_run` ở `QUEUED` và đúng một việc trong hàng đợi theo hồ sơ. Bước 3: sandbox chỉ gọi hai API nội bộ (lấy gói chạy qua mTLS, `POST /internal/v1/testruns/{id}/steps` theo lô khoảng 200 ms); không có lượt nào tới WireMock CONN-HT (endpoint ra đã thay bằng `mock:`). Bước 4: sự kiện `step` mang thân đã che (không có `soDinhDanh` rõ), rồi `completed` với `PASSED` sau khi chạy khẳng định; EVT-04-10 phát. Bước 5: có tệp `{nodeId}-in.json`, `{nodeId}-out.json` mã hóa phía máy chủ. Toàn trình p95 < 5 giây.
