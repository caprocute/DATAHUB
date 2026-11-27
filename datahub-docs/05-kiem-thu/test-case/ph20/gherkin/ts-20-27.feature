# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-27
Tính năng: TS-20-27 · Xử lý xung đột sáp nhập

  @TC-20-122 @P1 @Dương
  Kịch bản: TC-20-122 Xem xung đột và xử lý từng dòng bằng ba cách
    # Truy vết: FR-20-049 · UC-20-27 · API-20-101, 102 · BR-20-023, 024 · UI-20-10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch `CONFLICT_REVIEW` T91→T90 với F-MERGE: 3 xung đột mã tổ chức, 2 mã danh mục, 1 mã `API_CONTEXT_PATH`.
    Khi `GET P/merge-plans/{id}/conflicts?status=OPEN`
    Và `POST .../conflicts/{c1}:resolve` với `resolution = KEEP_TARGET`, `comment`, kèm `If-Match`
    Và `POST .../{c2}:resolve` với `resolution = RENAME_SOURCE`, `newCode = DM-T91-01`
    Và `POST .../{c3}:resolve` danh mục với `resolution = MERGE_ITEMS`
    Và xem lại `GET .../conflicts?status=OPEN`
    Thì bước 1 6 dòng mở, mỗi dòng có hai bản nguồn, đích. Bước 2, 3, 4 `200`, dòng `RESOLVED` kèm người, ý kiến. Bước 5 còn 3 dòng; không bản ghi nào ở đích bị ghi đè ngoài `KEEP_SOURCE`. Kiểm toán từng quyết định.

  @TC-20-123 @P1 @Âm
  Kịch bản: TC-20-123 Xử lý xung đột sai cách, mã mới trùng, đã quyết, thiếu If-Match
    # Truy vết: FR-20-049 · API-20-102 · ERR-20-003, ERR-20-004, ERR-20-005, ERR-20-006, ERR-20-002, ERR-00-428
    Biết `U-PA1`, `U-PO` (không có `PERM-20-merge`); kế hoạch có xung đột mã tổ chức `c1`, danh mục `c2`, `c3` đã `RESOLVED`.
    Khi `:resolve` `c1` với `resolution = MERGE_ITEMS` (chỉ cho danh mục)
    Và `:resolve` `c1` với `RENAME_SOURCE` thiếu `newCode`, rồi với `newCode` đã dùng
    Và `:resolve` `c3` đã quyết; `c-khong-co`
    Và thiếu `If-Match`; `If-Match` cũ
    Và `U-PO` `:resolve`
    Thì bước 1 `400` `ERR-20-004`. Bước 2 `400` `ERR-20-004`, `409` `ERR-20-003`. Bước 3 `409` `ERR-20-006`, `404` `ERR-20-002`. Bước 4 `428` `ERR-00-428`, `412` `ERR-20-005`. Bước 5 `403` `ERR-00-403`. Không dòng nào đổi.

  @TC-20-124 @P2 @Dương @Biên
  Kịch bản: TC-20-124 Xử lý hàng loạt tối đa 500 xung đột cùng loại
    # Truy vết: FR-20-049 · API-20-103 · ERR-20-004, ERR-20-006 · UI-20-10 · `PERM-20-merge`
    Biết `U-PA1`; kế hoạch có 600 xung đột `CATALOG_CODE` và 5 xung đột `USER`.
    Khi `POST .../conflicts:resolve-batch` với 500 `conflictIds` cùng loại và `KEEP_TARGET`
    Và gửi 501 mã
    Và gửi lô trộn `CATALOG_CODE` và `USER`
    Và gửi lô có một mã đã `RESOLVED`
    Thì bước 1 `200`, `resolved = 500`, `openRemaining = 105`. Bước 2 `400` `ERR-20-004`. Bước 3 `400` `ERR-20-004` (khác loại). Bước 4 `409` `ERR-20-006`, không dòng nào đổi (tất cả hoặc không).

  @TC-20-125 @P2 @Dương
  Kịch bản: TC-20-125 Hết xung đột mở thì kế hoạch về TRANSFERRING và phần dính xung đột tiếp tục
    # Truy vết: FR-20-049, 048 · UC-20-27 · API-20-102, 167
    Biết kế hoạch `CONFLICT_REVIEW` còn một xung đột; `ops-sim` chờ lệnh tiếp tục cho phần dính xung đột.
    Khi `:resolve` xung đột cuối với `KEEP_SOURCE`
    Và kiểm lệnh tiếp tục gửi PH-18 và kế hoạch
    Thì kế hoạch về `TRANSFERRING`; `ops-sim` nhận đúng một lệnh tiếp tục cho phần xung đột (lũy đẳng); sau khi phân hệ báo xong kế hoạch sang `IDENTITY_TRANSFER`.
