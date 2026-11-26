# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-14
Tính năng: TS-17-14 · Xóa lan truyền đoạn tri thức khi nguồn bị thu hồi hoặc đổi mức phân loại

  @TC-17-044 @P1 @Dương @Bảo_mật @Hiệu_năng
  Kịch bản: TC-17-044 Đổi mức phân loại sang RESTRICTED xóa đoạn trong 60 giây
    # Truy vết: FR-17-019, 016 · BR-17-029 · NFR-17-011 · EVT-17-16 · API-17-080
    # Mục đích: Đo từ EVT-09-01 đến khi đoạn không còn trong bảng và truy hồi không trả đoạn.
    Biết T90; API `API-HGD` `INTERNAL` đã chỉ mục thành 4 đoạn; canary `DH-CANARY-xoa` trong mô tả; PH-09 WireMock phát `t90.privacy.classification.changed.v1` đổi sang `RESTRICTED`.
    Khi IE `POST /search` tìm `API-HGD` (có kết quả).
    Và phát sự kiện đổi mức, ghi `t0`.
    Và đếm đoạn của tài liệu mỗi giây tới khi bằng 0; ghi `t1`.
    Và IE `POST /search` lại, và DS `GET /knowledge/deletions`.
    Và lặp 30 lần lấy p95.
    Thì bước 3 `t1 - t0` p95 ≤ 60 giây, xóa vật lý (không đánh dấu ẩn). Bước 4 không còn `API-HGD` (không có trích dẫn, không có canary); nhật ký xóa lan truyền ghi lý do "đổi mức", EVT: `assist.index.purged`, KT: có.

  @TC-17-045 @P1 @Dương @Âm
  Kịch bản: TC-17-045 Ngừng nguồn xóa mọi đoạn trong 5 phút, thu hồi tài liệu tải lên
    # Truy vết: FR-17-019 · API-17-068, 079 · BR-17-029 · NFR-17-011 · ERR-17-001 · EVT-17-16
    # Mục đích: Chứng minh xóa nguồn, xóa tài liệu và ngừng nguồn qua API.
    Biết T90; nguồn `SRC-FLOW` 40 tài liệu (200 đoạn); U-T90-DS.
    Khi DS `POST /knowledge/sources/{id}:retire`; đo thời gian tới khi 200 đoạn biến mất.
    Và DS `DELETE /knowledge/documents/{docId}` một tài liệu của nguồn khác.
    Và DS `DELETE` lại cùng tài liệu.
    Và IE `POST /search` hỏi nội dung của nguồn đã ngừng.
    Thì bước 1 `200`, mọi đoạn biến mất ≤ 5 phút, EVT: `assist.source.state-changed` rồi `assist.index.purged`. Bước 2 `200`, tài liệu `DELETED` và mất đoạn. Bước 3 `404` ERR-17-001. Bước 4 không trả đoạn nào của nguồn đã ngừng.

  @TC-17-046 @P2 @Chịu_lỗi @Bảo_mật
  Kịch bản: TC-17-046 Xóa lan truyền khi PH-09 chưa trả lời và khi sự kiện thu hồi bị trễ
    # Truy vết: FR-17-019 · BR-17-026, 029 · NFR-17-011
    # Mục đích: Chứng minh đóng an toàn: truy hồi kiểm lại mức khi có thể và đoạn nghi ngờ không được trả.
    Biết T94; API `API-X` đổi mức nhưng sự kiện EVT-09-01 trễ 5 phút; PH-09 sẵn sàng.
    Khi IE `POST /search` hỏi `API-X`.
    Và chờ sự kiện tới rồi kiểm lại.
    Thì bước 1 truy hồi kiểm lại mức qua PH-09 trước khi trả đoạn, `API-X` không được trích dẫn. Bước 2 đoạn bị xóa ≤ 60 giây sau khi nhận sự kiện.
