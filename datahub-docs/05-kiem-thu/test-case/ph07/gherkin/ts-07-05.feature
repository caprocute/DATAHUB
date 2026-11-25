# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-05
Tính năng: TS-07-05 · Bản nháp và bản ghi

  @TC-07-047 @P1 @Dương
  Kịch bản: TC-07-047 Tạo bản nháp từ phiên bản hiện hành
    # Truy vết: FR-07-011 · API-07-012 · UC-07-02 · ADR-051 · LGC-DMDC-011
    Biết CAT-LH v1 có 39 bản ghi, 5 thuộc tính.
    Khi gọi `POST /catalogs/LOAI_HINH_TC/versions` với `Idempotency-Key`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/versions/draft`.
    Và truy vấn CSDL: đếm `catalog_item` và `attribute_def` theo `version_id` của bản nháp.
    Thì `201`; bản nháp `version_no = 2`, `status = DRAFT`, `origin = MANUAL`, `effective_from` rỗng. Số bản ghi 39 và số thuộc tính 5 sao chép đầy đủ với `id` mới, cùng `code`. `catalog.current_version_id` vẫn trỏ v1. KT: có (CREATE catalog_version). EVT: không.

  @TC-07-048 @P1 @Âm
  Kịch bản: TC-07-048 Không tạo bản nháp thứ hai khi đã có phiên bản mở
    # Truy vết: FR-07-011 · BR-07-005 · ERR-07-005
    Biết lặp lại cho ba trạng thái phiên bản mở: `DRAFT`, `IN_REVIEW`, `APPROVED`.
    Khi với mỗi trạng thái, gọi `POST /catalogs/LOAI_HINH_TC/versions` với `Idempotency-Key` mới.
    Và gửi đồng thời hai yêu cầu tạo bản nháp (hai luồng) khi chưa có phiên bản mở.
    Thì bước 1 trả `409` `ERR-07-005` cả ba lần, chi tiết có `versionNo` đang mở. Bước 2: đúng một yêu cầu trả `201`, yêu cầu kia `409` `ERR-07-005` (chỉ mục duy nhất từng phần chặn tranh chấp).

  @TC-07-049 @P2 @Dương
  Kịch bản: TC-07-049 Sửa ngày hiệu lực, căn cứ pháp lý, ghi chú của bản nháp
    # Truy vết: FR-07-016 · API-07-014
    Biết bản nháp v2.
    Khi gọi `PATCH /catalogs/LOAI_HINH_TC/versions/draft` với `If-Match`, thân `{"effectiveFrom":"2026-12-01","legalBasis":"Quyết định số 99/QĐ-UBND (giả lập)","changeNote":"Bổ sung loại hình"}`.
    Thì `200`, các trường được lưu; `ETag` tăng.

  @TC-07-050 @P1 @Dương
  Kịch bản: TC-07-050 Thêm bản ghi hợp lệ vào bản nháp
    # Truy vết: FR-07-012, 013 · API-07-027 · UI-07-05
    Biết bản nháp v2.
    Khi gọi `POST .../versions/draft/items` thân `{"code":"kh01.l01.p10","name":"Phân loại thử","parentCode":"KH01.L01","sortOrder":10,"attrs":{"viet_tat":"PLT","cap_quan_ly":"TINH","ngay_thanh_lap":"2026-01-15"}}`.
    Và trên UI-07-05, thêm một bản ghi bằng biểu mẫu.
    Thì `201`; mã lưu chuẩn hóa `KH01.L01.P10`; `depth = 3`, `path = ["KH01","KH01.L01"]`, `status = ACTIVE`, `nameSearch` = "phan loai thu". `item_count` của bản nháp tăng. KT: có.

  @TC-07-051 @P1 @Âm
  Kịch bản: TC-07-051 Thêm bản ghi trùng mã khác hoa thường
    # Truy vết: FR-07-012, 013 · BR-07-002 · ERR-07-008
    Biết bản nháp có `KH01.L01.P10`.
    Khi thêm bản ghi `code` = `Kh01.l01.p10`.
    Và thêm bản ghi `code` = ` KH01.L01.P10 ` (khoảng trắng đầu cuối).
    Thì cả hai trả `409`, `ERR-07-008`.

  @TC-07-052 @P1 @Âm
  Kịch bản: TC-07-052 Giá trị thuộc tính vi phạm lược đồ
    # Truy vết: FR-07-013 · ERR-07-009
    Biết bản nháp v2.
    Khi thêm bản ghi với `attrs` đồng thời sai: `ngay_thanh_lap` = "2026-02-30", `cap_quan_ly` = "HUYEN", `viet_tat` dài 21 ký tự, `so_bien_che` = "mười", `website` = "khong-phai-uri", thêm khóa lạ `khong_khai_bao`.
    Và thêm bản ghi thiếu `name`.
    Và thêm bản ghi `code` = `KH-01/ABC` (vi phạm T-CODE).
    Thì bước 1 trả `422` `ERR-07-009` với mảng `errors` có đúng 6 phần tử (mỗi phần tử `{field, code, message}`), báo đủ lỗi một lần chứ không dừng ở lỗi đầu. Bước 2, 3 trả `422` `ERR-07-009`. Không bản ghi nào được tạo.

  @TC-07-053 @P1 @Âm
  Kịch bản: TC-07-053 Mã cha không tồn tại và vượt số cấp tối đa
    # Truy vết: FR-07-013 · BR-07-014 · ERR-07-010, ERR-07-011
    Biết CAT-LH `maxDepth = 3`.
    Khi thêm bản ghi `parentCode` = `KH99`.
    Và thêm bản ghi `parentCode` = `KH01.L01.P01` (sẽ ở cấp 4).
    Thì bước 1 trả `422` `ERR-07-010`. Bước 2 trả `422` `ERR-07-011`.

  @TC-07-054 @P1 @Âm
  Kịch bản: TC-07-054 Đổi mã cha tạo vòng
    # Truy vết: FR-07-013 · BR-07-014 · API-07-028 · ERR-07-010
    Biết `KH01` là cha của `KH01.L01`.
    Khi gọi `PATCH .../items/KH01` thân `{"parentCode":"KH01.L01"}`.
    Và gọi `PATCH .../items/KH01` thân `{"parentCode":"KH01"}` (tự làm cha mình).
    Thì cả hai trả `422` `ERR-07-010` (chi tiết "tạo vòng"). Cây không đổi.

  @TC-07-055 @P1 @Dương
  Kịch bản: TC-07-055 Ngừng dùng bản ghi kèm mã thay thế
    # Truy vết: FR-07-012, 019 · BR-07-003, 004 · API-07-029 · UI-07-05
    Biết bản nháp v2; `KH02.L03.P01` đã phát hành ở v1, không có con.
    Khi gọi `POST .../items/KH02.L03.P01:deprecate` thân `{"replacedBy":["KH02.L03.P02"],"reason":"Gộp loại hình"}`.
    Và phát hành v2 (qua luồng duyệt chuẩn TS-07-07).
    Và gọi `GET /catalogs/LOAI_HINH_TC/items/KH02.L03.P01` bằng APP-T68-READ.
    Thì bước 1 trả `200`, `status = DEPRECATED`, `replacedBy` lưu đúng. Bước 3 trả `200` kèm `status = DEPRECATED`, `replacedBy = ["KH02.L03.P02"]` (BR-07-004). Bộ phân loại khác biệt đánh dấu ngừng dùng mã là phá vỡ.

  @TC-07-056 @P2 @Âm
  Kịch bản: TC-07-056 Ngừng dùng bản ghi cha còn con hoạt động và mã thay thế không tồn tại
    # Truy vết: FR-07-019 · BR-07-014 · ERR-07-010, ERR-07-009
    Biết `KH01.L01` có 3 con ACTIVE.
    Khi gọi `POST .../items/KH01.L01:deprecate` không kèm tùy chọn ngừng dùng cả nhánh.
    Và gọi `POST .../items/KH01.L02.P01:deprecate` thân `{"replacedBy":["KHONG_CO"]}`.
    Và gọi `POST .../items/KH01.L02.P02:deprecate` thân `{"replacedBy":["KH01.L02.P02"]}` (tự thay thế).
    Thì bước 1 trả `422` `ERR-07-010` (bản ghi ACTIVE không được có cha DEPRECATED). Bước 2, 3 trả `422` `ERR-07-009` (trường `replacedBy`).

  @TC-07-057 @P3 @Dương
  Kịch bản: TC-07-057 Khôi phục bản ghi đã ngừng dùng trong bản nháp mới
    # Truy vết: FR-07-012 · API-07-028
    Biết v2 đã phát hành với `KH02.L03.P01` DEPRECATED; tạo bản nháp v3.
    Khi gọi `PATCH .../versions/draft/items/KH02.L03.P01` thân `{"status":"ACTIVE","replacedBy":[]}`.
    Và gọi `GET .../versions/draft/diff?against=current`.
    Thì `200`; bản ghi ACTIVE trong v3; diff ghi `CHANGED` (trạng thái), không phá vỡ.

  @TC-07-058 @P1 @Âm
  Kịch bản: TC-07-058 Không xóa bản ghi đã từng phát hành
    # Truy vết: FR-07-012 · BR-07-003 · API-07-030 · ERR-07-013 · AT-07-004 (SRS cũ)
    Biết bản nháp v2; `KH01` đã phát hành ở v1.
    Khi gọi `DELETE .../versions/draft/items/KH01`.
    Thì `409`, `ERR-07-013`, chi tiết gợi ý dùng ngừng dùng. Bản ghi giữ nguyên.

  @TC-07-059 @P2 @Dương
  Kịch bản: TC-07-059 Xóa bản ghi mới thêm trong bản nháp
    # Truy vết: FR-07-012 · API-07-030
    Biết `KH01.L01.P10` vừa thêm ở TC-07-050 (chưa từng phát hành).
    Khi gọi `DELETE .../versions/draft/items/KH01.L01.P10`.
    Thì `204`; bản ghi bị xóa vật lý khỏi bản nháp; diff không còn mục `ADDED` tương ứng. KT: có.

  @TC-07-060 @P1 @Dương
  Kịch bản: TC-07-060 Sửa bản ghi bằng If-Match
    # Truy vết: FR-07-012 · API-07-028 · UI-07-05 · LGC-DMDC-011
    Biết bản nháp v2; bản ghi `KH01.L02` có `ETag` `"3"`.
    Khi gọi `PATCH .../items/KH01.L02` với `If-Match: "3"`, thân `{"name":"Loại 2 (sửa)","attrs":{"viet_tat":"L2S"}}`.
    Và trên UI-07-05, sửa trực tiếp ô tên trong bảng và nhấn Enter.
    Thì `200`, `ETag` mới; chỉ khóa `viet_tat` trong `attrs` thay đổi (cập nhật kiểu hợp nhất JSON Merge Patch), các khóa khác giữ nguyên.

  @TC-07-061 @P2 @Dương
  Kịch bản: TC-07-061 Kiểm tra hợp lệ toàn bản nháp không có lỗi
    # Truy vết: FR-07-013 · API-07-016
    Biết bản nháp v2 hợp lệ.
    Khi gọi `POST .../versions/draft:validate`.
    Thì `200`, `{"valid":true,"errorCount":0,"stats":{...}}` với `stats` gồm số thêm, sửa, ngừng dùng, phá vỡ.

  @TC-07-062 @P2 @Âm
  Kịch bản: TC-07-062 Kiểm tra hợp lệ toàn bản nháp phát hiện lỗi tích lũy
    # Truy vết: FR-07-013 · BR-07-014 · API-07-016
    Biết chèn trực tiếp vào CSDL (bằng vai trò kiểm thử) hai bản ghi vi phạm mà API đơn lẻ không bắt được do đổi lược đồ sau: một bản ghi `cap_quan_ly` ngoài miền mới, một bản ghi ACTIVE có cha DEPRECATED.
    Khi gọi `POST .../versions/draft:validate`.
    Và gọi `POST .../versions/draft:submit`.
    Thì bước 1 trả `200` với `valid = false`, `errors` liệt kê đủ 2 lỗi theo mã bản ghi. Bước 2 trả `422` `ERR-07-009` (không trình được bản nháp không hợp lệ).

  @TC-07-063 @P1 @Dương
  Kịch bản: TC-07-063 Hiển thị bản ghi dạng bảng và dạng cây
    # Truy vết: FR-07-018 · UI-07-02, 05 · API-07-026, 044 · LGC-DMDC-002
    Biết CAT-LH v1; người dùng U-T68-VW.
    Khi mở UI-07-02 tab Bản ghi, chế độ Bảng; đổi trang, sắp xếp theo tên, tìm "phan loai".
    Và chuyển chế độ Cây; mở rộng `KH01`, `KH01.L01`.
    Và dùng bàn phím mũi tên phải, trái để mở, thu nút cây.
    Thì bảng phân trang phía máy chủ 20 dòng mặc định (FR-00-021), sắp xếp đúng, tìm không dấu đúng. Cây tải theo nhánh khi mở (không tải toàn bộ), hiển thị tên cấp, số con. Điều hướng bàn phím theo mẫu WAI-ARIA tree.

  @TC-07-064 @P1 @Dương
  Kịch bản: TC-07-064 Hủy bản nháp
    # Truy vết: FR-07-017 · API-07-015 · EN-07-07
    Biết bản nháp v2 có thay đổi.
    Khi gọi `DELETE /catalogs/LOAI_HINH_TC/versions/draft` với `If-Match`, thân `{"reason":"Làm lại"}`.
    Và gọi `POST /catalogs/LOAI_HINH_TC/versions`.
    Thì bước 1 trả `204`; phiên bản chuyển `DISCARDED`, có dòng `version_review` hành động `DISCARD`. Bước 2 trả `201` với `version_no = 3` (không tái sử dụng số 2). KT: có.

  @TC-07-065 @P2 @Âm
  Kịch bản: TC-07-065 Không hủy phiên bản đang duyệt, đã duyệt hoặc đã phát hành
    # Truy vết: FR-07-017 · ERR-07-004
    Biết ba phiên bản ở `IN_REVIEW`, `APPROVED`, `PUBLISHED` (trên ba danh mục thử).
    Khi gọi `DELETE /catalogs/{c}/versions/{v}` cho từng phiên bản.
    Thì cả ba trả `409` `ERR-07-004`.

  @TC-07-066 @P1 @Dương
  Kịch bản: TC-07-066 Thay đổi trên bản nháp không ảnh hưởng tra cứu phiên bản hiện hành
    # Truy vết: FR-07-011 · BR-07-006 · ADR-051
    Biết bản nháp v2 đã đổi tên `KH01` và ngừng dùng `KH02.L03.P01`.
    Khi APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/items/KH01` và `.../KH02.L03.P01`.
    Và gọi `GET /catalogs/LOAI_HINH_TC/items` với `If-None-Match` bằng ETag lấy trước khi sửa nháp.
    Thì bước 1 trả dữ liệu của v1 (tên cũ, ACTIVE). Bước 2 trả `304`.
