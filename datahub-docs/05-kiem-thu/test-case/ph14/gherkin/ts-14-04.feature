# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-04
Tính năng: TS-14-04 · Dịch vụ quốc gia: danh sách, khai báo, chi tiết

  @TC-14-011 @P2 @Dương
  Kịch bản: TC-14-011 Tìm, lọc danh mục dịch vụ và xem chi tiết hợp đồng
    # Truy vết: FR-14-004, 006 · API-14-010, 012 · UI-14-04, 05 · UC-14-04.
    Biết U-T68-VW; V-LLTP, V-HT, V-BHXH.
    Khi Ở UI-14-04 tìm `hotich`, lọc nhóm `HO_TICH`, trang 1, 20 dòng.
    Và `GET /services/lltp-tra-trang-thai`.
    Thì danh sách đúng, phân trang `page`/`size`, có nhãn đối chiếu và chỉ báo đã cung cấp lại; chi tiết có `purposeRequired`, `signingMode`, `cacheable`, `priority`, đặc tả `ACTIVE`; không trường bí mật.

  @TC-14-012 @P1 @Dương
  Kịch bản: TC-14-012 Khai báo dịch vụ và kích hoạt khi đủ điều kiện
    # Truy vết: FR-14-005 · API-14-011, 013 · UI-14-05 · UC-14-04 · BR-14-025.
    Biết U-T68-IE; V-NEW chưa có; `ndxp` `ACTIVE`; đặc tả mẫu `ACTIVE`.
    Khi `POST /services` mã `tc-dich-vu-moi`, nhóm `TU_PHAP`, thao tác đọc, ưu tiên `NORMAL`, đệm 60 giây.
    Và `PATCH /services/tc-dich-vu-moi` với `If-Match`, chuyển `ACTIVE`.
    Thì `201` `DRAFT`; `PATCH` `200` `ACTIVE`; mã dịch vụ trung ương nằm ở cấu hình theo tenant.

  @TC-14-013 @P1 @Âm
  Kịch bản: TC-14-013 Khai báo dịch vụ sai: mâu thuẫn đệm, vượt trần, chưa đủ điều kiện
    # Truy vết: FR-14-005 · API-14-011, 013 · ERR-14-002, 003, 004, 009, 036, 038 · BR-14-014.
    Biết U-T68-IE; `14.cache.max-ttl-seconds = 86400`; dịch vụ `tc-chua-dac-ta` chưa có đặc tả `ACTIVE`.
    Khi `POST /services` mức `SENSITIVE` kèm `cacheable = true`.
    Và `POST /services` thao tác ghi kèm đệm.
    Và `POST /services` đệm 90.000 giây.
    Và `POST /services` mã trùng; thiếu nhóm.
    Và chuyển `ACTIVE` dịch vụ `tc-chua-dac-ta`; `PATCH` với `If-Match` cũ.
    Thì bước 1, 2 `422` ERR-14-038; bước 3 `422` ERR-14-036; bước 4 `409` ERR-14-002 và `400` ERR-14-003; bước 5 `422` ERR-14-009 và `412` ERR-14-004 (`If-Match` cũ).

  @TC-14-014 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-014 Dịch vụ của tenant khác và `COMMON`
    # Truy vết: FR-14-004, 006 · API-14-010, 012, 013 · ERR-14-001 · BR-14-029.
    Biết `T01` có `hotich-tra-cuu` khác cấu hình; `COMMON` có dịch vụ `dmdc-ds`.
    Khi U-T68-IE `GET /services/hotich-tra-cuu`; đối chiếu `baseUrl` với T01.
    Và U-T01-TA `GET /services/dich-vu-chi-t68`.
    Và U-T68-IE `PATCH` dịch vụ `COMMON`.
    Thì bước 1 trả cấu hình của T68; bước 2 `404` ERR-14-001; bước 3 `403`; dịch vụ `COMMON` đọc được.
