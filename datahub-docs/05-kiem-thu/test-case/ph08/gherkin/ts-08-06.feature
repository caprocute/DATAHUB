# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-06
Tính năng: TS-08-06 · Quy tắc nâng cao, thư viện mẫu và chạy thử

  @TC-08-030 @P2 @Dương
  Kịch bản: TC-08-030 Kiểm tra và thêm quy tắc CEL
    # Truy vết: FR-08-014 · API-08-031, 034 · UI-08-08 · BR-08-017
    Biết nháp v1 `RS-CITIZEN`; U-T90-DS1.
    Khi `POST /rules:validate-expression` `{assetCode: mdm-citizen, operator: CEL_EXPRESSION, expression: "has(ngayCap) && ngayCap >= ngaySinh"}`
    Và `POST /rule-sets/RS-CITIZEN/versions/1/rules` `{operator: CEL_EXPRESSION, dimension: CONSISTENCY, expression: "..."}`
    Thì bước 1 `200`, `valid = true`, `costEstimate` dưới giới hạn, `referencedFields[]`; quy tắc ở bước 2 đặt `execMode = BOTH`. Bước 2 `201`, quy tắc chạy được cả lô và trực tuyến.

  @TC-08-031 @P1 @Âm
  Kịch bản: TC-08-031 CEL sai cú pháp, sai kiểu hoặc vượt chi phí
    # Truy vết: FR-08-014 · API-08-034 · BR-08-017 · ERR-08-019
    Biết như cel-ok.
    Khi `POST /rules:validate-expression` với `"ngayCap >="`
    Và với `"ngayCap + 1 > ngaySinh"` (cộng ngày với số nguyên không hợp kiểu)
    Và với biểu thức lồng `all` trên danh sách 10^6 phần tử
    Thì cả ba `422` ERR-08-019, bước 1 chỉ vị trí `1:11`; không lưu quy tắc.

  @TC-08-032 @P1 @Âm
  Kịch bản: TC-08-032 Vị từ SQL chưa bật, vi phạm danh sách cho phép và chế độ chạy
    # Truy vết: FR-08-014 · FR-08-013 · API-08-031, 032 · BR-08-017 · ERR-08-020, 016
    Biết `src-hotich` có `ngay_sinh`; cờ `08.rule.sql-predicate-enabled = false`; sau bước 1 TA bật cờ.
    Khi `POST` quy tắc `SQL_PREDICATE` `ngay_sinh <= current_date`
    Và bật cờ rồi `POST` lại
    Và `POST` `SQL_PREDICATE` `1=1; DROP TABLE khai_sinh`
    Và `POST` `SQL_PREDICATE` có truy vấn con `(SELECT ...)` hoặc `pg_sleep(100)`
    Và `POST` `UNIQUE_IN_ASSET` với `execMode = INLINE`
    Thì bước 1 `409` ERR-08-006. Bước 2 `201`, `execMode = BATCH`. Bước 3 và 4 `422` ERR-08-020. Bước 5 `422` ERR-08-016 (BR-08-017): quy tắc `UNIQUE_*`, `CROSS_ENTITY`, `EQ_SOURCE`, `SQL_PREDICATE` chỉ chạy lô.

  @TC-08-033 @P2 @Dương
  Kịch bản: TC-08-033 Dùng quy tắc mẫu COMMON
    # Truy vết: FR-08-015 · API-08-035, 031 · UI-08-06, 08 · LGC-NGSP-005
    Biết `COMMON` có 12 mẫu (`TPL-CCCD`, `TPL-MST`, `TPL-SDT`, `TPL-EMAIL`, `TPL-DVHC`…); `mdm-org` có CDE `mst`.
    Khi `GET /rule-templates?scope=COMMON`
    Và `POST /rule-sets/RS-ORG/versions/1/rules` `{templateCode: TPL-MST, fieldName: mst}`
    Thì bước 1 trả 12 mẫu có phiên bản. Bước 2 `201`, quy tắc `ACCURACY` `CHECKSUM` `MST_10`, `source = TEMPLATE`, giữ `templateCode` và số phiên bản mẫu.

  @TC-08-034 @P2 @Âm
  Kịch bản: TC-08-034 Tenant sửa mẫu COMMON, PA sửa mẫu
    # Truy vết: FR-08-015 · API-08-036 · BR-08-032
    Biết quy tắc `R-MST` đang dùng `TPL-MST` v1; U-T90-DS1; U-PA.
    Khi DS1 `POST /rule-templates` sửa `TPL-MST` ở `COMMON`
    Và PA `POST /rule-templates` sửa `TPL-MST`
    Và kiểm `R-MST`
    Thì bước 1 `403` ERR-00-403 ("Anh/chị không có quyền sửa mẫu dùng chung toàn quốc."). Bước 2 `201`, mẫu v2. Bước 3 `R-MST` vẫn trỏ `TPL-MST` v1; `GET /rules?templateOutdated=true` liệt kê `R-MST`.

  @TC-08-035 @P1 @Dương
  Kịch bản: TC-08-035 Chạy thử quy tắc trên mẫu tái lập
    # Truy vết: FR-08-016 · API-08-037 · UI-08-08 · BR-08-012, 019 · PERM-08-rule-admin
    Biết nháp v1 `RS-CITIZEN` đủ 6 quy tắc; F-SCORE (10.000 bản ghi); U-T90-DS1.
    Khi `POST /rule-sets/RS-CITIZEN/versions/1:dry-run` `{sampleSize: 1000, sampleSeed: 42}`
    Và lặp lại với cùng `sampleSeed`
    Và đếm bản ghi lỗi và ảnh chụp mới
    Thì bước 1 `200`, `sampleSeed = 42`, `results[]` (`status`, `rowsEvaluated`, `rowsFailed`, `passRate`, `examples[]` đã che), `durationMs`, `estimatedScore`; ví dụ lỗi của cột Nhạy cảm chỉ có giá trị băm hoặc che. Bước 2 cùng tập khóa và cùng số đếm. Bước 3 không có bản ghi lỗi, không có ảnh chụp; phiên bản có dấu chạy thử.

  @TC-08-036 @P2 @Âm
  Kịch bản: TC-08-036 Chạy thử vượt giới hạn hoặc nguồn không khả dụng
    # Truy vết: FR-08-016 · API-08-037 · ERR-08-105 · ERR-08-031
    Biết `08.dryrun.max-rows = 10000`; `conn-sim` có thể ngắt.
    Khi `POST …:dry-run` `{sampleSize: 60000}`
    Và ngắt `conn-sim` rồi `POST …:dry-run` cho `RS-HOTICH`
    Thì bước 1 `422` ERR-08-031. Bước 2 `503` ERR-08-105.
