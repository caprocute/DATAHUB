# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-03
Tính năng: TS-09-03 · Đề xuất, xác nhận và hạ mức phân loại trường

  @TC-09-007 @P1 @Dương
  Kịch bản: TC-09-007 Đề xuất rồi xác nhận nâng mức, sự kiện đổi phân loại
    # Truy vết: FR-09-004 · API-09-015, 016, 019 · UI-09-03 · EVT-09-01 · BR-09-003
    # Mục đích: Chứng minh nâng mức chỉ cần một người xác nhận khác người đề xuất, có sự kiện và lịch sử.
    Biết T90; phần tử `ngaySinh` mức `INTERNAL`; U-T90-DS1 (đề xuất), U-T90-SO (xác nhận).
    Khi DS1 `PUT /data-elements/{id}/classification` đề xuất `RESTRICTED`, loại `BASIC`, `identifiability = QUASI`.
    Và SO `POST /classifications/{cid}:confirm`.
    Và `GET /data-elements/{id}/history`.
    Thì bước 1 `200`, `PROPOSED`. Bước 2 `200`, `CONFIRMED`, bản cũ `SUPERSEDED`. EVT: `classification.changed` mang mức cũ và mới. Bước 3 hai dòng lịch sử, người, thời điểm. KT: có (classification-confirm).

  @TC-09-008 @P1 @Âm
  Kịch bản: TC-09-008 Người đề xuất tự xác nhận, DS xác nhận, thiếu loại DLCN
    # Truy vết: FR-09-004 · API-09-015, 016 · ERR-09-005, 012 · BR-09-003
    # Mục đích: Chứng minh chỉ TA, SO, DO tổ chức sở hữu xác nhận và người đề xuất không tự xác nhận (BR-09-003).
    Biết T90; phần tử `email` chưa phân loại; U-T90-DS1, U-T90-SO.
    Khi DS1 đề xuất `INTERNAL` rồi tự `:confirm`.
    Và DS1 đề xuất `INTERNAL` loại `NONE` cho trường tên `soDienThoai`.
    Và SO đề xuất rồi tự `:confirm`.
    Thì bước 1 `403` ERR-09-005. Bước 2 `422` ERR-09-012 (trường là DLCN cần chọn loại phù hợp). Bước 3 `403` ERR-09-005. Phân loại còn `PROPOSED`.

  @TC-09-009 @P1 @Dương @Âm
  Kịch bản: TC-09-009 Hạ mức cần số văn bản căn cứ và người thứ hai
    # Truy vết: FR-09-004 · API-09-015, 016 · ERR-09-013, 005 · BR-09-002
    # Mục đích: Chứng minh hạ mức hoặc hạ loại DLCN từ `SENSITIVE` xuống `BASIC` hoặc `NONE` cần văn bản căn cứ và hai người khác nhau (BR-09-002).
    Biết T90; `soTaiKhoan` đang `SENSITIVE` `CONFIRMED`; U-T90-SO, U-T90-TA.
    Khi SO đề xuất hạ xuống `RESTRICTED` không nêu căn cứ.
    Và SO đề xuất kèm `legalDocument = CV-123/2026`, lý do 30 ký tự; SO tự xác nhận.
    Và TA xác nhận.
    Thì bước 1 `422` ERR-09-013. Bước 2 đề xuất `PROPOSED`, tự xác nhận `403` ERR-09-005. Bước 3 `200`, mức mới `RESTRICTED`, EVT: `classification.changed`, KT: có (classification-downgrade) kèm số văn bản.

  @TC-09-010 @P2 @Dương @Âm
  Kịch bản: TC-09-010 Xác nhận hàng loạt chỉ cho mẫu đã duyệt và từ chối đề xuất
    # Truy vết: FR-09-004 · API-09-017, 018 · BR-09-007 · ERR-09-006
    # Mục đích: Chứng minh xác nhận hàng loạt chỉ áp cho đề xuất cùng mẫu đã xem và từ chối ghi được lý do.
    Biết T90; 5 phần tử `PROPOSED` từ khai báo MVP; U-T90-SO.
    Khi SO `POST /classifications:bulk-confirm` với 5 mã.
    Và SO `:reject` một đề xuất đã `CONFIRMED`.
    Và SO `:reject` đề xuất `PROPOSED` kèm lý do.
    Thì bước 1 `200`, 5 phần tử `CONFIRMED`, giữ đúng mức đã khai. Bước 2 `409` ERR-09-006. Bước 3 `200`, `REJECTED`.
