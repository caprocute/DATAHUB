# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-19
Tính năng: TS-19-19 · Đối soát ngày

  @TC-19-451 @P1 @Dương
  Kịch bản: TC-19-451 Phiên tự động khớp hoàn toàn
    # Truy vết: FR-19-042, 043, 044 · BR-19-025 · UI-19-19, 20
    Biết ngày D-1 có 100 giao dịch thành công của PV-PG; `PGSIM` phục vụ F-RECON-OK lúc 06:00.
    Khi tiến đồng hồ tới 06:00 giờ Việt Nam; chạy SessionScheduler.
    Và mở UI-19-20.
    Thì bước 1: một phiên (PV-PG, D-1) `SCHEDULED` → `COLLECTING` → `MATCHING` → `READY_TO_CLOSE`. Bước 2: tổng hợp hai phía bằng nhau, khớp tự động 100%; mọi giao dịch có `reconStatus = MATCHED`. Giao dịch thử không có trong phiên.

  @TC-19-452 @P2 @Âm
  Kịch bản: TC-19-452 NCC chưa có dữ liệu, thu thập lại
    # Truy vết: FR-19-043 · API-19-066 · BR-19-025
    Biết `PGSIM` trả "chưa có dữ liệu" tới 09:00.
    Khi chạy phiên lúc 06:00.
    Và tiến tới 09:05; U-ACC1 bấm "Thu thập lại".
    Thì bước 1: `WAITING_DATA`, `nextCollectAt` có giá trị; huy hiệu "Đối soát" tăng. Bước 2: `COLLECTING` → `MATCHING` → `READY_TO_CLOSE`. Quá `19.recon.collect-deadline` mà vẫn thiếu thì cảnh báo PH-13.

  @TC-19-453 @P1 @Dương @Âm
  Kịch bản: TC-19-453 Tải file đối soát lên, mã băm và nội dung sai
    # Truy vết: FR-19-043 · API-19-065 · ERR-19-041 · UI-19-20
    Biết phiên `WAITING_DATA`; U-ACC1; F-RECON-BADHASH; tệp của ngày khác; F-RECON-OK.
    Khi tải F-RECON-BADHASH.
    Và tải tệp của ngày D-2.
    Và tải F-RECON-OK (giao diện tự tính SHA-256).
    Thì bước 1, 2 trả `422` ERR-19-041 với lý do "sai mã băm", "sai ngày". Bước 3 trả `202`; phiên tiếp tục so khớp; tệp lưu WORM.

  @TC-19-454 @P1 @Dương
  Kịch bản: TC-19-454 So khớp sinh đủ loại chênh lệch
    # Truy vết: FR-19-044, 045 · BR-19-028 · API-19-067, 070, 071
    Biết F-RECON-DIFF.
    Khi chạy phiên với F-RECON-DIFF.
    Và `GET /reconciliation-sessions/{id}/items?matchResult=MISMATCHED,MISSING_DH,MISSING_PROVIDER`.
    Thì bước 1: phiên `IN_REVIEW`, đúng 5 chênh lệch loại `MISSING_AT_DATAHUB`, `MISSING_AT_PROVIDER`, `AMOUNT_MISMATCH`, `STATUS_MISMATCH`, `DUPLICATE`; mỗi dòng lệch đúng một chênh lệch. Bước 2: 5 dòng, mỗi dòng có `discrepancyId`.

  @TC-19-456 @P1 @Âm
  Kịch bản: TC-19-456 So khớp loại giao dịch không thuộc phiên
    # Truy vết: FR-19-044 · BR-19-025, 028, 033, 034
    Biết ngày D-1 có thêm: 2 giao dịch thử, 1 giao dịch `is_shadow`, 1 giao dịch của NCC khác, 1 giao dịch thanh toán lúc 00:00:01 ngày D; tệp NCC khớp đúng phần còn lại.
    Khi chạy phiên (PV-PG, D-1).
    Thì phiên `READY_TO_CLOSE`, 0 chênh lệch; năm giao dịch trên không có trong phiên; giao dịch 00:00:01 nằm ở phiên ngày D.

  @TC-19-455 @P2 @Âm
  Kịch bản: TC-19-455 Tạo phiên trùng, phiên ngày chưa kết thúc
    # Truy vết: FR-19-042 · API-19-063 · ERR-19-040, 001
    Biết U-ACC1; phiên (PV-PG, D-1) đã có.
    Khi `POST /reconciliation-sessions` (PV-PG, D-1).
    Và (PV-PG, hôm nay).
    Thì bước 1 trả `409` ERR-19-040. Bước 2 trả `400` ERR-19-001.
