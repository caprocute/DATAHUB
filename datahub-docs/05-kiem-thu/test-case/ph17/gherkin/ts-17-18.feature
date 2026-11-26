# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-18
Tính năng: TS-17-18 · Xem, xóa lịch sử hội thoại của tôi và hết hạn theo hạn lưu

  @TC-17-059 @P1 @Dương @Âm
  Kịch bản: TC-17-059 Xem lịch sử, xóa một hội thoại, xóa toàn bộ
    # Truy vết: FR-17-027 · API-17-091, 092, 093, 094 · BR-17-039 · ERR-17-051, 001 · UI-17-05
    # Mục đích: Chứng minh xóa ẩn khỏi lịch sử của người dùng ngay và giới hạn số hội thoại.
    Biết T90 `17.conversation.max-per-user = 20`; U-T90-IE có 20 hội thoại; U-T90-VW có 3.
    Khi IE `POST /conversations` hội thoại thứ 21.
    Và IE `GET /conversations`; tìm theo từ khóa.
    Và IE `DELETE /conversations/{id}`; rồi `GET` cùng id.
    Và IE `DELETE /conversations`.
    Và kiểm bảng nhật ký đã che của IE.
    Thì bước 1 `409` ERR-17-051. Bước 2 20 hội thoại theo thời gian, tìm được. Bước 3 `200` rồi `404` ERR-17-001. Bước 4 `200`, lịch sử rỗng, hội thoại của VW không đổi. Bước 5 bản nhật ký đã che còn (SO, AU truy cập có lý do, Q17-24).

  @TC-17-060 @P1 @Dương @Biên
  Kịch bản: TC-17-060 Nhật ký quá 90 ngày bị xóa vật lý trong 24 giờ
    # Truy vết: FR-17-027, 055 · API-17-172 · BR-17-039, 073 · NFR-17-017 · EVT-17-27
    # Mục đích: Chứng minh BR-17-039, NFR-17-017 và sự kiện xóa.
    Biết T95 (đồng hồ giả); 40 hội thoại ngày D-91, 10 hội thoại ngày D-89; `17.log.retention-days = 90`.
    Khi đẩy đồng hồ tới sau lượt xóa hằng ngày (24 giờ).
    Và đếm hội thoại còn lại; SO `GET /logs/retention`.
    Và IE `GET /conversations/{id}` của hội thoại D-91.
    Thì bước 2 chỉ còn 10 hội thoại D-89, 40 hội thoại D-91 bị xóa vật lý (không còn ở bảng, kể cả bản sao ẩn), EVT: `assist.log.purged` kèm số 40, hiển thị kết quả xóa gần nhất. Bước 3 `404` ERR-17-001.

  @TC-17-061 @P1 @Bảo_mật @Âm
  Kịch bản: TC-17-061 Lịch sử không lẫn tenant
    # Truy vết: FR-17-027 · API-17-091, 092, 098 · BR-17-033, 086 · NFR-17-007 · ERR-17-001
    # Mục đích: Chứng minh BR-17-086 cho API hội thoại.
    Biết T90 và T91 cùng mã người dùng nội bộ `quan.nv` (đối chứng); `CV-90-1` thuộc T90.
    Khi U-T91-IE `GET /conversations/{CV-90-1}` và `/messages`.
    Và U-T91-IE `GET /conversations`.
    Thì bước 1 `404` ERR-17-001, thân giống "không tồn tại" trừ `traceId`. Bước 2 chỉ hội thoại của T91.
