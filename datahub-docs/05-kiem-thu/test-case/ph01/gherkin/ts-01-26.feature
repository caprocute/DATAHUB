# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-26
Tính năng: TS-01-26 · Xác nhận của đơn vị, xử lý kết quả và báo cáo rà soát

  @TC-01-099 @P1 @Dương
  Kịch bản: TC-01-099 Gửi phiếu và đơn vị trả lời
    # Truy vết: FR-01-041 · UC-01-28 · API-01-069, 070, 071 · UI-01-12, 13 · BR-01-014.
    Biết kỳ `OPEN`; U-T68-TA1; U-T68-OR1 (Sở Tư pháp).
    Khi TA1 `POST …:send-confirmations`.
    Và đọc thư mail-sink; OR1 mở liên kết, đăng nhập MFA; `GET /access-review-confirmations/{token}`.
    Và OR1 `POST …:respond`: phạm vi 1 "Còn cần", phạm vi 2 "Thu hẹp", phạm vi 3 "Không cần".
    Thì bước 1: `202`, kỳ `WAITING`. Bước 2: thư chỉ có liên kết (hạn 30 ngày); phiếu liệt kê phạm vi của đơn vị kèm mức dùng thực tế. Bước 3: `200`, phản hồi lưu; hết phản hồi thì kỳ sang `DECIDING`.

  @TC-01-100 @P1 @Âm @Bảomật
  Kịch bản: TC-01-100 Phiếu: sai người, hết hạn, đã trả lời
    # Truy vết: FR-01-041 · API-01-070, 071 · ERR-01-025, 040.
    Biết phiếu `PENDING` của Sở Tư pháp; phiếu quá 30 ngày; phiếu đã trả lời; U-T68-OR2.
    Khi OR2 (tổ chức khác) mở phiếu của Sở Tư pháp.
    Và OR1 mở phiếu quá hạn; trả lời lần hai phiếu đã trả lời.
    Thì `403` ERR-01-025; `410` ERR-01-040 cho cả hai.

  @TC-01-101 @P2 @Biên
  Kịch bản: TC-01-101 Đơn vị không phản hồi sau 30 ngày: đề xuất thu hẹp
    # Truy vết: FR-01-041, 042 · UC-01-28 · BR-01-014 · API-01-068.
    Biết phiếu đã gửi; `accessReview.noResponseDays = 30`; đồng hồ giả.
    Khi tua 31 ngày; chạy tác vụ; `GET …/items`.
    Thì kỳ sang `DECIDING`; các phạm vi của đơn vị không phản hồi có đề xuất "Thu hẹp".

  @TC-01-102 @P1 @Dương @Âm
  Kịch bản: TC-01-102 Quyết định thu hẹp, thu hồi phạm vi và đóng kỳ
    # Truy vết: FR-01-042 · UC-01-29 · API-01-072 · UI-01-12 · BR-01-003, 009 · ERR-01-020, 033, 035, 041 · EVT-01-11, 12.
    Biết kỳ `DECIDING`; kỳ `OPEN`; TA1 có MFA mới.
    Khi `POST …/items:decide` thu hẹp một phạm vi, thu hồi một phạm vi, kèm lý do.
    Và lặp với (a) thiếu lý do; (b) thiếu MFA; (c) quyết định ngoài danh sách; (d) kỳ đang `OPEN`.
    Và xử lý hết mục; xem kỳ.
    Thì bước 1: `200`; trần thu hẹp hoặc thu hồi, `EVT-01-11`. Bước 2: (a) `400` ERR-01-033; (b) `403` ERR-01-035; (c) `422` ERR-01-041; (d) `409` ERR-01-020. Bước 3: kỳ `CLOSED`, `EVT-01-12`, bằng chứng giữ 5 năm.

  @TC-01-103 @P3 @Dương @Âm
  Kịch bản: TC-01-103 Báo cáo rà soát và xuất (Đợt 2)
    # Truy vết: FR-01-044 · UC-01-29 · API-01-074, 075 · UI-01-12 · ERR-01-020, 052.
    Biết kỳ `CLOSED`; kỳ `OPEN`; U-T68-AU; U-T68-OR1.
    Khi AU `GET …/report`; `POST …/report:export`.
    Và AU gọi báo cáo kỳ `OPEN`; OR1 gọi báo cáo.
    Thì bước 1: `200` rồi `202`, tệp có đủ quyết định, người quyết, lý do. Bước 2: `409` ERR-01-020; `403-PQ`.
