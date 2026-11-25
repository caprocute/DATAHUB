# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-03
Tính năng: TS-07-03 · Lược đồ thuộc tính động và phân cấp

  @TC-07-024 @P1 @Dương
  Kịch bản: TC-07-024 Thêm thuộc tính với đủ các kiểu dữ liệu và ràng buộc
    # Truy vết: FR-07-005 · API-07-023, 022 · UI-07-04 · LGC-DMDC-004
    Biết bản nháp v2 của CAT-LH.
    Khi lần lượt gọi `POST /catalogs/LOAI_HINH_TC/versions/draft/attributes` cho 11 thuộc tính, mỗi kiểu một thuộc tính: `STRING` (`maxLength` 50, `pattern` `^[A-Z]+$`), `TEXT`, `INTEGER` (`minValue` 0, `maxValue` 1000), `DECIMAL`, `BOOLEAN`, `DATE`, `DATETIME`, `ENUM` (`enumValues` `["A","B"]`), `CATALOG_REF` (`refCatalogCode` `DAN_TOC`), `URI`, `EMAIL`; tất cả không bắt buộc.
    Và gọi `GET .../versions/draft/attributes`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/schema?version=draft`.
    Thì mỗi lệnh trả `201`. Bước 2 liệt kê 16 thuộc tính (5 cũ, 11 mới) theo `sortOrder`. Bước 3 trả JSON Schema (draft 2020-12) có `properties.attrs.properties` đủ 16 khóa, kiểu ánh xạ đúng (`DATE` thành `string` + `format: date`, `ENUM` thành `enum`, `CATALOG_REF` thành `string` kèm `x-ref-catalog`). Phiên bản v1 đã phát hành vẫn chỉ có 5 thuộc tính. KT: có (CREATE attribute_def × 11).

  @TC-07-025 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-025 Chặn thuộc tính mức Nhạy cảm và tên gợi ý dữ liệu cá nhân
    # Truy vết: FR-07-005 · BR-07-025 · ERR-07-036
    Biết bản nháp v2.
    Khi gọi thêm thuộc tính với `{"code":"so_dinh_danh","label":"Số định danh cá nhân","dataType":"STRING"}`.
    Và gọi thêm thuộc tính `{"code":"ghi_chu","dataType":"TEXT","dataClass":"NHAY_CAM"}` (khai báo mức Nhạy cảm).
    Và gọi thêm thuộc tính `{"code":"ngay_sinh_nguoi_dai_dien","label":"Ngày sinh","dataType":"DATE"}`.
    Thì cả ba trả `422`, `ERR-07-036`, chi tiết nêu lý do (tên khớp danh sách từ khóa dữ liệu cá nhân hoặc mức phân loại bị cấm). Không thuộc tính nào được tạo.

  @TC-07-026 @P2 @Âm
  Kịch bản: TC-07-026 Thuộc tính CATALOG_REF trỏ danh mục không tồn tại và ràng buộc mâu thuẫn
    # Truy vết: FR-07-005 · ERR-07-009
    Biết bản nháp v2.
    Khi thêm thuộc tính `CATALOG_REF` với `refCatalogCode` = `KHONG_CO`.
    Và thêm thuộc tính `INTEGER` với `minValue` 10, `maxValue` 5.
    Và thêm thuộc tính `ENUM` với `enumValues` rỗng.
    Và thêm thuộc tính có `code` = `ma` (trùng cột cố định `MA` của khuôn tệp).
    Thì mỗi lệnh trả `422`, `ERR-07-009` với mảng `errors` nêu trường sai (`refCatalogCode`, `minValue`, `enumValues`, `code`).

  @TC-07-027 @P1 @Âm
  Kịch bản: TC-07-027 Không sửa lược đồ của phiên bản đã phát hành
    # Truy vết: FR-07-005, 006 · BR-07-006 · ERR-07-004
    Biết v1 của CAT-LH `PUBLISHED`.
    Khi gọi `POST /catalogs/LOAI_HINH_TC/versions/1/attributes`.
    Và gọi `PATCH /catalogs/LOAI_HINH_TC/versions/1/attributes/viet_tat`.
    Và gọi `DELETE /catalogs/LOAI_HINH_TC/versions/1/attributes/viet_tat`.
    Thì cả ba trả `409`, `ERR-07-004`. `schema_hash` của v1 không đổi.

  @TC-07-028 @P1 @Dương
  Kịch bản: TC-07-028 Sửa nhãn, sắp lại thứ tự và ẩn thuộc tính
    # Truy vết: FR-07-006 · API-07-024 · UI-07-04 · LGC-DMDC-010, 018
    Biết bản nháp v2.
    Khi gọi `PATCH .../attributes/viet_tat` thân `{"label":"Tên viết tắt","sortOrder":1}`.
    Và gọi `PATCH .../attributes/website` thân `{"status":"HIDDEN"}`.
    Và trên UI-07-04 kéo thả thuộc tính `cap_quan_ly` lên đầu danh sách và lưu.
    Và gọi `GET /catalogs/LOAI_HINH_TC/import-template?format=xlsx` (theo bản nháp).
    Thì các lệnh trả `200`. Thứ tự mới được lưu. Thuộc tính `website` HIDDEN không hiện trong tệp mẫu và không trả trong API khai thác sau khi phát hành, nhưng giá trị cũ vẫn được giữ trong `attrs`. Bộ phân loại khác biệt coi đổi nhãn, thứ tự, ẩn là thay đổi không phá vỡ.

  @TC-07-029 @P1 @Dương
  Kịch bản: TC-07-029 Đổi kiểu thuộc tính khi mọi giá trị chuyển đổi được
    # Truy vết: FR-07-006 · BR-07-013 · API-07-024
    Biết thuộc tính `ma_so` STRING có giá trị "001", "25", "300" trên 3 bản ghi của bản nháp.
    Khi gọi `PATCH .../attributes/ma_so` thân `{"dataType":"INTEGER"}`.
    Và gọi `GET .../versions/draft/diff?against=current`.
    Thì bước 1 trả `200`; giá trị trong `attrs` được chuyển thành số 1, 25, 300. Bước 2 có mục `ATTRIBUTE_TYPE_CHANGED` đánh dấu `breaking = true` (đổi kiểu là phá vỡ theo khung §3.18).

  @TC-07-030 @P1 @Âm
  Kịch bản: TC-07-030 Đổi kiểu thuộc tính khi có giá trị không chuyển được
    # Truy vết: FR-07-006 · BR-07-013 · ERR-07-014
    Biết `viet_tat` STRING có giá trị "UBND", "SNV".
    Khi gọi `PATCH .../attributes/viet_tat` thân `{"dataType":"INTEGER"}`.
    Và gọi `PATCH .../attributes/ngay_thanh_lap` thân `{"dataType":"BOOLEAN"}`.
    Thì cả hai trả `422`, `ERR-07-014`, chi tiết liệt kê tối đa 20 mã bản ghi có giá trị không chuyển được và tổng số. Lược đồ không đổi.

  @TC-07-031 @P1 @Âm @Biên
  Kịch bản: TC-07-031 Thu hẹp ràng buộc độ dài và miền giá trị
    # Truy vết: FR-07-006 · BR-07-013 · ERR-07-014
    Biết `viet_tat` `maxLength` 20, giá trị dài nhất 12 ký tự; `cap_quan_ly` ENUM {`TINH`,`XA`} có cả hai giá trị được dùng.
    Khi gọi đổi `maxLength` thành 12.
    Và gọi đổi `maxLength` thành 11.
    Và gọi đổi `enumValues` thành `["TINH"]`.
    Thì bước 1 trả `200` và diff đánh dấu thay đổi phá vỡ (thu hẹp ràng buộc). Bước 2 trả `422` `ERR-07-014` (giá trị 12 ký tự vi phạm). Bước 3 trả `422` `ERR-07-014`.

  @TC-07-032 @P2 @Dương
  Kịch bản: TC-07-032 Xóa thuộc tính trong bản nháp
    # Truy vết: FR-07-006 · BR-07-013 · API-07-025
    Biết bản nháp v2 có `so_bien_che` với giá trị trên 39 bản ghi.
    Khi gọi `DELETE .../versions/draft/attributes/so_bien_che`.
    Và gọi `GET .../versions/draft/diff?against=current`.
    Thì bước 1 trả `204`; khóa `so_bien_che` bị gỡ khỏi `attrs` của bản ghi trong bản nháp (v1 giữ nguyên). Bước 2 có `ATTRIBUTE_REMOVED` với `breaking = true`; vì có thay đổi phá vỡ, phiên bản phải qua duyệt (BR-07-012).

  @TC-07-033 @P2 @Âm
  Kịch bản: TC-07-033 Thêm thuộc tính bắt buộc không có giá trị mặc định khi đã có bản ghi
    # Truy vết: FR-07-005 · BR-07-013 · ERR-07-014
    Biết bản nháp v2 có 39 bản ghi.
    Khi thêm thuộc tính `ma_qhns` STRING `required = true`, không `defaultValue`.
    Và thêm lại với `defaultValue` = "CHUA_CO".
    Thì bước 1 trả `422` `ERR-07-014`. Bước 2 trả `201`, 39 bản ghi nhận giá trị mặc định.

  @TC-07-034 @P2 @Âm
  Kịch bản: TC-07-034 Bật ràng buộc duy nhất khi dữ liệu đang trùng
    # Truy vết: FR-07-006 · BR-07-013 · ERR-07-014
    Biết hai bản ghi có `viet_tat` = "SNV".
    Khi gọi `PATCH .../attributes/viet_tat` thân `{"uniqueInVersion":true}`.
    Thì `422`, `ERR-07-014`, chi tiết nêu giá trị trùng "SNV" và hai mã bản ghi.

  @TC-07-035 @P1 @Dương
  Kịch bản: TC-07-035 Cấu hình phân cấp: bật cây, số cấp, tên cấp
    # Truy vết: FR-07-007 · BR-07-014 · API-07-002, 004 · UI-07-03 · LGC-DMDC-002
    Biết danh mục mới `TC035_CAY` phẳng, DRAFT.
    Khi gọi `PATCH /catalogs/TC035_CAY` thân `{"isHierarchical":true,"maxDepth":4,"levelNames":["Cấp 1","Cấp 2","Cấp 3","Cấp 4"]}`.
    Và thêm 4 bản ghi lồng nhau `A`, `A.1` (cha `A`), `A.1.1`, `A.1.1.1`.
    Và mở tab Bản ghi dạng cây trên UI-07-02.
    Thì bước 1 trả `200`. Bước 2 thành công, `depth` lần lượt 1…4, `levelName` đúng tên cấp, `path` đúng chuỗi tổ tiên. Cây hiển thị 4 cấp.

  @TC-07-036 @P2 @Âm @Biên
  Kịch bản: TC-07-036 Số cấp tối đa vượt giới hạn 10
    # Truy vết: FR-07-007 · BR-07-014
    Biết `TC035_CAY`.
    Khi đặt `maxDepth` = 10 với 10 tên cấp.
    Và đặt `maxDepth` = 11.
    Và đặt `maxDepth` = 3 nhưng `levelNames` có 2 phần tử.
    Thì bước 1 trả `200`. Bước 2 và 3 trả `422` lỗi kiểm tra hợp lệ (trường `maxDepth`, `levelNames`).

  @TC-07-037 @P2 @Âm
  Kịch bản: TC-07-037 Giảm số cấp dưới độ sâu dữ liệu hiện có
    # Truy vết: FR-07-007 · BR-07-014 · ERR-07-011
    Biết `TC035_CAY` có bản ghi độ sâu 4.
    Khi gọi `PATCH /catalogs/TC035_CAY` thân `{"maxDepth":3,"levelNames":["Cấp 1","Cấp 2","Cấp 3"]}`.
    Thì `422`, `ERR-07-011`, chi tiết nêu mã `A.1.1.1` vượt cấp.

  @TC-07-038 @P2 @Dương @Âm
  Kịch bản: TC-07-038 JSON Schema sinh từ định nghĩa kiểm tra đúng bản ghi
    # Truy vết: FR-07-005, 013, 033 · ADR-050
    Biết bộ sinh định nghĩa thuộc tính ngẫu nhiên (jqwik) gồm mọi kiểu và ràng buộc.
    Khi với mỗi định nghĩa ngẫu nhiên, sinh JSON Schema; sinh 100 giá trị hợp lệ và 100 giá trị vi phạm từng ràng buộc.
    Và kiểm tra bằng bộ kiểm tra JSON Schema (networknt) và bằng bộ kiểm tra nghiệp vụ của PH-07.
    Thì giá trị hợp lệ được chấp nhận, giá trị vi phạm bị từ chối; hai bộ kiểm tra cho kết quả giống nhau 100%.
