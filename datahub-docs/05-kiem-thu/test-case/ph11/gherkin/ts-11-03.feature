# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-03
Tính năng: TS-11-03 · Biến, biểu mẫu việc và bảng quyết định

  @TC-11-019 @P1 @Dương
  Kịch bản: TC-11-019 Tạo, phát hành, bất biến biểu mẫu
    # Truy vết: FR-11-012 · API-11-029, 030, 031, 032, 033 · UI-11-08 · BR-11-005 · PERM-11-model
    Biết IE1; mã `BIEU_MAU_TIEP_NHAN` chưa dùng.
    Khi IE1 `POST /forms` `{formKey, schema (30 trường), decisions:["APPROVE","REJECT","RETURN"]}`
    Và IE1 `PUT /forms/BIEU_MAU_TIEP_NHAN/versions/1` thêm trường
    Và IE1 `POST .../versions/1:publish`
    Và IE1 `PUT /versions/1` lần nữa
    Và IE1 `GET /forms/BIEU_MAU_TIEP_NHAN`
    Thì bước 3 `200` `PUBLISHED`, có `checksum`. Bước 4 `409` ERR-11-006. Bước 5 có phiên bản 1 `PUBLISHED`; sửa phải tạo phiên bản 2 `DRAFT`.

  @TC-11-020 @P1 @Âm
  Kịch bản: TC-11-020 Biểu mẫu trùng mã, schema sai, ánh xạ biến chưa khai
    # Truy vết: FR-11-012 · API-11-030, 031, 032 · ERR-11-001, 002, 003, 006, 015
    Biết sau `form-publish`; `U-T91-IE1`.
    Khi IE1 `POST /forms` trùng `formKey`
    Và IE1 `POST /forms` với schema không phải JSON Schema
    Và IE1 sửa bản đã `PUBLISHED`
    Và IE1 `PUT` ánh xạ trường tới biến `soChuaKhai`
    Và `U-T91-IE1` `GET /forms/BIEU_MAU_TIEP_NHAN`
    Thì bước 1 `409` ERR-11-002. Bước 2 `400` ERR-11-003. Bước 3 `409` ERR-11-006. Bước 4 `422` ERR-11-015. Bước 5 `404-ẩn` ERR-11-001.

  @TC-11-021 @P1 @Dương
  Kịch bản: TC-11-021 Khai báo biến và phân loại dữ liệu
    # Truy vết: FR-11-016 · API-11-044, 045 · UI-11-04 · BR-11-014, 015
    Biết v4 `DRAFT`; IE1; `F-DLCN`.
    Khi IE1 `PUT /versions/4/variables` khai `soDinhDanhMe` (`SENSITIVE`), `hoTenTre` (`RESTRICTED`), `maXa` (`INTERNAL`), `ngaySinhTre` (`DATE`)
    Và IE1 `GET /versions/4/variables`
    Thì bước 1 `200`. Bước 2 `soDinhDanhMe` có `encrypt = true`, `mask` đặt sẵn; `maXa` không mã hóa; kiểu `DATE` giữ nguyên.

  @TC-11-022 @P1 @Âm
  Kịch bản: TC-11-022 Khai báo biến sai
    # Truy vết: FR-11-016 · API-11-045 · ERR-11-003, 015 · BR-11-014, 015
    Biết v4 `DRAFT`; IE1.
    Khi IE1 khai hai biến cùng tên `maXa`
    Và IE1 khai biến `1sai`
    Và IE1 khai `SENSITIVE` với `encrypt:false`
    Và IE1 dùng `soDinhDanhMe` trong `publicName` rồi `:validate`
    Thì bước 1 và 2 `400` ERR-11-003. Bước 3 `422` ERR-11-015. Bước 4 `422` ERR-11-010 hoặc kết quả `SENSITIVE_IN_PUBLIC` mức `ERROR`.

  @TC-11-023 @P3 @Dương @Âm
  Kịch bản: TC-11-023 Bảng quyết định cho rẽ nhánh
    # Truy vết: FR-11-017 · API-11-046, 047, 048 · ERR-11-040 · BR-11-005
    Biết IE1.
    Khi IE1 `PUT /decision-tables/LOAI_HO_SO` `{hitPolicy:"FIRST", inputs:["tuoi"], rules:[...]}`
    Và IE1 `POST /decision-tables/LOAI_HO_SO:evaluate` `{tuoi:5}`
    Và IE1 `PUT` bảng có `hitPolicy` lạ rồi bảng thiếu luật mặc định
    Thì bước 2 `200` đầu ra theo luật khớp đầu tiên. Bước 3 `422` ERR-11-040 cả hai lần.
