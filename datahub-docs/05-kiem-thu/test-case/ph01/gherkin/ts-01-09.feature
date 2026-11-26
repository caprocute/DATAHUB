# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-09
Tính năng: TS-01-09 · Thẩm định kỹ thuật và tác động hạn mức dữ liệu quốc gia

  @TC-01-041 @P1 @Dương @Âm
  Kịch bản: TC-01-041 Ghi kết luận kỹ thuật đúng quy tắc
    # Truy vết: FR-01-013 · UC-01-09 · API-01-024 · UI-01-06 · BR-01-017, 019, 026 · ERR-01-017, 019, 020, 047 · EVT-01-02.
    Biết `HT-HOTICH-SS` mức Hạn chế; U-T68-IE (được giao), U-T68-TECH, U-T68-X1.
    Khi IE `POST …/reviews/technical` xác nhận nhóm 2, chọn xác thực bằng khóa công khai.
    Và lặp với (a) thiếu `confirmedGroup`; (b) chọn chuỗi bí mật; (c) cấp độ `L2`; (d) người ngoài phân công; (e) X1 là người lập hồ sơ; (f) bước đã hoàn tất.
    Thì bước 1: `200`, `confirmedGroup = 2`; KT: có; EVT: `EVT-01-02`. Bước 2: (a) `422` ERR-01-019; (b) và (c) `422` ERR-01-047 (BR-01-019, 026); (d) `403-PQ`; (e) `403` ERR-01-017; (f) `409` ERR-01-020.

  @TC-01-042 @P2 @Dương @Biên
  Kịch bản: TC-01-042 Tác động hạn mức quốc gia theo ngưỡng
    # Truy vết: FR-01-015 · UC-01-09 · API-01-026 · UI-01-06 · BR-01-016.
    Biết `HT-HOTICH-SS` có nhu cầu dịch vụ quốc gia; giả lập PH-14 trả hạn mức còn lại; `quotaImpact.mediumPct = 20`, `highPct = 50`.
    Khi `POST …/reviews/quota-impact` với dự kiến 19 %, 20 %, 50 % hạn mức còn lại.
    Thì mức tác động lần lượt `LOW`, `MEDIUM`, `HIGH` (biên đúng ngưỡng); kết quả đi vào kết luận kỹ thuật.

  @TC-01-043 @P3 @Âm @Chịulỗi
  Kịch bản: TC-01-043 PH-14 không khả dụng khi đánh giá tác động
    # Truy vết: FR-01-015 · API-01-026 · ERR-01-046.
    Biết PH-14 giả lập `fail`.
    Khi gọi `…/reviews/quota-impact`.
    Thì `503` ERR-01-046; không mất kết luận đã ghi trước đó; người thẩm định ghi được ghi chú "chưa đánh giá được".
