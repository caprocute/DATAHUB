# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-01
Tính năng: TS-10-01 · Dự án tích hợp

  @TC-10-001 @P1 @Dương
  Kịch bản: TC-10-001 Tạo dự án hợp lệ và xem chi tiết
    # Truy vết: FR-10-003, 002 · API-10-002, 003 · UI-10-04, 03 · UC-10-01 · LGC-HUB-008
    # Mục đích: Chứng minh luồng thành công, theo FR-10-003 (Tạo dự án tích hợp).
    Biết U-T68-IE1; tenant T68 còn dưới `10.quota.max-projects`.
    Khi mở UI-10-04 (`/tich-hop/du-an/moi`), nhập mã `tc-lien-thong-thue`, tên "Liên thông thuế thử", tổ chức `SO-KHDT`, nhãn `doanh-nghiep`; bấm "Tạo".
    Và `GET /projects/tc-lien-thong-thue`.
    Thì bước 1 gọi `POST /projects` có `Idempotency-Key`, trả `201`, `Location`, `ETag`; màn chuyển sang UI-10-03. Bước 2: `status = ACTIVE`, `ownerUser` là người tạo, `topicCount = 0`, `publisherCount = 0`, `subscriberCount = 0`. KT: có (tạo dự án). EVT: không.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-004.

  @TC-10-002 @P1 @Âm
  Kịch bản: TC-10-002 Tạo dự án sai mẫu, từ dành riêng, trùng mã, ngoài tổ chức, vượt hạn mức
    # Truy vết: FR-10-003 · API-10-002 · ERR-10-002, 003, 011, 039, 044 · BR-10-003
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-003 (Tạo dự án tích hợp).
    Biết U-T68-IE1; U-T68-SV (tổ chức `SO-KHDT`); P-CU đã lưu trữ ở bước chuẩn bị; T92 đã có 200 dự án giả (đặt `10.quota.max-projects = 200`).
    Khi `POST /projects` với `projectCode = "Tc_Hoa"`.
    Và lặp với `projectCode` lần lượt `moi`, `tong-quan`, `nhap`, `di-tru`, `ben-phat`, `ben-nhan`.
    Và lặp với `dang-ky-kinh-doanh` và `thu-nghiem-cu` (đã `ARCHIVED`).
    Và U-T68-SV gửi `ownerOrgCode = SO-TC`.
    Và U-T90-IE trên T92 tạo dự án thứ 201.
    Và người dùng IE của T94 (tenant tạm ngừng) tạo dự án.
    Thì bước 1, 2 `400` ERR-10-003 với `errors[0].field = projectCode`. Bước 3 `409` ERR-10-002 (mã đã lưu trữ cũng không dùng lại). Bước 4 403-TC. Bước 5 `422` ERR-10-011. Bước 6 `423` ERR-10-039. KT: không.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-003 @P2 @Dương @Âm
  Kịch bản: TC-10-003 Danh sách dự án lọc, sắp xếp, đếm và facets
    # Truy vết: FR-10-001 · API-10-001 · UI-10-02 · ERR-10-049
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-001 (Liệt kê, tìm kiếm và lọc dự án tích hợp).
    Biết U-T68-VW; P-DKKD, P-HT, P-CU.
    Khi `GET /projects?q=kinh doanh&status=ACTIVE&sort=topicCount,desc`.
    Và `GET /projects?size=201`.
    Và U-T68-OR gọi `GET /projects`.
    Thì bước 1 `200`, có `dang-ky-kinh-doanh` với `topicCount = 4`, `publisherCount`, `subscriberCount` đếm theo quan hệ `ACTIVE`, `maxLagSeconds` có giá trị; `facets.status` đếm đúng. Bước 2 `400` ERR-10-049. Bước 3 chỉ trả dự án có HTTT của `SO-TC` tham gia (P-DKKD qua SB-TC chưa có subscription thì không có). Tìm không dấu "kinh doanh" khớp tên có dấu.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-004 @P2 @Dương @Âm
  Kịch bản: TC-10-004 Sửa dự án có If-Match; mã bất biến; dự án đã lưu trữ không sửa
    # Truy vết: FR-10-004 · API-10-004 · ERR-10-003, 006, 007
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-004 (Sửa dự án).
    Biết U-T68-IE1, U-T68-IE2; dự án `tc-lien-thong-thue` từ TC-10-001.
    Khi IE1 `PATCH /projects/tc-lien-thong-thue` đổi `name`, `If-Match` đúng.
    Và IE2 gửi `PATCH` với `ETag` cũ.
    Và IE1 gửi `PATCH` có `projectCode = "doi-ma"`.
    Và lưu trữ dự án rồi `PATCH` tên.
    Thì bước 1 `200`, `ETag` mới. Bước 2 `412` ERR-10-007 có `currentEtag`. Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006. KT: có (sửa dự án, giá trị trước và sau) chỉ cho bước 1.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-005 @P1 @Dương @Âm
  Kịch bản: TC-10-005 Lưu trữ khi còn topic bị chặn; lưu trữ, khôi phục thành công
    # Truy vết: FR-10-005 · API-10-005, 006 · UI-10-03 · ERR-10-009, 010 · BR-10-003 · LGC-HUB-008
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-005 (Lưu trữ và khôi phục dự án).
    Biết U-T68-IE1; P-DKKD (có topic `ACTIVE`); P-CU (chỉ có một topic `DRAFT`).
    Khi `POST /projects/dang-ky-kinh-doanh:archive` với lý do hợp lệ.
    Và `POST /projects/thu-nghiem-cu:archive` không có `reason`.
    Và lặp bước 2 với lý do "Dự án thử nghiệm đã kết thúc".
    Và `POST /projects/thu-nghiem-cu:restore`.
    Và Ở UI-10-02 mở bộ lọc mặc định.
    Thì bước 1 `409` ERR-10-010 với `dependents[]` liệt kê 4 topic. Bước 2 `400` ERR-10-009. Bước 3 `200`, `status = ARCHIVED`, topic `DRAFT` bị xóa mềm, không có nút "Xóa" ở bất kỳ màn nào. Bước 4 `200`, `ACTIVE`. Bước 5 dự án `ARCHIVED` không hiện ở lọc mặc định, hiện khi chọn trạng thái "Đã lưu trữ". KT: có cho bước 3, 4.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
