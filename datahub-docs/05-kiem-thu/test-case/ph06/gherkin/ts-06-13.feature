# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-13
Tính năng: TS-06-13 · So sánh cạnh nhau và quyết định

  @TC-06-061 @P1 @Dương
  Kịch bản: TC-06-061 So sánh cạnh nhau hai bản ghi
    # Truy vết: FR-06-029 · API-06-046 · UI-06-05 · BR-06-010 · BR-06-026
    # Mục đích: Chứng minh bảng so sánh có `ComparisonLevel` từng thuộc tính, che DLCN và ghi nhật ký truy cập, theo FR-06-029.
    Biết mục POSSIBLE_MATCH điểm 0,62; DS1.
    Khi DS1 mở mục.
    Và bấm "Hiện giá trị" thuộc tính `SENSITIVE` khi không có `PERM-09-unmask`.
    Thì bước 1 năm mức `EXACT`, `FUZZY_HIGH`, `FUZZY_LOW`, `DIFFERENT`, `MISSING` đúng từng thuộc tính, màu kèm nhãn chữ; NK: có. Bước 2 giá trị vẫn che.
    # Hậu điều kiện: Một dòng `access_log`.

  @TC-06-062 @P1 @Dương
  Kịch bản: TC-06-062 Quyết định khớp hợp nhất ngay mức rủi ro thấp
    # Truy vết: FR-06-030 · BR-06-008, 019 · API-06-048 · EVT-06-03 · PERM-06-steward
    # Mục đích: Chứng minh quyết định `MATCH` có lý do ≥ 20 ký tự hợp nhất và phát sự kiện, theo FR-06-030.
    Biết mục hai bản ghi vàng 1 liên kết mỗi bên, điểm 0,96; DS1 đã nhận.
    Khi `POST /stewardship/items/{id}:decide` `MATCH`, `survivorId`, lý do 40 ký tự.
    Thì `200`, `riskLevel = LOW`, mục `RESOLVED`, bản ghi vàng còn lại `MERGED`, xref chuyển sang bản sống sót, EVT-06-03. KT: có (steward-decide).
    # Hậu điều kiện: Một bản ghi vàng `MERGED`.

  @TC-06-063 @P2 @Dương
  Kịch bản: TC-06-063 Quyết định không khớp và hoãn
    # Truy vết: FR-06-030 · BR-06-023 · API-06-048
    # Mục đích: Chứng minh `NO_MATCH` ghi `negativeLink` và `DEFER` giữ mục, theo FR-06-030.
    Biết hai mục POSSIBLE_MATCH; DS1.
    Khi `decide` `NO_MATCH` mục 1 kèm lý do.
    Và `decide` `DEFER` mục 2.
    Thì mục 1 `RESOLVED`, có `negativeLink`, cặp không đề xuất lại. Mục 2 `DEFERRED`, có hạn nhắc.
    # Hậu điều kiện: Một negativeLink.

  @TC-06-064 @P1 @Âm
  Kịch bản: TC-06-064 Lý do ngắn, mục lỗi thời, khác số định danh
    # Truy vết: FR-06-029, 030 · BR-06-006, 008 · API-06-048 · ERR-06-007, 029, 030
    # Mục đích: Chứng minh ba nhánh chặn quyết định, theo FR-06-030.
    Biết mục cặp CC-01/CC-02; mục M5 có bản ghi vừa đổi.
    Khi `decide` `MATCH` với lý do 10 ký tự.
    Và `decide` `MATCH` cặp CC-01/CC-02 kèm lý do đủ dài.
    Và sửa bản ghi của M5 rồi `decide` M5.
    Thì bước 1 `422` ERR-06-007. Bước 2 `422` ERR-06-029, nút "Khớp" ở UI bị vô hiệu kèm chú thích. Bước 3 `409` ERR-06-030, mục xem xét lại.
    # Hậu điều kiện: Không hợp nhất.
