# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-19
Tính năng: TS-11-19 · Theo dõi nhật ký Saga, xử lý bù trừ thủ công và đối soát định kỳ

  @TC-11-107 @P1 @Dương
  Kịch bản: TC-11-107 Xem nhật ký Saga
    # Truy vết: FR-11-052 · API-11-096, 097, 129 · UI-11-21 · BR-11-013, 025 · PERM-11-read, PERM-11-audit-read
    Biết một số Saga `SUCCEEDED`, `PARTIAL`; TO, AU.
    Khi TO `GET /sagas?status=PARTIAL&page=0&size=10`
    Và TO `GET /sagas/{id}`
    Và AU xuất nhật ký bằng `POST /sagas:export`
    Thì danh sách đúng trạng thái; chi tiết có `attempt`, `status`, `responseCode`, `evidence`, `resolvedBy` từng bước; AU xuất được tệp CSV có băm.

  @TC-11-108 @P2 @Âm
  Kịch bản: TC-11-108 Xem Saga sai tham số, tenant khác, xuất không quyền
    # Truy vết: FR-11-052 · API-11-096, 097, 129 · ERR-11-001, 003 · ERR-00-403
    Biết VW; `U-T91-IE1`.
    Khi VW `GET /sagas?status=FOO`
    Và `U-T91-IE1` `GET /sagas/{id}`
    Và VW `POST /sagas:export`
    Thì bước 1 `400` ERR-11-003. Bước 2 `404-ẩn` ERR-11-001. Bước 3 `403` ERR-00-403.

  @TC-11-109 @P1 @Dương
  Kịch bản: TC-11-109 Thử lại, xác nhận thủ công, hết lượt thử
    # Truy vết: FR-11-053 · API-11-099, 100 · UI-11-21 · EVT-11-15 · ERR-11-110 · BR-11-009, 012 · PERM-11-compensate
    Biết T92 `11.saga.maxRetries = 2`, `11.saga.retryBackoffSeconds = 30`; `ph04-sim` trả `failed` cho `huyDangKyThuongTru` 3 lần; TO.
    Khi gây Saga cho `HS-25`
    Và CLK +30 giây hai lần
    Và đọc `saga_step` và `saga_log`
    Và TO `POST /sagas/{id}/steps/{stepId}:retry`
    Và `ph04-sim` trả `completed`
    Thì hai lần thử lỗi (ERR-11-110 "Bù trừ huyDangKyThuongTru … vẫn lỗi"), sau đó bước `MANUAL`, việc `MANUAL_COMPENSATION`, cảnh báo P1, phiên `FAILED`, `saga_log` `PARTIAL`, EVT: `saga.compensation.failed` có `manualSteps`. Bước 4 `RUNNING` rồi `DONE`, phiên `COMPENSATED`.

  @TC-11-110 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-110 Bỏ qua bước bù trừ qua bốn mắt, bước không ở thủ công
    # Truy vết: FR-11-053 · API-11-101, 132, 133, 099, 100 · ERR-11-005, 006, 007 · ERR-00-403 · BR-11-012
    Biết hai bước `MANUAL` (`b1`, `b2`), một bước `DONE`; TA, TA2, TO, VW.
    Khi TO đề nghị `:skip` `b1` không lý do
    Và TO đề nghị `:skip` `b1` với lý do 40 ký tự
    Và TO gọi `:approve-skip` chính đề nghị của mình
    Và TA2 `:reject-skip` rồi TA `:approve-skip` đề nghị mới cho `b2` do TA2 đề nghị
    Và TO `:retry` bước `DONE`; VW `:resolve-manual`
    Thì bước 1 `422` ERR-11-007. Bước 2 chỉ tạo đề nghị và việc `MANUAL_COMPENSATION` cho TA khác, `b1` vẫn `MANUAL`. Bước 3 `403` ERR-11-005. Bước 4 `b1` về `MANUAL` có lý do từ chối; `b2` `SKIPPED` do người khác duyệt, KT: có. Bước 5 `409` ERR-11-006 rồi `403` ERR-00-403.

  @TC-11-111 @P2 @Dương @Âm
  Kịch bản: TC-11-111 Đối soát bù trừ định kỳ
    # Truy vết: FR-11-054 · API-11-102, 103 · ERR-11-121 · BR-11-012
    Biết một bước `DONE` mà `ph04-sim` báo bù trừ chưa hiệu lực; lịch `11.saga.reconcileCron = 0 0 2 * * *`; TO.
    Khi CLK tới 02:00
    Và TO `POST /reconciliations`
    Và `GET /reconciliations` và `GET /incidents`
    Thì lịch chạy tự động và chạy tay `202`; kết quả liệt kê một sai lệch; sự cố ERR-11-121 `OPEN` và việc cho TO; bước sai lệch không bị tự sửa.
