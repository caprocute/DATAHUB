# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-04
Tính năng: TS-07-04 · Nguồn danh mục, quyền cập nhật và mở rộng HYBRID

  @TC-07-039 @P1 @Dương
  Kịch bản: TC-07-039 Tạo danh mục HYBRID mở rộng danh mục COMMON
    # Truy vết: FR-07-008, 048 · UC-07-17 · API-07-002 · LGC-DMDC-017
    Biết `QUOC_TICH` (COMMON) ACTIVE.
    Khi gọi `POST /catalogs` thân `{"code":"TC039_QT_T68","name":"Quốc tịch mở rộng T68","sourceType":"HYBRID","extendsCatalogCode":"QUOC_TICH","localCodePattern":"^68\\.[0-9]{2}$"}`.
    Và gọi `GET /catalogs/TC039_QT_T68`.
    Thì `201`; `extendsCatalogId` trỏ đúng `QUOC_TICH` COMMON; lược đồ thuộc tính của bản nháp kế thừa từ phiên bản hiện hành của danh mục gốc (chỉ đọc), không thêm được thuộc tính bắt buộc mới. EVT-07-01 phát.

  @TC-07-040 @P1 @Dương
  Kịch bản: TC-07-040 Thêm bản ghi bổ sung trong dải mã địa phương
    # Truy vết: FR-07-008, 048 · BR-07-010 · API-07-027
    Biết CAT-DT68 có bản nháp.
    Khi gọi `POST /catalogs/DAN_TOC_T68/versions/draft/items` thân `{"code":"68.03","name":"Nhóm địa phương thử"}`.
    Thì `201`; bản ghi có `isLocalExtension = true`. KT: có.

  @TC-07-041 @P1 @Âm
  Kịch bản: TC-07-041 Thêm bản ghi HYBRID ngoài dải mã địa phương
    # Truy vết: FR-07-008 · BR-07-010 · ERR-07-012 · AT-07-007 (SRS cũ)
    Biết CAT-DT68 có bản nháp.
    Khi thêm bản ghi `code` = `69.01`.
    Và thêm bản ghi `code` = `68.1`.
    Thì cả hai trả `422`, `ERR-07-012`, chi tiết có biểu thức dải hợp lệ `^68\.[0-9]{2}$`.

  @TC-07-042 @P1 @Âm
  Kịch bản: TC-07-042 Bản ghi HYBRID trùng mã danh mục gốc
    # Truy vết: BR-07-010 · ERR-07-008
    Biết danh mục HYBRID `TC042_DT` với dải rộng `^[0-9]{2}$` (cố ý chồng lấn với mã gốc `01`…`55`).
    Khi thêm bản ghi `code` = `05`.
    Và thêm bản ghi `code` = `90`.
    Thì bước 1 trả `409`, `ERR-07-008` (trùng mã của danh mục gốc). Bước 2 trả `201`.

  @TC-07-043 @P1 @Dương
  Kịch bản: TC-07-043 Tra cứu danh mục HYBRID trả hợp bản COMMON và phần bổ sung
    # Truy vết: FR-07-048, 028, 026 · ADR-052 · API-07-041, 042
    Biết CAT-DT68 v1 đã phát hành với 2 bản ghi bổ sung; `DAN_TOC` COMMON có 55 bản ghi. Người gọi APP-T68-READ.
    Khi gọi `GET /catalogs/DAN_TOC_T68/items?limit=1000`.
    Và gọi `GET /catalogs/DAN_TOC_T68/items/05`.
    Và gọi `GET /catalogs/DAN_TOC_T68/items/68.01`.
    Và gọi `GET /catalogs/DAN_TOC/items/68.01` bằng APP-T68-READ.
    Thì bước 1 trả 57 bản ghi, phần bổ sung có `isLocalExtension = true`. Bước 2 trả bản ghi gốc. Bước 3 trả bản ghi bổ sung. Bước 4 trả `404` `ERR-07-007` (bản ghi địa phương không lẫn vào danh mục COMMON).

  @TC-07-044 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-044 Tenant sửa bản ghi gốc qua danh mục HYBRID hoặc trực tiếp danh mục COMMON
    # Truy vết: FR-07-048 · BR-07-009, 010 · ERR-07-003
    Biết CAT-DT68 có bản nháp; người gọi U-T68-TA.
    Khi gọi `PATCH /catalogs/DAN_TOC_T68/versions/draft/items/05` sửa tên.
    Và gọi `POST /catalogs/DAN_TOC/versions` (tạo bản nháp danh mục COMMON).
    Và gọi `POST /catalogs/DAN_TOC/versions/draft/items`.
    Thì cả ba trả `403`, `ERR-07-003`. Không có thay đổi trong dữ liệu COMMON (kiểm tra `updated_at` của danh mục `DAN_TOC`). EVT: không.

  @TC-07-045 @P1 @Âm
  Kịch bản: TC-07-045 Không sửa thủ công danh mục NATIONAL
    # Truy vết: FR-07-008 · BR-07-009 · ERR-07-003 · AT-07-005 (SRS cũ)
    Biết danh mục `TC045_NAT` của T68 `sourceType = NATIONAL` được tạo bởi đồng bộ.
    Khi người dùng U-T68-TA gọi `POST /catalogs/TC045_NAT/versions`.
    Và gọi `POST /import-jobs` nhập vào `TC045_NAT`.
    Và gọi `PATCH /catalogs/TC045_NAT` đổi `sourceType` thành `LOCAL`.
    Thì bước 1, 2 trả `403` `ERR-07-003`. Bước 3 trả `403` `ERR-07-003` (không đổi nguồn của danh mục đã gắn đồng bộ; muốn tách phải gỡ nguồn đồng bộ trước theo quy trình ở FRS).

  @TC-07-046 @P2 @Dương
  Kịch bản: TC-07-046 Danh mục HYBRID tự theo phiên bản mới của danh mục gốc
    # Truy vết: FR-07-048 · ADR-052 · EVT-07-05
    Biết U-PA phát hành `DAN_TOC` v mới thêm mã `56` hiệu lực 2026-11-21.
    Khi sau khi nhận sự kiện `common.rdm.catalog.published.v1`, gọi `GET /catalogs/DAN_TOC_T68/items/56` bằng APP-T68-READ.
    Và gọi `GET /catalogs/DAN_TOC_T68/items/56?at=2026-11-20`.
    Thì bước 1 trả `200` trong vòng 5 giây sau sự kiện (con trỏ hiệu lực được làm mới). Bước 2 trả `404` `ERR-07-007` (trước ngày hiệu lực).
