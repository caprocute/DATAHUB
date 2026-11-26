# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-05
Tính năng: TS-08-05 · Soạn bộ quy tắc và định nghĩa quy tắc theo chiều

  @TC-08-024 @P1 @Dương
  Kịch bản: TC-08-024 Tạo bộ quy tắc và phiên bản nháp
    # Truy vết: FR-08-012 · API-08-025, 026, 027, 029 · UI-08-06 · BR-08-006 · PERM-08-rule-admin
    Biết `mdm-citizen` `ACTIVE`; U-T90-DS1.
    Khi `POST /rule-sets` `{ruleSetCode: RS-CITIZEN, assetCode: mdm-citizen}`
    Và `GET /rule-sets/RS-CITIZEN`
    Và `GET /rule-sets/RS-CITIZEN/versions`
    Và `GET /rule-sets?assetCode=mdm-citizen`
    Thì bước 1 `201`, `version = 1`, `status = DRAFT`, `ruleCount = 0`, `ETag`. Phiên bản `ACTIVE` (nếu có) không đổi. KT: có (ruleset.create).

  @TC-08-025 @P2 @Âm
  Kịch bản: TC-08-025 Đã có bản nháp hoặc đối tượng đã có bộ quy tắc
    # Truy vết: FR-08-012 · API-08-026, 029 · BR-08-006 · ERR-08-022, 002
    Biết `RS-CITIZEN` có nháp v2 do DS1 tạo; U-T90-DS2.
    Khi DS2 `POST /rule-sets/RS-CITIZEN/versions`
    Và DS2 `POST /rule-sets` `{ruleSetCode: RS-CITIZEN-2, assetCode: mdm-citizen}`
    Thì bước 1 `409` ERR-08-022. Bước 2 `409` ERR-08-002. Không tạo thêm nháp.

  @TC-08-026 @P1 @Dương
  Kịch bản: TC-08-026 Định nghĩa quy tắc cho từng chiều
    # Truy vết: FR-08-013 · API-08-031, 032, 033 · UI-08-07, 08 · PERM-08-rule-admin
    Biết nháp v1 của `RS-CITIZEN`; danh mục `GIOI-TINH` đã phát hành ở `rdm-sim`; CDE `nationalId`, `gender`, `birthDate`, `updatedAt`.
    Khi thêm 6 quy tắc bằng `POST /rule-sets/RS-CITIZEN/versions/1/rules`: `R-CCCD-NN` `COMPLETENESS` `NOT_NULL` `CRITICAL`
    Và `R-CCCD-RX` `ACCURACY` `REGEX` `^\d{12}$` `MAJOR`
    Và `R-NS-EQ` `CONSISTENCY` `EQ_SOURCE` đối chiếu `src-hotich.ngay_sinh`
    Và `R-CAPNHAT` `TIMELINESS` `MAX_AGE_DAYS` 365 `MINOR`
    Và `R-CCCD-UQ` `UNIQUENESS` `UNIQUE_IN_ASSET` `CRITICAL`
    Và `R-GT-RDM` `VALIDITY` `IN_RDM` `catalogCode = GIOI-TINH` `MAJOR`
    Và `DELETE …/rules/R-CAPNHAT` (quy tắc mới thêm trong nháp)
    Thì mỗi lệnh `201`, quy tắc có `execMode` suy ra (`R-CCCD-UQ` là `BATCH`, còn lại `BOTH`), `ETag` phiên bản đổi; `DELETE` `204`, quy tắc xóa thật vì chưa từng có ở phiên bản trước (quy tắc đã có ở phiên bản trước chỉ được tắt `enabled = false`); sau đó thêm lại để `ruleCount = 6`; dấu chạy thử cũ (nếu có) bị vô hiệu (BR-08-006). Sáu chiều đều có quy tắc.

  @TC-08-027 @P1 @Âm
  Kịch bản: TC-08-027 Toán tử không thuộc chiều, tham số sai, thiếu danh mục hoặc nguồn
    # Truy vết: FR-08-013 · API-08-031, 032 · BR-08-003 · ERR-08-015, 016, 017, 018, 014
    Biết như rule-def.
    Khi `POST` quy tắc `COMPLETENESS` với `operator = REGEX`
    Và `POST` `REGEX` với `pattern = "[a-"`
    Và `POST` chiều `VALIDITY` `IN_RDM` không có `catalogCode`
    Và `POST` chiều `CONSISTENCY` `EQ_SOURCE` không có nguồn đối chiếu
    Và `POST` quy tắc `NOT_NULL` trên trường `khong_co`
    Thì bước 1 `422` ERR-08-015. Bước 2 `422` ERR-08-016. Bước 3 `422` ERR-08-017. Bước 4 `422` ERR-08-018. Bước 5 `422` ERR-08-014. Không quy tắc nào được lưu.

  @TC-08-028 @P1 @Âm
  Kịch bản: TC-08-028 Quy tắc hợp lệ tự liệt kê mã thay cho danh mục
    # Truy vết: FR-08-013 · API-08-031 · BR-08-003 · ERR-08-017 · ERR-08-015
    Biết nháp v1 của `RS-CITIZEN`.
    Khi `POST` quy tắc `VALIDITY` `IN_RDM` với `params = {values: ["1","2","3"]}` không có `catalogCode`
    Và `POST` quy tắc `VALIDITY` `REGEX` `^(1|2|3)$` cho trường `gender`
    Thì bước 1 `422` ERR-08-017: PH-08 không nhận danh sách mã tự khai. Bước 2 `422` ERR-08-015 vì `REGEX` không thuộc chiều `VALIDITY`. Schema `ph08_dq` không có bảng chứa mã danh mục.

  @TC-08-029 @P2 @Dương @Âm
  Kịch bản: TC-08-029 Liệt kê và tìm quy tắc
    # Truy vết: FR-08-022 · API-08-053 · UI-08-06 · PERM-08-read · ERR-08-045
    Biết T90 có 40 quy tắc ở 5 đối tượng, 6 quy tắc dùng mẫu `TPL-MST` bản cũ.
    Khi `GET /rules?dimension=VALIDITY&severity=MAJOR&execMode=BOTH&page=0&size=20`
    Và `GET /rules?templateOutdated=true`
    Và `GET /rules?dimension=KHAC`
    Thì `200`, `items[]` có `ruleCode`, `assetCode`, `dimension`, `operator`, `severity`, `execMode`, `lastFailRate`, `templateRef`, kèm `facets`; bước 2 trả đúng 6 quy tắc dùng mẫu cũ. Bước 3 `422` ERR-08-045.
