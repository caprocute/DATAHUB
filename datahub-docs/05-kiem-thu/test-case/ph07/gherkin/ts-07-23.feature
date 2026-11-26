# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-23
Tính năng: TS-07-23 · Khai thác danh mục RESTRICTED

  @TC-07-268 @P1 @Dương
  Kịch bản: TC-07-268 Thay danh sách cấp quyền và khai thác
    # Truy vết: FR-07-052 · BR-07-019 · API-07-075
    Biết CAT-RES cấp cho `HT-DATDAI`.
    Khi U-T68-TA `PUT /catalogs/TRAM_QUAN_TRAC/access-grants` với `If-Match`, `reason`, thêm `HT-HOTICH` scope `rdm.read`, `expiresAt` = 2026-11-21T10:00+07:00.
    Và trong ≤ 10 giây, APP-T68-READ gọi `GET /catalogs/TRAM_QUAN_TRAC/items`.
    Và tua đồng hồ qua 10:00, gọi lại.
    Thì bước 1 `200`, `ETag` mới, KT: có (`RDM_ACCESS_GRANT_REPLACE` với phần thêm). Bước 2 `200`. Bước 3 `403` `ERR-07-030`.

  @TC-07-269 @P1 @Âm
  Kịch bản: TC-07-269 Danh sách cấp quyền sai
    # Truy vết: FR-07-052 · ERR-07-009, 018
    Biết —.
    Khi PUT với HTTT không tồn tại; HTTT trùng; scope `rdm.write`; `expiresAt` trong quá khứ; thiếu `reason`.
    Và PUT với `If-Match` cũ.
    Thì bước 1 mỗi trường hợp `422` `ERR-07-009`, danh sách không đổi. Bước 2 `412` `ERR-07-018`.

  @TC-07-270 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-270 HTTT bị đình chỉ mất quyền ngay
    # Truy vết: FR-07-052 bước 5 · ERR-07-030
    Biết `HT-DATDAI` được cấp.
    Khi giả lập PH-01 phát sự kiện `HT-DATDAI` chuyển `SUSPENDED`.
    Và APP-T68-QUERY gọi `items:query` trên CAT-RES sau 2 giây.
    Thì `403` `ERR-07-030`; bộ đệm quyền ở mọi pod đã bị vô hiệu.

  @TC-07-271 @P2 @Dương
  Kịch bản: TC-07-271 Nâng mức phân loại lên RESTRICTED cần xác nhận
    # Truy vết: FR-07-052 bước 6 · FR-07-004 · UI-07-03
    Biết CAT-MUC (`INTERNAL`) có 3 HTTT khai thác trong 30 ngày.
    Khi U-T68-TA đổi phân loại CAT-MUC thành `RESTRICTED` trên UI-07-03.
    Thì hộp xác nhận nêu "3 hệ thống đã khai thác danh mục này trong 30 ngày sẽ mất quyền"; sau khi xác nhận, ba HTTT nhận `ERR-07-030`; tenant tỉnh thay danh sách cấp quyền của danh mục `COMMON` cho HTTT quốc gia bị `403` `ERR-07-003` (kiểm thêm bằng API).
