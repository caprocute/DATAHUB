# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-11
Tính năng: TS-06-11 · Job đối sánh theo lô bằng Splink

  @TC-06-051 @P1 @Dương
  Kịch bản: TC-06-051 Job FULL_INITIAL trên 20.000 CITIZEN
    # Truy vết: FR-06-022 · API-06-042, 043 · EVT-06-09 · BR-06-016 · PERM-06-operate
    # Mục đích: Chứng minh vòng đời job, staging chỉ có HMAC và dọn sau job, theo FR-06-022.
    Biết T90 nạp 20.000 ứng viên F-CIT mở rộng, bộ quy tắc v2 ACTIVE; TO.
    Khi `POST /domains/CITIZEN/match-jobs` `BatchScope = FULL_INITIAL`.
    Và theo dõi `GET /match-jobs/{id}` tới kết thúc.
    Và quét `ph06_mdm.stg_match_{jobId}` khi `RUNNING`, rồi sau job.
    Thì trạng thái đi qua `QUEUED`, `PREPARING`, `RUNNING`, `APPLYING`, `SUCCEEDED`; `counts` đủ `input`, `pairs`, `match`, `possible`, `applied`, `skipped`. Staging chỉ chứa thuộc tính `matchable` đã chuẩn hóa, định danh dạng HMAC, không có CCCD rõ; sau job bảng staging bị xóa. Mỗi hợp nhất mang `batchOperationId`, `method = PROBABILISTIC_BATCH`. EVT-06-09 một bản tin. KT: có (job-start).
    # Hậu điều kiện: Bản ghi vàng đã gom; dùng ở ca batch-partial.

  @TC-06-052 @P2 @Dương @Âm
  Kịch bản: TC-06-052 Chạy thử không áp; job trùng bị chặn
    # Truy vết: FR-06-022 · API-06-042 · ERR-06-025
    # Mục đích: Chứng minh `dryRun` dừng sau chấm điểm và không cho hai job cùng loại, theo FR-06-022.
    Biết T90 như batch-run.
    Khi tạo job `dryRun = true`; đếm bản ghi vàng trước, sau.
    Và tạo job thật rồi tạo tiếp một job nữa khi job đầu `RUNNING`.
    Thì bước 1 báo cáo cặp theo vùng, mẫu 100 cặp, số bản ghi vàng không đổi. Bước 2 job thứ hai `409` ERR-06-025.
    # Hậu điều kiện: Một job đang chạy.

  @TC-06-053 @P1 @Dương @Âm
  Kịch bản: TC-06-053 Vượt ngưỡng an toàn 5 % chờ xác nhận
    # Truy vết: FR-06-022 · BR-06-022 · API-06-044 · ERR-06-105 · PERM-06-approve
    # Mục đích: Chứng minh job có số cặp `MATCH` > 5 % số bản ghi vào dừng ở `AWAITING_CONFIRMATION`, theo BR-06-022.
    Biết tập T99 dựng 30 % bản ghi trùng chủ ý; `06.batch.safety-ratio = 0,05`.
    Khi chạy job, chờ trạng thái.
    Và DA1 `:confirm` một job; với job khác DA1 từ chối.
    Thì bước 1 `AWAITING_CONFIRMATION`, ERR-06-105 ở UI-06-12, không bản ghi vàng nào đổi. Bước 2 xác nhận thì `APPLYING` → `SUCCEEDED`; từ chối thì `CANCELLED`, không đổi (ĐN-UC-04).
    # Hậu điều kiện: Hai job ở trạng thái cuối.

  @TC-06-054 @P1 @Âm @Chịu @lỗi
  Kịch bản: TC-06-054 Job lỗi đọc staging, quá giờ, hết bộ nhớ
    # Truy vết: FR-06-022 · ERR-06-101, 102, 103 · BR-06-023
    # Mục đích: Chứng minh job thất bại không đổi bản ghi vàng nào, theo FR-06-022.
    Biết T95; chặn quyền đọc staging; đặt thời gian tối đa 1 phút; giới hạn bộ nhớ Job 256 MB.
    Khi chạy job với từng sự cố.
    Và đối chiếu bảng `golden_record`, `golden_history`.
    Thì ba job `FAILED` lần lượt ERR-06-101, 102, 103 (kèm gợi ý chuyển Spark); `golden_record` và `golden_history` không đổi; vận hành thấy câu "Job {id} lỗi khi đọc dữ liệu … Không bản ghi vàng nào bị đổi.".
    # Hậu điều kiện: Staging đã dọn.

  @TC-06-055 @P1 @Dương
  Kịch bản: TC-06-055 Bỏ qua cặp đã đổi sau khi xuất và cặp có quyết định thủ công
    # Truy vết: FR-06-022 · BR-06-023 · ERR-06-104
    # Mục đích: Chứng minh job không ghi đè quyết định của người và dữ liệu đổi giữa chừng, theo BR-06-023.
    Biết cặp P-17 `negativeLink`; cặp P-18 liên kết do người xác nhận; cặp P-19 đổi bản ghi sau khi xuất staging.
    Khi chạy job, trong lúc `RUNNING` sửa P-19.
    Thì P-17 không đề xuất lại; P-18 không bị tự tách; P-19 bị bỏ qua ERR-06-104; `skipped = 3`.
    # Hậu điều kiện: Ba cặp không đổi.

  @TC-06-056 @P1 @Chịu @lỗi
  Kịch bản: TC-06-056 Job thất bại giữa chừng chỉ để lại cặp đã áp
    # Truy vết: FR-06-022 · BR-06-005, 023 · ERR-06-103
    # Mục đích: Chứng minh tiêu chí chấp nhận 9: không đổi bản ghi vàng ngoài các cặp đã áp có `batchOperationId`.
    Biết T95; job `APPLYING` 5.000 cặp.
    Khi xóa pod Job khi đã áp khoảng 2.000 cặp.
    Và so `golden_record` trước, sau theo `batchOperationId`.
    Thì job `PARTIALLY_SUCCEEDED` hoặc `FAILED`; mọi bản ghi vàng đổi đều có `batchOperationId` và ảnh chụp; không bản ghi nào đổi nửa chừng; chạy lại job không áp trùng cặp.
    # Hậu điều kiện: Có thể `:rerun`.
