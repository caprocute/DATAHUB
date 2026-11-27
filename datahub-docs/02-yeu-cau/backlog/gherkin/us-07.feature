# language: vi
# Sinh tự động từ D02-02/D02-03-PH07 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-07
Tính năng: PH-07 · Danh mục dùng chung

  # ---- EP-07-A · Danh mục và lược đồ

  @US-07-001 @FR-07-001 @M
  Kịch bản: US-07-001 dương · Liệt kê danh mục, đếm số lượng, lọc theo nhóm, nguồn, trạng thái, phân loại
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi người dùng mở mục "Danh mục dùng chung" trên menu (UI-07-01), gõ từ khóa hoặc chọn bộ lọc; HTTT gọi API-07-001
    Thì trang kết quả gồm `items[]` (mã, tên, nhóm, nguồn, phân loại, trạng thái, cơ quan chủ quản, số phiên bản hiện hành, ngày hiệu lực hiện hành, số bản ghi hiện hành, có phiên bản mở hay không, tenant sở hữu `COMMON` hay tenant hiện hành) …

  @US-07-001 @FR-07-001 @M @âm
  Kịch bản: US-07-001 âm 1 · Tham số sai kiểu hoặc ngoài miền
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi tham số sai kiểu hoặc ngoài miền
    Thì HTTP 400; trả `errors` theo tham số

  @US-07-001 @FR-07-001 @M @âm
  Kịch bản: US-07-001 âm 2 · `size` > 200
    Biết người dùng đã đăng nhập và chọn tenant làm việc (FR-00-004)
    Khi `size` > 200
    Thì hệ thống từ chối với ERR-07-026 (400)
    Và người dùng thấy thông báo "Số lượng vượt mức tối đa cho một lần ({max}). Chia nhỏ danh sách rồi thực hiện lại."

  @US-07-002 @FR-07-002 @M
  Kịch bản: US-07-002 dương · Xem chi tiết danh mục: thông tin, thuộc tính, phiên bản, bản ghi
    Biết danh mục tồn tại, chưa bị xóa mềm, thuộc tenant hiện hành hoặc `COMMON`
    Khi người dùng bấm vào tên một danh mục ở UI-07-01, mở đường dẫn trực tiếp tới UI-07-02, hoặc chọn phiên bản khác ở bộ chọn phiên bản
    Thì khối thông tin danh mục (mọi trường của EN-07-02 trừ `legacy_ref` chỉ hiện cho PA), danh sách phiên bản (số, trạng thái, nhãn hiệu lực tính toán, ngày hiệu lực, số bản ghi, thống kê thay đổi, người phát hành) …

  @US-07-002 @FR-07-002 @M @âm
  Kịch bản: US-07-002 âm 1 · Không tìm thấy danh mục hoặc không đủ quyền xem bản nháp
    Biết danh mục tồn tại, chưa bị xóa mềm, thuộc tenant hiện hành hoặc `COMMON`
    Khi không tìm thấy danh mục hoặc không đủ quyền xem bản nháp
    Thì hệ thống từ chối với ERR-07-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-002 @FR-07-002 @M @âm
  Kịch bản: US-07-002 âm 2 · Không tìm thấy phiên bản yêu cầu
    Biết danh mục tồn tại, chưa bị xóa mềm, thuộc tenant hiện hành hoặc `COMMON`
    Khi không tìm thấy phiên bản yêu cầu
    Thì hệ thống từ chối với ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-003 @FR-07-003 @M
  Kịch bản: US-07-003 dương · Tạo danh mục thủ công
    Biết tenant hiện hành ở trạng thái hoạt động; nếu tạo danh mục `COMMON` thì tenant hiện hành là `PLATFORM`
    Khi người dùng bấm "+ Tạo danh mục" ở UI-07-01, điền ba bước của trình hướng dẫn UI-07-03 rồi bấm "Tạo danh mục"
    Thì hệ thống trả `201 Created`, tiêu đề `Location: /api/rdm/v1/catalogs/{code}`, thân là chi tiết danh mục (như FR-07-002) kèm `draftVersionNo = 1`; ETag
    Và một bản ghi `catalog` trạng thái `DRAFT`; một `catalog_version` số 1 trạng thái `DRAFT`, `origin = MANUAL`, `item_count = 0`; các `attribute_def` của phiên bản 1 nếu có khai báo; `current_version_id` rỗng
    Và sự kiện được phát: EVT-07-01 `{tenant}.rdm.catalog.created.v1` với `catalogCode`, `name`, `sourceType`, `classification`, `ownerOrgId`

  @US-07-003 @FR-07-003 @M @âm
  Kịch bản: US-07-003 âm 1 · Mã danh mục trùng
    Biết tenant hiện hành ở trạng thái hoạt động; nếu tạo danh mục `COMMON` thì tenant hiện hành là `PLATFORM`
    Khi mã danh mục trùng
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "Mã danh mục"

  @US-07-003 @FR-07-003 @M @âm
  Kịch bản: US-07-003 âm 2 · Tenant không phải `PLATFORM` mà yêu cầu tạo danh mục `COMMON`, hoặc `sourceType = NATIONAL`
    Biết tenant hiện hành ở trạng thái hoạt động; nếu tạo danh mục `COMMON` thì tenant hiện hành là `PLATFORM`
    Khi tenant không phải `PLATFORM` mà yêu cầu tạo danh mục `COMMON`, hoặc `sourceType = NATIONAL`
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-004 @FR-07-004 @M
  Kịch bản: US-07-004 dương · Cập nhật thông tin danh mục
    Biết danh mục tồn tại, không `RETIRED`, không `NATIONAL` (riêng danh mục `NATIONAL` chỉ cho sửa `groupId`, `description`, `classification` vì đây là thông tin quản lý tại chỗ, không phải nội dung quốc gia)
    Khi người dùng bấm "Sửa thông tin" ở đầu trang UI-07-02; UI-07-03 mở ở chế độ sửa
    Thì hệ thống trả `200` với chi tiết danh mục mới và ETag mới
    Và các trường được gửi được cập nhật; `version` của danh mục tăng 1; nếu đổi `name` thì tên mới hiển thị ở mọi phiên bản (tên danh mục không thuộc phiên bản)
    Và sự kiện được phát: EVT-07-02 `{tenant}.rdm.catalog.updated.v1` với `catalogCode` và danh sách trường đã đổi

  @US-07-004 @FR-07-004 @M @âm
  Kịch bản: US-07-004 âm 1 · ETag không khớp
    Biết danh mục tồn tại, không `RETIRED`, không `NATIONAL` (riêng danh mục `NATIONAL` chỉ cho sửa `groupId`, `description`, `classification` vì đây là thông tin quản lý tại chỗ, không phải nội dung quốc gia)
    Khi ETag không khớp
    Thì hệ thống từ chối với ERR-07-018 (412)
    Và người dùng thấy thông báo "Dữ liệu đã được người khác cập nhật trong lúc bạn đang sửa. Xem khác biệt rồi chọn"

  @US-07-004 @FR-07-004 @M @âm
  Kịch bản: US-07-004 âm 2 · Danh mục `RETIRED`
    Biết danh mục tồn tại, không `RETIRED`, không `NATIONAL` (riêng danh mục `NATIONAL` chỉ cho sửa `groupId`, `description`, `classification` vì đây là thông tin quản lý tại chỗ, không phải nội dung quốc gia)
    Khi danh mục `RETIRED`
    Thì hệ thống từ chối với ERR-07-031 (410)
    Và người dùng thấy thông báo "Danh mục đã ngừng hiệu lực. Danh mục chỉ còn xem được lịch sử; không tạo phiên bản mới."

  @US-07-005 @FR-07-005 @M
  Kịch bản: US-07-005 dương · Khai báo thuộc tính động có kiểu và ràng buộc
    Biết danh mục có phiên bản `DRAFT` (`{v}` là `draft` hoặc số của bản nháp); danh mục không `NATIONAL`; số thuộc tính hiện có < 100
    Khi người dùng bấm "+ Thêm thuộc tính" ở UI-07-04 trên bản nháp, hoặc khai báo thuộc tính ở bước 3 của trình hướng dẫn tạo danh mục
    Thì hệ thống trả `201` với định nghĩa thuộc tính đã tạo; ETag mới của phiên bản
    Và một `attribute_def` mới gắn với bản nháp; `schema_hash` của bản nháp được tính lại; nếu có `default_value` thì mọi bản ghi `ACTIVE` hiện có trong bản nháp được điền giá trị mặc định; `version` của phiên bản tăng 1

  @US-07-005 @FR-07-005 @M @âm
  Kịch bản: US-07-005 âm 1 · Phiên bản không phải `DRAFT`
    Biết danh mục có phiên bản `DRAFT` (`{v}` là `draft` hoặc số của bản nháp); danh mục không `NATIONAL`; số thuộc tính hiện có < 100
    Khi phiên bản không phải `DRAFT`
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-005 @FR-07-005 @M @âm
  Kịch bản: US-07-005 âm 2 · Danh mục `NATIONAL` hoặc `COMMON` với tenant tỉnh
    Biết danh mục có phiên bản `DRAFT` (`{v}` là `draft` hoặc số của bản nháp); danh mục không `NATIONAL`; số thuộc tính hiện có < 100
    Khi danh mục `NATIONAL` hoặc `COMMON` với tenant tỉnh
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-006 @FR-07-006 @M
  Kịch bản: US-07-006 dương · Sửa, ẩn, xóa, sắp thứ tự thuộc tính trong bản nháp có kiểm tra tương thích
    Biết bản nháp `DRAFT`; thuộc tính tồn tại trong bản nháp; với HYBRID chỉ sửa được thuộc tính không kế thừa
    Khi người dùng sửa, ẩn, xóa hoặc kéo thả sắp thứ tự một thuộc tính ở UI-07-04 rồi bấm "Lưu"
    Thì hệ thống trả `200` (sửa, sắp thứ tự) hoặc `204` (xóa); phản hồi kèm `compatibility`: `{breaking: bool, reasons: [..], affectedItems: n}`
    Và định nghĩa thuộc tính được cập nhật hoặc xóa khỏi bản nháp; giá trị trong `attrs` của bản ghi bản nháp được chuyển đổi (đổi kiểu) hoặc xóa khóa (xóa thuộc tính); `schema_hash` tính lại; `stats.breaking` của bản nháp được cập nhật

  @US-07-006 @FR-07-006 @M @âm
  Kịch bản: US-07-006 âm 1 · Không thấy thuộc tính
    Biết bản nháp `DRAFT`; thuộc tính tồn tại trong bản nháp; với HYBRID chỉ sửa được thuộc tính không kế thừa
    Khi không thấy thuộc tính
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-006 @FR-07-006 @M @âm
  Kịch bản: US-07-006 âm 2 · Phiên bản không `DRAFT`
    Biết bản nháp `DRAFT`; thuộc tính tồn tại trong bản nháp; với HYBRID chỉ sửa được thuộc tính không kế thừa
    Khi phiên bản không `DRAFT`
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-007 @FR-07-007 @M
  Kịch bản: US-07-007 dương · Cấu hình phân cấp
    Biết danh mục có bản nháp `DRAFT`; danh mục không `NATIONAL`, không HYBRID (HYBRID kế thừa cấu hình phân cấp của danh mục gốc)
    Khi người dùng bật "Danh mục phân cấp" ở bước 2 của UI-07-03 hoặc ở UI-07-04 trên bản nháp, khai số cấp và tên cấp
    Thì hệ thống trả `200` với cấu hình mới và kết quả kiểm tra cây
    Và cấu hình phân cấp được ghi vào bản nháp (trường `stats.hierarchy` của phiên bản) và đồng bộ lên `catalog` khi phát hành; `depth`, `path`, `level_name` của bản ghi bản nháp được tính lại

  @US-07-007 @FR-07-007 @M @âm
  Kịch bản: US-07-007 âm 1 · Còn bản ghi có mã cha khi tắt phân cấp, mã cha không tồn tại, có vòng
    Biết danh mục có bản nháp `DRAFT`; danh mục không `NATIONAL`, không HYBRID (HYBRID kế thừa cấu hình phân cấp của danh mục gốc)
    Khi còn bản ghi có mã cha khi tắt phân cấp, mã cha không tồn tại, có vòng
    Thì hệ thống từ chối với ERR-07-010 (422)
    Và người dùng thấy thông báo "Mã cha"

  @US-07-007 @FR-07-007 @M @âm
  Kịch bản: US-07-007 âm 2 · Độ sâu thực tế vượt `maxDepth` mới
    Biết danh mục có bản nháp `DRAFT`; danh mục không `NATIONAL`, không HYBRID (HYBRID kế thừa cấu hình phân cấp của danh mục gốc)
    Khi độ sâu thực tế vượt `maxDepth` mới
    Thì hệ thống từ chối với ERR-07-011 (422)
    Và người dùng thấy thông báo "Bản ghi vượt quá số cấp tối đa ({maxDepth} cấp). Chọn mã cha ở cấp cao hơn, hoặc tăng số cấp tối đa ở thông tin danh mục."

  @US-07-008 @FR-07-008 @M
  Kịch bản: US-07-008 dương · Thiết lập nguồn và quyền cập nhật
    Biết danh mục tồn tại, không `RETIRED`, không có phiên bản `IN_REVIEW` hoặc `APPROVED`
    Khi người dùng chọn nguồn và HTTT được cập nhật ở bước 2 của UI-07-03 (khi tạo) hoặc ở chế độ sửa thông tin (TA, PA)
    Thì hệ thống trả `200` với thông tin danh mục mới
    Và `source_type`, `local_code_pattern`, `extends_catalog_id` được cập nhật theo bảng chuyển nguồn dưới đây
    Và sự kiện được phát: EVT-07-02 với trường `sourceType` trong danh sách trường đã đổi

  @US-07-008 @FR-07-008 @M @âm
  Kịch bản: US-07-008 âm 1 · Chuyển nguồn không được phép, hoặc có phiên bản đang chờ duyệt
    Biết danh mục tồn tại, không `RETIRED`, không có phiên bản `IN_REVIEW` hoặc `APPROVED`
    Khi chuyển nguồn không được phép, hoặc có phiên bản đang chờ duyệt
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-008 @FR-07-008 @M @âm
  Kịch bản: US-07-008 âm 2 · Bản ghi bổ sung không khớp dải mới hoặc dải chồng mã gốc
    Biết danh mục tồn tại, không `RETIRED`, không có phiên bản `IN_REVIEW` hoặc `APPROVED`
    Khi bản ghi bổ sung không khớp dải mới hoặc dải chồng mã gốc
    Thì hệ thống từ chối với ERR-07-012 (422)
    Và người dùng thấy thông báo "{itemCode}"

  @US-07-009 @FR-07-009 @M
  Kịch bản: US-07-009 dương · Xóa danh mục chưa phát hành; ngừng hiệu lực danh mục đã phát hành
    Biết xóa: `catalog.status = DRAFT`
    Khi người dùng bấm "Xóa danh mục" (danh mục chưa từng phát hành) hoặc "Ngừng hiệu lực" (đã phát hành) trong menu "Thêm" ở UI-07-02 và xác nhận ở hộp thoại
    Thì xóa: `204`
    Và xóa: `deleted_at` được gán, phiên bản nháp chuyển `DISCARDED`, tác vụ nhập đang mở bị hủy; dữ liệu giữ 30 ngày rồi xóa vật lý (FR-00-051)
    Và sự kiện được phát: Ngừng hiệu lực: EVT-07-03 `{tenant}.rdm.catalog.retired.v1` với `catalogCode`, `retireDate`, `reason`, `replacementCatalogCode`

  @US-07-009 @FR-07-009 @M @âm
  Kịch bản: US-07-009 âm 1 · Xóa danh mục đã phát hành
    Biết xóa: `catalog.status = DRAFT`
    Khi xóa danh mục đã phát hành
    Thì hệ thống từ chối với ERR-07-048 (409)

  @US-07-009 @FR-07-009 @M @âm
  Kịch bản: US-07-009 âm 2 · Ngừng hiệu lực danh mục chưa từng phát hành (`DRAFT`)
    Biết xóa: `catalog.status = DRAFT`
    Khi ngừng hiệu lực danh mục chưa từng phát hành (`DRAFT`)
    Thì hệ thống từ chối với ERR-07-048 (409)

  @US-07-010 @FR-07-010 @S
  Kịch bản: US-07-010 dương · Quản lý nhóm danh mục
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi TA bấm "Quản lý nhóm" ở cây nhóm của UI-07-01, thêm, đổi tên, chuyển hoặc xóa nhóm
    Thì API-07-007 trả cây nhóm (tenant và `COMMON`) kèm số danh mục mỗi nhóm; API-07-008, 009 trả nhóm; API-07-010 trả `204`
    Và `catalog_group` được tạo, sửa hoặc xóa mềm

  @US-07-010 @FR-07-010 @S @âm
  Kịch bản: US-07-010 âm 1 · Mã nhóm trùng, nhóm cha tạo vòng hoặc vượt độ sâu
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mã nhóm trùng, nhóm cha tạo vòng hoặc vượt độ sâu
    Thì hệ thống từ chối với ERR-07-039 (409)

  # ---- EP-07-B · Bản ghi và phiên bản

  @US-07-011 @FR-07-011 @M
  Kịch bản: US-07-011 dương · Tạo bản nháp phiên bản mới từ phiên bản hiện hành
    Biết danh mục `ACTIVE`; không `NATIONAL` (trừ tiến trình đồng bộ); không có phiên bản mở (BR-07-005)
    Khi người dùng bấm "Tạo phiên bản mới" ở UI-07-02; hoặc tiến trình đồng bộ, nhập lô qua API tự mở bản nháp
    Thì hệ thống trả `201` với chi tiết phiên bản nháp: `versionNo` mới, `baseVersionNo`, `status = DRAFT`, `itemCount`, ETag
    Và một `catalog_version` mới `DRAFT` với `version_no = max + 1`, `origin` theo nguồn tạo; mọi `attribute_def` và `catalog_item` của phiên bản gốc được sao chép sang phiên bản mới (định danh mới, cùng mã) …

  @US-07-011 @FR-07-011 @M @âm
  Kịch bản: US-07-011 âm 1 · Đã có phiên bản mở
    Biết danh mục `ACTIVE`; không `NATIONAL` (trừ tiến trình đồng bộ); không có phiên bản mở (BR-07-005)
    Khi đã có phiên bản mở
    Thì hệ thống từ chối với ERR-07-005 (409)
    Và người dùng thấy thông báo "Danh mục đã có một phiên bản đang soạn hoặc chờ duyệt (phiên bản {versionNo}). Mở phiên bản đó để tiếp tục, hoặc hủy nó trước khi tạo bản nháp mới."

  @US-07-011 @FR-07-011 @M @âm
  Kịch bản: US-07-011 âm 2 · Danh mục chưa phát hành (đã có nháp số 1)
    Biết danh mục `ACTIVE`; không `NATIONAL` (trừ tiến trình đồng bộ); không có phiên bản mở (BR-07-005)
    Khi danh mục chưa phát hành (đã có nháp số 1)
    Thì hệ thống từ chối với ERR-07-005 (409)
    Và người dùng thấy thông báo "Danh mục đã có một phiên bản đang soạn hoặc chờ duyệt (phiên bản {versionNo}). Mở phiên bản đó để tiếp tục, hoặc hủy nó trước khi tạo bản nháp mới."

  @US-07-012 @FR-07-012 @M
  Kịch bản: US-07-012 dương · Thêm, sửa, ngừng dùng bản ghi trên bản nháp
    Biết bản nháp `DRAFT`; danh mục không `NATIONAL`; với HYBRID chỉ thao tác trên bản ghi bổ sung
    Khi người dùng thêm dòng, sửa ô hoặc chọn "Ngừng dùng" trên một dòng ở lưới của UI-07-05
    Thì thêm: `201` với bản ghi
    Và bản ghi được thêm, sửa, chuyển `DEPRECATED` hoặc xóa trong bản nháp; `depth`, `path`, `level_name` tính lại cho bản ghi và cây con khi mã cha đổi; `item_count`, `stats` của bản nháp cập nhật …

  @US-07-012 @FR-07-012 @M @âm
  Kịch bản: US-07-012 âm 1 · Mã trùng trong bản nháp
    Biết bản nháp `DRAFT`; danh mục không `NATIONAL`; với HYBRID chỉ thao tác trên bản ghi bổ sung
    Khi mã trùng trong bản nháp
    Thì hệ thống từ chối với ERR-07-008 (409)
    Và người dùng thấy thông báo "Mã bản ghi"

  @US-07-012 @FR-07-012 @M @âm
  Kịch bản: US-07-012 âm 2 · Thuộc tính sai lược đồ
    Biết bản nháp `DRAFT`; danh mục không `NATIONAL`; với HYBRID chỉ thao tác trên bản ghi bổ sung
    Khi thuộc tính sai lược đồ
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-013 @FR-07-013 @M
  Kịch bản: US-07-013 dương · Kiểm tra hợp lệ bản ghi theo lược đồ
    Biết phiên bản tồn tại (kiểm tra được cả phiên bản đã phát hành để chẩn đoán, nhưng không sửa)
    Khi người dùng bấm "Kiểm tra hợp lệ" ở UI-07-05; hệ thống cũng gọi ngầm khi lưu bản ghi, khi nhập tệp và trước khi trình duyệt
    Thì hệ thống trả `200` với `{valid: bool, errorCount, warningCount, errors: [{itemCode, field, code, message, severity}], checkedAt}`; tối đa 1.000 lỗi trong phản hồi, đầy đủ tải qua `?format=xlsx`
    Và kết quả kiểm tra gần nhất được lưu vào `stats.validation` của phiên bản kèm `version` của phiên bản tại thời điểm kiểm tra; thao tác trình duyệt dùng kết quả này nếu `version` không đổi

  @US-07-013 @FR-07-013 @M @âm
  Kịch bản: US-07-013 âm 1 · Không tìm thấy phiên bản
    Biết phiên bản tồn tại (kiểm tra được cả phiên bản đã phát hành để chẩn đoán, nhưng không sửa)
    Khi không tìm thấy phiên bản
    Thì hệ thống từ chối với ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-013 @FR-07-013 @M @âm
  Kịch bản: US-07-013 âm 2 · Gọi ngầm từ FR ghi mà bản ghi sai
    Biết phiên bản tồn tại (kiểm tra được cả phiên bản đã phát hành để chẩn đoán, nhưng không sửa)
    Khi gọi ngầm từ FR ghi mà bản ghi sai
    Thì hệ thống từ chối với ERR-07-009
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-014 @FR-07-014 @M
  Kịch bản: US-07-014 dương · So sánh khác biệt giữa hai phiên bản, phân loại phá vỡ và không phá vỡ
    Biết hai phiên bản tồn tại và thuộc cùng danh mục
    Khi người dùng mở tab "So sánh" ở UI-07-07 hoặc bấm "So sánh với phiên bản…" ở tab Phiên bản; FR-07-015, 016, 031, 036 gọi nội bộ
    Thì hệ thống trả `200` với khối `summary` và trang `changes` như mô tả ở bước 7; `?format=xlsx` trả tệp khác biệt
    Và khi so bản nháp với phiên bản gốc, `stats` của bản nháp được cập nhật

  @US-07-014 @FR-07-014 @M @âm
  Kịch bản: US-07-014 âm 1 · Phiên bản không tồn tại hoặc khác danh mục
    Biết hai phiên bản tồn tại và thuộc cùng danh mục
    Khi phiên bản không tồn tại hoặc khác danh mục
    Thì hệ thống từ chối với ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-014 @FR-07-014 @M @âm
  Kịch bản: US-07-014 âm 2 · `size` > 200
    Biết hai phiên bản tồn tại và thuộc cùng danh mục
    Khi `size` > 200
    Thì hệ thống từ chối với ERR-07-026 (400)
    Và người dùng thấy thông báo "Số lượng vượt mức tối đa cho một lần ({max}). Chia nhỏ danh sách rồi thực hiện lại."

  @US-07-015 @FR-07-015 @M
  Kịch bản: US-07-015 dương · Trình duyệt, duyệt, từ chối phiên bản
    Biết trình: bản nháp `DRAFT`, kiểm tra hợp lệ không có lỗi
    Khi người soạn bấm "Trình duyệt" ở UI-07-05; người duyệt mở việc chờ duyệt trong hộp "Việc của tôi" (PH-12) hoặc UI-07-07 rồi bấm "Duyệt" hoặc "Từ chối"
    Thì hệ thống trả `200` với phiên bản ở trạng thái mới, `diffSummary`
    Và trình: `status = IN_REVIEW`, `submitted_by/at` được gán, một dòng `version_review` `SUBMIT` kèm `diff_stats`
    Và sự kiện được phát: Trình: EVT-07-04 `{tenant}.rdm.catalog.submitted.v1` (để PH-12 tạo việc cho người có `PERM-07-publish` phù hợp)

  @US-07-015 @FR-07-015 @M @âm
  Kịch bản: US-07-015 âm 1 · Phiên bản không ở trạng thái cho phép, bản nháp không có thay đổi
    Biết trình: bản nháp `DRAFT`, kiểm tra hợp lệ không có lỗi
    Khi phiên bản không ở trạng thái cho phép, bản nháp không có thay đổi
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-015 @FR-07-015 @M @âm
  Kịch bản: US-07-015 âm 2 · Bản nháp còn lỗi hợp lệ
    Biết trình: bản nháp `DRAFT`, kiểm tra hợp lệ không có lỗi
    Khi bản nháp còn lỗi hợp lệ
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-016 @FR-07-016 @M
  Kịch bản: US-07-016 dương · Phát hành phiên bản với ngày hiệu lực và căn cứ pháp lý
    Biết phiên bản `APPROVED`; hoặc `DRAFT` khi danh mục `require_approval = false`, thay đổi không vượt ngưỡng và không phá vỡ (BR-07-026); kiểm tra hợp lệ không lỗi; danh mục không `RETIRED`
    Khi người duyệt bấm "Phát hành" ở UI-07-07, chọn ngày hiệu lực, nhập căn cứ pháp lý và xác nhận; tiến trình đồng bộ hoặc di trú gọi nội bộ
    Thì hệ thống trả `200` với phiên bản `PUBLISHED`, `effectiveFrom`, `effectiveTo`, `snapshotUri`, nhãn hiệu lực
    Và phiên bản `PUBLISHED`, bất biến; `published_by/at`, `effective_from`, `legal_basis` gán; phiên bản đã phát hành có `effective_to` rỗng trước đó được gán `effective_to = effective_from` mới (BR-07-007) …
    Và sự kiện được phát: EVT-07-05 `{tenant}.rdm.catalog.published.v1` với `catalogCode`, `versionNo`, `effectiveFrom`, `effectiveTo` của phiên bản trước, `stats`, `breaking` …

  @US-07-016 @FR-07-016 @M @âm
  Kịch bản: US-07-016 âm 1 · Phiên bản không `APPROVED` (hoặc `DRAFT` hợp lệ)
    Biết phiên bản `APPROVED`; hoặc `DRAFT` khi danh mục `require_approval = false`, thay đổi không vượt ngưỡng và không phá vỡ (BR-07-026); kiểm tra hợp lệ không lỗi; danh mục không `RETIRED`
    Khi phiên bản không `APPROVED` (hoặc `DRAFT` hợp lệ)
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-016 @FR-07-016 @M @âm
  Kịch bản: US-07-016 âm 2 · Phát hành thẳng nhưng vượt ngưỡng hoặc phá vỡ
    Biết phiên bản `APPROVED`; hoặc `DRAFT` khi danh mục `require_approval = false`, thay đổi không vượt ngưỡng và không phá vỡ (BR-07-026); kiểm tra hợp lệ không lỗi; danh mục không `RETIRED`
    Khi phát hành thẳng nhưng vượt ngưỡng hoặc phá vỡ
    Thì hệ thống từ chối với ERR-07-016 (409)
    Và người dùng thấy thông báo "Phiên bản có thay đổi lớn ({percent}% bản ghi) hoặc thay đổi phá vỡ nên phải qua duyệt. Bấm"

  @US-07-017 @FR-07-017 @M
  Kịch bản: US-07-017 dương · Hủy bản nháp
    Biết phiên bản `DRAFT` (phiên bản `IN_REVIEW` phải rút lại trước, `APPROVED` phải thu hồi duyệt trước); không phải nháp số 1 của danh mục chưa phát hành (trường hợp đó dùng xóa danh mục, FR-07-009) …
    Khi người soạn bấm "Hủy bản nháp" ở UI-07-05 và xác nhận
    Thì hệ thống trả `204`
    Và `status = DISCARDED`; số phiên bản không được tái sử dụng; bản ghi và thuộc tính của phiên bản bị xóa vật lý sau 7 ngày bởi tác vụ dọn dẹp (phiên bản `DISCARDED` vẫn giữ dòng `catalog_version` và `version_review` để kiểm toán) …

  @US-07-017 @FR-07-017 @M @âm
  Kịch bản: US-07-017 âm 1 · Phiên bản không `DRAFT`, là nháp số 1 chưa phát hành, hoặc gắn với đồng bộ chờ xác nhận
    Biết phiên bản `DRAFT` (phiên bản `IN_REVIEW` phải rút lại trước, `APPROVED` phải thu hồi duyệt trước); không phải nháp số 1 của danh mục chưa phát hành (trường hợp đó dùng xóa danh mục, FR-07-009) …
    Khi phiên bản không `DRAFT`, là nháp số 1 chưa phát hành, hoặc gắn với đồng bộ chờ xác nhận
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-017 @FR-07-017 @M @âm
  Kịch bản: US-07-017 âm 2 · ETag không khớp
    Biết phiên bản `DRAFT` (phiên bản `IN_REVIEW` phải rút lại trước, `APPROVED` phải thu hồi duyệt trước); không phải nháp số 1 của danh mục chưa phát hành (trường hợp đó dùng xóa danh mục, FR-07-009) …
    Khi ETag không khớp
    Thì hệ thống từ chối với ERR-07-018 (412)
    Và người dùng thấy thông báo "Dữ liệu đã được người khác cập nhật trong lúc bạn đang sửa. Xem khác biệt rồi chọn"

  @US-07-018 @FR-07-018 @M
  Kịch bản: US-07-018 dương · Hiển thị bản ghi dạng bảng và dạng cây
    Biết phiên bản tồn tại
    Khi người dùng mở tab Bản ghi ở UI-07-02 và chọn "Bảng" hoặc "Cây"
    Thì dạng bảng: trang bản ghi (API-07-026) với cột cố định và cột thuộc tính động theo `sort_order`, ẩn thuộc tính `HIDDEN`

  @US-07-018 @FR-07-018 @M @âm
  Kịch bản: US-07-018 âm 1 · Không tìm thấy danh mục hoặc phiên bản
    Biết phiên bản tồn tại
    Khi không tìm thấy danh mục hoặc phiên bản
    Thì hệ thống từ chối với ERR-07-001, ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-018 @FR-07-018 @M @âm
  Kịch bản: US-07-018 âm 2 · `view = tree` với danh mục không phân cấp
    Biết phiên bản tồn tại
    Khi `view = tree` với danh mục không phân cấp
    Thì HTTP 400

  @US-07-019 @FR-07-019 @M
  Kịch bản: US-07-019 dương · Ghi mã thay thế và quan hệ kế thừa cho bản ghi ngừng dùng
    Biết bản nháp `DRAFT`; bản ghi `DEPRECATED` trong bản nháp (hoặc đang được ngừng dùng qua API-07-029)
    Khi người dùng chọn "Ngừng dùng" trên một bản ghi ở UI-07-05 và chọn mã thay thế ở hộp thoại
    Thì bản ghi với `replacedBy` mới
    Và `replaced_by` của bản ghi được cập nhật; sửa `replaced_by` của bản ghi đã ngừng dùng ở phiên bản trước là thay đổi không phá vỡ

  @US-07-019 @FR-07-019 @M @âm
  Kịch bản: US-07-019 âm 1 · Mã thay thế không tồn tại, không `ACTIVE`, trùng chính nó, tạo vòng
    Biết bản nháp `DRAFT`; bản ghi `DEPRECATED` trong bản nháp (hoặc đang được ngừng dùng qua API-07-029)
    Khi mã thay thế không tồn tại, không `ACTIVE`, trùng chính nó, tạo vòng
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-019 @FR-07-019 @M @âm
  Kịch bản: US-07-019 âm 2 · Nhập tay `replacedBy` cho ĐVHC
    Biết bản nháp `DRAFT`; bản ghi `DEPRECATED` trong bản nháp (hoặc đang được ngừng dùng qua API-07-029)
    Khi nhập tay `replacedBy` cho ĐVHC
    Thì hệ thống từ chối với ERR-07-035 (422)
    Và người dùng thấy thông báo "Sự kiện sắp xếp không hợp lệ: {reason}. Kiểm tra mã đơn vị, căn cứ pháp lý và ngày hiệu lực nằm trong phiên bản."

  # ---- EP-07-C · Nhập và xuất

  @US-07-020 @FR-07-020 @M
  Kịch bản: US-07-020 dương · Tải tệp mẫu Excel/CSV sinh theo lược đồ của danh mục
    Biết danh mục tồn tại; phiên bản chọn tồn tại
    Khi người dùng bấm "Tải tệp mẫu" ở bước 1 của UI-07-06 hoặc trong menu "Nhập, xuất" của UI-07-02
    Thì tệp `{catalogCode}_v{n}_mau.xlsx` hoặc `.csv` theo khuôn chuẩn mục 6.4.0; tùy chọn `includeData = true` điền sẵn bản ghi hiện có (để sửa rồi nhập lại với chế độ UPSERT hoặc REPLACE)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-07-020 @FR-07-020 @M @âm
  Kịch bản: US-07-020 âm 1 · Không tìm thấy danh mục, phiên bản
    Biết danh mục tồn tại; phiên bản chọn tồn tại
    Khi không tìm thấy danh mục, phiên bản
    Thì hệ thống từ chối với ERR-07-001, ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-020 @FR-07-020 @M @âm
  Kịch bản: US-07-020 âm 2 · `format` không hỗ trợ
    Biết danh mục tồn tại; phiên bản chọn tồn tại
    Khi `format` không hỗ trợ
    Thì HTTP 400

  @US-07-021 @FR-07-021 @M
  Kịch bản: US-07-021 dương · Nhập bản ghi từ Excel/CSV vào bản nháp
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT` hoặc người dùng chọn tự tạo bản nháp (`createDraft = true`, áp FR-07-011) …
    Khi người dùng bấm "Nhập từ tệp" ở UI-07-05, chọn tệp ở UI-07-06, ánh xạ cột rồi bấm "Kiểm tra"; sau khi xem trước bấm "Ghi vào bản nháp"
    Thì pha 1: `202 Accepted` với `jobId` và `Location: /api/rdm/v1/import-jobs/{jobId}`; khi xong, API-07-034 trả `status = VALIDATED`, `summary` gồm `totalRows`, `validRows`, `errorRows`, `warningRows`, số dòng theo `action` (`INSERT`, `UPDATE` …
    Và pha 1: `file_object` (DD-12) và `import_job`, các dòng `import_row` được tạo; bản nháp không đổi
    Và sự kiện được phát: EVT-07-07 `{tenant}.rdm.import.completed.v1` khi tác vụ kết thúc pha 1 (`VALIDATED` hoặc `FAILED`) và khi kết thúc pha 2 (`COMMITTED` hoặc `FAILED`) …

  @US-07-021 @FR-07-021 @M @âm
  Kịch bản: US-07-021 âm 1 · Tệp sai định dạng, mã hóa, vượt kích thước hoặc số dòng, thiếu cột bắt buộc, tệp nhiễm mã độc
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT` hoặc người dùng chọn tự tạo bản nháp (`createDraft = true`, áp FR-07-011) …
    Khi tệp sai định dạng, mã hóa, vượt kích thước hoặc số dòng, thiếu cột bắt buộc, tệp nhiễm mã độc
    Thì hệ thống từ chối với ERR-07-019
    Và người dùng thấy thông báo "Tệp không hợp lệ: {reason}. Kiểm tra định dạng (xlsx, csv), mã hóa (UTF-8, UTF-16), kích thước (≤ 50 MB), số dòng (≤ 200.000) và các cột bắt buộc, hoặc tải tệp mẫu."

  @US-07-021 @FR-07-021 @M @âm
  Kịch bản: US-07-021 âm 2 · Đã có tác vụ nhập đang hoạt động cho danh mục
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT` hoặc người dùng chọn tự tạo bản nháp (`createDraft = true`, áp FR-07-011) …
    Khi đã có tác vụ nhập đang hoạt động cho danh mục
    Thì hệ thống từ chối với ERR-07-020 (409)
    Và người dùng thấy thông báo "Tác vụ nhập không còn ghi được ({reason}). Kết quả xem trước chỉ giữ 24 giờ và bản nháp không được sửa trong lúc chờ. Hãy nhập lại tệp."

  @US-07-022 @FR-07-022 @M
  Kịch bản: US-07-022 dương · Tạo danh mục mới từ tệp, hỗ trợ khuôn hệ cũ Aita
    Biết như FR-07-003
    Khi người dùng bấm "Tạo từ tệp" ở UI-07-01, chọn khuôn chuẩn hoặc khuôn Aita và tải tệp lên UI-07-06
    Thì pha 1: như FR-07-021, thêm khối `proposedCatalog` (mã, tên lấy từ ô A2 với khuôn Aita hoặc tên tệp với khuôn chuẩn) và `proposedAttributes` (mã, nhãn, kiểu suy ra, bắt buộc suy ra, độ dài tối đa quan sát, số giá trị khác nhau)
    Và như FR-07-003 cộng bản ghi của bản nháp số 1; `catalog_version.origin = IMPORT`; với khuôn Aita, mỗi thuộc tính có nhãn gốc lưu trong `description`
    Và sự kiện được phát: EVT-07-07 (pha 1, pha 2) và EVT-07-01 (khi danh mục được tạo ở pha 2)

  @US-07-022 @FR-07-022 @M @âm
  Kịch bản: US-07-022 âm 1 · Khuôn Aita mà ô A2 rỗng hoặc dòng 4 không có tên thuộc tính
    Biết như FR-07-003
    Khi khuôn Aita mà ô A2 rỗng hoặc dòng 4 không có tên thuộc tính
    Thì hệ thống từ chối với ERR-07-019 (422)
    Và người dùng thấy thông báo "Tệp không hợp lệ: {reason}. Kiểm tra định dạng (xlsx, csv), mã hóa (UTF-8, UTF-16), kích thước (≤ 50 MB), số dòng (≤ 200.000) và các cột bắt buộc, hoặc tải tệp mẫu."

  @US-07-022 @FR-07-022 @M @âm
  Kịch bản: US-07-022 âm 2 · Không xác định được cột `MA` hoặc `TEN`
    Biết như FR-07-003
    Khi không xác định được cột `MA` hoặc `TEN`
    Thì hệ thống từ chối với ERR-07-019 (422)
    Và người dùng thấy thông báo "Tệp không hợp lệ: {reason}. Kiểm tra định dạng (xlsx, csv), mã hóa (UTF-8, UTF-16), kích thước (≤ 50 MB), số dòng (≤ 200.000) và các cột bắt buộc, hoặc tải tệp mẫu."

  @US-07-023 @FR-07-023 @M
  Kịch bản: US-07-023 dương · Nhập bản ghi qua API theo lô, idempotent
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT`, hoặc `createDraftIfMissing = true`
    Khi HTTT nguồn hoặc người dùng gọi API-07-031 với lô bản ghi và `Idempotency-Key`
    Thì hệ thống trả `200` với `results[]` theo thứ tự thao tác gửi lên: `{index, op, code, status: APPLIED/UNCHANGED/FAILED, errors}`, `summary`, ETag mới của bản nháp; `207 Multi-Status` không dùng, kết quả từng thao tác nằm trong thân
    Và với `atomic = true` (mặc định): tất cả thao tác được áp hoặc không thao tác nào; với `atomic = false`: thao tác hợp lệ được áp, thao tác lỗi được báo

  @US-07-023 @FR-07-023 @M @âm
  Kịch bản: US-07-023 âm 1 · Lô vượt kích thước
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT`, hoặc `createDraftIfMissing = true`
    Khi lô vượt kích thước
    Thì hệ thống từ chối với ERR-07-026 (400)
    Và người dùng thấy thông báo "Số lượng vượt mức tối đa cho một lần ({max}). Chia nhỏ danh sách rồi thực hiện lại."

  @US-07-023 @FR-07-023 @M @âm
  Kịch bản: US-07-023 âm 2 · Khóa idempotent dùng lại với nội dung khác
    Biết danh mục không `NATIONAL`, không `RETIRED`; có bản nháp `DRAFT`, hoặc `createDraftIfMissing = true`
    Khi khóa idempotent dùng lại với nội dung khác
    Thì hệ thống từ chối với ERR-07-022 (409)
    Và người dùng thấy thông báo "Yêu cầu này đã được gửi trước đó với nội dung khác. Tải lại trang rồi thực hiện lại."

  @US-07-024 @FR-07-024 @M
  Kịch bản: US-07-024 dương · Xuất phiên bản ra Excel, CSV, JSON
    Biết phiên bản tồn tại; danh mục `RESTRICTED` chỉ xuất bởi người trong tenant có `PERM-07-export` (không xuất qua cổng nhà phát triển)
    Khi người dùng bấm "Xuất" ở UI-07-02, chọn phiên bản, định dạng; HTTT gọi API-07-038
    Thì ≤ 10.000 dòng và không có tiêu đề `Prefer: respond-async`: `200` trả tệp trực tiếp
    Và với xuất nền: `import_job` `job_type = EXPORT`, `file_object` kết quả có `expires_at` 24 giờ
    Và sự kiện được phát: EVT-07-08 `{tenant}.rdm.export.completed.v1` khi xuất nền kết thúc

  @US-07-024 @FR-07-024 @M @âm
  Kịch bản: US-07-024 âm 1 · Không tìm thấy danh mục, phiên bản, hoặc không có phiên bản hiệu lực tại `at`
    Biết phiên bản tồn tại; danh mục `RESTRICTED` chỉ xuất bởi người trong tenant có `PERM-07-export` (không xuất qua cổng nhà phát triển)
    Khi không tìm thấy danh mục, phiên bản, hoặc không có phiên bản hiệu lực tại `at`
    Thì hệ thống từ chối với ERR-07-001, ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-024 @FR-07-024 @M @âm
  Kịch bản: US-07-024 âm 2 · Tải tệp đã hết hạn
    Biết phiên bản tồn tại; danh mục `RESTRICTED` chỉ xuất bởi người trong tenant có `PERM-07-export` (không xuất qua cổng nhà phát triển)
    Khi tải tệp đã hết hạn
    Thì hệ thống từ chối với ERR-07-020 (409)
    Và người dùng thấy thông báo "Tác vụ nhập không còn ghi được ({reason}). Kết quả xem trước chỉ giữ 24 giờ và bản nháp không được sửa trong lúc chờ. Hãy nhập lại tệp."

  @US-07-025 @FR-07-025 @M
  Kịch bản: US-07-025 dương · Xem lịch sử tác vụ nhập xuất và tải báo cáo lỗi
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi người dùng mở UI-07-08 "Tác vụ nhập xuất" hoặc bấm vào thông báo tác vụ xong
    Thì API-07-040: trang tác vụ (loại, danh mục, phiên bản, chế độ, định dạng, khuôn, trạng thái, người tạo, thời điểm bắt đầu, kết thúc, thống kê)

  @US-07-025 @FR-07-025 @M @âm
  Kịch bản: US-07-025 âm 1 · Tác vụ không tồn tại hoặc ngoài phạm vi xem
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi tác vụ không tồn tại hoặc ngoài phạm vi xem
    Thì HTTP 404

  @US-07-025 @FR-07-025 @M @âm
  Kịch bản: US-07-025 âm 2 · Dòng đã bị dọn sau 7 ngày
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dòng đã bị dọn sau 7 ngày
    Thì hệ thống từ chối với ERR-07-020 (409)
    Và người dùng thấy thông báo "Tác vụ nhập không còn ghi được ({reason}). Kết quả xem trước chỉ giữ 24 giờ và bản nháp không được sửa trong lúc chờ. Hãy nhập lại tệp."

  # ---- EP-07-D · Khai thác

  @US-07-026 @FR-07-026 @M
  Kịch bản: US-07-026 dương · Tra cứu một mã tại thời điểm
    Biết danh mục `ACTIVE` hoặc `RETIRED` (với `at` trước ngày ngừng)
    Khi HTTT gọi API-07-042 với mã và thời điểm `at`; người dùng thử ở UI-07-12; PH-04 tra trong luồng tích hợp
    Thì hệ thống trả `200` với bản ghi; bản ghi `DEPRECATED` trả bình thường kèm `status` và `replacedBy` (BR-07-004); tùy chọn `resolveReplacement = true` thêm khối `replacement` là bản ghi thay thế cuối chuỗi (khi `replacedBy` có đúng một mã)

  @US-07-026 @FR-07-026 @M @âm
  Kịch bản: US-07-026 âm 1 · Không tìm thấy danh mục
    Biết danh mục `ACTIVE` hoặc `RETIRED` (với `at` trước ngày ngừng)
    Khi không tìm thấy danh mục
    Thì hệ thống từ chối với ERR-07-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-026 @FR-07-026 @M @âm
  Kịch bản: US-07-026 âm 2 · Không có phiên bản hiệu lực tại `at`
    Biết danh mục `ACTIVE` hoặc `RETIRED` (với `at` trước ngày ngừng)
    Khi không có phiên bản hiệu lực tại `at`
    Thì hệ thống từ chối với ERR-07-006 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-027 @FR-07-027 @M
  Kịch bản: US-07-027 dương · Tra cứu lô tối đa 500 mã
    Biết như FR-07-026
    Khi HTTT gọi API-07-043 với danh sách tối đa 500 mã
    Thì hệ thống trả `200` với `found` (ánh xạ mã → bản ghi, theo mã chuẩn hóa chữ hoa) và `notFound` (mảng mã không tìm thấy); thứ tự không đảm bảo; `X-Catalog-Version`

  @US-07-027 @FR-07-027 @M @âm
  Kịch bản: US-07-027 âm 1 · ERR-07-007
    Biết như FR-07-026
    Khi ERR-07-007
    Thì hệ thống từ chối với ERR-07-007
    Và người dùng thấy thông báo "Không có mã"

  @US-07-027 @FR-07-027 @M @âm
  Kịch bản: US-07-027 âm 2 · ERR-07-026
    Biết như FR-07-026
    Khi ERR-07-026
    Thì hệ thống từ chối với ERR-07-026
    Và người dùng thấy thông báo "Số lượng vượt mức tối đa cho một lần ({max}). Chia nhỏ danh sách rồi thực hiện lại."

  @US-07-028 @FR-07-028 @M
  Kịch bản: US-07-028 dương · Lấy toàn bộ bản ghi theo phiên bản
    Biết như FR-07-026
    Khi HTTT gọi API-07-041 (phân trang) hoặc API-07-049 (ảnh chụp toàn bộ) để nạp bản sao danh mục
    Thì API-07-041: `{items: [...], nextCursor, catalogVersion, schemaHash}`; `nextCursor` rỗng khi hết

  @US-07-028 @FR-07-028 @M @âm
  Kịch bản: US-07-028 âm 1 · ERR-07-007
    Biết như FR-07-026
    Khi ERR-07-007
    Thì hệ thống từ chối với ERR-07-007
    Và người dùng thấy thông báo "Không có mã"

  @US-07-028 @FR-07-028 @M @âm
  Kịch bản: US-07-028 âm 2 · ERR-07-023
    Biết như FR-07-026
    Khi ERR-07-023
    Thì hệ thống từ chối với ERR-07-023
    Và người dùng thấy thông báo "Biểu thức truy vấn sai cú pháp tại {pointer}. Sửa JSON theo vị trí được tô đỏ, hoặc dựng lại bằng trình dựng điều kiện."

  @US-07-029 @FR-07-029 @M
  Kịch bản: US-07-029 dương · Lấy cây hoặc nhánh con
    Biết danh mục phân cấp
    Khi HTTT gọi API-07-044 với mã gốc của nhánh và độ sâu
    Thì hệ thống trả `200` với `nodes`: mảng nút `{code, name, levelName, status, attrs?, children: [...]}` lồng tối đa `depth` cấp tính từ `root`; nút có con chưa trả (do giới hạn `depth`) mang `hasChildren = true`

  @US-07-029 @FR-07-029 @M @âm
  Kịch bản: US-07-029 âm 1 · ERR-07-007
    Biết danh mục phân cấp
    Khi ERR-07-007
    Thì hệ thống từ chối với ERR-07-007
    Và người dùng thấy thông báo "Không có mã"

  @US-07-029 @FR-07-029 @M @âm
  Kịch bản: US-07-029 âm 2 · ERR-07-024
    Biết danh mục phân cấp
    Khi ERR-07-024
    Thì hệ thống từ chối với ERR-07-024
    Và người dùng thấy thông báo "Truy vấn vượt giới hạn: {reason}. Tối đa 20 điều kiện, lồng 3 cấp, 500 giá trị cho"

  @US-07-030 @FR-07-030 @S
  Kịch bản: US-07-030 dương · Tìm kiếm không dấu trong danh mục
    Biết danh mục tồn tại
    Khi HTTT gọi API-07-045 với từ khóa; người dùng gõ vào ô tìm kiếm ở UI-07-02 hoặc UI-07-12
    Thì hệ thống trả `200` với tối đa `limit` bản ghi xếp theo độ liên quan: khớp mã chính xác, mã bắt đầu bằng, tên bắt đầu bằng, tên chứa từ, thuộc tính `searchable` chứa

  @US-07-030 @FR-07-030 @S @âm
  Kịch bản: US-07-030 âm 1 · ERR-07-007
    Biết danh mục tồn tại
    Khi ERR-07-007
    Thì hệ thống từ chối với ERR-07-007
    Và người dùng thấy thông báo "Không có mã"

  @US-07-031 @FR-07-031 @M
  Kịch bản: US-07-031 dương · Lấy thay đổi kể từ một phiên bản (delta)
    Biết `sinceVersion` là phiên bản đã phát hành của danh mục
    Khi HTTT gọi API-07-046 với số phiên bản đang có, thường theo lịch hoặc khi nhận sự kiện EVT-07-05
    Thì hệ thống trả `200` với `fromVersion`, `toVersion`, `schemaChanged` (bool), `schemaChanges[]`, `changes[]`: `{code, changeType: ADDED/CHANGED/DEPRECATED/REACTIVATED/REMOVED, item (trạng thái sau), changedFields}`, phân trang con trỏ …

  @US-07-031 @FR-07-031 @M @âm
  Kịch bản: US-07-031 âm 1 · ERR-07-006
    Biết `sinceVersion` là phiên bản đã phát hành của danh mục
    Khi ERR-07-006
    Thì hệ thống từ chối với ERR-07-006
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-032 @FR-07-032 @M
  Kịch bản: US-07-032 dương · API truy vấn có cấu trúc
    Biết danh mục có phiên bản hiệu lực; trường được lọc hoặc sắp xếp là trường hệ thống hoặc thuộc tính `queryable`
    Khi HTTT gọi API-07-047 với biểu thức lọc có cấu trúc; người dùng soạn truy vấn ở UI-07-12
    Thì hệ thống trả `200` với `items` (chỉ các trường trong `select`), `nextCursor`, `catalogVersion`, `took` (mili giây)

  @US-07-032 @FR-07-032 @M @âm
  Kịch bản: US-07-032 âm 1 · Biểu thức sai cú pháp, giá trị sai kiểu, con trỏ sai
    Biết danh mục có phiên bản hiệu lực; trường được lọc hoặc sắp xếp là trường hệ thống hoặc thuộc tính `queryable`
    Khi biểu thức sai cú pháp, giá trị sai kiểu, con trỏ sai
    Thì hệ thống từ chối với ERR-07-023 (400)
    Và người dùng thấy thông báo "Biểu thức truy vấn sai cú pháp tại {pointer}. Sửa JSON theo vị trí được tô đỏ, hoặc dựng lại bằng trình dựng điều kiện."

  @US-07-032 @FR-07-032 @M @âm
  Kịch bản: US-07-032 âm 2 · Vượt giới hạn điều kiện, độ lồng, phần tử, thời gian
    Biết danh mục có phiên bản hiệu lực; trường được lọc hoặc sắp xếp là trường hệ thống hoặc thuộc tính `queryable`
    Khi vượt giới hạn điều kiện, độ lồng, phần tử, thời gian
    Thì hệ thống từ chối với ERR-07-024 (422)
    Và người dùng thấy thông báo "Truy vấn vượt giới hạn: {reason}. Tối đa 20 điều kiện, lồng 3 cấp, 500 giá trị cho"

  @US-07-033 @FR-07-033 @M
  Kịch bản: US-07-033 dương · Liệt kê danh mục và lấy lược đồ qua API
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi HTTT gọi API-07-001 và API-07-048; nhà phát triển duyệt danh mục trên cổng nhà phát triển
    Thì API-07-001 (với HTTT): danh sách danh mục `ACTIVE` mà HTTT được khai thác, kèm phiên bản hiệu lực, `schemaHash`, số bản ghi; không trả danh mục `DRAFT`

  @US-07-033 @FR-07-033 @M @âm
  Kịch bản: US-07-033 âm 1 · ERR-07-001
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi ERR-07-001
    Thì hệ thống từ chối với ERR-07-001
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-033 @FR-07-033 @M @âm
  Kịch bản: US-07-033 âm 2 · ERR-07-006
    Biết người dùng đã đăng nhập với vai trò nhà phát triển
    Khi ERR-07-006
    Thì hệ thống từ chối với ERR-07-006
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {v} của danh mục. Phiên bản có thể đã bị hủy. Mở tab Phiên bản để chọn lại."

  @US-07-034 @FR-07-034 @M
  Kịch bản: US-07-034 dương · Phát sự kiện thay đổi danh mục
    Biết thay đổi dữ liệu đã cam kết
    Khi một thay đổi được ghi thành công ở các FR ghi (tạo, sửa, phát hành, ngừng hiệu lực, ánh xạ, đồng bộ); bộ chuyển tiếp outbox đọc bản ghi outbox
    Thì bản tin CloudEvents 1.0 trên Kafka theo bảng sự kiện EVT-07-01…10
    Và mỗi sự kiện có đúng một dòng outbox; Debezium đưa lên Kafka; topic theo `{tenant}.rdm.{thực-thể}.{sự-kiện}.v1` (tenant viết thường, `COMMON` dùng `common`)
    Và sự kiện được phát: EVT-07-01…10

  @US-07-034 @FR-07-034 @M @âm
  Kịch bản: US-07-034 âm 1 · Ngoại lệ
    Biết thay đổi dữ liệu đã cam kết
    Khi ngoại lệ
    Thì không có ngoại lệ trả cho người dùng; lỗi đẩy của Debezium được giám sát ở PH-18 và không làm mất sự kiện vì outbox giữ tới khi được đọc

  # ---- EP-07-E · Đồng bộ danh mục quốc gia

  @US-07-035 @FR-07-035 @M
  Kịch bản: US-07-035 dương · Cấu hình nguồn đồng bộ danh mục quốc gia
    Biết danh mục tồn tại, không `RETIRED`, `source_type = NATIONAL` (hoặc danh mục `COMMON` với tenant `PLATFORM`); kết nối `NDXP_DMDC` của tenant (hoặc của nền tảng) đã cấu hình ở PH-14
    Khi người dùng bấm "+ Thêm nguồn đồng bộ" hoặc "Sửa" ở UI-07-09
    Thì API-07-055: trang danh sách nguồn kèm trạng thái lần chạy cuối, `lastSuccessAt`, `remoteVersion`, `nextRunAt` tính từ `scheduleCron`
    Và `sync_source` (EN-07-10) được tạo hoặc cập nhật; bộ lập lịch nạp lại lịch của nguồn trong ≤ 60 giây

  @US-07-035 @FR-07-035 @M @âm
  Kịch bản: US-07-035 âm 1 · Danh mục không phải `NATIONAL` (hoặc `COMMON` với `PLATFORM`)
    Biết danh mục tồn tại, không `RETIRED`, `source_type = NATIONAL` (hoặc danh mục `COMMON` với tenant `PLATFORM`); kết nối `NDXP_DMDC` của tenant (hoặc của nền tảng) đã cấu hình ở PH-14
    Khi danh mục không phải `NATIONAL` (hoặc `COMMON` với `PLATFORM`)
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-035 @FR-07-035 @M @âm
  Kịch bản: US-07-035 âm 2 · Danh mục đã có nguồn của cùng nhà cung cấp
    Biết danh mục tồn tại, không `RETIRED`, `source_type = NATIONAL` (hoặc danh mục `COMMON` với tenant `PLATFORM`); kết nối `NDXP_DMDC` của tenant (hoặc của nền tảng) đã cấu hình ở PH-14
    Khi danh mục đã có nguồn của cùng nhà cung cấp
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "danh mục đã có nguồn đồng bộ"

  @US-07-036 @FR-07-036 @M
  Kịch bản: US-07-036 dương · Chạy đồng bộ theo lịch hoặc theo yêu cầu và tính khác biệt
    Biết nguồn `enabled = true` (chạy theo lịch) hoặc nguồn tồn tại (chạy theo yêu cầu, kể cả khi đang tắt); không có lần chạy `RUNNING` của cùng nguồn
    Khi bộ lập lịch đến giờ chạy theo biểu thức lịch của nguồn; hoặc người dùng bấm "Chạy ngay" ở UI-07-09
    Thì API-07-058: `202` với `runId` và `Location` tới API-07-060. API-07-059: trang lịch sử lần chạy
    Và một `sync_run` (EN-07-11) với trạng thái kết thúc rõ ràng; các `sync_change` (EN-07-12) của lần chạy; với `APPLIED` có phiên bản `origin = SYNC` đã `PUBLISHED`; với `PENDING_CONFIRMATION` có bản nháp `origin = SYNC` chiếm suất phiên bản mở …
    Và sự kiện được phát: EVT-07-09 `{tenant}.rdm.sync.completed.v1` ở mọi trạng thái kết thúc trừ `NO_CHANGE` (chỉ đếm vào chỉ số để không làm ồn bên nhận); kèm EVT-07-05 khi `APPLIED`

  @US-07-036 @FR-07-036 @M @âm
  Kịch bản: US-07-036 âm 1 · Không tìm thấy nguồn hoặc lần chạy
    Biết nguồn `enabled = true` (chạy theo lịch) hoặc nguồn tồn tại (chạy theo yêu cầu, kể cả khi đang tắt); không có lần chạy `RUNNING` của cùng nguồn
    Khi không tìm thấy nguồn hoặc lần chạy
    Thì hệ thống từ chối với ERR-07-045 (404)

  @US-07-036 @FR-07-036 @M @âm
  Kịch bản: US-07-036 âm 2 · Nguồn đang có lần chạy `RUNNING` (theo yêu cầu)
    Biết nguồn `enabled = true` (chạy theo lịch) hoặc nguồn tồn tại (chạy theo yêu cầu, kể cả khi đang tắt); không có lần chạy `RUNNING` của cùng nguồn
    Khi nguồn đang có lần chạy `RUNNING` (theo yêu cầu)
    Thì hệ thống từ chối với ERR-07-005 (409)
    Và người dùng thấy thông báo "Danh mục đã có một phiên bản đang soạn hoặc chờ duyệt (phiên bản {versionNo}). Mở phiên bản đó để tiếp tục, hoặc hủy nó trước khi tạo bản nháp mới."

  @US-07-037 @FR-07-037 @M
  Kịch bản: US-07-037 dương · Xác nhận hoặc từ chối thay đổi từ nguồn quốc gia
    Biết lần chạy `PENDING_CONFIRMATION`; bản nháp `origin = SYNC` của lần chạy còn `DRAFT`
    Khi người dùng mở lần đồng bộ ở trạng thái chờ xác nhận ở UI-07-09 (hoặc từ "Việc của tôi"), xem khác biệt rồi bấm "Xác nhận" hoặc "Từ chối"
    Thì hệ thống trả `200` với lần chạy ở trạng thái mới; khi xác nhận kèm phiên bản kết quả (`PUBLISHED`, hoặc `IN_REVIEW` khi danh mục `require_approval = true` và người xác nhận không có `PERM-07-publish`)
    Và xác nhận: `confirmed_by`, `confirmed_at` được ghi; thay đổi được áp dụng theo lựa chọn; lần chạy `APPLIED`; `sync_source.remote_version` và `last_success_at` cập nhật
    Và sự kiện được phát: EVT-07-09 với trạng thái mới; EVT-07-05 khi phiên bản được phát hành; EVT-07-04 khi phiên bản được chuyển sang chờ duyệt

  @US-07-037 @FR-07-037 @M @âm
  Kịch bản: US-07-037 âm 1 · Lần chạy không ở `PENDING_CONFIRMATION`, hoặc phiên bản hiện hành đã đổi
    Biết lần chạy `PENDING_CONFIRMATION`; bản nháp `origin = SYNC` của lần chạy còn `DRAFT`
    Khi lần chạy không ở `PENDING_CONFIRMATION`, hoặc phiên bản hiện hành đã đổi
    Thì hệ thống từ chối với ERR-07-029 (409)
    Và người dùng thấy thông báo "Lần đồng bộ này không còn chờ xác nhận. Có thể người khác đã xác nhận hoặc từ chối. Tải lại để xem kết quả."

  @US-07-037 @FR-07-037 @M @âm
  Kịch bản: US-07-037 âm 2 · Có bản ghi lỗi mà không chọn bỏ qua
    Biết lần chạy `PENDING_CONFIRMATION`; bản nháp `origin = SYNC` của lần chạy còn `DRAFT`
    Khi có bản ghi lỗi mà không chọn bỏ qua
    Thì hệ thống từ chối với ERR-07-021 (422)
    Và người dùng thấy thông báo "Tệp còn {errorRows} dòng lỗi. Sửa tệp và nhập lại, hoặc chọn"

  @US-07-038 @FR-07-038 @M
  Kịch bản: US-07-038 dương · Khám phá danh mục quốc gia và đăng ký đồng bộ
    Biết kết nối `NDXP_DMDC` hoạt động
    Khi người dùng mở tab "Danh mục quốc gia" ở UI-07-09, tìm danh mục và bấm "Đăng ký đồng bộ"
    Thì API-07-063: trang danh mục quốc gia gồm `remoteCode`, `remoteName`, cơ quan ban hành, `remoteVersion`, ngày cập nhật, số bản ghi (nếu nguồn cung cấp), và `localStatus` ∈ `IN_COMMON` (đã có ở `COMMON`, kèm mã danh mục) …
    Và danh mục (EN-07-02) và phiên bản nháp số 1 được tạo với lược đồ suy từ cấu trúc từ xa; `sync_source` được tạo với `autoApply` theo lựa chọn …
    Và sự kiện được phát: EVT-07-01 khi danh mục được tạo; EVT-07-09 khi lần chạy đầu kết thúc

  @US-07-038 @FR-07-038 @M @âm
  Kịch bản: US-07-038 âm 1 · Cổng tiếp hợp lỗi
    Biết kết nối `NDXP_DMDC` hoạt động
    Khi cổng tiếp hợp lỗi
    Thì hệ thống từ chối với ERR-07-028 (502)
    Và người dùng thấy thông báo "Nguồn danh mục quốc gia chưa phản hồi. Hệ thống sẽ thử lại theo lịch. Nếu kéo dài, kiểm tra kết nối NDXP ở phân hệ Kết nối quốc gia."

  @US-07-038 @FR-07-038 @M @âm
  Kịch bản: US-07-038 âm 2 · Mã danh mục đề xuất trùng
    Biết kết nối `NDXP_DMDC` hoạt động
    Khi mã danh mục đề xuất trùng
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "Mã danh mục"

  @US-07-039 @FR-07-039 @C
  Kịch bản: US-07-039 dương · Đề xuất bổ sung bản ghi lên danh mục quốc gia
    Biết danh mục là `HYBRID` có gốc là danh mục `NATIONAL` hoặc `COMMON` có nguồn đồng bộ; bản ghi được đề xuất là bản ghi bổ sung `ACTIVE` trong phiên bản đã phát hành; cổng tiếp hợp hỗ trợ chức năng đề xuất
    Khi người dùng bấm "Đề xuất lên quốc gia" trên bản ghi địa phương ở UI-07-09
    Thì hệ thống trả `202` với đề xuất gồm `proposalId`, `remoteReference` (mã tham chiếu do NDXP trả), `status` ∈ `SUBMITTED`, `ACCEPTED`, `REJECTED`, `UNKNOWN`, danh sách mã đề xuất
    Và đề xuất được lưu (trong `import_job` với `job_type = PROPOSAL`, xem Q07-07) và gửi qua cổng tiếp hợp; trạng thái được làm mới ở mỗi lần chạy đồng bộ của nguồn gốc

  @US-07-039 @FR-07-039 @C @âm
  Kịch bản: US-07-039 âm 1 · Danh mục không phải HYBRID gốc quốc gia, mã không phải bản ghi bổ sung
    Biết danh mục là `HYBRID` có gốc là danh mục `NATIONAL` hoặc `COMMON` có nguồn đồng bộ; bản ghi được đề xuất là bản ghi bổ sung `ACTIVE` trong phiên bản đã phát hành; cổng tiếp hợp hỗ trợ chức năng đề xuất
    Khi danh mục không phải HYBRID gốc quốc gia, mã không phải bản ghi bổ sung
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  # ---- EP-07-F · Hệ thống mã ngoài và ánh xạ mã

  @US-07-040 @FR-07-040 @M
  Kịch bản: US-07-040 dương · Quản lý hệ thống mã ngoài
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi người dùng bấm "+ Hệ thống mã" ở UI-07-10
    Thì API-07-064: trang hệ thống mã (tenant và `COMMON`) với số danh mục đã ánh xạ, số dòng ánh xạ
    Và `code_system` (EN-07-13) được tạo hoặc cập nhật

  @US-07-040 @FR-07-040 @M @âm
  Kịch bản: US-07-040 âm 1 · Mã trùng
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi mã trùng
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "mã hệ thống mã đã được dùng"

  @US-07-040 @FR-07-040 @M @âm
  Kịch bản: US-07-040 âm 2 · Tenant tỉnh sửa hệ thống mã `COMMON`
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi tenant tỉnh sửa hệ thống mã `COMMON`
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-041 @FR-07-041 @M
  Kịch bản: US-07-041 dương · Quản lý bảng ánh xạ mã giữa danh mục và hệ thống mã ngoài
    Biết danh mục có ít nhất một phiên bản `PUBLISHED`; hệ thống mã `ACTIVE`
    Khi người dùng chọn danh mục và hệ thống mã ở UI-07-10, sửa ô ánh xạ hoặc nhập lô từ tệp rồi bấm "Lưu"
    Thì API-07-067: trang ánh xạ của danh mục, lọc theo `codeSystem`, `itemCode`, `externalCode`, `relation`, `provisional`, `at` (chỉ ánh xạ hiệu lực tại ngày), `unmapped=true` (liệt kê mã danh mục chưa có ánh xạ)
    Và `code_mapping` (EN-07-14) được thêm, sửa hoặc xóa trong một giao dịch cho cả lô; bộ đệm chuyển mã của cặp (danh mục, hệ thống mã) bị vô hiệu

  @US-07-041 @FR-07-041 @M @âm
  Kịch bản: US-07-041 âm 1 · Mã danh mục không tồn tại tại ngày hiệu lực
    Biết danh mục có ít nhất một phiên bản `PUBLISHED`; hệ thống mã `ACTIVE`
    Khi mã danh mục không tồn tại tại ngày hiệu lực
    Thì hệ thống từ chối với ERR-07-007 (422)
    Và người dùng thấy thông báo "Không có mã"

  @US-07-041 @FR-07-041 @M @âm
  Kịch bản: US-07-041 âm 2 · Mã ngoài trùng trong khoảng hiệu lực giao nhau
    Biết danh mục có ít nhất một phiên bản `PUBLISHED`; hệ thống mã `ACTIVE`
    Khi mã ngoài trùng trong khoảng hiệu lực giao nhau
    Thì hệ thống từ chối với ERR-07-033 (422)
    Và người dùng thấy thông báo "Mã ngoài"

  @US-07-042 @FR-07-042 @M
  Kịch bản: US-07-042 dương · Chuyển mã qua bảng ánh xạ
    Biết hệ thống mã và danh mục tồn tại
    Khi HTTT hoặc PH-04 gọi API-07-070 với mã nguồn, hệ thống mã và chiều chuyển
    Thì hệ thống trả `200` với mảng kết quả cùng thứ tự đầu vào; mỗi phần tử gồm `input`, `status` ∈ `MAPPED`, `MULTIPLE`, `NOT_MAPPED`, và tùy chiều: `itemCode`, `itemName`, `itemStatus` (chiều `TO_CATALOG`) hoặc `externalCodes[]` với `relation` …

  @US-07-042 @FR-07-042 @M @âm
  Kịch bản: US-07-042 âm 1 · Không tìm thấy danh mục
    Biết hệ thống mã và danh mục tồn tại
    Khi không tìm thấy danh mục
    Thì hệ thống từ chối với ERR-07-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-042 @FR-07-042 @M @âm
  Kịch bản: US-07-042 âm 2 · Không tìm thấy hệ thống mã
    Biết hệ thống mã và danh mục tồn tại
    Khi không tìm thấy hệ thống mã
    Thì hệ thống từ chối với ERR-07-045 (404)

  @US-07-043 @FR-07-043 @S
  Kịch bản: US-07-043 dương · Báo cáo độ phủ ánh xạ
    Biết danh mục có phiên bản `PUBLISHED`; hệ thống mã tồn tại
    Khi người dùng mở tab "Độ phủ" ở UI-07-10
    Thì API-07-071: `totalActiveItems`, `mappedItems` (có ít nhất một ánh xạ không tạm thời hiệu lực tại `at`), `provisionalItems`, `coverageRatio`, và ba danh sách phân trang: `unmapped` (mã `ACTIVE` chưa có ánh xạ), `provisional` …

  @US-07-043 @FR-07-043 @S @âm
  Kịch bản: US-07-043 âm 1 · ERR-07-001
    Biết danh mục có phiên bản `PUBLISHED`; hệ thống mã tồn tại
    Khi ERR-07-001
    Thì hệ thống từ chối với ERR-07-001
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  # ---- EP-07-G · Đơn vị hành chính

  @US-07-044 @FR-07-044 @M
  Kịch bản: US-07-044 dương · Quản lý danh mục ĐVHC hai cấp kèm lịch sử ba cấp
    Biết gói nền đã nạp danh mục `DVHC` với lược đồ chuẩn (mục dưới)
    Khi PA mở danh mục ĐVHC ở UI-07-11 (tenant `PLATFORM`), tạo bản nháp và cập nhật theo văn bản sắp xếp
    Thì danh mục `DVHC` với các phiên bản lịch sử và hiện hành; bảng chiếu `admin_unit` (EN-07-18) phản ánh mọi đơn vị từng tồn tại với khoảng hiệu lực
    Và sau mỗi lần phát hành phiên bản `DVHC`, `admin_unit` được làm mới trong cùng giao dịch (hàm `f_refresh_admin_unit`); định danh `admin_unit.id` của một đơn vị không đổi qua các phiên bản chừng nào mã và đơn vị còn là một
    Và sự kiện được phát: EVT-07-05 khi phát hành; EVT-07-10 khi phiên bản có sự kiện sắp xếp

  @US-07-044 @FR-07-044 @M @âm
  Kịch bản: US-07-044 âm 1 · Tenant không phải `PLATFORM` ghi `DVHC`
    Biết gói nền đã nạp danh mục `DVHC` với lược đồ chuẩn (mục dưới)
    Khi tenant không phải `PLATFORM` ghi `DVHC`
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-044 @FR-07-044 @M @âm
  Kịch bản: US-07-044 âm 2 · Sửa lược đồ chuẩn của `DVHC`
    Biết gói nền đã nạp danh mục `DVHC` với lược đồ chuẩn (mục dưới)
    Khi sửa lược đồ chuẩn của `DVHC`
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "lược đồ ĐVHC do nền tảng cố định"

  @US-07-045 @FR-07-045 @M
  Kịch bản: US-07-045 dương · Ghi nhận sự kiện sắp xếp ĐVHC
    Biết danh mục `DVHC` có bản nháp `DRAFT`
    Khi PA bấm "+ Sự kiện sắp xếp" trên bản nháp ĐVHC ở UI-07-11, chọn loại, đơn vị nguồn, đích và văn bản căn cứ
    Thì API-07-053: `201` với sự kiện (`id`, `eventType`, `fromCodes`, `toCodes`, `effectiveDate`, `legalBasis`, `note`) và danh sách bản ghi bản nháp bị tác động
    Và `item_succession` (EN-07-06) được ghi; bản ghi của bản nháp được cập nhật theo bảng hệ quả dưới đây; `replaced_by` của bản ghi nguồn được tính lại

  @US-07-045 @FR-07-045 @M @âm
  Kịch bản: US-07-045 âm 1 · Bản số sai, mã nguồn không tồn tại hoặc không `ACTIVE`, mã đích đã dùng cho đơn vị khác, thiếu căn cứ …
    Biết danh mục `DVHC` có bản nháp `DRAFT`
    Khi bản số sai, mã nguồn không tồn tại hoặc không `ACTIVE`, mã đích đã dùng cho đơn vị khác, thiếu căn cứ, ngày hiệu lực không khớp bản nháp, mã nguồn trùng giữa hai sự kiện
    Thì hệ thống từ chối với ERR-07-035 (422)
    Và người dùng thấy thông báo "Sự kiện sắp xếp không hợp lệ: {reason}. Kiểm tra mã đơn vị, căn cứ pháp lý và ngày hiệu lực nằm trong phiên bản."

  @US-07-045 @FR-07-045 @M @âm
  Kịch bản: US-07-045 âm 2 · Bản nháp không `DRAFT`; xóa sự kiện của phiên bản đã phát hành
    Biết danh mục `DVHC` có bản nháp `DRAFT`
    Khi bản nháp không `DRAFT`; xóa sự kiện của phiên bản đã phát hành
    Thì hệ thống từ chối với ERR-07-004 (409)
    Và người dùng thấy thông báo "Phiên bản đang ở trạng thái"

  @US-07-046 @FR-07-046 @M
  Kịch bản: US-07-046 dương · Chuyển đổi mã ĐVHC cũ sang mới và tra ngược
    Biết danh mục `DVHC` có phiên bản hiệu lực tại các thời điểm được hỏi
    Khi HTTT gọi API-07-051; người dùng mở tab "Công cụ chuyển mã" ở UI-07-11 hoặc tải tệp ở UI-07-06
    Thì hệ thống trả `200` với mảng kết quả cùng thứ tự đầu vào, mỗi phần tử gồm `input` (`code`, `asOf`), `status` ∈ `MAPPED`, `UNCHANGED`, `AMBIGUOUS`, `NOT_FOUND`, `newCode`, `newName`, `newPath` (mã tỉnh, xã), `candidates[]` (khi `AMBIGUOUS`: mã, tên …

  @US-07-046 @FR-07-046 @M @âm
  Kịch bản: US-07-046 âm 1 · Lô vượt 1.000
    Biết danh mục `DVHC` có phiên bản hiệu lực tại các thời điểm được hỏi
    Khi lô vượt 1.000
    Thì hệ thống từ chối với ERR-07-026 (400)
    Và người dùng thấy thông báo "Số lượng vượt mức tối đa cho một lần ({max}). Chia nhỏ danh sách rồi thực hiện lại."

  @US-07-046 @FR-07-046 @M @âm
  Kịch bản: US-07-046 âm 2 · `asOf` sau `at` với chiều `OLD_TO_NEW` (hoặc ngược lại)
    Biết danh mục `DVHC` có phiên bản hiệu lực tại các thời điểm được hỏi
    Khi `asOf` sau `at` với chiều `OLD_TO_NEW` (hoặc ngược lại)
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-047 @FR-07-047 @M
  Kịch bản: US-07-047 dương · Xem dòng lịch sử của một bản ghi
    Biết danh mục tồn tại; mã từng xuất hiện ở ít nhất một phiên bản đã phát hành
    Khi HTTT gọi API-07-050; người dùng bấm "Dòng lịch sử" trên một bản ghi ở UI-07-11 hoặc UI-07-02
    Thì API-07-050: `code`, `segments[]` (mỗi đoạn gồm `from`, `to`, `versionNoFrom`, `versionNoTo`, `name`, `parentCode`, `levelName`, `status`, `attrsChanged[]`), `predecessors[]` và `successors[]` (mã, tên, loại sự kiện, ngày, căn cứ)

  @US-07-047 @FR-07-047 @M @âm
  Kịch bản: US-07-047 âm 1 · ERR-07-001
    Biết danh mục tồn tại; mã từng xuất hiện ở ít nhất một phiên bản đã phát hành
    Khi ERR-07-001
    Thì hệ thống từ chối với ERR-07-001
    Và người dùng thấy thông báo "Không tìm thấy danh mục"

  @US-07-047 @FR-07-047 @M @âm
  Kịch bản: US-07-047 âm 2 · ERR-07-007
    Biết danh mục tồn tại; mã từng xuất hiện ở ít nhất một phiên bản đã phát hành
    Khi ERR-07-007
    Thì hệ thống từ chối với ERR-07-007
    Và người dùng thấy thông báo "Không có mã"

  # ---- EP-07-H · Đa tenant, nền tảng và quản trị

  @US-07-048 @FR-07-048 @M
  Kịch bản: US-07-048 dương · Chia sẻ danh mục toàn quốc giữa các tenant và mở rộng HYBRID
    Biết danh mục `COMMON` `ACTIVE` (để mở rộng)
    Khi tenant tỉnh mở danh mục `COMMON` ở UI-07-01, UI-07-02 hoặc chọn "Tạo danh mục mở rộng" ở UI-07-03; mọi API nhóm A, B, D khi gặp danh mục `COMMON` hoặc `HYBRID`
    Thì danh mục `COMMON` hiện trong danh sách và tra cứu của mọi tenant, gắn nhãn "Dùng chung toàn quốc"; danh mục HYBRID trả hợp của gốc và bổ sung
    Và sự kiện được phát: Sự kiện của danh mục `COMMON` phát trên topic `common.rdm.*`; sự kiện của HYBRID phát trên topic của tenant …

  @US-07-048 @FR-07-048 @M @âm
  Kịch bản: US-07-048 âm 1 · Tenant tỉnh ghi danh mục `COMMON`
    Biết danh mục `COMMON` `ACTIVE` (để mở rộng)
    Khi tenant tỉnh ghi danh mục `COMMON`
    Thì hệ thống từ chối với ERR-07-003 (403)
    Và người dùng thấy thông báo "Danh mục này chỉ đọc với tỉnh của bạn. Danh mục quốc gia chỉ cập nhật qua đồng bộ; danh mục dùng chung chỉ quản trị nền tảng sửa. Muốn bổ sung bản ghi địa phương, hãy tạo danh mục mở rộng."

  @US-07-048 @FR-07-048 @M @âm
  Kịch bản: US-07-048 âm 2 · Mã danh mục trùng `COMMON`
    Biết danh mục `COMMON` `ACTIVE` (để mở rộng)
    Khi mã danh mục trùng `COMMON`
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "Mã danh mục"

  @US-07-049 @FR-07-049 @M
  Kịch bản: US-07-049 dương · Nạp gói danh mục nền khi khởi tạo tenant
    Biết tenant đã được PH-20 tạo, ở trạng thái khởi tạo; gói nền phiên bản `packageVersion` đã được nền tảng phát hành (tệp gói ở kho đối tượng của `PLATFORM`)
    Khi PH-20 gọi API-07-073 khi khởi tạo tenant mới; PA chạy lại khi nền tảng phát hành gói nền mới
    Thì API-07-073: `200` với `packageVersion`, `status` ∈ `COMPLETED`, `PARTIAL`, `catalogs[]` (mã, phiên bản, số bản ghi, kết quả), `parameters[]` (khóa đã ghi), `commonAvailable[]` (danh mục `COMMON` bắt buộc đọc được), `warnings[]`
    Và tham số mặc định `07.rdm.*` của tenant được ghi ở PH-18; nhóm danh mục mặc định được tạo …
    Và sự kiện được phát: EVT-07-01 và EVT-07-05 cho từng danh mục được tạo

  @US-07-049 @FR-07-049 @M @âm
  Kịch bản: US-07-049 âm 1 · Chủ thể không phải PH-20 hoặc PA
    Biết tenant đã được PH-20 tạo, ở trạng thái khởi tạo; gói nền phiên bản `packageVersion` đã được nền tảng phát hành (tệp gói ở kho đối tượng của `PLATFORM`)
    Khi chủ thể không phải PH-20 hoặc PA
    Thì hệ thống từ chối với ERR-07-046 (403)

  @US-07-049 @FR-07-049 @M @âm
  Kịch bản: US-07-049 âm 2 · Tenant không tồn tại
    Biết tenant đã được PH-20 tạo, ở trạng thái khởi tạo; gói nền phiên bản `packageVersion` đã được nền tảng phát hành (tệp gói ở kho đối tượng của `PLATFORM`)
    Khi tenant không tồn tại
    Thì hệ thống từ chối với ERR-07-045 (404)

  @US-07-050 @FR-07-050 @M
  Kịch bản: US-07-050 dương · Lịch sử thay đổi và kiểm toán
    Biết danh mục tồn tại (kể cả `RETIRED` và đã xóa mềm trong 30 ngày, với AU)
    Khi người dùng mở tab "Lịch sử" ở UI-07-02; kiểm toán viên lọc và xuất bằng chứng
    Thì API-07-072: trang con trỏ các mục lịch sử, mỗi mục gồm `occurredAt`, `actor` (tên hiển thị, loại người, máy hoặc hệ thống), `action` (mã hành động `RDM_*`), `objectType`, `objectRef` (mã danh mục, số phiên bản, mã bản ghi, mã tác vụ) …

  @US-07-050 @FR-07-050 @M @âm
  Kịch bản: US-07-050 âm 1 · Khoảng thời gian vượt 3 năm, `from` sau `to`
    Biết danh mục tồn tại (kể cả `RETIRED` và đã xóa mềm trong 30 ngày, với AU)
    Khi khoảng thời gian vượt 3 năm, `from` sau `to`
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-050 @FR-07-050 @M @âm
  Kịch bản: US-07-050 âm 2 · PH-13 không sẵn sàng
    Biết danh mục tồn tại (kể cả `RETIRED` và đã xóa mềm trong 30 ngày, với AU)
    Khi PH-13 không sẵn sàng
    Thì hệ thống từ chối với ERR-07-047 (503)

  @US-07-051 @FR-07-051 @M
  Kịch bản: US-07-051 dương · Di trú dữ liệu danh mục từ hệ cũ Aita
    Biết bản kết xuất CSDL Aita (MySQL) hoặc kết nối chỉ đọc tới bản sao, đã đưa vào vùng di trú của tenant; tenant đã nạp gói nền (FR-07-049)
    Khi TA chạy công cụ di trú với bản xuất CSDL Aita, rà soát kết quả ở UI-07-06
    Thì báo cáo chạy thử (mỗi danh mục Aita một dòng: đề xuất, lược đồ, số dòng, vấn đề); khi chạy thật: danh mục Datahub với `legacy_ref`, bản ghi với `legacy_ref`, thuộc tính với `legacy_field_id`; biên bản đối soát PDF và Excel
    Và mỗi danh mục Aita được xử lý theo đúng một quyết định: tạo mới `LOCAL`, dùng `COMMON` kèm ánh xạ, tạo HYBRID cho phần bổ sung, đăng ký đồng bộ quốc gia, hoặc bỏ qua có lý do; phiên bản 1 của danh mục tạo mới có `origin = MIGRATION` …
    Và sự kiện được phát: Như các API được gọi (EVT-07-01, 04, 05)

  @US-07-051 @FR-07-051 @M @âm
  Kịch bản: US-07-051 âm 1 · Bản kết xuất hỏng, thiếu bảng hoặc cột
    Biết bản kết xuất CSDL Aita (MySQL) hoặc kết nối chỉ đọc tới bản sao, đã đưa vào vùng di trú của tenant; tenant đã nạp gói nền (FR-07-049)
    Khi bản kết xuất hỏng, thiếu bảng hoặc cột
    Thì không có mã riêng; công cụ dừng, báo cáo lỗi, không gọi API

  @US-07-051 @FR-07-051 @M @âm
  Kịch bản: US-07-051 âm 2 · Mã danh mục trùng
    Biết bản kết xuất CSDL Aita (MySQL) hoặc kết nối chỉ đọc tới bản sao, đã đưa vào vùng di trú của tenant; tenant đã nạp gói nền (FR-07-049)
    Khi mã danh mục trùng
    Thì hệ thống từ chối với ERR-07-002 (409)
    Và người dùng thấy thông báo "Mã danh mục"

  @US-07-052 @FR-07-052 @M
  Kịch bản: US-07-052 dương · Khai thác danh mục hạn chế và cấp quyền khai thác
    Biết danh mục tồn tại; cấp quyền chỉ có ý nghĩa với danh mục `RESTRICTED` (với mức khác, API chấp nhận nhưng cảnh báo "không có tác dụng")
    Khi TA mở tab "Quyền khai thác" ở UI-07-02 của danh mục `RESTRICTED`, thêm hoặc bỏ HTTT rồi bấm "Lưu"
    Thì API-07-075 GET: danh sách cấp quyền (`memberSystemId`, tên HTTT tra PH-01, `scopes`, `grantedBy`, `grantedAt`, `expiresAt`)
    Và `catalog_access_grant` (EN-07-15) phản ánh đúng danh sách gửi lên; bộ đệm quyền khai thác của danh mục bị vô hiệu ở mọi pod trong ≤ 10 giây

  @US-07-052 @FR-07-052 @M @âm
  Kịch bản: US-07-052 âm 1 · HTTT chưa được cấp quyền khai thác
    Biết danh mục tồn tại; cấp quyền chỉ có ý nghĩa với danh mục `RESTRICTED` (với mức khác, API chấp nhận nhưng cảnh báo "không có tác dụng")
    Khi HTTT chưa được cấp quyền khai thác
    Thì hệ thống từ chối với ERR-07-030 (403)
    Và người dùng thấy thông báo "Hệ thống thông tin chưa được cấp quyền khai thác danh mục hạn chế này. Cấp quyền ở tab"

  @US-07-052 @FR-07-052 @M @âm
  Kịch bản: US-07-052 âm 2 · HTTT không tồn tại, không `ACTIVE`, trùng trong danh sách, scope sai
    Biết danh mục tồn tại; cấp quyền chỉ có ý nghĩa với danh mục `RESTRICTED` (với mức khác, API chấp nhận nhưng cảnh báo "không có tác dụng")
    Khi HTTT không tồn tại, không `ACTIVE`, trùng trong danh sách, scope sai
    Thì hệ thống từ chối với ERR-07-009 (422)
    Và người dùng thấy thông báo "Có {count} giá trị không hợp lệ. Xem lỗi tại từng trường được tô đỏ."

  @US-07-053 @FR-07-053 @S
  Kịch bản: US-07-053 dương · Tham số PH-07 theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi TA mở UI-07-13 "Tham số PH-07", sửa giá trị rồi bấm "Lưu"
    Thì giá trị hiệu lực của từng khóa `07.rdm.*` cho tenant (giá trị tenant nếu có, nếu không là mặc định nền tảng)
    Và giá trị được lưu ở PH-18; các pod PH-07 nhận sự kiện thay đổi tham số của PH-18 và áp dụng trong ≤ 60 giây mà không cần khởi động lại
    Và sự kiện được phát: Sự kiện thay đổi tham số do PH-18 phát
