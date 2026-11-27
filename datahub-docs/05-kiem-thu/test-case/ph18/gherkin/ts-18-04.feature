# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-04
Tính năng: TS-18-04 · Xem lịch sử, so sánh và khôi phục phiên bản tham số

  @TC-18-014 @P1 @Dương
  Kịch bản: TC-18-014 Xem lịch sử, so sánh v1 với v3 và khôi phục v1 thành v4
    # Truy vết: FR-18-005 · API-18-013, 014, 015, 016 · BR-18-005 · EVT-18-01 · UI-18-09
    # Mục đích: Chứng minh BR-18-005: khôi phục không xóa phiên bản trung gian, tạo phiên bản mới có ghi nguồn khôi phục.
    Biết T90; `04.retry.max-attempts` có ba phiên bản (3, 5, 4).
    Khi U-T90-TA1 mở `/van-hanh/tham-so/04.retry.max-attempts/lich-su`.
    Và `GET /params/04.retry.max-attempts/versions:compare?from=1&to=3`.
    Và `POST /params/04.retry.max-attempts/versions/1:restore` kèm lý do và `If-Match`.
    Thì bước 1 ba dòng có người đổi, lý do, thời điểm, phiên bản 3 đánh dấu hiện hành. Bước 2 `200` hiện giá trị trước và sau. Bước 3 `200`, phiên bản 4 giá trị 3, `restoredFrom = 1`, phiên bản 1 đến 3 còn nguyên, EVT-18-01 phát.

  @TC-18-015 @P1 @Âm
  Kịch bản: TC-18-015 Khôi phục phiên bản không tồn tại, không còn hợp lệ với lược đồ, thiếu lý do
    # Truy vết: FR-18-005 · API-18-015 · BR-18-002, 005 · ERR-18-001, 007, 023
    # Mục đích: Chứng minh khôi phục vẫn đi qua kiểm miền của lược đồ hiện hành và cần lý do.
    Biết T90; `02.review.sla-days` phiên bản 1 giá trị 20, lược đồ hiện hành đã thu miền về 1…15 (sau khi PH-02 di chuyển dữ liệu).
    Khi `POST /params/02.review.sla-days/versions/9:restore`.
    Và `POST /params/02.review.sla-days/versions/1:restore` có lý do.
    Và khôi phục phiên bản 2 hợp lệ nhưng lý do rỗng.
    Thì bước 1 `404` ERR-18-001. Bước 2 `409` ERR-18-023 nêu miền mới. Bước 3 `422` ERR-18-007. Không phiên bản mới nào được tạo.
