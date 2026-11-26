# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-01
Tính năng: TS-11-01 · Tạo mô hình, bản nháp, so sánh, nhập, xuất và mẫu dùng chung

  @TC-11-001 @P2 @Dương
  Kịch bản: TC-11-001 Liệt kê, tìm kiếm và xem chi tiết mô hình
    # Truy vết: FR-11-001 · API-11-001, 002 · UI-11-01 · BR-11-031 · PERM-11-read
    Biết T90 có `M-KS`, `M-DUYET` và 3 mô hình khác; VW.
    Khi VW gọi `GET /models?page=0&size=2&q=KHAI&status=PUBLISHED&sort=name`
    Và VW gọi `GET /models/LT_KHAI_SINH`
    Và VW đổi `size=50` và so `totalElements` với số mô hình của T90
    Thì bước 1 `200`, tối đa 2 phần tử, chỉ `LT_KHAI_SINH`. Bước 2 có `activeVersion = 3`, danh sách phiên bản và `ETag`. Bước 3 `totalElements = 5`, không có mô hình của T91.

  @TC-11-002 @P2 @Âm
  Kịch bản: TC-11-002 Tham số liệt kê sai và mô hình không tồn tại
    # Truy vết: FR-11-001 · API-11-001, 002 · ERR-11-001, 003
    Biết VW ở T90; `U-T91-IE1` đã tạo `LT_RIENG_T91` ở T91.
    Khi VW gọi `GET /models?size=0`, `size=1000`, `sort=lạ`, `status=FOO`
    Và VW gọi `GET /models/KHONG_CO`
    Và VW gọi `GET /models/LT_RIENG_T91`
    Thì bước 1 `400` ERR-11-003, `errors[]` chỉ đúng tham số sai. Bước 2 và 3 `404-ẩn` ERR-11-001, hai thân giống nhau trừ `traceId`.

  @TC-11-003 @P1 @Dương
  Kịch bản: TC-11-003 Tạo mô hình trống và sửa thuộc tính
    # Truy vết: FR-11-002 · API-11-003, 005 · UI-11-02 · PERM-11-model
    Biết IE1; mã `LT_THU_NGHIEM` chưa dùng.
    Khi IE1 gọi `POST /models` `{processKey:"LT_THU_NGHIEM", name:"Thử nghiệm", groupCode:"HO_TICH"}`
    Và IE1 gọi `PATCH /models/LT_THU_NGHIEM` với `If-Match` đúng, đổi `name`
    Thì bước 1 `201`, `Location`, phiên bản 1 `DRAFT`, `ETag`. Bước 2 `200`, `name` mới, `ETag` đổi. KT: có (`model.create`, `model.update`).
    # Hậu điều kiện: Mô hình `LT_THU_NGHIEM` dùng lại ở TS-11-05.

  @TC-11-004 @P1 @Âm
  Kịch bản: TC-11-004 Tạo mô hình trùng mã, sai mẫu, lệch ETag
    # Truy vết: FR-11-002 · API-11-003, 005 · ERR-11-002, 003, 004, 006 · ERR-00-403, 428
    Biết IE1, VW; `LT_KHAI_SINH` có sẵn; `LT_CU` đã lưu trữ (`archived`).
    Khi IE1 `POST /models` với `processKey = LT_KHAI_SINH`
    Và IE1 `POST /models` với `processKey = lt-khai-sinh` rồi `AB`
    Và IE1 `PATCH` không `If-Match`
    Và IE1 `PATCH` với `If-Match` cũ
    Và IE1 `PATCH /models/LT_CU`
    Và VW `POST /models`
    Thì bước 1 `409` ERR-11-002. Bước 2 `400` ERR-11-003 (hai lần). Bước 3 `428`. Bước 4 `409` ERR-11-004. Bước 5 `409` ERR-11-006. Bước 6 `403` ERR-00-403.

  @TC-11-005 @P1 @Dương
  Kịch bản: TC-11-005 Tạo bản nháp từ bản phát hành và so sánh hai phiên bản
    # Truy vết: FR-11-006 · API-11-007, 008, 009, 015 · UI-11-03, 05 · BR-11-005
    Biết `M-KS` v3 `PUBLISHED`; IE1.
    Khi IE1 gọi `POST /models/LT_KHAI_SINH/versions` `{basedOn:3}`
    Và IE1 thêm một service task ở v4 bằng `PUT /versions/4/bpmn`
    Và IE1 gọi `GET /versions/4/diff?against=3`
    Và VW gọi `GET /versions` rồi `GET /versions/3`
    Thì bước 1 `201`, v4 `DRAFT`, `basedOn = 3`, XML giống v3. Bước 3 `200` liệt kê 1 phần tử thêm, 0 xóa, cờ thuộc tính đổi. Bước 4 `checksum` v3 không đổi so với trước ca (BR-11-005).

  @TC-11-006 @P1 @Âm
  Kịch bản: TC-11-006 Nháp thứ hai, so sánh phiên bản lạ, sửa bản đã phát hành
    # Truy vết: FR-11-006 · API-11-008, 009, 010, 015 · ERR-11-001, 006 · ERR-00-403 · BR-11-005
    Biết sau ca `draft-diff` (v4 đang là nháp); VW.
    Khi IE1 gọi lại `POST /versions` `{basedOn:3}`
    Và IE1 gọi `GET /versions/4/diff?against=99`
    Và IE1 gọi `PUT /versions/3/bpmn`
    Và VW gọi `POST /versions`
    Thì bước 1 `409` ERR-11-006. Bước 2 `404` ERR-11-001. Bước 3 `409` ERR-11-006, `checksum` v3 không đổi. Bước 4 `403` ERR-00-403.

  @TC-11-007 @P2 @Dương
  Kịch bản: TC-11-007 Nhập BPMN XML, xuất XML và gói quy trình
    # Truy vết: FR-11-010 · API-11-004, 024 · UI-11-02 · BR-11-005, 014 · PERM-11-model, PERM-11-read
    Biết IE1, VW; tệp `X-OK`.
    Khi IE1 gọi `POST /models:import` với `X-OK`
    Và VW gọi `GET /versions/1/export?format=bpmn`
    Và VW gọi `GET /versions/1/export?format=package`
    Và IE1 nhập lại gói thành `LT_NHAP_LAI`
    Thì bước 1 `201`, `DRAFT`, `checksum` SHA-256 của `X-OK`. Bước 2 XML khớp `checksum`. Bước 3 tệp nén có BPMN, biểu mẫu, ý định, bù trừ, danh sách biến, tệp kê khai có băm. Bước 4 mô hình mới có cùng bộ phần tử, biến, bù trừ.

  @TC-11-008 @P1 @Âm
  Kịch bản: TC-11-008 Nhập XML sai chuẩn, vượt cỡ, thực thể ngoài
    # Truy vết: FR-11-010 · API-11-004 · ERR-11-008, 009 · BR-11-014
    Biết IE1; `X-SAI`, `X-LON`; một XML có `<!DOCTYPE>` và thực thể ngoài trỏ `file:///etc/passwd`; T92 có `11.model.maxXmlKb = 256`.
    Khi IE1 nhập `X-SAI`
    Và IE1 nhập `X-LON`
    Và IE1 nhập XML thực thể ngoài
    Và IE1 ở T92 nhập tệp 300 KB
    Thì bước 1 `400` ERR-11-008. Bước 2 `413` ERR-11-009. Bước 3 `400` ERR-11-008, nội dung tệp hệ thống không xuất hiện trong phản hồi hay log. Bước 4 `413` ERR-11-009.
    # Hậu điều kiện: Không có mô hình mới.

  @TC-11-009 @P2 @Dương @Âm
  Kịch bản: TC-11-009 Mẫu dùng chung COMMON: tạo, phát hành bởi người khác, sao chép, cấm TA sửa
    # Truy vết: FR-11-015, 002 · API-11-041, 042, 043, 003 · UI-11-10 · ERR-11-002, 005, 036 · BR-11-027
    Biết PA, PA2, TA ở T90.
    Khi PA gọi `POST /templates` `{templateCode:"MAU_DUYET_2_CAP"}`
    Và PA gọi `POST /templates/MAU_DUYET_2_CAP:publish`
    Và PA2 gọi lại `:publish`
    Và TA gọi `POST /models` `{fromTemplate:"MAU_DUYET_2_CAP", processKey:"LT_DUYET_RIENG"}`
    Và TA gọi `POST /templates` trùng mã và sửa mẫu `COMMON`
    Thì bước 2 `409` ERR-11-005 (PA tự phát hành). Bước 3 `200` `PUBLISHED`. Bước 4 `201` mô hình riêng `DRAFT`, mẫu không đổi. Bước 5 `409` ERR-11-002, sửa mẫu `403` ERR-11-036.
