# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-01
Tính năng: TS-16-01 · Bộ chỉ tiêu, nhóm và trọng số

  @TC-16-001 @P1 @Dương
  Kịch bản: TC-16-001 Liệt kê, lọc và xem chi tiết chỉ tiêu
    # Truy vết: FR-16-001 · API-16-001, 003, 004 · UI-16-03
    Biết T90 đã kế thừa 24 chỉ tiêu `COMMON`; U-T90-VW.
    Khi `GET /indicators?page=0&size=10`
    Và `GET /indicators?groupCode=KET_NOI&state=ACTIVE&measurement=AUTO`
    Và `GET /indicators?q=mttd`
    Và `GET /indicators/httt-ket-noi-ty-le`
    Và `GET /indicators/httt-ket-noi-ty-le/versions`
    Thì bước 1 `200`, `totalElements = 24`, `items` đủ `indicatorCode`, `groupCode`, `kind`, `direction`, `measurement`, `unit`, `state`, `facets.byGroup` cộng bằng 24. Bước 2 chỉ chỉ tiêu `KET_NOI` đo `AUTO` (`httt-ket-noi-ty-le`, `thoi-gian-ket-nap-httt`, `thoi-gian-xay-luong`). Bước 3 trả `mttd`. Bước 4 có `activeVersion = 1`, `activeDefinition.formula`, `scope = TENANT`, `derivedFrom.indicatorCode`. Bước 5 trả danh sách phiên bản. EVT: không. KT: không (đọc).

  @TC-16-002 @P1 @Âm
  Kịch bản: TC-16-002 Bộ lọc sai và chỉ tiêu thuộc tenant khác
    # Truy vết: FR-16-001 · API-16-001, 003 · ERR-16-057, ERR-16-001
    Biết T90; chỉ tiêu `tc-chi-t91` chỉ có ở T91 (U-T91-TA1 tạo).
    Khi `GET /indicators?groupCode=XYZ`
    Và `GET /indicators?size=5000`
    Và U-T90-VW `GET /indicators/tc-chi-t91`
    Và `GET /indicators/khong-co`
    Thì bước 1, 2 `400` ERR-16-057, `errors[]` trỏ `groupCode`, `size`. Bước 3, 4 `404` ERR-16-001, hai thân giống nhau trừ `traceId` (404-ẩn). Không lộ sự tồn tại của chỉ tiêu tenant khác.

  @TC-16-003 @P2 @Dương
  Kịch bản: TC-16-003 Đặt trọng số năm nhóm tổng bằng 100
    # Truy vết: FR-16-007 · API-16-016, 017 · UI-16-03 · BR-16-016
    Biết T90; U-T90-TA1; trọng số hiện hành 20 mỗi nhóm.
    Khi `GET /groups`
    Và `PUT /groups` với `groups` = `KET_NOI` 30, `CHIA_SE` 20, `DU_LIEU` 20, `VAN_HANH` 15, `KIEN_TRUC` 15, `effectiveFrom = 2026-11-01`, kèm `If-Match`
    Và `GET /groups`
    Thì bước 2 `200`; bước 3 trả đúng năm nhóm với `weight` mới, `displayName`, `order`. Điểm tổng kỳ `M-2026-10` tính lại theo 30/20/20/15/15 cho 66,50 (xem TC-16-051).

  @TC-16-004 @P1 @Âm
  Kịch bản: TC-16-004 Tổng trọng số khác 100 hoặc thiếu If-Match
    # Truy vết: FR-16-007 · API-16-017 · ERR-16-012, ERR-16-004, ERR-00-428, ERR-00-403
    Biết T90; U-T90-TA1, U-T90-VW.
    Khi `PUT /groups` với trọng số 30, 20, 20, 15, 10 (tổng 95)
    Và `PUT /groups` hợp lệ nhưng không có `If-Match`
    Và U-T90-VW `PUT /groups` hợp lệ
    Và hai phiên U-T90-TA1 cùng đọc `ETag` rồi cùng `PUT /groups`
    Thì bước 1 `422` ERR-16-012, không đổi dữ liệu. Bước 2 `428` ERR-00-428. Bước 3 `403` ERR-00-403. Bước 4 phiên đầu `200`, phiên sau `409` ERR-16-004. Không mất cập nhật.
