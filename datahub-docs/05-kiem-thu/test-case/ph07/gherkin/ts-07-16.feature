# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-16
Tính năng: TS-07-16 · Hệ thống mã, ánh xạ và chuyển mã

  @TC-07-191 @P1 @Dương
  Kịch bản: TC-07-191 Tạo, sửa, ngừng hệ thống mã ngoài
    # Truy vết: FR-07-040 · API-07-064, 065, 066 · LGC-BUS-036
    Biết U-T68-IE.
    Khi `POST /code-systems` với `code = TC191_CS`, `name = "Mã đơn vị của HT-NOIVU"`, `ownerSystem = HT-NOIVU`.
    Và `PATCH /code-systems/TC191_CS` với `If-Match`, đổi `name`.
    Và `PATCH` đặt `status = RETIRED`.
    Và `GET /code-systems?status=ACTIVE`.
    Thì bước 1 `201`; bước 2, 3 `200`; bước 4 không có `TC191_CS`. KT: có cho bước 1…3.

  @TC-07-192 @P2 @Âm
  Kịch bản: TC-07-192 Hệ thống mã trùng, không quyền, ETag cũ
    # Truy vết: FR-07-040 · ERR-07-002, 018, 045 · D02-08
    Biết `CS-BHXH-DT` đã có.
    Khi tạo lại `CS-BHXH-DT`.
    Và U-T68-VW tạo hệ thống mã mới.
    Và sửa `CS-BHXH-DT` với `If-Match` cũ.
    Và `PATCH /code-systems/KHONG_CO`.
    Thì bước 1 `409` `ERR-07-002`. Bước 2 `403-PQ`. Bước 3 `412` `ERR-07-018`. Bước 4 `404` `ERR-07-045`.

  @TC-07-193 @P1 @Dương
  Kịch bản: TC-07-193 Ghi lô ánh xạ theo chế độ MERGE và REPLACE
    # Truy vết: FR-07-041 · API-07-067, 068 · BR-07-023
    Biết `CS-BHXH-DT`.
    Khi `PUT /catalogs/DAN_TOC/mappings/CS-BHXH-DT?mode=MERGE` với 3 ánh xạ cho `53`, `54`, `55` (quan hệ `EQUAL`, `validFrom = 2026-12-01`).
    Và `GET /catalogs/DAN_TOC/mappings?codeSystem=CS-BHXH-DT&at=2026-12-01`.
    Và `PUT ...?mode=REPLACE` với danh sách chỉ gồm 50 ánh xạ.
    Thì bước 1 `200`, `stats.created = 3`. Bước 2 trả 58 ánh xạ (55 + 3). Bước 3 `200`; các ánh xạ không có trong danh sách được đóng hiệu lực (`validTo` = hôm nay) chứ không xóa vật lý; tra lại tại ngày hôm qua vẫn thấy ánh xạ cũ. KT: có (MAPPING_PUT, số ánh xạ theo loại).

  @TC-07-194 @P1 @Âm
  Kịch bản: TC-07-194 Ánh xạ chồng hiệu lực, tạm thời thiếu lý do, mã không tồn tại
    # Truy vết: FR-07-041 · BR-07-023, 024 · ERR-07-007, 026, 033, 034
    Biết `DT01` đang ánh xạ tới `01` từ 2024-01-01, không thời hạn.
    Khi ghi ánh xạ `DT01` → `02` từ 2026-01-01 (giao khoảng với ánh xạ cũ).
    Và ghi ánh xạ `provisional = true` không có `note`.
    Và ghi ánh xạ tới mã danh mục `99` không có trong `DAN_TOC`.
    Và ghi lô 5.001 ánh xạ.
    Thì bước 1 `422` `ERR-07-033`, nêu ánh xạ đang chồng. Bước 2 `422` `ERR-07-034`. Bước 3 `422` hoặc `404` `ERR-07-007` theo phần tử. Bước 4 `400` `ERR-07-026`. Lô lỗi không ghi phần nào (tất cả hoặc không).

  @TC-07-195 @P2 @Dương @Âm
  Kịch bản: TC-07-195 Xóa ánh xạ
    # Truy vết: FR-07-041 · API-07-069 · ERR-07-027
    Biết ánh xạ `TC195` tạo trong ca.
    Khi `DELETE /catalogs/DAN_TOC/mappings/CS-BHXH-DT/{id}` với `If-Match`.
    Và lặp lại bước 1.
    Thì bước 1 `204`, KT: có (MAPPING_DELETE). Bước 2 `404` `ERR-07-027`.

  @TC-07-196 @P1 @Dương
  Kịch bản: TC-07-196 Chuyển mã chiều TO_CATALOG
    # Truy vết: FR-07-042 · API-07-070 · LGC-BUS-036
    Biết APP-T68-READ.
    Khi `POST /mappings:translate` với `catalog = DAN_TOC`, `codeSystem = CS-BHXH-DT`, `direction = TO_CATALOG`, `codes = ["DT01","DT04B","KHONG_CO"]`.
    Thì `200`; kết quả cùng thứ tự đầu vào: `DT01` `MAPPED` → `01` "Kinh"; `DT04B` `MAPPED` → `04`; `KHONG_CO` `NOT_MAPPED`; `stats` = {MAPPED: 2, NOT_MAPPED: 1}.

  @TC-07-197 @P2 @Dương
  Kịch bản: TC-07-197 Chuyển mã chiều FROM_CATALOG và bỏ qua ánh xạ tạm thời
    # Truy vết: FR-07-042 · API-07-070
    Biết ánh xạ `55` → `DT55` là tạm thời.
    Khi `direction = FROM_CATALOG`, `codes = ["04","55"]`.
    Và như bước 1 với `includeProvisional = false`.
    Thì bước 1: `04` `MULTIPLE` với `externalCodes` `DT04`, `DT04B`; `55` `MAPPED` có `provisional = true`. Bước 2: `55` `NOT_MAPPED`.

  @TC-07-198 @P1 @Âm
  Kịch bản: TC-07-198 Chuyển mã lô vượt mức, hệ thống mã không tồn tại, danh mục hạn chế
    # Truy vết: FR-07-042 · ERR-07-001, 026, 030, 045
    Biết APP-T68-READ; CAT-RES không cấp cho `HT-HOTICH`.
    Khi gửi 501 mã.
    Và gửi `codeSystem = KHONG_CO`.
    Và gửi `catalog = KHONG_CO`.
    Và gửi `catalog = TRAM_QUAN_TRAC`.
    Thì bước 1 `400` `ERR-07-026`. Bước 2 `404` `ERR-07-045`. Bước 3 `404` `ERR-07-001`. Bước 4 `403` `ERR-07-030`.

  @TC-07-199 @P2 @Dương @Âm
  Kịch bản: TC-07-199 Báo cáo độ phủ ánh xạ và màn ánh xạ
    # Truy vết: FR-07-043 · API-07-071 · UI-07-10 · ERR-07-045
    Biết trạng thái đầu kịch bản (55 bản ghi, 52 có ánh xạ).
    Khi `GET /catalogs/DAN_TOC/mappings/CS-BHXH-DT/coverage`.
    Và gọi với `csCode = KHONG_CO`.
    Và mở UI-07-10, bấm thẻ "Chưa ánh xạ", nhập mã ngoài cho `53` trực tiếp trên lưới, lưu.
    Thì bước 1 `200`, `total = 55`, `mapped = 52`, `ratio = 0.945`, danh sách `unmapped` = `53`, `54`, `55`, `multiple` = `04`. Bước 2 `404` `ERR-07-045`. Bước 3: lưới lọc còn 3 dòng; sau khi lưu, thẻ đếm còn 2 và độ phủ 96,4%.
