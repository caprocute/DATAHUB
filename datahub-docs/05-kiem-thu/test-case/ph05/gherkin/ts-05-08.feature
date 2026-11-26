# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-08
Tính năng: TS-05-08 · Cấp sử dụng và nơi dùng

  @TC-05-032 @P1 @Dương
  Kịch bản: TC-05-032 Cấp cho không gian, có hạn; thu hồi
    # Truy vết: FR-05-009 · API-05-022, 023, 024 · EVT-05-05 · UC-05-07
    Biết U-T68-IE1; không gian `ho-tich` ở PH-04.
    Khi `POST …/tc-ndxp-moi/grants` với `scope = WORKSPACE`, `scopeCode = ho-tich`, `envs = [TEST]`, `expiresAt` +30 ngày.
    Và `GET …/grants`.
    Và `DELETE …/grants/{id}`.
    Thì bước 1 `201`. EVT: `connection.grant-changed`. Bước 2 có mục. Bước 3 `204`, EVT lần nữa. KT: có (`GRANT_CREATE`, `GRANT_REVOKE`).

  @TC-05-033 @P2 @Âm
  Kịch bản: TC-05-033 Cấp cho không gian không tồn tại; db-flow cấp không gian
    # Truy vết: FR-05-009, 023 · API-05-023 · ERR-05-033, 003 · BR-05-018
    Biết U-T68-IE1; C-DKKD; `05.dbflow.allow-workspace-scope = false`.
    Khi `POST …/tc-ndxp-moi/grants` với `scopeCode = khong-co`.
    Và `POST …/dkkd-db/grants` với `scope = WORKSPACE`.
    Thì bước 1 `422` ERR-05-033. Bước 2 `400` ERR-05-003 rule `dbflow-flow-scope-only`.

  @TC-05-034 @P2 @Dương
  Kịch bản: TC-05-034 Nơi dùng liệt kê phiên bản luồng và bộ điều hợp
    # Truy vết: FR-05-013 · API-05-025, 062 · UI-05-02, 09
    Biết U-T68-VW; C-NDXP; A-DVC.
    Thì danh sách khớp chỉ mục `usage_ref` (luồng, phiên bản, môi trường, đã triển khai), đếm khớp `usageCount` ở danh sách.
