# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-04
Tính năng: TS-19-04 · Tạm dừng, mở lại, ngừng hẳn NCC

  @TC-19-076 @P1 @Dương
  Kịch bản: TC-19-076 Tạm dừng NCC khi còn giao dịch dở
    # Truy vết: FR-19-006 · BR-19-009 · API-19-013 · UI-19-04 · LGC-PAY-008
    Biết U-ADM1; C-DVC được gán S-PG2.
    Khi U-ADM1 bấm "Tạm dừng" trên UI-19-04, đọc hộp, nhập lý do, xác nhận.
    Và C-DVC gọi `P: POST /payments` cho S-PG2.
    Và `PGSIM` gửi IPN thành công cho TX-PEND2.
    Và chạy PendingQueryScheduler.
    Thì bước 1: hộp hiện "Đang có 1 giao dịch chờ thanh toán…"; API trả `200`, `status = SUSPENDED`. Bước 2 trả `503` ERR-19-017 có `Retry-After`, không ghi giao dịch. Bước 3: ST: `PENDING` → `SUCCEEDED`; WH: `transaction.succeeded`. Bước 4 vẫn truy vấn NCC tạm dừng. KT: có (`PROVIDER_SUSPEND` kèm lý do). EVT: `provider.suspended`.

  @TC-19-077 @P1 @Dương @Âm
  Kịch bản: TC-19-077 Mở lại NCC cần kiểm tra kết nối trong một giờ
    # Truy vết: FR-19-006 · API-19-014, 009 · ERR-19-021
    Biết PV-PG2 `SUSPENDED` từ TC-19-076; lần kiểm tra kết nối cuối cách 2 giờ.
    Khi `POST /providers/{id}/resumptions` với lý do.
    Và chạy kiểm tra kết nối `PRODUCTION` đạt; gọi lại bước 1.
    Thì bước 1 trả `409` ERR-19-021 với `detail` "chưa có kiểm tra kết nối đạt trong 1 giờ"; `disabledReasons.RESUME` cùng nội dung. Bước 2 trả `200`, `status = ACTIVE`. KT: có (`PROVIDER_RESUME`).

  @TC-19-078 @P2 @Dương
  Kịch bản: TC-19-078 Ngừng hẳn NCC có phê duyệt sau khi hết việc dở
    # Truy vết: FR-19-010 · BR-19-027, 011 · API-19-012, 050 · LGC-PAY-005
    Biết PV-PG2 `SUSPENDED`, không còn giao dịch `CREATED`/`PENDING`, yêu cầu hoàn mở, phiên đối soát chưa chốt.
    Khi U-ADM1 gửi `{"action":"RETIRE"}` kèm lý do.
    Và U-APR1 duyệt.
    Thì bước 1 trả `201`. Bước 2: `status = RETIRED`, `retiredAt` có giá trị; dịch vụ của NCC không kích hoạt được; NCC vẫn hiện ở UI-19-02 nhóm "Kênh đã ngừng". EVT: `provider.retired`.

  @TC-19-079 @P1 @Âm
  Kịch bản: TC-19-079 Ngừng hẳn khi còn việc dở, xóa NCC đã có giao dịch
    # Truy vết: FR-19-010 · BR-19-027 · API-19-005, 012 · ERR-19-036, 037
    Biết PV-PG (có giao dịch `PENDING` và phiên đối soát `IN_REVIEW`).
    Khi gửi đề nghị `RETIRE` cho PV-PG.
    Và gọi `DELETE /providers/{PV-PG}`.
    Thì bước 1 trả `409` ERR-19-036 với `pendingTransactions`, `openSessions` đúng số. Bước 2 trả `409` ERR-19-037. Dữ liệu không đổi.

  @TC-19-080 @P2 @Dương
  Kịch bản: TC-19-080 Xóa cứng NCC Nháp chưa có giao dịch
    # Truy vết: FR-19-010 · API-19-005 · UI-19-03 · LGC-PAY-005
    Biết U-ADM1; NCC `MOCK3` từ TC-19-001.
    Khi trên UI-19-03 chọn "Xóa", gõ lại mã, xác nhận.
    Và `GET /providers/{id}`.
    Thì bước 1 trả `204`. Bước 2: 404-ẩn. Tham chiếu bí mật đã gắn được gỡ khỏi `provider_credential`; `callback_route` không còn `connectionKey` của NCC. KT: có (`PROVIDER_DELETE`).

  @TC-19-081 @P2 @Âm
  Kịch bản: TC-19-081 Chuyển trạng thái NCC trái máy trạng thái
    # Truy vết: FR-19-005, 006, 010 · API-19-012, 013, 014 · ERR-19-021
    Biết NCC ở từng trạng thái `DRAFT`, `PENDING_ACTIVATION`, `ACTIVE`, `SUSPENDED`, `RETIRED`.
    Khi với mỗi trạng thái, gọi mọi thao tác vòng đời không có trong khung §7.1 (ví dụ tạm dừng NCC `DRAFT`, mở lại NCC `ACTIVE`, gửi `ACTIVATE` cho NCC `RETIRED`).
    Thì mọi lời gọi trả `409` ERR-19-021, `detail` nêu trạng thái hiện tại; `allowedActions` của bản ghi không chứa thao tác đó. UT phủ đủ ma trận 5 × 6.
