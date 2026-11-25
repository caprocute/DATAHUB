# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-07
Tính năng: TS-07-07 · Trình duyệt, duyệt, từ chối và phát hành phiên bản

  @TC-07-072 @P1 @Dương
  Kịch bản: TC-07-072 Trình duyệt bản nháp
    # Truy vết: FR-07-015 · API-07-017 · UC-07-06 · EVT-07-04 · FR-00-070
    Biết bản nháp v2 của CAT-LH hợp lệ, `effectiveFrom` = 2026-12-01, có `legalBasis`.
    Khi U-T68-DS-NV gọi `POST /catalogs/LOAI_HINH_TC/versions/draft:submit` thân `{"comment":"Đề nghị duyệt"}`.
    Và đọc topic `t68.rdm.catalog.submitted.v1`.
    Và U-T68-DA1 mở hộp "Việc của tôi".
    Thì `200`; `status = IN_REVIEW`, `submittedBy` = U-T68-DS-NV; `version_review` có dòng `SUBMIT` kèm `diffStats`. EVT-07-04 phát đúng một lần (có `catalogCode`, `versionNo`, `submittedBy`, `diffStats`, đường dẫn tới UI-07-07). Hộp "Việc của tôi" của U-T68-DA1 có việc chờ duyệt. KT: có (SUBMIT).

  @TC-07-073 @P1 @Dương
  Kịch bản: TC-07-073 Duyệt phiên bản bởi người khác người trình
    # Truy vết: FR-07-015 · BR-07-011 · API-07-018 · UI-07-07
    Biết v2 `IN_REVIEW` do U-T68-DS-NV trình.
    Khi U-T68-DA1 gọi `POST .../versions/2:approve` thân `{"comment":"Đồng ý"}`.
    Thì `200`; `status = APPROVED`, `approvedBy` = U-T68-DA1; `version_review` có `APPROVE`. Không phát EVT-07-05. KT: có (APPROVE).

  @TC-07-074 @P1 @Dương
  Kịch bản: TC-07-074 Phát hành phiên bản đã duyệt
    # Truy vết: FR-07-016 · BR-07-006, 007 · API-07-020 · UC-07-07 · EVT-07-05 · ADR-053
    Biết v2 `APPROVED`, `effectiveFrom` = 2026-12-01; v1 hiệu lực từ 2025-01-01 không có `effective_to`.
    Khi U-T68-DA1 gọi `POST .../versions/2:publish`.
    Và kiểm tra CSDL: `catalog_version` v1, v2; `catalog.current_version_id`.
    Và kiểm tra kho đối tượng `s3://dh-t68-rdm/snapshots/LOAI_HINH_TC/2.json.gz` và `.csv`.
    Và đọc topic `t68.rdm.catalog.published.v1`.
    Thì `200`; v2 `PUBLISHED`, `publishedBy`, `publishedAt`, `snapshotUri`, `schemaHash` có giá trị; v1 `effective_to` = 2026-12-01 (BR-07-007). `current_version_id` trỏ v2 (con trỏ "phiên bản mới nhất đã phát hành"; phiên bản hiệu lực tại một thời điểm vẫn tính theo khoảng ngày). Ảnh chụp có số bản ghi bằng `item_count`, giải nén ra JSON hợp lệ, SHA-256 ghi trong metadata đối tượng. EVT-07-05 phát đúng một lần với `catalogCode`, `versionNo` = 2, `effectiveFrom`, `stats`, `breaking`, `snapshotUri`. KT: có (PUBLISH).

  @TC-07-075 @P1 @Dương
  Kịch bản: TC-07-075 Phát hành lần đầu chuyển danh mục sang ACTIVE
    # Truy vết: FR-07-016 · khung §3.6 · API-07-020
    Biết danh mục `TC005_CAP_DO` DRAFT, v1 đã qua submit, approve.
    Khi U-T68-DA1 gọi `POST /catalogs/TC005_CAP_DO/versions/1:publish`.
    Và gọi `GET /catalogs/TC005_CAP_DO`.
    Thì `status` danh mục chuyển `DRAFT` → `ACTIVE`; v1 `PUBLISHED`. Danh mục xuất hiện trong `GET /catalogs?status=ACTIVE` và tra cứu được qua API khai thác.

  @TC-07-076 @P1 @Dương @Âm
  Kịch bản: TC-07-076 Từ chối phiên bản, bắt buộc lý do
    # Truy vết: FR-07-015 · API-07-019 · EVT-07-06 · FR-00-072
    Biết phiên bản `IN_REVIEW` do U-T68-DS-NV trình.
    Khi U-T68-DA1 gọi `POST .../versions/{v}:reject` thân `{}`.
    Và U-T68-DA1 gọi lại với `{"comment":"Thiếu căn cứ pháp lý"}`.
    Và U-T68-DS-NV sửa bản ghi trên phiên bản đó.
    Thì bước 1 trả `422` lỗi kiểm tra hợp lệ (trường `comment` bắt buộc). Bước 2 trả `200`, `status = DRAFT`; `version_review` lưu `REJECT` cùng lý do; EVT-07-06 phát một lần (người nhận là người trình). Bước 3 thành công vì phiên bản đã về `DRAFT`. KT: có (REJECT).

  @TC-07-077 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-077 Người trình không được tự duyệt
    # Truy vết: FR-07-015 · BR-07-011 · ERR-07-015 · FR-00-071 · D02-08
    Biết U-T68-DA2 (có cả DATA_STEWARD và DATA_APPROVER) soạn và trình bản nháp v2.
    Khi U-T68-DA2 gọi `POST .../versions/2:approve`.
    Và U-T68-DA2 gọi `POST .../versions/2:reject` (người trình không được tự từ chối; muốn đưa bản nháp về thì dùng `action = WITHDRAW` trên API-07-017, xem TC-07-256).
    Thì bước 1 trả `403`, `ERR-07-015`; phiên bản giữ `IN_REVIEW`. Bước 2 trả `403` `ERR-07-015`. KT: nhật ký an ninh ghi nhận lần thử tự duyệt.

  @TC-07-078 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-078 Người sửa lần cuối không được duyệt hoặc phát hành
    # Truy vết: FR-07-015, 016 · BR-07-011 · ERR-07-015 · khung §14.3
    Biết U-T68-DA2 sửa một bản ghi trong bản nháp v2; sau đó U-T68-DS-NV trình.
    Khi U-T68-DA2 gọi `:approve`.
    Và U-T68-DA1 gọi `:approve` (hợp lệ), sau đó U-T68-DA2 gọi `:publish`.
    Và với CAT-MUC (`require_approval = false`), U-T68-DA2 sửa bản nháp rồi tự gọi `:publish`.
    Thì bước 1 trả `403` `ERR-07-015`. Bước 2: duyệt thành công; `:publish` của U-T68-DA2 trả `403` `ERR-07-015`. Bước 3 trả `403` `ERR-07-015`.

  @TC-07-079 @P1 @Âm
  Kịch bản: TC-07-079 Không sửa bản ghi của phiên bản đã phát hành
    # Truy vết: FR-07-016 · BR-07-006 · ERR-07-004
    Biết v1 PUBLISHED.
    Khi gọi `POST /catalogs/LOAI_HINH_TC/versions/1/items`.
    Và gọi `PATCH .../versions/1/items/KH01`.
    Và gọi `POST .../versions/1/items/KH01:deprecate`.
    Và gọi `POST .../versions/1/items:batch`.
    Và (IT) Dùng vai trò ứng dụng `dh_data_app` chạy `UPDATE ph07_rdm.catalog_item SET name='x' WHERE version_id=<v1>`.
    Thì bước 1…4 trả `409` `ERR-07-004`. Bước 5 bị từ chối bởi ràng buộc ở CSDL (trigger hoặc chính sách chặn ghi vào phiên bản đã phát hành) nếu SDD chọn bảo vệ hai lớp; nếu SDD chỉ bảo vệ ở tầng ứng dụng thì bước 5 được ghi nhận là rủi ro chấp nhận (xem Q07-80). Băm nội dung v1 không đổi.

  @TC-07-080 @P2 @Âm
  Kịch bản: TC-07-080 Không sửa ngày hiệu lực, căn cứ của phiên bản đã phát hành
    # Truy vết: FR-07-016 · BR-07-006 · API-07-014 · ERR-07-004
    Biết v1 PUBLISHED.
    Khi gọi `PATCH /catalogs/LOAI_HINH_TC/versions/1` đổi `effectiveFrom`, `legalBasis`.
    Thì `409` `ERR-07-004`.

  @TC-07-081 @P1 @Âm
  Kịch bản: TC-07-081 Không sửa bản ghi khi phiên bản đang duyệt hoặc đã duyệt
    # Truy vết: FR-07-012, 015 · ERR-07-004
    Biết hai phiên bản ở `IN_REVIEW` và `APPROVED`.
    Khi với mỗi phiên bản gọi `PATCH .../items/{code}`, `POST .../attributes`, `POST /import-jobs` (đích là phiên bản đó).
    Thì mọi lệnh trả `409` `ERR-07-004` (tác vụ nhập bị từ chối ngay khi tạo hoặc khi commit, tùy SDD; ca này kiểm tra không có dữ liệu nào bị ghi).

  @TC-07-082 @P2 @Âm
  Kịch bản: TC-07-082 Không trình phiên bản đã hủy
    # Truy vết: FR-07-015, 017 · ERR-07-004
    Biết phiên bản số 2 `DISCARDED` (TC-07-064).
    Khi gọi `POST .../versions/2:submit`.
    Thì `409` `ERR-07-004`.

  @TC-07-083 @P1 @Âm
  Kịch bản: TC-07-083 Không bỏ qua bước trình hoặc bước duyệt khi danh mục cần duyệt
    # Truy vết: FR-07-015, 016 · BR-07-026 · ERR-07-004
    Biết CAT-LH `require_approval = true`; bản nháp v2 `DRAFT` rồi `IN_REVIEW`.
    Khi khi `DRAFT`, U-T68-DA1 gọi `:approve`.
    Và khi `DRAFT`, U-T68-DA1 gọi `:publish`.
    Và khi `IN_REVIEW`, U-T68-DA1 gọi `:publish`.
    Thì cả ba trả `409` `ERR-07-004`.

  @TC-07-084 @P1 @Dương
  Kịch bản: TC-07-084 Phát hành trực tiếp từ bản nháp khi không cần duyệt
    # Truy vết: FR-07-016 · BR-07-026 · API-07-020 · EVT-07-05
    Biết CAT-MUC 4 bản ghi; bản nháp do U-T68-DS-NV soạn chỉ sửa mô tả một thuộc tính, không đổi bản ghi nào (0% thay đổi, không phá vỡ). Người phát hành U-T68-DA1.
    Khi U-T68-DA1 gọi `POST /catalogs/MUC_DO_DVC/versions/draft:publish` với `effectiveFrom` hôm nay.
    Và trên UI-07-07, kiểm tra nút hiển thị khi người dùng có `PERM-07-publish`.
    Thì `200`; phiên bản chuyển thẳng `DRAFT` → `PUBLISHED`; `version_review` có `PUBLISH` (không có `SUBMIT`, `APPROVE`). EVT-07-05 phát; không phát EVT-07-04. Giao diện hiện nút "Phát hành" (không chỉ "Trình duyệt").

  @TC-07-085 @P1 @Âm
  Kịch bản: TC-07-085 Phát hành trực tiếp bị chặn khi thay đổi vượt ngưỡng
    # Truy vết: FR-07-015, 016 · BR-07-012, 026 · ERR-07-016 · AT-07-010 (SRS cũ)
    Biết danh mục `TC085_DM` 100 bản ghi, `require_approval = false`; bản nháp thêm 11 bản ghi (11%).
    Khi U-T68-DA1 gọi `:publish` trên bản nháp.
    Và mở UI-07-07.
    Thì `409` `ERR-07-016`, chi tiết có tỉ lệ 11% và ngưỡng 10%. Giao diện vô hiệu nút "Phát hành" kèm giải thích, chỉ còn "Trình duyệt".

  @TC-07-086 @P1 @Âm
  Kịch bản: TC-07-086 Phát hành trực tiếp bị chặn khi có thay đổi phá vỡ
    # Truy vết: BR-07-012, 026 · ERR-07-016
    Biết `TC085_DM` (`require_approval = false`), bản nháp chỉ ngừng dùng 1 bản ghi (1%, phá vỡ).
    Khi U-T68-DA1 gọi `:publish`.
    Và trình duyệt bằng U-T68-DS-NV, U-T68-DA1 duyệt rồi phát hành.
    Thì bước 1 trả `409` `ERR-07-016`. Bước 2 thành công qua luồng duyệt.

  @TC-07-087 @P2 @Biên
  Kịch bản: TC-07-087 Biên của ngưỡng thay đổi lớn
    # Truy vết: BR-07-012 · FR-07-053
    Biết `TC085_DM` 100 bản ghi; ngưỡng 10%.
    Khi bản nháp thêm đúng 10 bản ghi; gọi `:publish`.
    Và bản nháp khác thêm 10 và sửa tên 1 (11 thay đổi); gọi `:publish`.
    Và đổi tham số ngưỡng tenant `07.rdm.large-change-threshold-percent` = 20; lặp bước 2.
    Thì bước 1 trả `200` (bằng ngưỡng không phải vượt). Bước 2 trả `409` `ERR-07-016`. Bước 3 trả `200`. Cách tính tỉ lệ: số bản ghi thay đổi (thêm, sửa, ngừng dùng) chia số bản ghi của phiên bản hiện hành; danh mục chưa có phiên bản phát hành thì không áp ngưỡng.

  @TC-07-088 @P1 @Âm @Dương
  Kịch bản: TC-07-088 Ngày hiệu lực không hợp lệ: thiếu, sớm hơn ngày phát hành, hồi tố có lý do
    # Truy vết: FR-07-016 · BR-07-027 · ERR-07-017
    Biết đồng hồ 2026-11-21; phiên bản `APPROVED` của `TC088_DM`; phiên bản `origin = SYNC` của `GIOI_TINH` chờ áp dụng.
    Khi phát hành khi `effectiveFrom` rỗng.
    Và phát hành với `effectiveFrom` = 2026-11-20 (`origin = MANUAL`).
    Và phát hành phiên bản `origin = SYNC` với `effectiveFrom` = 2026-11-01 và `retroactiveReason` = "Quốc gia ban hành từ 01/11".
    Và lặp bước 3 nhưng thiếu `retroactiveReason`.
    Thì bước 1, 2, 4 trả `422` `ERR-07-017`. Bước 3 trả `200`, lý do hồi tố lưu trong `change_note` hoặc trường riêng và trong kiểm toán.

  @TC-07-089 @P1 @Âm
  Kịch bản: TC-07-089 Khoảng hiệu lực chồng lấn với phiên bản trước
    # Truy vết: FR-07-016 · BR-07-007 · ERR-07-017 · AT-07-008 (SRS cũ)
    Biết `TC089_DM` v1 hiệu lực từ 2026-12-15 (đã phát hành, sắp hiệu lực); v2 `APPROVED`.
    Khi phát hành v2 với `effectiveFrom` = 2026-12-15.
    Và phát hành v2 với `effectiveFrom` = 2026-12-10.
    Và phát hành v2 với `effectiveFrom` = 2026-12-16.
    Thì bước 1, 2 trả `422` `ERR-07-017` (phải lớn hơn `effective_from` của phiên bản trước). Bước 3 trả `200`; v1 có `effective_to` = 2026-12-16. Ràng buộc loại trừ `daterange` trong CSDL (nếu có) không bị vi phạm.

  @TC-07-090 @P1 @Dương
  Kịch bản: TC-07-090 Phiên bản sắp hiệu lực và tra cứu theo thời điểm
    # Truy vết: FR-07-016, 026 · BR-07-008 · ADR-051
    Biết CAT-LH v2 phát hành ở TC-07-074 với `effectiveFrom` = 2026-12-01 (đổi tên `KH01`); đồng hồ 2026-11-21.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/versions` và xem nhãn.
    Và gọi `GET /catalogs/LOAI_HINH_TC/items/KH01`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/items/KH01?at=2026-12-01`.
    Và đặt đồng hồ 2026-12-01T00:00:01+07:00 rồi gọi lại bước 2.
    Và đặt đồng hồ 2026-11-30T23:59:59+07:00 (tương đương 2026-11-30T16:59:59Z) rồi gọi lại bước 2.
    Thì bước 1: v1 "Đang hiệu lực", v2 "Sắp hiệu lực". Bước 2 trả tên cũ (v1). Bước 3 trả tên mới. Bước 4 trả tên mới. Bước 5 trả tên cũ (ngày tính theo giờ Việt Nam, không theo UTC).

  @TC-07-091 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-091 Quản trị tỉnh không được duyệt và phát hành
    # Truy vết: FR-07-015, 016 · D02-08 §3.1 · khung §14.2
    Biết phiên bản `IN_REVIEW` và một phiên bản `APPROVED`; CAT-MUC có bản nháp; người gọi U-T68-TA.
    Khi gọi `:approve` trên phiên bản `IN_REVIEW`.
    Và gọi `:publish` trên phiên bản `APPROVED`.
    Và gọi `:publish` trên bản nháp CAT-MUC (không cần duyệt).
    Và mở UI-07-07 bằng U-T68-TA.
    Thì bước 1…3 trả 403-PQ; trạng thái không đổi. Giao diện không hiện nút "Duyệt", "Phát hành" cho U-T68-TA.

  @TC-07-092 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-092 Cán bộ quản lý danh mục không tự phát hành dù danh mục không cần duyệt
    # Truy vết: FR-07-016 · BR-07-026 · D02-08 §3.1
    Biết CAT-MUC có bản nháp dưới ngưỡng; người gọi U-T68-DS-NV.
    Khi gọi `POST /catalogs/MUC_DO_DVC/versions/draft:publish`.
    Thì 403-PQ (DATA_STEWARD không có `PERM-07-publish` theo D02-08; khung §4 cũ cho phép, đã bị §14 ghi đè). Gợi ý trên giao diện: chỉ có nút "Trình duyệt".
