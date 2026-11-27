# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-36
Tính năng: TS-18-36 · Chạy thật di trú có duyệt bốn mắt và đánh dấu cấp lại xác thực

  @TC-18-119 @P1 @Dương
  Kịch bản: TC-18-119 Chạy thật sau chạy thử, PA duyệt, ghi qua API nhập với migration = true
    # Truy vết: FR-18-062, 064 · API-18-164, 166, 167, 171 · BR-18-040, 041, 043 · EVT-18-25 · UI-18-15, 21, 22
    # Mục đích: Chứng minh FR-18-062: chạy thật đi `PENDING_APPROVAL → QUEUED → RUNNING → SUCCEEDED`, ghi qua API nhập của PH-07, PH-01, PH-02, không phát sự kiện nghiệp vụ hàng loạt.
    Biết T96; chạy thử `PLAN-AITA` thành công 2 ngày trước, đối chiếu đã giải trình; U-T96-TA1 tạo, U-PA2 duyệt.
    Khi TA1 `POST /migration-runs` `mode = REAL`.
    Và PA2 mở việc, `:approve`.
    Và theo dõi lần chạy tới xong.
    Và đếm bản ghi ở WireMock đích và sự kiện nghiệp vụ.
    Thì bước 1 `201` `PENDING_APPROVAL`. Bước 2 `QUEUED` rồi `RUNNING`. Bước 3 `SUCCEEDED`, EVT-18-25 `mode = REAL`. Bước 4 mỗi lời gọi nhập có cờ `migration = true`; 0 sự kiện nghiệp vụ hàng loạt; số ghi khớp đối chiếu.

  @TC-18-120 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-120 Không có chạy thử gần đây, đang đóng băng, tác vụ nặng khác, người tạo tự duyệt
    # Truy vết: FR-18-062 · API-18-164, 167, 168 · BR-18-039, 041 · ERR-18-005, 051, 057, 064
    # Mục đích: Chứng minh BR-18-041, 039 và LP-18-01 cho chạy thật.
    Biết T95 (đồng hồ giả) với bản sao `PLAN-AITA`; chạy thử thành công 8 ngày trước; U-T95-TA1 có cả `PERM-18-approve`.
    Khi tạo chạy thật.
    Và chạy thử lại thành công, tạo cửa sổ `FREEZE` hiện hành, tạo chạy thật.
    Và hủy cửa sổ, tạo khôi phục chạy song song, tạo chạy thật.
    Và khi không còn tác vụ nặng, tạo chạy thật và TA1 tự `:approve`; PA2 `:reject`.
    Thì bước 1 `409` ERR-18-064. Bước 2 `409` ERR-18-051. Bước 3 `409` ERR-18-057. Bước 4 `403` ERR-18-005; sau đó `REJECTED`.

  @TC-18-121 @P1 @Chịu_lỗi
  Kịch bản: TC-18-121 Phân hệ đích không nhận lô thì tạm dừng, từ chối bản ghi thì ghi lỗi
    # Truy vết: FR-18-062, 063 · API-18-166, 170 · ERR-18-069, 119
    # Mục đích: Chứng minh lỗi phía đích không làm mất bản ghi và lần chạy tiếp tục được.
    Biết T96; WireMock PH-01 trả `503` từ lô thứ 2, trả `422` cho 3 HTTT thiếu cơ quan chủ quản.
    Khi chạy thật đã duyệt.
    Và khôi phục WireMock, tiếp tục lần chạy.
    Thì bước 1 lần chạy tạm dừng ghi ERR-18-069 ở UI-18-22. Bước 2 chạy tiếp từ lô dở, kết thúc `SUCCEEDED_WITH_ERRORS`, 3 bản ghi lỗi ERR-18-119 kèm mã lỗi của PH-01.

  @TC-18-122 @P1 @Lũy_đẳng
  Kịch bản: TC-18-122 Chạy lại toàn bộ lần chạy thật ba lần không tạo bản trùng
    # Truy vết: FR-18-062 · BR-18-041 · NFR-18-014
    # Mục đích: Chứng minh NFR-18-014 và BR-18-041: khóa `legacySystem:objectType:legacyKey` bảo đảm 0 bản ghi trùng.
    Biết T96 sau ca chạy thật; đếm bản ghi ở WireMock đích theo khóa.
    Khi tạo và duyệt chạy thật lần 2, lần 3, lần 4 liên tiếp.
    Thì mỗi lần kết quả `written = 0`, `skipped = 13.080`; đích không có khóa trùng; báo cáo đối chiếu giữ nguyên.

  @TC-18-123 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-18-123 Thông tin xác thực không di trú, đánh dấu cấp lại và phát sự kiện cho PH-01, PH-03
    # Truy vết: FR-18-065, 062 · API-18-172 · BR-18-042 · EVT-18-26 · ERR-18-124 · UI-18-22, 23
    # Mục đích: Chứng minh BR-18-042 và FR-18-065: không có giá trị xác thực nào rời nguồn, mỗi thông tin bỏ qua có dấu cấp lại; lỗi bộ tiêu thụ đi vào DLQ PH-18.
    Biết T96; `LEG-AITA` có 40 khóa API của consumer và 12 chứng thư đối tác; lần chạy thật đã duyệt.
    Khi chạy thật.
    Và `GET /credential-reissues`.
    Và đọc `t96.ops.migration.credential-reissue-required.v1`.
    Và rà payload các lời gọi nhập và log của `dh-migrate`.
    Và làm bộ xử lý sự kiện cấp lại phía PH-18 lỗi năm lần.
    Thì bước 2 52 dấu cấp lại theo HTTT, trạng thái `REQUIRED`. Bước 3 EVT-18-26 theo `systemCode` có `credentialType`, `count`. Bước 4 không có giá trị xác thực nào. Bước 5 ghi ERR-18-124, mục DLQ `PH18_INBOX`.

  @TC-18-168 @P2 @Dương @Âm
  Kịch bản: TC-18-168 Đánh dấu WAIVED cho HTTT không còn dùng, dấu đã cấp lại bị từ chối
    # Truy vết: FR-18-065, 068 · API-18-183, 172, 174 · ERR-18-006, 007 · UI-18-22
    # Mục đích: Chứng minh luồng thay thế FR-18-065 qua API-18-183: dấu `PENDING` hoặc `NOTIFIED` chuyển `WAIVED` có lý do và được tính là đạt ở danh sách cắt chuyển.
    Biết T96; dấu `MK-01` `NOTIFIED`, dấu `MK-02` `REISSUED` của nhóm `PG-THUE`; U-T96-TA1 có `PERM-18-migration`.
    Khi TA1 `POST /credential-reissues/MK-01:waive` kèm `reason` "HTTT dừng kết nối theo văn bản 12/STTTT".
    Và TA1 `POST /credential-reissues/MK-01:waive` với `reason` rỗng.
    Và TA1 `POST /credential-reissues/MK-02:waive` kèm lý do hợp lệ.
    Và TA1 `GET /parallel-groups/PG-THUE` xem mục `CREDENTIALS_REISSUED`.
    Thì bước 1 `200` dấu `WAIVED`, ghi lý do và người đánh dấu; kiểm toán có. Bước 2 `422` ERR-18-007. Bước 3 `409` ERR-18-006, dấu giữ `REISSUED`. Bước 4 mục `CREDENTIALS_REISSUED` tính `MK-01` như đã đạt.
