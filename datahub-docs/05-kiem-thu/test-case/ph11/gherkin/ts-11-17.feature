# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-17
Tính năng: TS-11-17 · Can thiệp phiên có duyệt: sửa biến, chuyển bước, di trú

  @TC-11-099 @P2 @Dương @Âm
  Kịch bản: TC-11-099 Sửa biến phiên có duyệt
    # Truy vết: FR-11-025 · API-11-059, 060, 061, 062 · ERR-11-005, 019, 033 · BR-11-014, 021 · PERM-11-instance-admin
    Biết phiên `HS-03`; `maXa` cho sửa, `soDinhDanhMe` không; TA, TA2.
    Khi TA `POST /instances/{id}/changes` `{type:"VARIABLE_UPDATE", name:"maXa", value:"26735", reason}`
    Và TA `:approve`
    Và TA2 `:approve`
    Và TA đề nghị sửa `soDinhDanhMe`
    Và TA đề nghị `ngaySinhTre` giá trị `abc`
    Và TA đề nghị rồi TA2 `:reject` với ý kiến
    Thì bước 1 `PENDING`, có việc duyệt cho TA2. Bước 2 `403` ERR-11-005. Bước 3 `APPLIED`, KT ghi giá trị cũ đã che. Bước 4 `422` ERR-11-033. Bước 5 `422` ERR-11-019. Bước 6 `REJECTED`.

  @TC-11-100 @P2 @Dương @Âm
  Kịch bản: TC-11-100 Chuyển phiên tới bước khác có duyệt
    # Truy vết: FR-11-027 · API-11-059, 061 · ERR-11-005, 030, 032 · BR-11-021
    Biết phiên `HS-18` ở `capTheBHYT`; một phiên `COMPENSATING`; TA, TA2.
    Khi TA đề nghị `MOVE_TOKEN` tới `guiCuTru`, TA2 duyệt
    Và TA đề nghị chuyển vào sự kiện biên
    Và TA đề nghị chuyển vào giữa nhánh song song chưa hợp
    Và TA đề nghị cho phiên `COMPENSATING`
    Và TA tự duyệt
    Thì bước 1 token ở `guiCuTru`, việc cũ `CANCELLED`, dòng thời gian "Chuyển bước thủ công". Bước 2 và 3 `422` ERR-11-032. Bước 4 `409` ERR-11-030. Bước 5 `403` ERR-11-005.

  @TC-11-101 @P2 @Dương
  Kịch bản: TC-11-101 Di trú 25 phiên từ v3 sang v4
    # Truy vết: FR-11-026 · API-11-063, 064, 065, 066, 068 · UI-11-14 · BR-11-006, 021 · PERM-11-instance-admin
    Biết 25 phiên `RUNNING` ở v3; v4 `PUBLISHED`; TA, TA2; `11.migration.batchSize = 10`.
    Khi TA `POST /migration-plans` `{processKey, from:3, to:4}`
    Và TA `:validate`
    Và TA `:submit`, TA2 `:approve`
    Và theo dõi chạy ba lô
    Và `GET /migration-plans/{id}`
    Thì ghép tự động theo `elementId`; kế hoạch `VALIDATED`; chạy 10, 10, 5 phiên, mỗi phiên một giao dịch; `COMPLETED`; `instance_index.version = 4`; phiên chạy tiếp đúng bước.

  @TC-11-102 @P2 @Âm
  Kịch bản: TC-11-102 Di trú: bước chưa ánh xạ, tự duyệt, phiên lỗi giữa chừng
    # Truy vết: FR-11-026 · API-11-064, 066 · ERR-11-005, 031, 119 · BR-11-021
    Biết v4 bỏ bước `guiCuTru` mà còn 3 phiên đang ở đó; một phiên bị chèn lỗi khi di trú.
    Khi TA `:validate` kế hoạch
    Và TA tự `:approve`
    Và ánh xạ tay, TA2 duyệt, chạy
    Và đọc kết quả lô
    Thì bước 1 `422` ERR-11-031 nêu 3 phiên và bước chưa ánh xạ. Bước 2 `403` ERR-11-005. Sau chạy: `PARTIAL`, phiên lỗi ghi ERR-11-119 ở UI-11-14, các phiên khác `instance_index.version = 4`.
