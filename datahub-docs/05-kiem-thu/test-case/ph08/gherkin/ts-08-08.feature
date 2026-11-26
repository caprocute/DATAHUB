# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-08
Tính năng: TS-08-08 · So sánh phiên bản, sao chép, nhập và xuất bộ quy tắc

  @TC-08-042 @P2 @Dương @Âm
  Kịch bản: TC-08-042 So sánh phiên bản và xem lịch sử
    # Truy vết: FR-08-019 · API-08-028, 030, 043 · UI-08-09
    Biết `RS-CITIZEN` v1 (6 quy tắc) và v2 (thêm 1, sửa 1, đổi `ruleCode` 1).
    Khi `GET /rule-sets/RS-CITIZEN/versions/2/diff?against=1`
    Và `GET /rule-sets/RS-CITIZEN/versions/99`
    Thì bước 1 `changes[]` có `ADDED`, `MODIFIED`, `REMOVED` với `before`, `after`; quy tắc đổi `ruleCode` được cảnh báo "dấu vân tay lỗi cũ không nối tiếp"; `history[]` có người duyệt, thời điểm. Bước 2 `404` ERR-08-001.

  @TC-08-043 @P2 @Dương
  Kịch bản: TC-08-043 Sao chép bộ quy tắc sang đối tượng cùng lược đồ và khác lược đồ
    # Truy vết: FR-08-020 · API-08-044, 045 · UI-08-06 · ERR-08-026, 022
    Biết `mdm-citizen-b` cùng lược đồ; `mdm-org` thiếu trường `birthDate`; không có nháp ở đích.
    Khi `POST /rule-sets/RS-CITIZEN:copy` `{targetAssetCode: mdm-citizen-b}`
    Và `POST …:copy` `{targetAssetCode: mdm-org}`
    Và sao chép lần hai khi đích đã có nháp
    Và `GET /rule-sets/RS-CITIZEN/versions/2/export?format=YAML`
    Thì bước 1 `201`, nháp mới, `rulesNeedingReview[]`. Bước 2 `422` ERR-08-026. Bước 3 `409` ERR-08-022. Bước 4 `200` tệp YAML.

  @TC-08-044 @P2 @Âm
  Kịch bản: TC-08-044 Nhập tệp sai lược đồ hoặc quá lớn
    # Truy vết: FR-08-020 · API-08-046 · ERR-08-025, 046
    Biết tệp `sai-luoc-do.yaml` (toán tử `REGEXX` ở `rules[3]`); tệp `lon.yaml` 11 MB; giới hạn 10 MB.
    Khi `POST /rule-sets:import` với `sai-luoc-do.yaml`
    Và `POST /rule-sets:import` với `lon.yaml`
    Thì bước 1 `422` ERR-08-025 chỉ `rules[3].operator`. Bước 2 `413` ERR-08-046. Không tạo bản nháp.
