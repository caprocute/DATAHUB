# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-20
Tính năng: TS-19-20 · Xử lý chênh lệch

  @TC-19-476 @P2 @Dương
  Kịch bản: TC-19-476 Giao việc, nhận việc, ghi chú chỉ thêm
    # Truy vết: FR-19-045 · BR-19-030 · API-19-072, 074 · UI-19-21, 22
    Biết chênh lệch `AMOUNT_MISMATCH` từ TC-19-454; U-ACC1, U-ACC2.
    Khi U-ACC1 giao cho U-ACC2 (`ASSIGN`).
    Và U-ACC2 `CLAIM`, thêm ghi chú kèm tệp.
    Và thử `UPDATE` trực tiếp cột `notes` trong CSDL bằng vai trò `ph19_app`.
    Thì bước 1: người phụ trách đổi, trạng thái `OPEN`. Bước 2: `INVESTIGATING`, ghi chú hiện ở dòng thời gian. Bước 3 bị trigger chặn (chỉ thêm qua `append_discrepancy_note`).

  @TC-19-477 @P3 @Dương
  Kịch bản: TC-19-477 Chuyển cấp tới NCC và phản hồi
    # Truy vết: FR-19-045 · API-19-072
    Biết chênh lệch `INVESTIGATING`.
    Khi `ESCALATE` với `escalationRef` "PG-TICKET-1".
    Và `PROVIDER_RESPONDED` có ghi chú.
    Thì `ESCALATED` rồi `INVESTIGATING`. Quá `19.recon.escalate-workdays` thì DiscrepancyEscalator thông báo người phê duyệt.

  @TC-19-478 @P1 @Dương
  Kịch bản: TC-19-478 Đề xuất cập nhật trạng thái theo NCC và duyệt
    # Truy vết: FR-19-046 · BR-19-011, 014 · API-19-073, 050 · UI-19-22
    Biết chênh lệch `STATUS_MISMATCH` (Datahub `FAILED`, NCC thành công); U-ACC2 đề xuất; U-APR1.
    Khi U-ACC2 đề xuất `UPDATE_STATUS_FROM_PROVIDER` với `targetTransactionVersion`.
    Và U-APR1 duyệt.
    Thì bước 1: `PROPOSED`, đề nghị `DISCREPANCY_RESOLUTION`. Bước 2: ST: `FAILED` → `SUCCEEDED` nguồn `DISCREPANCY_RESOLUTION`; chênh lệch `RESOLVED`; WH: `transaction.succeeded`.

  @TC-19-479 @P2 @Dương
  Kịch bản: TC-19-479 Chấp nhận số liệu NCC, tạo yêu cầu hoàn, không xử lý
    # Truy vết: FR-19-046 · API-19-073
    Biết ba chênh lệch `AMOUNT_MISMATCH`, `DUPLICATE`, `MISSING_AT_PROVIDER` (kỹ thuật).
    Khi đề xuất `ACCEPT_PROVIDER_FIGURE`, `CREATE_REFUND` (số tiền trùng), `NO_ACTION` (ghi chú bắt buộc) và duyệt.
    Thì lần lượt: giao dịch có `adjustments` `PAYMENT_AMOUNT`; một yêu cầu hoàn `PENDING_APPROVAL` mới (phải qua duyệt hoàn riêng); chênh lệch đóng không đổi giao dịch. Ba chênh lệch `RESOLVED`.

  @TC-19-480 @P1 @Âm
  Kịch bản: TC-19-480 Đề xuất sai, tự duyệt, giao dịch đã đổi
    # Truy vết: FR-19-045, 046 · API-19-073, 050 · ERR-19-001, 033, 045
    Biết U-AA1 có `discrepancy-handle` và `discrepancy-approve` qua vai trò thử.
    Khi đề xuất `NO_ACTION` không ghi chú.
    Và U-AA1 đề xuất rồi tự duyệt.
    Và đề xuất với `targetTransactionVersion` cũ.
    Thì bước 1 trả `400` ERR-19-001. Bước 2 trả `403` ERR-19-033. Bước 3 trả `412` ERR-19-045.

  @TC-19-481 @P2 @Dương
  Kịch bản: TC-19-481 Chênh lệch tự khớp khi chạy lại so khớp
    # Truy vết: FR-19-044, 045 · BR-19-028 · API-19-066
    Biết chênh lệch `MISSING_AT_DATAHUB` do IPN đến muộn; IPN đã tới sau đó.
    Khi `POST /reconciliation-sessions/{id}/runs` `REMATCH`.
    Thì lần chạy 2; chênh lệch `RESOLVED` với `resolutionType = AUTO_MATCHED`; kết quả lần chạy 1 vẫn xem được.
