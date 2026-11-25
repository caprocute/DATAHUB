# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-01
Tính năng: TS-07-01 · Quản lý danh mục: liệt kê, xem, tạo, sửa, xóa, ngừng hiệu lực

  @TC-07-001 @P1 @Dương
  Kịch bản: TC-07-001 Liệt kê danh mục có lọc, sắp xếp và đếm số lượng
    # Truy vết: FR-07-001 · API-07-001 · UI-07-01 · LGC-DMDC-001
    Biết T68 có 9 danh mục riêng (CAT-DT68, CAT-LH, CAT-MUC, CAT-NHAP, CAT-RES, CAT-REF, CAT-BIG và 2 danh mục khác); COMMON có 4 danh mục. Người gọi U-T68-VW.
    Khi gọi `GET /catalogs?page=0&size=20&sort=code,asc`.
    Và gọi `GET /catalogs?sourceType=LOCAL&status=ACTIVE`.
    Và gọi `GET /catalogs?q=loai hinh` (không dấu).
    Và gọi `GET /catalogs?classification=RESTRICTED`.
    Thì bước 1 trả `200`, `totalElements` = 13 (9 của T68 cộng 4 COMMON hiển thị kèm nhãn nguồn `COMMON`), danh sách sắp theo mã tăng dần, không có danh mục nào của T01 hoặc đã xóa mềm. Bước 2 chỉ trả danh mục LOCAL đang ACTIVE (không có `DM_THU_NGHIEM` vì đang DRAFT). Bước 3 trả `LOAI_HINH_TC` (tìm không dấu theo FR-00-020). Bước 4 trả đúng `TRAM_QUAN_TRAC`. Mỗi phần tử có `code`, `name`, `sourceType`, `status`, `classification`, `currentVersionNo`, `itemCount`. KT: không. EVT: không.

  @TC-07-002 @P2 @Âm @Biên
  Kịch bản: TC-07-002 Liệt kê với tham số phân trang hoặc bộ lọc không hợp lệ
    # Truy vết: FR-07-001 · API-07-001 · FR-00-021
    Biết người gọi U-T68-VW.
    Khi gọi `GET /catalogs?size=200` (biên trên).
    Và gọi `GET /catalogs?size=201`.
    Và gọi `GET /catalogs?status=ARCHIVED` (giá trị không có trong miền).
    Và gọi `GET /catalogs?sort=drop_table,asc` (trường sắp xếp không cho phép).
    Thì bước 1 trả `200`. Bước 2, 3, 4 trả `400` dạng `application/problem+json`, có trường `errors` chỉ rõ tham số sai, không lộ thông điệp SQL. KT: không.

  @TC-07-003 @P1 @Dương
  Kịch bản: TC-07-003 Xem chi tiết danh mục phân cấp
    # Truy vết: FR-07-002 · API-07-003, 011, 022, 026 · UI-07-02 · LGC-DMDC-003
    Biết CAT-LH đã phát hành v1; người gọi U-T68-VW.
    Khi gọi `GET /catalogs/LOAI_HINH_TC`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/versions`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/versions/current/attributes`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/versions/current/items?page=0&size=50`.
    Và trên giao diện, mở UI-07-02 của danh mục, lần lượt bấm các tab Tổng quan, Bản ghi, Thuộc tính, Phiên bản.
    Thì bước 1 trả `200` với `isHierarchical = true`, `maxDepth = 3`, `levelNames` = `["Khối","Loại","Phân loại"]`, `ETag` khớp `version`. Bước 2 liệt kê v1 `PUBLISHED` có nhãn tính toán "Đang hiệu lực". Bước 3 trả 5 thuộc tính theo `sortOrder`. Bước 4 trả 39 bản ghi, mỗi bản ghi có `depth`, `path`, `levelName`. Giao diện hiển thị đúng số liệu, tab Ánh xạ, Đồng bộ chỉ hiện khi có dữ liệu hoặc quyền tương ứng. KT: không.

  @TC-07-004 @P2 @Âm
  Kịch bản: TC-07-004 Xem chi tiết danh mục không tồn tại
    # Truy vết: FR-07-002 · API-07-003 · ERR-07-001
    Biết người gọi U-T68-VW.
    Khi gọi `GET /catalogs/KHONG_TON_TAI`.
    Và gọi `GET /catalogs/DM_DA_XOA` (danh mục đã bị xóa mềm trước đó ở TC-07-011).
    Thì cả hai trả `404`, `code` = `ERR-07-001`, thông điệp tiếng Việt "Không tìm thấy danh mục", có `traceId`. KT: không.

  @TC-07-005 @P1 @Dương
  Kịch bản: TC-07-005 Tạo danh mục thủ công kèm thuộc tính ban đầu
    # Truy vết: FR-07-003, 005, 007 · BR-07-001 · API-07-002 · UI-07-03 · UC-07-01 · EVT-07-01 · LGC-DMDC-004
    Biết người gọi U-T68-DS-NV; mã `TC005_CAP_DO`.
    Khi gọi `POST /catalogs` với `Idempotency-Key: k-005`, thân `{"code":"tc005_cap_do","name":"Cấp độ hồ sơ","sourceType":"LOCAL","classification":"PUBLIC","isHierarchical":false,"requireApproval":true,"ownerOrgId":"<ORG-SNV>","attributes":[{"code":"mo_ta","label":"Mô tả","dataType":"TEXT"},{"code":"so_ngay","label":"Số ngày xử lý","dataType":"INTEGER","minValue":0,"queryable":true}]}`.
    Và gọi `GET /catalogs/TC005_CAP_DO` và `GET /catalogs/TC005_CAP_DO/versions`.
    Và đọc bảng `ph07_rdm.outbox` và topic `t68.rdm.catalog.created.v1`.
    Thì bước 1 trả `201`, header `Location` trỏ `/catalogs/TC005_CAP_DO`, mã được chuẩn hóa thành chữ hoa. Bước 2 cho `status = DRAFT`, có đúng một phiên bản v1 `DRAFT`, 2 thuộc tính, `tenantId` = `T68` (lấy từ token). Bước 3: đúng một sự kiện EVT-07-01 dạng CloudEvents (`type` = `vn.datahub.rdm.catalog.created.v1`, `source`, `id` duy nhất, `tenantid` = `t68`). KT: có (CREATE catalog, giá trị sau).

  @TC-07-006 @P1 @Âm
  Kịch bản: TC-07-006 Tạo danh mục trùng mã trong cùng tenant
    # Truy vết: FR-07-003 · BR-07-001 · API-07-002 · ERR-07-002
    Biết CAT-LH tồn tại trong T68; người gọi U-T68-DS-NV.
    Khi gọi `POST /catalogs` với `code` = `loai_hinh_tc` (khác hoa thường), `Idempotency-Key` mới.
    Thì `409`, `ERR-07-002`. Không có bản ghi `catalog` mới. EVT: không. KT: có (CREATE catalog, kết quả thất bại) theo FR-00-040 nếu chính sách kiểm toán ghi cả thao tác bị từ chối nghiệp vụ.

  @TC-07-007 @P1 @Âm
  Kịch bản: TC-07-007 Tạo danh mục trùng mã danh mục COMMON đang ACTIVE
    # Truy vết: FR-07-003 · BR-07-001 · ERR-07-002
    Biết COMMON có `GIOI_TINH` ACTIVE; người gọi U-T68-DS-NV.
    Khi gọi `POST /catalogs` với `code` = `GIOI_TINH`.
    Và gọi `POST /catalogs` với `code` = `TC007_GIOI_TINH_RIENG`.
    Thì bước 1 trả `409` `ERR-07-002` (chi tiết nêu trùng với danh mục dùng chung). Bước 2 trả `201`. EVT: chỉ một EVT-07-01 cho bước 2.

  @TC-07-008 @P2 @Dương
  Kịch bản: TC-07-008 Gửi lại yêu cầu tạo với cùng Idempotency-Key và cùng nội dung
    # Truy vết: FR-07-003 · API-07-002 · D03-01 §7.2
    Biết đã chạy TC-07-005 với `k-005`.
    Khi gửi lại nguyên văn yêu cầu bước 1 của TC-07-005 trong vòng 24 giờ.
    Thì `201` (hoặc `200` kèm header `Idempotency-Replayed: true` theo D03-04), thân phản hồi giống lần đầu; không có danh mục thứ hai; không có EVT-07-01 thứ hai; không có bản ghi kiểm toán thứ hai.

  @TC-07-009 @P2 @Âm
  Kịch bản: TC-07-009 Dùng lại Idempotency-Key với nội dung khác
    # Truy vết: FR-07-003 · ERR-07-022
    Biết đã chạy TC-07-005 với `k-005`.
    Khi gọi `POST /catalogs` với `Idempotency-Key: k-005` nhưng `name` = "Tên khác".
    Thì `409`, `ERR-07-022`. Danh mục `TC005_CAP_DO` giữ nguyên tên. EVT: không.

  @TC-07-010 @P1 @Dương
  Kịch bản: TC-07-010 Cập nhật thông tin danh mục với If-Match đúng
    # Truy vết: FR-07-004 · API-07-004 · UI-07-03 · EVT-07-02 · LGC-DMDC-009
    Biết CAT-LH ACTIVE, `ETag` = `"7"`; người gọi U-T68-DS-NV (cùng tổ chức chủ quản).
    Khi gọi `GET /catalogs/LOAI_HINH_TC`, lấy `ETag`.
    Và gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match: "7"`, thân `{"name":"Loại hình tổ chức (sửa)","description":"Mô tả mới"}`.
    Thì `200`, `ETag` mới `"8"`; tên mới hiển thị ở UI-07-01; nội dung phiên bản đã phát hành không đổi (tên danh mục là thông tin của thực thể danh mục, không thuộc ảnh chụp phiên bản). EVT-07-02 phát một lần với danh sách trường đổi. KT: có (UPDATE catalog, giá trị trước và sau).

  @TC-07-011 @P1 @Dương
  Kịch bản: TC-07-011 Xóa danh mục chưa từng phát hành
    # Truy vết: FR-07-009 · API-07-005 · UI-07-02 · UC-07-14 · LGC-DMDC-012 · FR-00-050, 051
    Biết CAT-NHAP (`DM_THU_NGHIEM`, `DRAFT`); người gọi U-T68-TA.
    Khi trên UI-07-02 bấm "Xóa danh mục"; hộp xác nhận hiện, nhập lại mã danh mục để xác nhận.
    Và gọi tương đương `DELETE /catalogs/DM_THU_NGHIEM` với `If-Match`.
    Và gọi `GET /catalogs/DM_THU_NGHIEM`.
    Thì bước 2 trả `204`. `catalog.deleted_at` có giá trị, phiên bản nháp chuyển `DISCARDED`. Bước 3 trả `404` `ERR-07-001`. Mã `DM_THU_NGHIEM` có thể dùng lại để tạo danh mục mới (chỉ mục duy nhất loại trừ bản ghi đã xóa mềm). KT: có (DELETE catalog). EVT: không có EVT-07-03 (xóa danh mục chưa phát hành không phát sự kiện cho bên khai thác).

  @TC-07-012 @P1 @Âm
  Kịch bản: TC-07-012 Không cho xóa danh mục đã phát hành
    # Truy vết: FR-07-009 · API-07-005 · ERR-07-048
    Biết CAT-MUC ACTIVE; người gọi U-T68-TA.
    Khi gọi `DELETE /catalogs/MUC_DO_DVC` với `If-Match` đúng.
    Thì `409`, `ERR-07-048` với chi tiết gợi ý "Danh mục đã phát hành, hãy dùng chức năng ngừng hiệu lực". Danh mục giữ nguyên. Trên UI-07-02 nút "Xóa" không hiển thị với danh mục ACTIVE (FR-00-053).

  @TC-07-013 @P1 @Dương
  Kịch bản: TC-07-013 Ngừng hiệu lực danh mục đã phát hành
    # Truy vết: FR-07-009 · API-07-006 · UC-07-14 · EVT-07-03 · LGC-DMDC-012
    Biết danh mục `TC013_DM` ACTIVE (tạo và phát hành trong bước chuẩn bị), không bị tham chiếu; người gọi U-T68-TA.
    Khi gọi `POST /catalogs/TC013_DM:retire` với thân `{"reason":"Hết căn cứ pháp lý","effectiveDate":"2026-12-01"}`.
    Và gọi `GET /catalogs/TC013_DM`.
    Thì bước 1 trả `200`; `status = RETIRED`; phiên bản hiện hành có `effective_to` = 2026-12-01. EVT-07-03 phát một lần (có `reason`, `effectiveDate`). Con trỏ phiên bản hiệu lực trong bộ đệm bị vô hiệu. KT: có (RETIRE catalog, lý do).

  @TC-07-014 @P1 @Âm
  Kịch bản: TC-07-014 Không ngừng hiệu lực danh mục đang được tham chiếu
    # Truy vết: FR-07-009 · BR-07-020 · ERR-07-032
    Biết CAT-REF ACTIVE có thuộc tính CATALOG_REF trỏ `LOAI_HINH_TC`; người gọi U-T68-TA.
    Khi gọi `POST /catalogs/LOAI_HINH_TC:retire` với lý do hợp lệ.
    Thì `409`, `ERR-07-032`, chi tiết liệt kê danh mục tham chiếu `LINH_VUC_TTHC`. `LOAI_HINH_TC` vẫn ACTIVE. EVT: không.

  @TC-07-015 @P2 @Âm
  Kịch bản: TC-07-015 Tra cứu danh mục đã ngừng hiệu lực
    # Truy vết: FR-07-009, 026 · ERR-07-031 · BR-07-008
    Biết `TC013_DM` RETIRED từ 2026-12-01; đồng hồ đặt 2026-12-02; người gọi APP-T68-READ.
    Khi gọi `GET /catalogs/TC013_DM/items/A01`.
    Và gọi `GET /catalogs/TC013_DM/items/A01?at=2026-11-25`.
    Thì bước 1 trả `410`, `ERR-07-031`. Bước 2 trả `200` với bản ghi theo phiên bản hiệu lực tại 2026-11-25 (dữ liệu lịch sử vẫn tra được).

  @TC-07-016 @P2 @Âm
  Kịch bản: TC-07-016 Không tạo bản nháp mới cho danh mục RETIRED
    # Truy vết: FR-07-009, 011 · API-07-012 · ERR-07-031
    Biết `TC013_DM` RETIRED; người gọi U-T68-DS-NV.
    Khi gọi `POST /catalogs/TC013_DM/versions`.
    Thì `410`, `ERR-07-031`. Không có phiên bản mới.

  @TC-07-017 @P3 @Âm
  Kịch bản: TC-07-017 Không ngừng hiệu lực danh mục chưa phát hành
    # Truy vết: FR-07-009 · API-07-006 · ERR-07-048
    Biết danh mục `TC017_DM` DRAFT; người gọi U-T68-TA.
    Khi gọi `POST /catalogs/TC017_DM:retire`.
    Thì `409`, `ERR-07-048`, gợi ý dùng xóa. Trạng thái giữ `DRAFT`.

  @TC-07-018 @P1 @Âm
  Kịch bản: TC-07-018 Cập nhật thông tin danh mục với ETag cũ
    # Truy vết: FR-07-004 · API-07-004 · ERR-07-018, 040, 004 · BR-07-040 · FR-00-052
    Biết CAT-LH có `ETag` `"8"` sau TC-07-010; người gọi U-T68-DS-NV.
    Khi gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match: "7"`.
    Và gọi `PATCH /catalogs/LOAI_HINH_TC` không có `If-Match`.
    Và trên giao diện: mở UI-07-03 ở hai tab trình duyệt, lưu tab 1, rồi lưu tab 2.
    Và gọi `PATCH /catalogs/LOAI_HINH_TC` với `If-Match` đúng và `code = LOAI_HINH_TC2` (danh mục đã phát hành).
    Thì bước 1 trả `412`, `ERR-07-018`. Bước 2 trả `400` `ERR-07-040` (quy ước thiếu `If-Match` của D03-04-PH07 §6). Bước 4 trả `409` `ERR-07-004`, mã danh mục không đổi (BR-07-040). Bước 3: tab 2 hiển thị hộp thoại xung đột có khác biệt, cho chọn "Tải lại" hoặc "Ghi đè" (FR-00-052). Dữ liệu không bị ghi đè âm thầm.
