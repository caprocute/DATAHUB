# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-17
Tính năng: TS-19-17 · Lập yêu cầu hoàn tiền

  @TC-19-401 @P1 @Dương
  Kịch bản: TC-19-401 Kế toán lập yêu cầu hoàn toàn phần
    # Truy vết: FR-19-038 · BR-19-022 · API-19-059, 087 · UI-19-18 · LGC-PAY-025
    Biết U-ACC1; TX-OK; F-VOUCHER làm tài liệu đính kèm.
    Khi từ UI-19-15 của TX-OK bấm "Lập yêu cầu hoàn", chọn "Toàn phần", lý do "Nộp thừa", ngân hàng, số tài khoản, tải tài liệu.
    Và bấm "Gửi yêu cầu hoàn".
    Thì bước 1: tệp quét `CLEAN` trước khi bật nút gửi. Bước 2: `POST /refunds` trả `201`, `status = PENDING_APPROVAL`, `mode = MANUAL`, `accountNoMasked` chỉ còn 4 số cuối; số tài khoản lưu mã hóa. KT: có. EVT: `refund.requested`.

  @TC-19-402 @P2 @Dương
  Kịch bản: TC-19-402 Đối tác lập yêu cầu hoàn một phần
    # Truy vết: FR-19-038 · API-19-105, 106
    Biết C-DVC; TX-PR (còn được hoàn 600.000 ₫).
    Khi `P: POST /refunds` 300.000 ₫ có khóa.
    Và `P: GET /refunds/{refundCode}`.
    Thì bước 1 trả `201`, `requestedByType = PARTNER`. Bước 2 trả `PENDING_APPROVAL`.

  @TC-19-403 @P1 @Âm
  Kịch bản: TC-19-403 Hoàn sai trạng thái, quá hạn, vượt số còn được hoàn, giao dịch thử
    # Truy vết: FR-19-038 · BR-19-022, 033 · API-19-059 · ERR-19-029, 030, 031, 032
    Biết U-ACC1; TX-PEND; TX-OLD; TX-PR; TX-TEST; tenant T68 bản sao có `19.refund.enabled = false`.
    Khi hoàn TX-PEND.
    Và hoàn TX-OLD.
    Và hoàn TX-PR 600.001 ₫.
    Và hoàn TX-TEST.
    Và lập thêm yêu cầu cho TX-PR khi đang có yêu cầu `PENDING_APPROVAL`.
    Và hoàn ở tenant đã tắt hoàn tiền.
    Thì bước 1, 4, 5 trả `409` ERR-19-029. Bước 2 trả `422` ERR-19-031. Bước 3 trả `422` ERR-19-030 với `remaining = 600000`. Bước 6 trả `422` ERR-19-032.
