# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-03
Tính năng: TS-08-03 · Tìm, xem, ngừng và khôi phục đối tượng đo

  @TC-08-015 @P1 @Dương
  Kịch bản: TC-08-015 Liệt kê, lọc và xem đối tượng đo
    # Truy vết: FR-08-006 · API-08-005, 007 · UI-08-02, 04 · BR-08-026 · PERM-08-read
    Biết T90 có `mdm-citizen`, `rdm-dvhc`, `src-hotich` đã đo; U-T90-DS1, U-T90-DO1 (ORG-CA), U-T90-VW.
    Khi DS1 `GET /assets?domainCode=DAN_CU&verdict=PASS&sort=score,desc&page=0&size=10`
    Và DS1 `GET /assets/mdm-citizen`
    Và DO1 `GET /assets`
    Thì bước 1 `200`, `items[]` có `score`, `verdict`, `trend`, `lastScanAt`, `openFindings{CRITICAL,MAJOR,MINOR}`, `cdeCoverage`, kèm `facets`. Bước 2 có `ETag`. Bước 3 chỉ các đối tượng của miền thuộc ORG-CA.

  @TC-08-016 @P1 @Âm @Bảo @mật
  Kịch bản: TC-08-016 DO ngoài tổ chức, tham số sai và tenant khác
    # Truy vết: FR-08-006 · API-08-005, 007 · BR-08-026 · ERR-08-032, 001, 045
    Biết `mdm-org` thuộc miền `DOANH_NGHIEP` (ORG-TC); T91 có đối tượng cùng mã `mdm-citizen`.
    Khi DO1 `GET /assets/mdm-org`
    Và DS1 `GET /assets/khong-co`
    Và U-T91-DS1 `GET /assets/src-hotich` (chỉ có ở T90)
    Và DS1 `GET /assets?size=0&sort=xyz`
    Thì bước 1 `403` ERR-08-032. Bước 2 và 3 `404` ERR-08-001, hai thân giống nhau trừ `traceId` (404-ẩn). Bước 4 `422` ERR-08-045.

  @TC-08-017 @P1 @Dương
  Kịch bản: TC-08-017 Tạm ngừng, khôi phục và ngừng hẳn đối tượng
    # Truy vết: FR-08-007 · API-08-010, 011, 012 · UI-08-04 · BR-08-020 · PERM-08-asset
    Biết `mdm-citizen` `ACTIVE`, lịch tháng hoạt động, một lần đo `QUEUED`.
    Khi DS1 `POST /assets/mdm-citizen:suspend` `{reason: "Nguồn bảo trì đến hết tuần, tạm ngừng đo"}`
    Và `GET /scans?assetCode=mdm-citizen&status=CANCELLED`
    Và `POST /assets/mdm-citizen:resume`
    Và `POST /assets/rdm-dvhc:retire` (lý do ≥ 20 ký tự)
    Thì bước 1 `200`, `status = SUSPENDED`, `cancelledScans[]` có lần đo `QUEUED`, lịch không bắn. Bước 3 `ACTIVE`, lịch tiếp tục. Bước 4 `RETIRED`; dữ liệu đo giữ theo chính sách lưu giữ (FR-08-059). KT: có (asset.suspend, asset.resume, asset.retire).

  @TC-08-018 @P1 @Âm
  Kịch bản: TC-08-018 Ngừng thiếu lý do, đang đo hoặc sai trạng thái
    # Truy vết: FR-08-007 · API-08-010, 011, 012 · ERR-08-007, 028, 006
    Biết `mdm-citizen` có lần đo `RUNNING`; `rdm-dvhc` `RETIRED`.
    Khi `POST /assets/src-hotich:suspend` `{reason: "bảo trì"}`
    Và `POST /assets/mdm-citizen:suspend` (lý do đủ dài)
    Và `POST /assets/rdm-dvhc:resume`
    Thì bước 1 `422` ERR-08-007. Bước 2 `409` ERR-08-028. Bước 3 `409` ERR-08-006.
