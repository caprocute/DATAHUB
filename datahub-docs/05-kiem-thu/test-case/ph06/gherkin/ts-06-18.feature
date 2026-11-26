# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-18
Tính năng: TS-06-18 · Hợp nhất bản ghi vàng thủ công

  @TC-06-080 @P1 @Dương
  Kịch bản: TC-06-080 Hợp nhất hai bản ghi vàng
    # Truy vết: FR-06-037 · API-06-058 · UI-06-06 · EVT-06-03 · BR-06-005 · PERM-06-merge
    # Mục đích: Chứng minh hợp nhất chuyển xref, tính lại sống sót, ghi ảnh chụp, theo FR-06-037.
    Biết hai bản ghi vàng cùng người, một liên kết mỗi bên, không CCCD mâu thuẫn; DS1.
    Khi `POST .../golden-records:merge` `survivorId`, `mergedIds`, lý do 40 ký tự.
    Và `GET` hai bản ghi và `history`.
    Thì `200` mức `LOW`; bản ghi bị gộp `MERGED` `mergedInto`, xref của nó sang survivor; `version` tăng; ảnh chụp cả hai; EVT-06-03 có `mergedGoldenIds`. KT: có (merge).
    # Hậu điều kiện: Dùng ở undo-merge.

  @TC-06-081 @P1 @Âm
  Kịch bản: TC-06-081 Hợp nhất khác số định danh qua mọi đường
    # Truy vết: FR-06-037, 030, 022, 021 · BR-06-006 · ERR-06-007, 029 · API-06-058
    # Mục đích: Chứng minh tiêu chí chấp nhận 4: hai bản ghi có CCCD khác nhau không hợp nhất được bằng bất kỳ đường nào.
    Biết hai bản ghi vàng CC-01 và CC-02 (cùng tên, ngày sinh); DA1.
    Khi `merge` thủ công kèm lý do đủ dài.
    Và `decide` `MATCH` ở hàng đợi.
    Và ép job lô và resolve trực tuyến cho cặp này.
    Và DA1 duyệt một đề nghị hợp nhất cặp này (tạo bằng cách sửa dữ liệu trực tiếp trong CSDL kiểm thử).
    Thì bước 1, 2 `422` ERR-06-029. Bước 3 không `MATCH`. Bước 4 `422` ERR-06-029 ngay khi duyệt (kiểm phía máy chủ). Hai bản ghi vẫn `ACTIVE`; cũng chặn khi thiếu lý do `422` ERR-06-007.
    # Hậu điều kiện: Hai bản ghi riêng.

  @TC-06-082 @P1 @Dương @Âm
  Kịch bản: TC-06-082 Hợp nhất từ ba bản ghi chờ duyệt
    # Truy vết: FR-06-037, 031 · BR-06-019 · API-06-058, 061 · ERR-06-031
    # Mục đích: Chứng minh hợp nhất ≥ 3 bản ghi là rủi ro cao, khóa bản ghi và chờ DA, theo BR-06-019.
    Biết ba bản ghi vàng cùng người; DS1, DA1.
    Khi DS1 `merge` ba bản ghi.
    Và DS2 `merge` một trong ba.
    Và DA1 `:approve`.
    Thì bước 1 `202` `PENDING_APPROVAL`, ba bản ghi `LOCKED`. Bước 2 `409` ERR-06-031. Bước 3 áp, EVT-06-03, mở khóa.
    # Hậu điều kiện: Ba bản ghi thành một.
