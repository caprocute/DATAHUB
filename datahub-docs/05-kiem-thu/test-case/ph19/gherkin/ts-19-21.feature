# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-21
Tính năng: TS-19-21 · Chốt, mở lại phiên và biên bản

  @TC-19-501 @P1 @Dương
  Kịch bản: TC-19-501 Chốt phiên, sinh biên bản
    # Truy vết: FR-19-047, 048 · API-19-068, 083, 084, 088 · UI-19-20
    Biết phiên `READY_TO_CLOSE` từ TC-19-451; U-ACC1.
    Khi bấm "Chốt phiên", gõ lại ngày, xác nhận.
    Và mở tab "Biên bản", tải PDF và XLSX.
    Thì bước 1: `CLOSED`, `closedBy`; tác vụ `RECON_MINUTES` chạy. Bước 2: PDF, XLSX có tổng hai phía; SHA-256 của PDF bằng `minutesSha256`; tệp ở bucket WORM. WH: `reconciliation.closed`. KT: có.

  @TC-19-502 @P1 @Âm
  Kịch bản: TC-19-502 Chốt phiên còn chênh lệch
    # Truy vết: FR-19-047 · API-19-068 · ERR-19-042, 021
    Biết phiên `IN_REVIEW` với 2 chênh lệch mở; phiên `COLLECTING`.
    Khi chốt phiên `IN_REVIEW`.
    Và chốt phiên `COLLECTING`.
    Thì bước 1 trả `409` ERR-19-042 với `count = 2`. Bước 2 trả `409` ERR-19-021.

  @TC-19-503 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-503 Phiên đã chốt bất biến
    # Truy vết: FR-19-047 · BR-19-030 · NFR-19-016 · API-19-065, 066, 072 · ERR-19-043
    Biết phiên `CLOSED` từ TC-19-501.
    Khi tải file lên phiên; chạy lại so khớp; sửa chênh lệch của phiên.
    Và `UPDATE reconciliation_session SET …` bằng `ph19_app`.
    Và xóa đối tượng biên bản trên Ceph RGW bằng tài khoản ứng dụng.
    Thì bước 1 trả `409` ERR-19-043. Bước 2 bị trigger chặn (SQLSTATE P1930). Bước 3 bị từ chối (khóa đối tượng WORM).

  @TC-19-504 @P1 @Dương @Âm
  Kịch bản: TC-19-504 Mở lại phiên có phê duyệt, người chốt không tự duyệt
    # Truy vết: FR-19-047 · BR-19-028 · API-19-069, 050 · ERR-19-033
    Biết phiên `CLOSED` do U-ACC1 chốt; U-AA1 được gán tạm `recon-close` và `recon-reopen-approve` và là người chốt phiên thứ hai.
    Khi U-ACC1 đề nghị mở lại có lý do.
    Và U-APR1 duyệt.
    Và trên phiên thứ hai, U-AA1 (người chốt) duyệt đề nghị mở lại do U-ACC1 lập.
    Thì bước 1: `REOPEN_PENDING`. Bước 2: `IN_REVIEW`, lần chạy mới; biên bản cũ giữ và đánh dấu "bị thay thế". Bước 3 trả `403` ERR-19-033.

  @TC-19-505 @P3 @Dương @Âm
  Kịch bản: TC-19-505 Đối tác tải kết quả đối soát phần của mình
    # Truy vết: FR-19-048 · API-19-107 · ERR-19-020
    Biết phiên D-1 `CLOSED`; phiên D-2 `IN_REVIEW`; C-DVC.
    Khi `P: GET /reconciliation-reports?date=D-1`.
    Và `?date=D-2`.
    Thì bước 1 trả tệp chỉ chứa giao dịch của P-DVC. Bước 2: 404-ẩn (phiên chưa chốt). Phát hành Đ2b.
