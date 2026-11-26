# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-09
Tính năng: TS-08-09 · Cấu hình trọng số và ngưỡng có duyệt

  @TC-08-045 @P1 @Dương
  Kịch bản: TC-08-045 Soạn, gửi duyệt và duyệt cấu hình trọng số
    # Truy vết: FR-08-021 · API-08-047, 048, 050, 051 · UI-08-10 · BR-08-002 · PERM-08-approve
    Biết chưa có cấu hình T90 (dùng v0 mặc định 0,20/0,20/0,15/0,10/0,15/0,20; ngưỡng 80/70); DS1, DA1.
    Khi `GET /weight-configs`
    Và DS1 `POST /weight-configs` `{scope: TENANT, weights: {completeness: 0.25, accuracy: 0.20, consistency: 0.15, timeliness: 0.10, uniqueness: 0.10, validity: 0.20}, passMin: 85, warnMin: 70}`
    Và `:submit`
    Và DA1 `:approve`
    Thì bước 1 có v0. Bước 2 `201`, `status = DRAFT`. Bước 4 `ACTIVE`, v0 `SUPERSEDED`; mỗi phạm vi đúng một cấu hình `ACTIVE`; lần đo sau dùng `weightConfigId` mới. KT: có (weight.approve).

  @TC-08-046 @P1 @Âm @Biên
  Kịch bản: TC-08-046 Tổng trọng số và ngưỡng ngoài miền
    # Truy vết: FR-08-021 · API-08-048, 049 · BR-08-002 · BR-08-023 · ERR-08-023, 024
    Biết nháp cấu hình của DS1.
    Khi `POST` trọng số `0.20/0.20/0.15/0.10/0.15/0.25` (tổng 1,05)
    Và `POST` trọng số `0.2005/0.20/0.15/0.10/0.15/0.20` (tổng 1,0005)
    Và `POST` một trọng số 1,2
    Và `POST` ngưỡng đạt 80, cảnh báo 85
    Thì bước 1 `422` ERR-08-023, thân ghi tổng 1,05. Bước 2 `201` (trong dung sai 0,001). Bước 3 `422` ERR-08-023. Bước 4 `422` ERR-08-024.

  @TC-08-047 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-047 Tự duyệt và hạ ngưỡng thiếu lý do
    # Truy vết: FR-08-021 · API-08-051, 052 · BR-08-007 · ERR-08-005, 007
    Biết cấu hình chờ duyệt do DS1 gửi; ngưỡng đạt hiện 80, đề xuất 70.
    Khi DS1 `:approve`
    Và TA (có cả quyền soạn và duyệt) `:approve` cấu hình do chính TA gửi
    Và DA1 `:reject` không lý do
    Và `POST` hạ ngưỡng đạt từ 80 xuống 70 không lý do
    Thì bước 1 và 2 `403` ERR-08-005. Bước 3 và 4 `422` ERR-08-007. Cấu hình giữ nguyên.

  @TC-08-048 @P1 @Dương
  Kịch bản: TC-08-048 Đổi trọng số không hồi tố điểm quá khứ
    # Truy vết: FR-08-021 · FR-08-028 · API-08-065 · BR-08-008
    Biết ảnh chụp S1 của `mdm-citizen` điểm 91,45 với cấu hình v0; DA1 vừa duyệt v1 như wc-flow; chạy lần đo S2 trên dữ liệu không đổi.
    Khi `GET /scans/{S1}/score`
    Và chạy lần đo S2 `POST /scans`
    Và `GET /scans/{S2}/score`
    Thì S1 giữ 91,45 và `weightConfigId` v0. S2 tính theo v1 (0,25/0,20/0,15/0,10/0,10/0,20): 98×0,25 + 95×0,20 + 80×0,15 + 90×0,10 + 99×0,10 + 85×0,20 = 91,40, `weightConfigId` v1, cờ `WEIGHTS_CHANGED` ở so kỳ S1 → S2.

  @TC-08-153 @P2 @Dương @Âm
  Kịch bản: TC-08-153 Xem trước điểm theo trọng số và ngưỡng mới
    # Truy vết: FR-08-021 · API-08-132 · UI-08-10 · BR-08-002 · PERM-08-rule-admin · ERR-08-023, 024, 027
    Biết miền `DAN_CU` có 3 đối tượng với ảnh chụp đầy đủ gần nhất (F-SCORE, F-ANNUAL); cấu hình hiện hành v0; đối tượng `rdm-dvhc` chưa có ảnh chụp nào; DS1.
    Khi DS1 `POST /weight-configs:preview` `{scope: DOMAIN, domainCode: DAN_CU, weights: {completeness: 0.25, accuracy: 0.20, consistency: 0.15, timeliness: 0.10, uniqueness: 0.10, validity: 0.20}, passMin: 85, warnMin: 70}`
    Và lặp bước 1 với tổng trọng số 1,05
    Và lặp bước 1 với `passMin: 60`, `warnMin: 70`
    Và lặp bước 1 với `{scope: ASSET, assetCode: rdm-dvhc}`
    Và `GET /weight-configs`
    Thì bước 1 `200`, `assetCount = 3`, `assets[]` mỗi đối tượng có `currentScore`, `projectedScore`, `currentVerdict`, `projectedVerdict`, `snapshotId`; `delta` bằng `projectedScore` trừ `currentScore`; `changedVerdictCount` đúng số đối tượng đổi kết luận. Bước 2 `422` ERR-08-023. Bước 3 `422` ERR-08-024. Bước 4 `422` ERR-08-027. Bước 5 không có cấu hình mới và điểm quá khứ không đổi (xem wc-no-retro): xem trước chỉ đọc, không ghi dữ liệu.
