# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-14
Tính năng: TS-05-14 · Bộ điều hợp: tạo, danh sách, chi tiết

  @TC-05-054 @P1 @Dương
  Kịch bản: TC-05-054 Tạo bộ điều hợp SOAP và mở trình cấu hình
    # Truy vết: FR-05-031 · API-05-044, 045 · UI-05-08, 10 · LGC-BUS-040
    Biết U-T68-IE1; C-QLVB.
    Khi Ở UI-05-08 bấm "Tạo bộ điều hợp", chọn HTTT `HT-QLVB`, giao thức SOAP, kết nối `qlvb-soap`, mã `tc-qlvb`, giới hạn 10.
    Và `GET /adapters/tc-qlvb`.
    Thì bước 1 `201`, chuyển UI-05-10 phiên bản 1. Bước 2: `DRAFT`, phiên bản 1 `DRAFT` 0 thao tác, `maxConcurrency = 10`, không có Kamelet sinh. KT: có (`ADAPTER_CREATE`).

  @TC-05-055 @P1 @Âm
  Kịch bản: TC-05-055 Kết nối khác HTTT, giao thức không khớp loại kết nối
    # Truy vết: FR-05-031 · API-05-044 · ERR-05-003, 002 · BR-05-015
    Biết U-T68-IE1.
    Khi `POST /adapters` với `systemCode = HT-QLVB`, `connectionCode = ndxp-ho-tich`.
    Và với `protocol = SOAP`, `connectionCode = bhxh-sftp` (cùng HTTT giả định).
    Và với mã `qlvb-soap` đã có.
    Thì bước 1 `400` ERR-05-003 rule `same-system` (BR-05-015). Bước 2 `400` ERR-05-003 (giao thức không khớp loại). Bước 3 `409` ERR-05-002.

  @TC-05-056 @P2 @Dương
  Kịch bản: TC-05-056 Danh sách lọc theo nhóm HTTT, có bản chờ duyệt
    # Truy vết: FR-05-029 · API-05-043 · UI-05-08 · BR-05-014
    Biết U-T68-VW; A-DVC, A-QLVB, A-CDC.
    Thì chỉ A-QLVB, có `effectiveVersion = 3`, `draftVersion = 4`.

  @TC-05-057 @P2 @Dương @Âm
  Kịch bản: TC-05-057 Chi tiết bộ điều hợp; sửa chỉ thông tin chung
    # Truy vết: FR-05-030, 031 · API-05-045, 046 · ERR-05-003 · UI-05-09
    Biết U-T68-IE1; A-QLVB.
    Khi `GET /adapters/qlvb-soap`.
    Và `PATCH` tên; rồi `PATCH` `{"maxConcurrency":5}`.
    Thì bước 1 có thao tác, Kamelet sinh, `allowedActions`. Bước 2 lần đầu `200`, lần hai `400` ERR-05-003 (đổi qua phiên bản nháp).
