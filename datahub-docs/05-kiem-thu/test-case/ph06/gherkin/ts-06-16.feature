# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-16
Tính năng: TS-06-16 · Chi tiết bản ghi vàng, lịch sử và nguồn gốc

  @TC-06-072 @P1 @Dương
  Kịch bản: TC-06-072 Xem chi tiết bản ghi vàng đã che
    # Truy vết: FR-06-035 · API-06-056 · UI-06-03 · BR-06-009, 010, 026 · PERM-06-read
    # Mục đích: Chứng minh chi tiết có thuộc tính, xref, nguồn từng thuộc tính, che theo phân loại, theo FR-06-035.
    Biết bản ghi vàng Bình; DS1, VW.
    Khi DS1 `GET .../golden-records/{id}` với `X-Purpose`.
    Và VW `GET` cùng bản ghi.
    Thì bước 1 `200`, mỗi thuộc tính có `source`, `confidence`; `idNumber` hiển thị `*303`. Bước 2 cùng che, không có giá trị rõ. NK: có hai dòng.
    # Hậu điều kiện: Hai dòng access_log.

  @TC-06-073 @P1 @Âm
  Kịch bản: TC-06-073 Bản ghi đã ngừng, không tồn tại, mất nhật ký truy cập
    # Truy vết: FR-06-035 · BR-06-010 · ERR-06-001, 039
    # Mục đích: Chứng minh `410`, `404` và không trả dữ liệu khi không ghi được nhật ký, theo BR-06-010.
    Biết bản ghi vàng `RETIRED` G-R; T95.
    Khi `GET` G-R.
    Và `GET` một `goldenId` không có.
    Và dừng dịch vụ ghi `access_log`, `GET` bản ghi `ACTIVE`.
    Thì bước 1 `410` ERR-06-001. Bước 2 `404` ERR-06-001. Bước 3 `503` ERR-06-039, thân không chứa giá trị thuộc tính.
    # Hậu điều kiện: Không có dòng access_log mới ở bước 3.

  @TC-06-074 @P2 @Dương @Âm
  Kịch bản: TC-06-074 Lịch sử phiên bản và so sánh hai phiên bản
    # Truy vết: FR-06-041 · BR-06-005 · API-06-063, 064 · ERR-06-001
    # Mục đích: Chứng minh mỗi thay đổi có ảnh chụp và so sánh hai phiên bản đúng, theo FR-06-041.
    Biết bản ghi vàng đã qua 5 thay đổi: `CREATE`, `UPDATE`, `MANUAL_EDIT`, `MERGE`, `UNDO`.
    Khi `GET .../history`.
    Và `GET .../history/3` và so với 5.
    Và `GET .../history/99`.
    Thì bước 1 5 dòng `GoldenChangeType` đúng thứ tự, người, thời điểm. Bước 2 diff chỉ ra thuộc tính đổi. Bước 3 `404` ERR-06-001.
    # Hậu điều kiện: Không đổi.

  @TC-06-075 @P1 @Dương @Âm
  Kịch bản: TC-06-075 Truy xuất nguồn gốc từng thuộc tính
    # Truy vết: FR-06-043 · BR-06-009, 014 · API-06-065 · ERR-06-001 · UI-06-03
    # Mục đích: Chứng minh lineage nêu nguồn, khóa nguồn, chiến lược và sửa tay, theo FR-06-043.
    Biết bản ghi vàng Bình có thuộc tính do `QG-DANCU`, `HT-YTE` và một giá trị `MANUAL`.
    Khi `GET .../lineage`.
    Và `GET .../lineage?attribute=khongco`.
    Thì bước 1 mỗi thuộc tính `sourceCode`, `sourceKey`, `strategy`, thời điểm; thuộc tính sửa tay nguồn `MANUAL` kèm hạn và yêu cầu sửa tại nguồn. Bước 2 `400` ERR-06-003.
    # Hậu điều kiện: Không đổi.
