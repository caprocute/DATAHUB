# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-02
Tính năng: TS-01-02 · Tạo hồ sơ nháp, sửa có tự lưu, mẫu văn bản

  @TC-01-007 @P1 @Dương
  Kịch bản: TC-01-007 Tạo hồ sơ nháp hợp lệ
    # Truy vết: FR-01-003 · UC-01-02 · API-01-004 · UI-01-01 · BR-01-018, 031 · EVT-01-03 · LGC-APIM-020.
    Biết U-T68-OR1; Sở Tư pháp hoạt động ở PH-20.
    Khi Ở UI-01-01 bước 1 nhập mã `TC-HOTICH-1`, tên, tổ chức Sở Tư pháp, vai trò `CONSUMER`, cấp độ `L3`, địa chỉ `https://hotich.t68.gov.vn`; bấm "Lưu và tiếp tục".
    Và `GET /systems/TC-HOTICH-1`.
    Thì gọi `POST /systems` trả `201`, `Location`, `ETag`; `status = DRAFT`, `revisionNo = 0`, `applicationNo` dạng `HS-KN-2026-nnnn`. Lịch sử, kiểm toán và outbox cùng một giao dịch. KT: có (tạo hồ sơ). EVT: `EVT-01-03` (∅ → DRAFT), không tới PH-10 vì chưa hoạt động.

  @TC-01-008 @P1 @Âm
  Kịch bản: TC-01-008 Mã trùng kể cả mã đã chấm dứt, sai mẫu
    # Truy vết: FR-01-003 · API-01-004 · ERR-01-002, 003 · BR-01-018.
    Biết U-T68-OR1; `HT-CU-TT` TERMINATED; HTTT từng bị từ chối `HT-TC-RJ`.
    Khi tạo hồ sơ mã `HT-CU-TT`; lặp với `HT-TC-RJ`.
    Và tạo hồ sơ mã `ht cu 1` (chữ thường, có khoảng trắng).
    Thì bước 1: `409` ERR-01-002 cho cả hai. Bước 2: `400` ERR-01-003, danh sách lỗi theo trường `code`. Ràng buộc duy nhất ở CSDL cũng chặn khi chèn trực tiếp (DB).

  @TC-01-009 @P1 @Âm @Bảomật
  Kịch bản: TC-01-009 Tổ chức chủ quản sai, ngừng hoạt động, TA lập thay
    # Truy vết: FR-01-003 · API-01-004 · ERR-01-004, 006 · UC-01-02.
    Biết U-T68-OR1; U-T68-TA1; tổ chức "Chi cục X" ngừng hoạt động ở giả lập PH-20.
    Khi U-T68-OR1 tạo hồ sơ khai tổ chức Văn phòng UBND.
    Và U-T68-TA1 tạo hồ sơ khai "Chi cục X".
    Và U-T68-TA1 tạo hồ sơ thay Sở Tư pháp.
    Thì bước 1: `403` ERR-01-006. Bước 2: `422` ERR-01-004. Bước 3: `201`, `createdBy` là Minh, hồ sơ ghi thay mặt Sở Tư pháp.

  @TC-01-010 @P2 @Biên
  Kịch bản: TC-01-010 Địa chỉ cơ sở không phải https, dải IP sai
    # Truy vết: FR-01-003, 004 · API-01-004, 005 · ERR-01-049.
    Biết U-T68-OR1.
    Khi tạo hồ sơ với `baseUrl = http://hotich.t68.gov.vn`.
    Và sửa hồ sơ hợp lệ với `allowedIps = ["10.0.0.0/33"]`.
    Thì cả hai `422` ERR-01-049; không có hồ sơ mới, hồ sơ cũ không đổi.

  @TC-01-011 @P1 @Âm
  Kịch bản: TC-01-011 Khóa lạc quan và trạng thái khi sửa
    # Truy vết: FR-01-004 · API-01-005 · ERR-01-005, 007 · UI-01-01.
    Biết U-T68-OR1, U-T68-TA1 cùng mở `HT-HOTICH`; `HT-HOTICH-SS` SUBMITTED.
    Khi OR1 và TA1 cùng lấy `ETag`; OR1 `PATCH /systems/HT-HOTICH` với `If-Match` đúng; TA1 `PATCH` với `If-Match` cũ.
    Và OR1 `PATCH /systems/HT-HOTICH-SS`.
    Thì bước 1: OR1 `200` với `ETag` mới; TA1 `412` ERR-01-007, UI-01-01 hiện hộp "Hồ sơ vừa được người khác sửa" cùng nút tải lại. Bước 2: `409` ERR-01-005 (đã nộp, chỉ đọc).

  @TC-01-012 @P2 @Âm @Biên
  Kịch bản: TC-01-012 Nhận lặp an toàn với Idempotency-Key
    # Truy vết: FR-01-003 · API-01-004 · ERR-01-051, 054.
    Biết U-T68-OR1.
    Khi gọi `POST /systems` hai lần cùng khóa, cùng thân.
    Và gọi lần ba cùng khóa, thân khác.
    Và gửi hai yêu cầu đồng thời cùng khóa mới.
    Thì bước 1: lần hai trả đúng kết quả lần một, chỉ một hồ sơ. Bước 2: `409` ERR-01-051. Bước 3: một yêu cầu thành công, yêu cầu kia `409` ERR-01-054 hoặc cùng kết quả; không có hai hồ sơ.

  @TC-01-013 @P2 @Dương @Khảdụng
  Kịch bản: TC-01-013 Tự lưu bản nháp, không mất khi mất kết nối, mẫu văn bản
    # Truy vết: FR-01-004, 010 · UC-01-02 · API-01-005, 020, 021 · UI-01-01 · NFR-01-014.
    Biết U-T68-OR1; `HT-HOTICH`.
    Khi nhập thêm mô tả; chờ 30 giây; ngắt mạng; nhập tiếp; bật mạng.
    Và bấm "Tải mẫu văn bản"; tải một mẫu qua `GET /templates/{templateCode}/content`.
    Và gọi `GET /templates` không đăng nhập.
    Thì bước 1: sau 30 giây có một lần `PATCH` tự động; sau khi có mạng, phần nhập thêm được lưu, không mất ký tự. Bước 2: có mẫu của `T68` hoặc mẫu mặc định nền tảng. Bước 3: `401` ERR-01-052.
