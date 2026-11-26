# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-24
Tính năng: TS-05-24 · Kamelet sinh và đồng bộ catalog

  @TC-05-092 @P1 @Dương
  Kịch bản: TC-05-092 Kamelet sinh có trong catalog PH-04
    # Truy vết: FR-05-047, 059 · API-05-089 · BR-05-027 · UI-05-14
    Biết S-INT; sau TC-05-084.
    Thì có Kamelet nền theo `runtime-manifest.json`, `COMMON` và `TENANT` `APPROVED`, Kamelet sinh của A-QLVB; mỗi mục có YAML, băm, mức native; Kamelet `DEPRECATED` có cờ ẩn. Không có mục của T01.

  @TC-05-093 @P3 @Biên
  Kịch bản: TC-05-093 Tên Kamelet sinh dài được rút gọn có băm
    # Truy vết: FR-05-047
    Biết mã bộ điều hợp 50 ký tự, mã thao tác 40 ký tự.
    Thì tên Kamelet ≤ 63 ký tự, có băm 6 ký tự, vẫn khớp mẫu `-(source|sink|action)$`; hai thao tác khác nhau không trùng tên.

  @TC-05-094 @P2 @Dương
  Kịch bản: TC-05-094 Nâng runtime chạy lại kiểm tra tĩnh, đánh dấu NEEDS_REVIEW
    # Truy vết: FR-05-059 · ERR-05-021
    Biết K-MST dùng thành phần bị bỏ khỏi `runtime-manifest.json` bản mới.
    Thì K-MST mang thuộc tính `NEEDS_REVIEW` (trạng thái giữ `APPROVED`), UI-05-14 có huy hiệu; chủ sở hữu nhận thông báo nêu ERR-05-021.

  @TC-05-153 @P2 @Âm
  Kịch bản: TC-05-153 Kamelet sinh không sửa tay; Kamelet thu hồi không vào catalog
    # Truy vết: FR-05-047, 059 · API-05-080, 089 · ERR-05-008, 003
    Biết U-T68-IE1; S-INT; Kamelet sinh của A-QLVB; một Kamelet `WITHDRAWN`.
    Khi IE1 `PUT /kamelets/{kamelet sinh}/versions/1.0.0`.
    Và S-INT `GET /internal/catalog/kamelets?tenant=T68&profile=khong-co`.
    Và S-INT `GET /internal/catalog/kamelets?tenant=T68&profile=core-native`.
    Thì bước 1 `409` ERR-05-008 (chỉ sửa ở `DRAFT`; Kamelet sinh luôn đã duyệt). Bước 2 `400` ERR-05-003. Bước 3 không có Kamelet `WITHDRAWN`.
