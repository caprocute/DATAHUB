# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-02
Tính năng: TS-17-02 · Bật tắt năng lực, nhóm vai trò, đặt hạn mức và tham số 17.*

  @TC-17-005 @P1 @Dương @Âm
  Kịch bản: TC-17-005 Năng lực theo nhóm vai trò: ẩn lối vào, 403 khi thiếu điều kiện
    # Truy vết: FR-17-002 · API-17-001, 009, 095, 104 · BR-17-003 · ERR-17-011, 015 · UI-17-06
    # Mục đích: Chứng minh một năng lực chỉ dùng được khi trợ lý bật, `17.feature.*` bật và nhóm vai trò của người dùng được phép.
    Biết T90 bật; `SEARCH` bật cho `ALL_READERS`, `MAPPING` bật chỉ cho nhóm `IE`, `EXPLAIN` tắt; U-T90-TA1, U-T90-IE, U-T90-VW.
    Khi TA1 `PUT /policy/capabilities` với `capabilities = []`.
    Và TA1 `PUT /policy/capabilities` hợp lệ như dữ liệu trên, kèm `If-Match`.
    Và U-T90-VW `GET /status` rồi gửi câu hỏi tìm dịch vụ.
    Và U-T90-VW `POST /mapping-suggestions` và `POST /explanations/error-codes`.
    Và U-T90-IE `POST /mapping-suggestions` với một cặp trường hợp lệ.
    Thì bước 1 `422` ERR-17-015. Bước 2 `200`, KT: có (capability-update), EVT: `assist.config.changed`. Bước 3 `status` chỉ liệt kê `SEARCH`, câu hỏi `200`. Bước 4 `403` ERR-17-011 cho cả hai (VW không thuộc nhóm `MAPPING`, `EXPLAIN` tắt), nút tương ứng ẩn. Bước 5 `200` có gợi ý.

  @TC-17-006 @P1 @Dương @Biên @Âm
  Kịch bản: TC-17-006 Hạn mức lượt, token, độ dài đầu vào và đầu ra
    # Truy vết: FR-17-004 · API-17-013, 014, 015, 095 · BR-17-005, 006, 042 · ERR-17-018, 019, 021, 022, 023 · EVT-17-12
    # Mục đích: Chứng minh hạn mức đếm trước khi gọi mô hình, chặn đúng mã `429` và độ dài đầu vào bị từ chối.
    Biết T92: `17.quota.user-turns-per-day = 10`, `user-turns-per-minute = 3`, `tenant-tokens-per-day = 100.000`, `input.max-chars = 500`, `output.max-tokens = 200`; LLM-MOCK; U-T92-IE, U-T92-TA1.
    Khi TA1 `PUT /policy/quotas` đặt `17.quota.user-turns-per-day = 2.000`.
    Và IE gửi câu hỏi 501 ký tự.
    Và IE gửi 3 câu hỏi liên tiếp trong một phút rồi câu thứ 4.
    Và gửi tiếp tới câu thứ 10 trong ngày (cách nhau 25 giây) rồi câu thứ 11.
    Và một IE khác dùng hết 100.000 token của tenant rồi IE gửi câu hỏi.
    Và gửi câu hỏi mà LLM-MOCK trả 500 token.
    Và TA1 `PUT /policy/quotas` đặt `17.quota.user-turns-per-day = 500`, `tenant-tokens-per-day = 5.000.000` rồi `GET /policy/quotas`.
    Thì bước 1 `422` ERR-17-018 (vượt trần 1.000). Bước 2 `400` hoặc `422` ERR-17-019, không gọi mô hình. Bước 3 câu thứ 4 `429` ERR-17-023, `Retry-After` đúng số giây. Bước 4 câu 11 `429` ERR-17-021 kèm thời điểm thử lại. Bước 5 `429` ERR-17-022, EVT: `assist.quota.threshold-reached` ở 80 % và 100 %, không gọi mô hình. Bước 6 câu trả lời bị cắt ở 200 token kèm dấu "đã rút gọn". Bước 7 `200`, KT: có (quota-update), EVT: `assist.config.changed`, giá trị mới hiệu lực.

  @TC-17-007 @P1 @Dương @Âm @Biên
  Kịch bản: TC-17-007 Tham số 17.*: ngoài miền, khóa lạ, sàn nhật ký, tham số nhạy cần bốn mắt, đưa về mặc định
    # Truy vết: FR-17-059 · API-17-003, 006, 180, 181, 182, 183 · BR-17-010, 078 · ERR-17-004, 082, 083, 084, ERR-00-428 · EVT-17-01
    # Mục đích: Chứng minh miền, trần, sàn được kiểm, tham số nhạy đi qua đề nghị bốn mắt và đổi tham số phát sự kiện cấu hình.
    Biết T90; U-T90-TA1, U-T90-TA2; tham số mặc định theo FRS mục 8.2.
    Khi TA1 `GET /settings/schema` và `GET /settings`.
    Và TA1 `PUT /settings/17.rag.top-k` giá trị 25.
    Và TA1 `PUT /settings/17.khong-co` giá trị 1.
    Và TA1 `PUT /settings/17.log.retention-days` giá trị 60.
    Và TA1 `PUT /settings/17.log.retention-days` giá trị 120.
    Và TA1 `PUT /settings/17.rag.top-k` giá trị 10 không có `If-Match`, rồi có `If-Match`.
    Và TA1 `POST /settings/17.rag.top-k:reset`.
    Và gửi `POST /policy/changes` `SENSITIVE_PARAM` đặt retention 120, TA2 duyệt.
    Và TA1 `PUT /settings/17.redteam.min-pass-rate` giá trị 90.
    Và TA1 và TA2 cùng đọc `ETag` của `17.rag.top-k`; TA1 `PUT` giá trị 9 rồi TA2 `PUT` giá trị 11 với `ETag` cũ.
    Thì bước 1 `200` đủ khóa với miền, mặc định, trần, sàn. Bước 2 `422` ERR-17-082 (miền 3…20). Bước 3 `422` ERR-17-084. Bước 4 `422` ERR-17-083. Bước 5 `PUT` trực tiếp bị từ chối vì cần đề nghị bốn mắt. Bước 6 `428` ERR-00-428 rồi `200`, EVT: `assist.config.changed`, KT: có. Bước 7 về 8. Bước 8 `PENDING` rồi `APPROVED`, retention hiệu lực 120. Bước 9 `422` ERR-17-082 (sàn 100 không đổi được). Bước 10 TA1 `200`, TA2 `409` ERR-17-004.

  @TC-17-008 @P2 @Biên @Chịu_lỗi
  Kịch bản: TC-17-008 Tham số hiệu lực trong 30 giây, thiếu tham số dùng mặc định an toàn
    # Truy vết: FR-17-059 · API-17-182 · BR-17-078 · NFR-17-004
    # Mục đích: Chứng minh bản sao đọc tham số có đệm 30 giây và tham số thiếu dùng mặc định ở mục 8.2.
    Biết T90 bật; `dh-assist` 2 bản sao; U-T90-TA1.
    Khi TA1 `PUT /settings/17.input.max-chars` giá trị 600; ghi thời điểm.
    Và gửi câu hỏi 700 ký tự tới từng bản sao mỗi 5 giây tới khi bị từ chối ở cả hai.
    Và xóa khóa `17.rag.top-k` khỏi kho PH-18 rồi gửi câu hỏi tìm dịch vụ.
    Thì bước 2 cả hai bản sao từ chối ERR-17-019 trong ≤ 30 giây (đệm) và không quá 60 giây. Bước 3 dùng `top-k = 8` mặc định, câu trả lời `200`, log cảnh báo thiếu khóa không chứa giá trị.
