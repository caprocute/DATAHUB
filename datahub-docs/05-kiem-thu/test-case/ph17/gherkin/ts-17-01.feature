# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-01
Tính năng: TS-17-01 · Đề nghị, xác nhận bật trợ lý và tắt trợ lý cho tenant

  @TC-17-001 @P1 @Dương
  Kịch bản: TC-17-001 Bật trợ lý bằng đề nghị bốn mắt rồi dùng được
    # Truy vết: FR-17-001, 002 · API-17-001, 003, 005, 006 · BR-17-001, 002, 009 · EVT-17-01, 02, 04 · UI-17-06
    # Mục đích: Chứng minh trợ lý chỉ có hiệu lực sau khi người thứ hai xác nhận, ghi kiểm toán trước khi đổi trạng thái và nút "Trợ lý" xuất hiện trong 60 giây.
    Biết T93 mới (`17.enabled = false`), có `MV-CHAT-1` và `MV-EMB-1` ở trạng thái `APPROVED` và là mô hình mặc định; U-T93-TA1, U-T93-SO.
    Khi U-T93-IE `GET /status`.
    Và U-T93-TA1 `POST /policy/changes` với `type = ENABLE`, `decisionNumber = "QĐ-123/UBND ngày 01/12/2026"`, `reason` 30 ký tự, `capabilities = [SEARCH]`, `roleGroups = [ALL_READERS]`, kèm `Idempotency-Key`.
    Và U-T93-SO `POST /policy/changes/{changeId}:approve` kèm `If-Match`.
    Và chờ tối đa 60 giây rồi U-T93-IE `GET /status` và mở bảng điều khiển.
    Thì bước 1 `200` `enabled = false`, không có nút "Trợ lý". Bước 2 `201`, `state = PENDING`, tenant vẫn `DISABLED`. Bước 3 `200`, `TenantAssistState = ENABLED`, `ETag` mới; KT: có (policy-enable) ghi trước khi đổi trạng thái; EVT: `assist.enablement.changed`, `assist.config.changed`, `assist.policy-change.decided`. Bước 4 `enabled = true`, `capabilities = [SEARCH]`, nút "Trợ lý" hiện trên thanh trên.

  @TC-17-002 @P1 @Âm
  Kịch bản: TC-17-002 Người duyệt trùng người đề nghị, thiếu số quyết định, đề nghị trùng
    # Truy vết: FR-17-001 · API-17-003, 006 · BR-17-002 · ERR-17-005, 013, 014, 033
    # Mục đích: Chứng minh bốn mắt không có đường vòng và các điều kiện đầu vào của đề nghị bật bị chặn đúng mã.
    Biết T93; U-T93-TA1, U-T93-TA2 (đều có `PERM-17-admin`); `MV-CHAT-1` mặc định.
    Khi TA1 `POST /policy/changes` `ENABLE` đủ trường rồi TA1 `POST /policy/changes/{changeId}:approve`.
    Và TA1 gửi `ENABLE` mới nhưng bỏ `decisionNumber`.
    Và TA1 gửi `ENABLE` hợp lệ khi đề nghị bước 1 còn `PENDING`.
    Và gỡ mô hình hội thoại mặc định của T93 rồi TA2 gửi `ENABLE` hợp lệ.
    Thì bước 1 `403` ERR-17-005, đề nghị vẫn `PENDING`. Bước 2 `422` ERR-17-014. Bước 3 `409` ERR-17-013. Bước 4 `409` ERR-17-033. Mọi bước tenant vẫn `DISABLED`, không có EVT enablement, KT: có cho các lần từ chối duyệt.

  @TC-17-003 @P1 @Dương @Chịu_lỗi
  Kịch bản: TC-17-003 Tắt trợ lý không cần bốn mắt, dữ liệu cũ giữ nguyên, đóng an toàn khi thiếu tham số
    # Truy vết: FR-17-001 · API-17-001, 008 · BR-17-001, 079 · ERR-17-008, 007 · EVT-17-02
    # Mục đích: Chứng minh tắt có hiệu lực ngay chỉ với lý do, chỉ mục và nhật ký không bị xóa, và tham số không đọc được thì coi là tắt.
    Biết T90 đang `ENABLED` có 120 đoạn chỉ mục và 10 hội thoại; U-T90-TA1.
    Khi TA1 `POST /policy:disable` với `reason` 5 ký tự.
    Và TA1 `POST /policy:disable` với `reason` 25 ký tự.
    Và U-T90-IE `POST /conversations/{id}/messages` và `GET /status`.
    Và đếm đoạn chỉ mục và hội thoại ở bảng; U-T90-AU tra siêu dữ liệu nhật ký.
    Và làm kho tham số PH-18 của T90 trả lỗi rồi U-T90-IE gọi `GET /status` và gửi câu hỏi.
    Thì bước 1 `422` ERR-17-007. Bước 2 `200`, `DISABLED`, KT: có (policy-disable), EVT: `assist.enablement.changed`. Bước 3 `403` ERR-17-008, `enabled = false`, nút "Trợ lý" ẩn. Bước 4 vẫn 120 đoạn và 10 hội thoại. Bước 5 mọi API người dùng `403` ERR-17-008 (đóng an toàn, BR-17-001).

  @TC-17-004 @P2 @Âm @Bảo_mật
  Kịch bản: TC-17-004 Đề nghị bật khi tenant đang tắt khẩn, từ chối đề nghị và API không có quyền
    # Truy vết: FR-17-001, 006 · API-17-002, 003, 007 · ERR-17-006, 007 · ERR-00-403, ERR-00-401
    # Mục đích: Chứng minh đề nghị bật bị chặn khi đang `KILLED`, đề nghị bị từ chối không đổi trạng thái và người không có `PERM-17-admin` không gọi được API quản trị.
    Biết T95 ở `KILLED`; U-T95-TA1, U-T95-TA2, U-T95-IE; một đề nghị `ENABLE` `PENDING` ở T90.
    Khi U-T95-TA1 `POST /policy/changes` `ENABLE` đủ trường.
    Và U-T90-TA2 `POST /policy/changes/{changeId}:reject` không có lý do, rồi với lý do 30 ký tự.
    Và U-T90-IE `GET /policy`, `POST /policy/changes`.
    Và gọi `GET /policy` không có token.
    Thì bước 1 `409` ERR-17-006 (trạng thái `KILLED`). Bước 2 lần đầu `422` ERR-17-007, lần sau `200` `REJECTED`, trợ lý vẫn tắt, EVT: `assist.policy-change.decided`. Bước 3 `403` ERR-00-403 (thiếu `PERM-17-admin`). Bước 4 `401` ERR-00-401.
