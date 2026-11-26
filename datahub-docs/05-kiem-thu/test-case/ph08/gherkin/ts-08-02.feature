# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-02
Tính năng: TS-08-02 · Đăng ký đối tượng đo từ PH-06, PH-07, PH-05 và khai báo CDE

  @TC-08-006 @P1 @Dương
  Kịch bản: TC-08-006 Đăng ký đối tượng đo từ domain PH-06
    # Truy vết: FR-08-002 · API-08-006, 016 · UI-08-03 · BR-08-004, 005 · PERM-08-asset
    Biết T90; U-T90-DS1; domain `CITIZEN` ở `mdm-sim` trạng thái `ACTIVE` có khung nhìn `ph06_mdm.v_dq_citizen`.
    Khi `GET /sources/mdm-domains`
    Và `POST /assets` `{assetCode: mdm-citizen, assetType: MDM_DOMAIN, sourceRef: {domainCode: CITIZEN}, domainCode: DAN_CU}`
    Thì bước 1 liệt kê `CITIZEN`. Bước 2 `201`, `status = DRAFT`, `fields[]` lấy từ khung nhìn, `recordKey = goldenId`. Nhật ký truy vấn của `mdm-sim` chỉ có `SELECT` trên khung nhìn; không có truy cập bảng vật lý `ph06_mdm.*` (BR-08-005).

  @TC-08-007 @P1 @Âm
  Kịch bản: TC-08-007 Domain PH-06 chưa sẵn sàng hoặc mã trùng
    # Truy vết: FR-08-002 · API-08-006 · BR-08-005 · ERR-08-009, 002
    Biết T90; domain `ORGANIZATION` ở `mdm-sim` trạng thái `DRAFT`; `mdm-citizen` đã có.
    Khi `POST /assets` với `sourceRef.domainCode = ORGANIZATION`
    Và `POST /assets` lại `assetCode = mdm-citizen`
    Thì bước 1 `422` ERR-08-009. Bước 2 `409` ERR-08-002. Không có đối tượng mới.

  @TC-08-008 @P1 @Dương
  Kịch bản: TC-08-008 Đăng ký đối tượng đo từ danh mục PH-07
    # Truy vết: FR-08-003 · API-08-006, 017 · UI-08-03 · LGC-DMDC-006, 007, 008
    Biết T90; danh mục `DVHC` đã phát hành ở `rdm-sim`.
    Khi `GET /sources/rdm-catalogs`
    Và `POST /assets` `{assetCode: rdm-dvhc, assetType: RDM_CATALOG, sourceRef: {catalogCode: DVHC, versionPolicy: LATEST}}`
    Thì `201`, `sourceRef = {catalogCode, versionPolicy, versionNo}`. Đối tượng này đo chất lượng danh mục sau mỗi lần nhập hoặc phát hành, không thay chức năng nhập của PH-07.

  @TC-08-009 @P2 @Âm
  Kịch bản: TC-08-009 Danh mục chưa phát hành hoặc hạn chế chưa cấp quyền
    # Truy vết: FR-08-003 · API-08-006 · ERR-08-010
    Biết T90; danh mục `LOAI-DAT` ở `rdm-sim` trạng thái `DRAFT`; danh mục hạn chế `HS-MAT` chưa cấp quyền khai thác cho PH-08.
    Khi `POST /assets` với `catalogCode = LOAI-DAT`
    Và `POST /assets` với `catalogCode = HS-MAT`
    Thì bước 1 `422` ERR-08-010. Bước 2 `403` ERR-08-032 (thiếu quyền khai thác danh mục).

  @TC-08-010 @P2 @Dương
  Kịch bản: TC-08-010 Đăng ký đối tượng đo từ nguồn PH-05 chỉ đọc
    # Truy vết: FR-08-004 · API-08-006, 018 · UI-08-03 · BR-08-025
    Biết T90; kết nối `hotich-pg-ro` ở `conn-sim` (PostgreSQL bản sao chỉ đọc, đã cấp cho PH-08); bảng `hotich.khai_sinh` (F-HT).
    Khi `POST /sources/connections/hotich-pg-ro:discover`
    Và `POST /assets` `{assetCode: src-hotich, assetType: SOURCE_DATASET, sourceRef: {connectionCode: hotich-pg-ro, schema: hotich, table: khai_sinh}, recordKey: [so_khai_sinh], updatedAtField: ngay_cap_nhat}`
    Thì bước 1 trả danh sách bảng và cột. Bước 2 `201`, `sourceRef` đủ ba trường, `scanWindow = 22:00-05:00`. PH-08 không lưu thông tin đăng nhập kết nối (bí mật ở OpenBao); nhật ký nguồn chỉ có `SELECT`.

  @TC-08-011 @P1 @Âm
  Kịch bản: TC-08-011 Kết nối không chỉ đọc, bảng cấm hoặc khóa sai
    # Truy vết: FR-08-004 · API-08-006 · BR-08-005 · ERR-08-011, 012, 013
    Biết T90; `hotich-rw` (kết nối ghi được); bảng `ph05_integration.connection` (CSDL control).
    Khi `POST /assets` với `connectionCode = hotich-rw`
    Và `POST /assets` với `table = ph05_integration.connection`
    Và `POST /assets` với `recordKey = [cot_khong_co]` trên `hotich.khai_sinh`
    Thì bước 1 `422` ERR-08-011. Bước 2 `422` ERR-08-012. Bước 3 `422` ERR-08-013. Không đối tượng nào được tạo.

  @TC-08-012 @P1 @Dương
  Kịch bản: TC-08-012 Khai báo CDE và kéo phân loại PH-09
    # Truy vết: FR-08-005 · API-08-008, 013, 014, 015 · UI-08-04 · BR-08-012, 031 · PERM-08-asset
    Biết `mdm-citizen` `DRAFT`; `cls-sim` trả `nationalId` `SENSITIVE` `CONFIRMED`, `fullName` `RESTRICTED` `CONFIRMED`.
    Khi `PUT /assets/mdm-citizen/fields/nationalId` `{isCde: true}`
    Và `PUT /assets/mdm-citizen/fields/fullName` `{isCde: true}`
    Và `POST /assets/mdm-citizen/fields:sync-classification`
    Và `GET /assets/mdm-citizen/fields`
    Và `PATCH /assets/mdm-citizen` đổi tên hiển thị với `If-Match` đúng
    Thì `nationalId` có `dataClass = SENSITIVE`, `maskingMode = HASH`; `fullName` `RESTRICTED`, `maskingMode = PARTIAL`; `cdeCoverage` hiển thị tỷ lệ CDE có quy tắc `COMPLETENESS` hoặc `VALIDITY` (0 % khi chưa có quy tắc). `PATCH` trả `200` và `ETag` mới. KT: có (field.cde).

  @TC-08-013 @P1 @Âm
  Kịch bản: TC-08-013 Che lỏng hơn phân loại hoặc trường không thuộc lược đồ
    # Truy vết: FR-08-005 · API-08-014 · BR-08-012 · ERR-08-003, 014
    Biết như cde-set.
    Khi `PUT /assets/mdm-citizen/fields/nationalId` `{maskingMode: NONE}`
    Và `PUT /assets/mdm-citizen/fields/truong_la` `{isCde: true}`
    Thì bước 1 `400` ERR-08-003 (che lỏng hơn mức `SENSITIVE`). Bước 2 `422` ERR-08-014. Cấu hình trường không đổi.

  @TC-08-014 @P1 @Âm
  Kịch bản: TC-08-014 Kích hoạt đối tượng theo điều kiện CDE và phân loại
    # Truy vết: FR-08-002 · FR-08-005 · API-08-009 · BR-08-031 · ERR-08-047
    Biết đối tượng `mdm-new` `DRAFT` chưa có CDE; đối tượng `mdm-citizen` có CDE `nationalId` mà `cls-sim` trả `PROPOSED`.
    Khi `POST /assets/mdm-new:activate`
    Và đặt CDE `nationalId` rồi `POST /assets/mdm-citizen:activate`
    Thì bước 1 `409` ERR-08-006, đối tượng giữ `DRAFT`. Bước 2 `200`, `ACTIVE` kèm cảnh báo ERR-08-047 (không chặn), trường che như `SENSITIVE`; tự tạo lịch theo `08.scan.default-cron` và chạy hồ sơ (`08.profile.on-activate`).
