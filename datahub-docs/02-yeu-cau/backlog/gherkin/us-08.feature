# language: vi
# Sinh tự động từ D02-02/D02-03-PH08 bằng backlog/tools/sinh_backlog.py; không sửa tay.
@PH-08
Tính năng: PH-08 · Chất lượng dữ liệu

  # ---- EP-08-A · Miền và đối tượng đo

  @US-08-001 @FR-08-001 @M
  Kịch bản: US-08-001 dương · Khai báo miền chất lượng, chủ quản, cán bộ phụ trách
    Biết tổ chức chủ quản tồn tại ở PH-20 (DD-02) và ở trạng thái hoạt động; cán bộ phụ trách là người dùng của tenant có vai trò DS
    Khi bấm "+ Miền chất lượng" ở UI-08-19 tab "Miền", hoặc sửa một miền có sẵn
    Thì hệ thống trả `201` (tạo) hoặc `200` (sửa); `domainCode`, `name`, `ownerOrgId`, `ownerOrgName`, `stewardUserId`, `status`, `assetCount`, `ETag`; tiêu đề `Location`
    Và miền `ACTIVE` hoặc `INACTIVE`; không đổi đối tượng đo, phiếu hiện có
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-001 @FR-08-001 @M @âm
  Kịch bản: US-08-001 âm 1 · Mã đã dùng
    Biết tổ chức chủ quản tồn tại ở PH-20 (DD-02) và ở trạng thái hoạt động; cán bộ phụ trách là người dùng của tenant có vai trò DS
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-08-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-08-001 @FR-08-001 @M @âm
  Kịch bản: US-08-001 âm 2 · Mã sai mẫu
    Biết tổ chức chủ quản tồn tại ở PH-20 (DD-02) và ở trạng thái hoạt động; cán bộ phụ trách là người dùng của tenant có vai trò DS
    Khi mã sai mẫu
    Thì hệ thống từ chối với ERR-08-003 (400)
    Và người dùng thấy thông báo "Mã miền chỉ gồm chữ in hoa, số và gạch dưới, 3 đến 32 ký tự."

  @US-08-002 @FR-08-002 @M
  Kịch bản: US-08-002 dương · Đăng ký đối tượng đo từ domain PH-06
    Biết miền `ACTIVE` (FR-08-001); domain PH-06 ở `ACTIVE` và đã có khung nhìn hợp đồng `ph06_mdm.v_dq_{domain}` cấp cho vai trò `dq_reader`
    Khi wizard UI-08-03, chọn loại "Domain dữ liệu chủ"
    Thì hệ thống trả `201`; `assetCode`, `assetType`, `status`, `fields[]`, `recordKey`; `Location`, `ETag`
    Và đối tượng đo `DRAFT` hoặc `ACTIVE`; không có thay đổi ở PH-06
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-002 @FR-08-002 @M @âm
  Kịch bản: US-08-002 âm 1 · Domain không `ACTIVE` hoặc chưa có khung nhìn hợp đồng
    Biết miền `ACTIVE` (FR-08-001); domain PH-06 ở `ACTIVE` và đã có khung nhìn hợp đồng `ph06_mdm.v_dq_{domain}` cấp cho vai trò `dq_reader`
    Khi domain không `ACTIVE` hoặc chưa có khung nhìn hợp đồng
    Thì hệ thống từ chối với ERR-08-009 (422)
    Và người dùng thấy thông báo "Domain {mã} chưa sẵn sàng cho đo chất lượng. Đề nghị PH-06 cấp khung nhìn hợp đồng."

  @US-08-002 @FR-08-002 @M @âm
  Kịch bản: US-08-002 âm 2 · Mã đã dùng
    Biết miền `ACTIVE` (FR-08-001); domain PH-06 ở `ACTIVE` và đã có khung nhìn hợp đồng `ph06_mdm.v_dq_{domain}` cấp cho vai trò `dq_reader`
    Khi mã đã dùng
    Thì hệ thống từ chối với ERR-08-002 (409)
    Và người dùng thấy thông báo "Mã {mã} đã được dùng. Chọn mã khác."

  @US-08-003 @FR-08-003 @M
  Kịch bản: US-08-003 dương · Đăng ký đối tượng đo từ danh mục PH-07
    Biết miền `ACTIVE`; danh mục PH-07 tồn tại, có ít nhất một phiên bản đã phát hành, người dùng có quyền đọc danh mục (danh mục hạn chế cần quyền khai thác theo FR-07-052)
    Khi wizard UI-08-03, chọn loại "Danh mục dùng chung"
    Thì hệ thống trả `201`; như FR-08-002, `sourceRef = {catalogCode, versionPolicy, versionNo}`
    Và đối tượng đo `DRAFT` hoặc `ACTIVE`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-003 @FR-08-003 @M @âm
  Kịch bản: US-08-003 âm 1 · Danh mục không tồn tại hoặc chưa phát hành
    Biết miền `ACTIVE`; danh mục PH-07 tồn tại, có ít nhất một phiên bản đã phát hành, người dùng có quyền đọc danh mục (danh mục hạn chế cần quyền khai thác theo FR-07-052)
    Khi danh mục không tồn tại hoặc chưa phát hành
    Thì hệ thống từ chối với ERR-08-010 (422)
    Và người dùng thấy thông báo "Danh mục {mã} chưa phát hành ở PH-07."

  @US-08-003 @FR-08-003 @M @âm
  Kịch bản: US-08-003 âm 2 · Danh mục hạn chế chưa được cấp quyền khai thác
    Biết miền `ACTIVE`; danh mục PH-07 tồn tại, có ít nhất một phiên bản đã phát hành, người dùng có quyền đọc danh mục (danh mục hạn chế cần quyền khai thác theo FR-07-052)
    Khi danh mục hạn chế chưa được cấp quyền khai thác
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Anh/chị chưa có quyền khai thác danh mục {mã}."

  @US-08-004 @FR-08-004 @S
  Kịch bản: US-08-004 dương · Đăng ký đối tượng đo nguồn qua kết nối PH-05 chỉ đọc
    Biết kết nối PH-05 loại CSDL ở `ACTIVE`, cờ `readOnly = true`, có cấp sử dụng cho `dh-data/dq`; tài khoản kết nối chỉ có quyền `SELECT`
    Khi wizard UI-08-03, chọn loại "Bảng của HTTT"
    Thì hệ thống trả `201`; `assetCode`, `sourceRef = {connectionCode, schema, table}`, `recordKey[]`, `updatedAtField`, `scanWindow`
    Và đối tượng đo `DRAFT` hoặc `ACTIVE`; PH-08 không lưu thông tin đăng nhập kết nối (bí mật ở OpenBao, ADR-012)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-004 @FR-08-004 @S @âm
  Kịch bản: US-08-004 âm 1 · Kết nối không đủ điều kiện
    Biết kết nối PH-05 loại CSDL ở `ACTIVE`, cờ `readOnly = true`, có cấp sử dụng cho `dh-data/dq`; tài khoản kết nối chỉ có quyền `SELECT`
    Khi kết nối không đủ điều kiện
    Thì hệ thống từ chối với ERR-08-011 (422)
    Và người dùng thấy thông báo "Kết nối {mã} không phải kết nối chỉ đọc được cấp cho chất lượng dữ liệu."

  @US-08-005 @FR-08-005 @M
  Kịch bản: US-08-005 dương · Khai báo phần tử dữ liệu trọng yếu, lấy phân loại PH-09
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`
    Khi bước 4 wizard UI-08-03; tab "Trường, CDE" ở UI-08-04
    Thì hệ thống trả `200`; `fields[]` gồm `fieldPath`, `isCde`, `dataClass`, `classificationStatus`, `valueMode`; `cdeCoverage`
    Và EN-08-03 cập nhật; bản ghi lỗi sau dùng chế độ che mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-005 @FR-08-005 @M @âm
  Kịch bản: US-08-005 âm 1 · Trường không thuộc lược đồ
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`
    Khi trường không thuộc lược đồ
    Thì hệ thống từ chối với ERR-08-014 (422)
    Và người dùng thấy thông báo "Trường {đường dẫn} không có trong đối tượng đo {mã}."

  @US-08-005 @FR-08-005 @M @âm
  Kịch bản: US-08-005 âm 2 · Đặt che lỏng hơn phân loại
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`
    Khi đặt che lỏng hơn phân loại
    Thì hệ thống từ chối với ERR-08-003 (400)
    Và người dùng thấy thông báo "Trường {đường dẫn} mức {phân loại} phải che ít nhất ở chế độ {chế độ}."

  @US-08-006 @FR-08-006 @M
  Kịch bản: US-08-006 dương · Liệt kê, tìm, xem đối tượng đo
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi mở UI-08-02; bấm một dòng mở UI-08-04
    Thì hệ thống trả `200`; `items[]` (`assetCode`, `name`, `assetType`, `domainCode`, `status`, `score`, `verdict`, `trend`, `lastScanAt`, `openFindings{CRITICAL,MAJOR,MINOR}`, `cdeCoverage`), `page`, `totalElements`, `facets`; chi tiết có `ETag`

  @US-08-006 @FR-08-006 @M @âm
  Kịch bản: US-08-006 âm 1 · Không tìm thấy hoặc thuộc tenant khác
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi không tìm thấy hoặc thuộc tenant khác
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy {đối tượng} {mã} trong tỉnh đang làm việc."

  @US-08-006 @FR-08-006 @M @âm
  Kịch bản: US-08-006 âm 2 · DO xem đối tượng của tổ chức khác
    Biết người dùng đã đăng nhập và chọn tenant (FR-00-004)
    Khi DO xem đối tượng của tổ chức khác
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Đối tượng {mã} không thuộc tổ chức của anh/chị."

  @US-08-007 @FR-08-007 @M
  Kịch bản: US-08-007 dương · Ngừng, khôi phục đối tượng đo
    Biết đối tượng `ACTIVE` (tạm ngừng, ngừng) hoặc `SUSPENDED` (khôi phục, ngừng)
    Khi nút "Tạm ngừng", "Khôi phục", "Ngừng" ở UI-08-04; tự động khi PH-06 ngừng domain hoặc PH-05 thu hồi kết nối
    Thì hệ thống trả `200`; `assetCode`, `status`, `cancelledScans[]`, `affectedIssues`
    Và `SUSPENDED` hoặc `RETIRED`; dữ liệu đo theo chính sách lưu giữ (FR-08-059)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-007 @FR-08-007 @M @âm
  Kịch bản: US-08-007 âm 1 · Thiếu lý do
    Biết đối tượng `ACTIVE` (tạm ngừng, ngừng) hoặc `SUSPENDED` (khôi phục, ngừng)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-08-007 (422)
    Và người dùng thấy thông báo "Nhập lý do (tối thiểu 20 ký tự)."

  @US-08-007 @FR-08-007 @M @âm
  Kịch bản: US-08-007 âm 2 · Trạng thái không cho thao tác
    Biết đối tượng `ACTIVE` (tạm ngừng, ngừng) hoặc `SUSPENDED` (khôi phục, ngừng)
    Khi trạng thái không cho thao tác
    Thì hệ thống từ chối với ERR-08-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi đối tượng đang ở trạng thái {trạng thái}."

  # ---- EP-08-B · Hồ sơ dữ liệu

  @US-08-008 @FR-08-008 @S
  Kịch bản: US-08-008 dương · Chạy hồ sơ dữ liệu
    Biết đối tượng `DRAFT` hoặc `ACTIVE`, loại khác `FLOW_MESSAGE`; không có lần hồ sơ `RUNNING` cùng đối tượng
    Khi nút "Chạy hồ sơ" ở UI-08-05; tự chạy một lần khi kích hoạt đối tượng mới (tham số `08.profile.on-activate`, mặc định bật)
    Thì hệ thống trả `202`; `runId`, `status = QUEUED`; `Location` tới API-08-021
    Và lần hồ sơ `SUCCEEDED` hoặc `FAILED`; không đổi điểm
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-008 @FR-08-008 @S @âm
  Kịch bản: US-08-008 âm 1 · Loại đối tượng không hỗ trợ
    Biết đối tượng `DRAFT` hoặc `ACTIVE`, loại khác `FLOW_MESSAGE`; không có lần hồ sơ `RUNNING` cùng đối tượng
    Khi loại đối tượng không hỗ trợ
    Thì hệ thống từ chối với ERR-08-050 (422)
    Và người dùng thấy thông báo "Đối tượng loại bản tin trên luồng không chạy hồ sơ hoặc đo theo lô."

  @US-08-009 @FR-08-009 @S
  Kịch bản: US-08-009 dương · Xem hồ sơ dữ liệu theo cột
    Biết có ít nhất một lần hồ sơ `SUCCEEDED` hoặc chỉ số từ PH-05 (FR-08-011)
    Khi mở UI-08-05
    Thì hệ thống trả `200`; `columns[]` (`fieldPath`, `nullRatio`, `distinctEstimate`, `min`, `max`, `quantiles`, `topPatterns`, `topValues` khi được phép, `inferredType`, `warnings[]`), `diff[]`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-009 @FR-08-009 @S @âm
  Kịch bản: US-08-009 âm 1 · Chưa có hồ sơ
    Biết có ít nhất một lần hồ sơ `SUCCEEDED` hoặc chỉ số từ PH-05 (FR-08-011)
    Khi chưa có hồ sơ
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Chưa có hồ sơ dữ liệu cho đối tượng {mã}. Bấm Chạy hồ sơ."

  @US-08-010 @FR-08-010 @C
  Kịch bản: US-08-010 dương · Gợi ý quy tắc từ hồ sơ
    Biết lần hồ sơ `SUCCEEDED`; bộ quy tắc của đối tượng có phiên bản `DRAFT` hoặc tạo mới
    Khi nút "Gợi ý quy tắc" ở UI-08-05
    Thì hệ thống trả `200`; `suggestions[]` (`dimension`, `operator`, `target`, `params`, `confidence`, `evidence`); sau khi thêm, `ruleCodes[]`
    Và quy tắc mới ở phiên bản `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-010 @FR-08-010 @C @âm
  Kịch bản: US-08-010 âm 1 · Bộ quy tắc đang có nháp của người khác
    Biết lần hồ sơ `SUCCEEDED`; bộ quy tắc của đối tượng có phiên bản `DRAFT` hoặc tạo mới
    Khi bộ quy tắc đang có nháp của người khác
    Thì hệ thống từ chối với ERR-08-022 (409)
    Và người dùng thấy thông báo "Bộ quy tắc {mã} đang có bản nháp phiên bản {n} do {người} tạo."

  @US-08-011 @FR-08-011 @C
  Kịch bản: US-08-011 dương · Nhận chỉ số hồ sơ từ PH-05
    Biết bộ điều hợp PH-05 gắn với một đối tượng đo (`sourceRef.connectionCode` hoặc `adapterCode`)
    Khi PH-05 gửi lô chỉ số mỗi giờ
    Thì hệ thống trả `202`; `accepted`, `ignored`
    Và EN-08-05 có thêm thống kê nguồn `EXTERNAL`

  @US-08-011 @FR-08-011 @C @âm
  Kịch bản: US-08-011 âm 1 · Lô sai định dạng
    Biết bộ điều hợp PH-05 gắn với một đối tượng đo (`sourceRef.connectionCode` hoặc `adapterCode`)
    Khi lô sai định dạng
    Thì hệ thống từ chối với ERR-08-118
    Và người dùng thấy thông báo "Lô chỉ số hồ sơ từ {bộ điều hợp} sai định dạng: {chi tiết}."

  # ---- EP-08-C · Quy tắc

  @US-08-012 @FR-08-012 @M
  Kịch bản: US-08-012 dương · Tạo bộ quy tắc phiên bản nháp
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`; bộ quy tắc chưa có bản nháp đang mở
    Khi "+ Bộ quy tắc" ở UI-08-06 (đối tượng chưa có bộ); "Tạo bản nháp" ở UI-08-07 (từ phiên bản `ACTIVE`)
    Thì hệ thống trả `201`; `ruleSetCode`, `version`, `status = DRAFT`, `ruleCount`, `ETag`
    Và phiên bản `ACTIVE` không đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-012 @FR-08-012 @M @âm
  Kịch bản: US-08-012 âm 1 · Đã có bản nháp
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`; bộ quy tắc chưa có bản nháp đang mở
    Khi đã có bản nháp
    Thì hệ thống từ chối với ERR-08-022 (409)
    Và người dùng thấy thông báo "Bộ quy tắc {mã} đang có bản nháp phiên bản {n} do {người} tạo."

  @US-08-012 @FR-08-012 @M @âm
  Kịch bản: US-08-012 âm 2 · Đối tượng đã có bộ quy tắc
    Biết đối tượng đo `DRAFT` hoặc `ACTIVE`; bộ quy tắc chưa có bản nháp đang mở
    Khi đối tượng đã có bộ quy tắc
    Thì hệ thống từ chối với ERR-08-002 (409)
    Và người dùng thấy thông báo "Đối tượng {mã} đã có bộ quy tắc {mã bộ}."

  @US-08-013 @FR-08-013 @M
  Kịch bản: US-08-013 dương · Định nghĩa quy tắc theo chiều và toán tử
    Biết phiên bản `DRAFT` của bộ quy tắc
    Khi "+ Quy tắc" ở UI-08-07, mở ngăn kéo UI-08-08
    Thì hệ thống trả `201` hoặc `200`; quy tắc đầy đủ, `ETag` của phiên bản
    Và phiên bản `DRAFT` có thêm hoặc sửa quy tắc; dấu chạy thử cũ bị vô hiệu (BR-08-006)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-013 @FR-08-013 @M @âm
  Kịch bản: US-08-013 âm 1 · Toán tử không thuộc chiều
    Biết phiên bản `DRAFT` của bộ quy tắc
    Khi toán tử không thuộc chiều
    Thì hệ thống từ chối với ERR-08-015 (422)
    Và người dùng thấy thông báo "Toán tử {toán tử} không dùng được cho chiều {chiều}."

  @US-08-013 @FR-08-013 @M @âm
  Kịch bản: US-08-013 âm 2 · Tham số sai
    Biết phiên bản `DRAFT` của bộ quy tắc
    Khi tham số sai
    Thì hệ thống từ chối với ERR-08-016 (422)
    Và người dùng thấy thông báo "Tham số {tên} của quy tắc {mã} không hợp lệ: {chi tiết}."

  @US-08-014 @FR-08-014 @S
  Kịch bản: US-08-014 dương · Quy tắc biểu thức CEL và vị từ SQL có kiểm soát
    Biết phiên bản `DRAFT`
    Khi chọn toán tử `CEL_EXPRESSION` hoặc `SQL_PREDICATE` ở UI-08-08; nút "Kiểm tra biểu thức"
    Thì hệ thống trả `200` (kiểm tra) hoặc `201`; `normalizedExpression`, `estimatedCost`, `execMode` cho phép
    Và như FR-08-013
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-014 @FR-08-014 @S @âm
  Kịch bản: US-08-014 âm 1 · CEL lỗi
    Biết phiên bản `DRAFT`
    Khi CEL lỗi
    Thì hệ thống từ chối với ERR-08-019 (422)
    Và người dùng thấy thông báo "Biểu thức không hợp lệ ở vị trí {dòng}:{cột}: {chi tiết}."

  @US-08-015 @FR-08-015 @S
  Kịch bản: US-08-015 dương · Thư viện quy tắc mẫu ở COMMON
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi tab "Thư viện mẫu" ở UI-08-06; nút "Từ mẫu" trong UI-08-08
    Thì hệ thống trả `200` (danh sách), `201` (mẫu mới hoặc phiên bản mẫu mới)
    Và mẫu có phiên bản; quy tắc giữ tham chiếu phiên bản mẫu
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-015 @FR-08-015 @S @âm
  Kịch bản: US-08-015 âm 1 · Tenant sửa mẫu `COMMON`
    Biết người dùng đã đăng nhập với vai trò quản trị nền tảng
    Khi tenant sửa mẫu `COMMON`
    Thì hệ thống từ chối với ERR-00-403 (403)
    Và người dùng thấy thông báo "Anh/chị không có quyền sửa mẫu dùng chung toàn quốc."

  @US-08-016 @FR-08-016 @M
  Kịch bản: US-08-016 dương · Chạy thử quy tắc trên mẫu
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đối tượng có nguồn khả dụng
    Khi nút "Chạy thử" ở UI-08-08 (một quy tắc) hoặc UI-08-07 (cả phiên bản)
    Thì hệ thống trả `200`; `dryRunId`, `sampleSeed`, `results[]` (`ruleCode`, `passCount`, `failCount`, `errorCount`, `examples[]`, `durationMs`), `estimatedScores`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-016 @FR-08-016 @M @âm
  Kịch bản: US-08-016 âm 1 · Vượt giới hạn
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đối tượng có nguồn khả dụng
    Khi vượt giới hạn
    Thì hệ thống từ chối với ERR-08-031 (422)
    Và người dùng thấy thông báo "Chạy thử tối đa {n} bản ghi. Giảm kích thước mẫu."

  @US-08-016 @FR-08-016 @M @âm
  Kịch bản: US-08-016 âm 2 · Nguồn không khả dụng
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đối tượng có nguồn khả dụng
    Khi nguồn không khả dụng
    Thì hệ thống từ chối với ERR-08-105 (503)
    Và người dùng thấy thông báo "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau."

  @US-08-017 @FR-08-017 @M
  Kịch bản: US-08-017 dương · Gửi duyệt, duyệt, từ chối bộ quy tắc
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đã chạy thử trên nội dung hiện tại
    Khi nút "Gửi duyệt" ở UI-08-07; việc trong "Việc của tôi" (FR-00-070) cho DA
    Thì hệ thống trả `200`; `version`, `status`, `approvedBy`, `effectiveFrom`
    Và phiên bản `ACTIVE`, `APPROVED` hoặc `DRAFT`
    Và sự kiện được phát: EVT-08-01 khi phiên bản thành `ACTIVE` (qua FR-08-018)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-017 @FR-08-017 @M @âm
  Kịch bản: US-08-017 âm 1 · Bộ trống
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đã chạy thử trên nội dung hiện tại
    Khi bộ trống
    Thì hệ thống từ chối với ERR-08-021 (422)
    Và người dùng thấy thông báo "Phiên bản {n} chưa có quy tắc nào đang bật."

  @US-08-017 @FR-08-017 @M @âm
  Kịch bản: US-08-017 âm 2 · Chưa chạy thử nội dung hiện tại
    Biết phiên bản `DRAFT` có ít nhất một quy tắc bật; đã chạy thử trên nội dung hiện tại
    Khi chưa chạy thử nội dung hiện tại
    Thì hệ thống từ chối với ERR-08-053 (422)
    Và người dùng thấy thông báo "Chạy thử phiên bản sau lần sửa cuối trước khi gửi duyệt."

  @US-08-018 @FR-08-018 @M
  Kịch bản: US-08-018 dương · Kích hoạt, thay thế, ngừng phiên bản bộ quy tắc
    Biết phiên bản `APPROVED` (kích hoạt) hoặc bộ có phiên bản `ACTIVE` (ngừng)
    Khi tới `effectiveFrom`; nút "Kích hoạt ngay" hoặc "Ngừng bộ quy tắc" ở UI-08-09
    Thì hệ thống trả `200`; `activeVersion`, `supersededVersion`
    Và đúng một phiên bản `ACTIVE` (hoặc không có khi ngừng)
    Và sự kiện được phát: EVT-08-01
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-018 @FR-08-018 @M @âm
  Kịch bản: US-08-018 âm 1 · Trạng thái không đúng
    Biết phiên bản `APPROVED` (kích hoạt) hoặc bộ có phiên bản `ACTIVE` (ngừng)
    Khi trạng thái không đúng
    Thì hệ thống từ chối với ERR-08-006 (409)
    Và người dùng thấy thông báo "Không thể kích hoạt khi phiên bản đang ở trạng thái {trạng thái}."

  @US-08-018 @FR-08-018 @M @âm
  Kịch bản: US-08-018 âm 2 · Ngừng thiếu lý do
    Biết phiên bản `APPROVED` (kích hoạt) hoặc bộ có phiên bản `ACTIVE` (ngừng)
    Khi ngừng thiếu lý do
    Thì hệ thống từ chối với ERR-08-007 (422)
    Và người dùng thấy thông báo "Nhập lý do (tối thiểu 20 ký tự)."

  @US-08-019 @FR-08-019 @S
  Kịch bản: US-08-019 dương · So sánh phiên bản, xem lịch sử
    Biết bộ quy tắc có ít nhất một phiên bản
    Khi mở UI-08-09; chọn hai phiên bản
    Thì hệ thống trả `200`; `changes[]` (`ruleCode`, `changeType`, `before`, `after`), `history[]`

  @US-08-019 @FR-08-019 @S @âm
  Kịch bản: US-08-019 âm 1 · Phiên bản không có
    Biết bộ quy tắc có ít nhất một phiên bản
    Khi phiên bản không có
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy phiên bản {n} của bộ quy tắc {mã}."

  @US-08-020 @FR-08-020 @S
  Kịch bản: US-08-020 dương · Sao chép, nhập, xuất bộ quy tắc YAML, JSON
    Biết đối tượng đích có bộ quy tắc không có bản nháp đang mở
    Khi menu "Sao chép", "Xuất", "Nhập" ở UI-08-06
    Thì hệ thống trả `201` (sao chép, nhập) kèm `version`, `rulesNeedingReview[]`; `200` tệp (xuất)
    Và phiên bản `DRAFT` mới ở đối tượng đích
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-020 @FR-08-020 @S @âm
  Kịch bản: US-08-020 âm 1 · Không tương thích
    Biết đối tượng đích có bộ quy tắc không có bản nháp đang mở
    Khi không tương thích
    Thì hệ thống từ chối với ERR-08-026 (422)
    Và người dùng thấy thông báo "Đối tượng đích thiếu trường {danh sách}. Khai báo ánh xạ trường trước khi sao chép."

  @US-08-021 @FR-08-021 @M
  Kịch bản: US-08-021 dương · Cấu hình trọng số và ngưỡng có phiên bản, có duyệt
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi mở UI-08-10, chọn phạm vi, "Tạo bản nháp"
    Thì hệ thống trả `201`, `200`; `configId`, `scope`, `weights{}`, `passMin`, `warnMin`, `status`, `effectiveFrom`
    Và một cấu hình `ACTIVE` mỗi phạm vi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-021 @FR-08-021 @M @âm
  Kịch bản: US-08-021 âm 1 · Tổng trọng số sai
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi tổng trọng số sai
    Thì hệ thống từ chối với ERR-08-023 (422)
    Và người dùng thấy thông báo "Tổng trọng số sáu chiều phải bằng 1 (hiện là {tổng})."

  @US-08-021 @FR-08-021 @M @âm
  Kịch bản: US-08-021 âm 2 · Ngưỡng sai
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi ngưỡng sai
    Thì hệ thống từ chối với ERR-08-024 (422)
    Và người dùng thấy thông báo "Ngưỡng cảnh báo phải nhỏ hơn hoặc bằng ngưỡng đạt và trong khoảng 0 đến 100."

  @US-08-022 @FR-08-022 @M
  Kịch bản: US-08-022 dương · Liệt kê, tìm quy tắc
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi mở UI-08-06 tab "Quy tắc"
    Thì hệ thống trả `200`; `items[]` (`ruleCode`, `assetCode`, `dimension`, `operator`, `severity`, `execMode`, `lastFailRate`, `templateRef`), `facets`

  @US-08-022 @FR-08-022 @M @âm
  Kịch bản: US-08-022 âm 1 · Tham số sai
    Biết người dùng đã đăng nhập với vai trò người dùng có quyền xem
    Khi tham số sai
    Thì hệ thống từ chối với ERR-08-045 (422)
    Và người dùng thấy thông báo "Tham số {tên} không hợp lệ: {chi tiết}."

  # ---- EP-08-D · Lịch và đo theo lô

  @US-08-023 @FR-08-023 @M
  Kịch bản: US-08-023 dương · Lập lịch đo
    Biết đối tượng (hoặc mọi đối tượng của miền) `ACTIVE`, có bộ quy tắc `ACTIVE`
    Khi "+ Lịch đo" ở UI-08-11; khi kích hoạt đối tượng mới, hệ thống tự tạo lịch theo `08.scan.default-cron`
    Thì hệ thống trả `201`; `scheduleId`, `cron`, `nextFireAt`, `status`
    Và lịch `ACTIVE` hoặc `PAUSED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-023 @FR-08-023 @M @âm
  Kịch bản: US-08-023 âm 1 · Cron sai hoặc quá dày
    Biết đối tượng (hoặc mọi đối tượng của miền) `ACTIVE`, có bộ quy tắc `ACTIVE`
    Khi cron sai hoặc quá dày
    Thì hệ thống từ chối với ERR-08-029 (422)
    Và người dùng thấy thông báo "Lịch {biểu thức} không hợp lệ hoặc dày hơn mức cho phép ({n} giờ một lần)."

  @US-08-023 @FR-08-023 @M @âm
  Kịch bản: US-08-023 âm 2 · Lịch trùng
    Biết đối tượng (hoặc mọi đối tượng của miền) `ACTIVE`, có bộ quy tắc `ACTIVE`
    Khi lịch trùng
    Thì hệ thống từ chối với ERR-08-049 (409)
    Và người dùng thấy thông báo "Đối tượng {mã} đã có lịch {chế độ} {biểu thức}."

  @US-08-024 @FR-08-024 @M
  Kịch bản: US-08-024 dương · Chạy đo theo yêu cầu
    Biết đối tượng `ACTIVE`, có bộ quy tắc `ACTIVE`; loại khác `FLOW_MESSAGE`
    Khi nút "Đo ngay" ở UI-08-04 hoặc UI-08-11
    Thì hệ thống trả `202`; `scanId`, `status = QUEUED`, `estimatedRows`, `position` (thứ tự hàng đợi); `Location`
    Và lần đo `QUEUED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-024 @FR-08-024 @M @âm
  Kịch bản: US-08-024 âm 1 · Không có bộ quy tắc hoặc trọng số
    Biết đối tượng `ACTIVE`, có bộ quy tắc `ACTIVE`; loại khác `FLOW_MESSAGE`
    Khi không có bộ quy tắc hoặc trọng số
    Thì hệ thống từ chối với ERR-08-027 (422)
    Và người dùng thấy thông báo "Đối tượng {mã} chưa có bộ quy tắc đang hiệu lực."

  @US-08-024 @FR-08-024 @M @âm
  Kịch bản: US-08-024 âm 2 · Đo năm bằng mẫu
    Biết đối tượng `ACTIVE`, có bộ quy tắc `ACTIVE`; loại khác `FLOW_MESSAGE`
    Khi đo năm bằng mẫu
    Thì hệ thống từ chối với ERR-08-030 (422)
    Và người dùng thấy thông báo "Lần đo cho báo cáo năm phải đo toàn bộ (FULL)."

  @US-08-025 @FR-08-025 @S
  Kịch bản: US-08-025 dương · Đo tăng dần theo sự kiện PH-06, PH-07
    Biết đối tượng `ACTIVE`, `incrementalEnabled = true` (bật bằng API-08-130, tắt bằng API-08-131); với `SOURCE_DATASET` cần `updatedAtField`
    Khi nhận EVT-06-01, EVT-06-02, EVT-06-03, EVT-06-04 (đổi bản ghi vàng), EVT-06-10 (mô hình domain kích hoạt), EVT-07-05 (danh mục phát hành), EVT-07-03 (danh mục ngừng), EVT-07-10 (sắp xếp ĐVHC); lịch `INCREMENTAL` với nguồn HTTT
    Thì lần đo `INCREMENTAL`; không trả cho bên phát sự kiện
    Và bản ghi lỗi cập nhật cho khóa đổi; ảnh chụp đầy đủ không bị thay
    Và sự kiện được phát: EVT-08-06 khi có lỗi mới
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-025 @FR-08-025 @S @âm
  Kịch bản: US-08-025 âm 1 · Sự kiện sai lược đồ
    Biết đối tượng `ACTIVE`, `incrementalEnabled = true` (bật bằng API-08-130, tắt bằng API-08-131); với `SOURCE_DATASET` cần `updatedAtField`
    Khi sự kiện sai lược đồ
    Thì hệ thống từ chối với ERR-08-118
    Và người dùng thấy thông báo "Sự kiện {loại} từ {nguồn} không xử lý được: {chi tiết}."

  @US-08-026 @FR-08-026 @M
  Kịch bản: US-08-026 dương · Thực thi quy tắc theo lô
    Biết lần đo `QUEUED`; có bộ thực thi rảnh; trong cửa sổ giờ của đối tượng
    Khi điều phối lấy lần đo theo thứ tự ưu tiên (`ANNUAL`, `VERIFY` trước; rồi `MANUAL`, `SCHEDULE`, `EVENT`)
    Thì lần đo trạng thái cuối; `ruleResults[]` (`ruleCode`, `status`, `passCount`, `failCount`, `skippedCount`, `errorDetail`)
    Và EN-08-12, EN-08-13, EN-08-14, EN-08-17 cập nhật
    Và sự kiện được phát: EVT-08-02 (`SUCCEEDED`, `PARTIAL`), EVT-08-03 (`FAILED`), EVT-08-06

  @US-08-026 @FR-08-026 @M @âm
  Kịch bản: US-08-026 âm 1 · Quy tắc lỗi khi chạy
    Biết lần đo `QUEUED`; có bộ thực thi rảnh; trong cửa sổ giờ của đối tượng
    Khi quy tắc lỗi khi chạy
    Thì hệ thống từ chối với ERR-08-107
    Và người dùng thấy thông báo "Lỗi kỹ thuật"

  @US-08-026 @FR-08-026 @M @âm
  Kịch bản: US-08-026 âm 2 · Quá thời gian
    Biết lần đo `QUEUED`; có bộ thực thi rảnh; trong cửa sổ giờ của đối tượng
    Khi quá thời gian
    Thì hệ thống từ chối với ERR-08-106
    Và người dùng thấy thông báo "Lần đo {mã} vượt {n} giờ và đã dừng."

  @US-08-027 @FR-08-027 @M
  Kịch bản: US-08-027 dương · Đối chiếu danh mục PH-07 cho chiều hợp lệ
    Biết quy tắc `IN_RDM` hoặc `IN_RDM_VERSION` trong phiên bản `ACTIVE`
    Khi bước 3 của FR-08-026; kiểm tra trực tuyến (FR-08-032)
    Thì số đếm đạt, vi phạm, bỏ qua cho từng quy tắc hợp lệ; gợi ý mã mới

  @US-08-027 @FR-08-027 @M @âm
  Kịch bản: US-08-027 âm 1 · PH-07 không khả dụng
    Biết quy tắc `IN_RDM` hoặc `IN_RDM_VERSION` trong phiên bản `ACTIVE`
    Khi PH-07 không khả dụng
    Thì hệ thống từ chối với ERR-08-108
    Và người dùng thấy thông báo "Không đối chiếu được danh mục {mã}. Chiều Hợp lệ bị bỏ qua ở lần đo này."

  @US-08-027 @FR-08-027 @M @âm
  Kịch bản: US-08-027 âm 2 · Danh mục đã ngừng
    Biết quy tắc `IN_RDM` hoặc `IN_RDM_VERSION` trong phiên bản `ACTIVE`
    Khi danh mục đã ngừng
    Thì hệ thống từ chối với ERR-08-107
    Và người dùng thấy thông báo "Quy tắc {mã} lỗi khi chạy: danh mục {mã danh mục} đã ngừng."

  @US-08-028 @FR-08-028 @M
  Kịch bản: US-08-028 dương · Tính điểm có trọng số
    Biết mọi tác vụ của lần đo kết thúc; lần đo không `FAILED`
    Khi bước 5 của FR-08-026
    Thì ảnh chụp: `snapshotId`, `score`, `verdict`, `flags[]`, `dimensions[]` (`dimension`, `score`, `weight`, `passCount`, `failCount`, `skippedCount`, `waivedCount`)
    Và ảnh chụp bất biến
    Và sự kiện được phát: EVT-08-05 khi kết luận `FAIL` hoặc điểm dưới ngưỡng cảnh báo lần đầu (chuyển từ `PASS`, `WARN`)

  @US-08-028 @FR-08-028 @M @âm
  Kịch bản: US-08-028 âm 1 · Không chiều nào có điểm vì mọi quy tắc bị bỏ qua
    Biết mọi tác vụ của lần đo kết thúc; lần đo không `FAILED`
    Khi không chiều nào có điểm vì mọi quy tắc bị bỏ qua
    Thì hệ thống từ chối với ERR-08-108
    Và người dùng thấy thông báo "Không đối chiếu được danh mục {mã}. Chiều Hợp lệ bị bỏ qua ở lần đo này."

  @US-08-029 @FR-08-029 @M
  Kịch bản: US-08-029 dương · So kỳ trước, xu hướng
    Biết ảnh chụp mới vừa ghi
    Khi sau FR-08-028; mở UI-08-04 tab "Xu hướng"
    Thì hệ thống trả `200`; `previousSnapshotId`, `delta`, `trend`, `dimensionDeltas[]`, `findingsNew`, `findingsPersisting`, `findingsResolved`, `flags[]`, `series[]`
    Và ảnh chụp có `trend`, `delta`
    Và sự kiện được phát: EVT-08-04

  @US-08-029 @FR-08-029 @M @âm
  Kịch bản: US-08-029 âm 1 · Không có ảnh chụp
    Biết ảnh chụp mới vừa ghi
    Khi không có ảnh chụp
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Đối tượng {mã} chưa có lần đo nào thành công."

  @US-08-030 @FR-08-030 @M
  Kịch bản: US-08-030 dương · Theo dõi tiến độ, hủy, chạy lại lần đo
    Biết lần đo tồn tại
    Khi mở UI-08-11, UI-08-12; nút "Hủy", "Chạy lại"
    Thì hệ thống trả `200`; lần đo với `status`, `progress`, `etaSeconds`, `tasks[]`; chạy lại trả `202` với `scanId` mới
    Và lần đo cũ không bị sửa; lần đo mới `QUEUED`
    Và sự kiện được phát: EVT-08-03 khi `FAILED`; không phát khi `CANCELLED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-030 @FR-08-030 @M @âm
  Kịch bản: US-08-030 âm 1 · Trạng thái không cho thao tác
    Biết lần đo tồn tại
    Khi trạng thái không cho thao tác
    Thì hệ thống từ chối với ERR-08-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} khi lần đo đang ở trạng thái {trạng thái}."

  @US-08-030 @FR-08-030 @M @âm
  Kịch bản: US-08-030 âm 2 · Thiếu lý do hủy
    Biết lần đo tồn tại
    Khi thiếu lý do hủy
    Thì hệ thống từ chối với ERR-08-007 (422)
    Và người dùng thấy thông báo "Nhập lý do (tối thiểu 20 ký tự)."

  @US-08-031 @FR-08-031 @M
  Kịch bản: US-08-031 dương · Xử lý phụ thuộc không khả dụng
    Biết lần đo `RUNNING`
    Khi lỗi kết nối, quá thời gian, circuit breaker mở khi gọi phụ thuộc
    Thì lần đo `FAILED` hoặc `PARTIAL` kèm `dependencyIssues[]`
    Và sự kiện được phát: EVT-08-03 (`FAILED`), EVT-08-02 (`PARTIAL`, có cờ)

  @US-08-031 @FR-08-031 @M @âm
  Kịch bản: US-08-031 âm 1 · Nguồn không khả dụng
    Biết lần đo `RUNNING`
    Khi nguồn không khả dụng
    Thì hệ thống từ chối với ERR-08-105
    Và người dùng thấy thông báo "Không đọc được nguồn của đối tượng {mã}: {nguyên nhân}. Thử lại sau."

  @US-08-031 @FR-08-031 @M @âm
  Kịch bản: US-08-031 âm 2 · PH-07 không khả dụng
    Biết lần đo `RUNNING`
    Khi PH-07 không khả dụng
    Thì hệ thống từ chối với ERR-08-108
    Và người dùng thấy thông báo "Không đối chiếu được danh mục {mã}. Chiều Hợp lệ bị bỏ qua ở lần đo này."

  # ---- EP-08-E · Kiểm tra trực tuyến

  @US-08-032 @FR-08-032 @S
  Kịch bản: US-08-032 dương · API kiểm tra trực tuyến bản ghi
    Biết đối tượng `ACTIVE`, `inlineEnabled = true`, có quy tắc `INLINE` hoặc `BOTH` trong phiên bản `ACTIVE`
    Khi `POST /api/dq/v1/checks:evaluate`
    Thì hệ thống trả `200`; `verdict` (`PASS`, `WARN`, `FAIL`), `degraded`, `violations[]` (`ruleCode`, `dimension`, `severity`, `fieldPath`, `message`, không chứa giá trị), `evaluatedRules`, `durationMs`, `ruleSetVersion`
    Và thống kê phút tăng; không thay đổi dữ liệu khác
    Và sự kiện được phát: EVT-08-13 (gộp theo phút khi có `FAIL`)

  @US-08-032 @FR-08-032 @S @âm
  Kịch bản: US-08-032 âm 1 · Bản ghi sai lược đồ, quá lớn
    Biết đối tượng `ACTIVE`, `inlineEnabled = true`, có quy tắc `INLINE` hoặc `BOTH` trong phiên bản `ACTIVE`
    Khi bản ghi sai lược đồ, quá lớn
    Thì hệ thống từ chối với ERR-08-101 (422)
    Và người dùng thấy thông báo "Bản ghi không đúng lược đồ của đối tượng {mã}: {chi tiết}."

  @US-08-033 @FR-08-033 @S
  Kịch bản: US-08-033 dương · Bước kiểm tra chất lượng trong luồng PH-04
    Biết Kamelet `dh-dq-check` đã đăng ký ở danh mục Kamelet PH-05 (Phụ lục B); đối tượng đo loại `FLOW_MESSAGE` hoặc loại khác có bật trực tuyến
    Khi bản tin đi tới bước `dh-dq-check` của luồng
    Thì bản tin đi tiếp kèm tiêu đề hoặc vào DLQ
    Và sự kiện được phát: EVT-08-13 (qua FR-08-032)

  @US-08-033 @FR-08-033 @S @âm
  Kịch bản: US-08-033 âm 1 · PH-08 trả ERR-08-102
    Biết Kamelet `dh-dq-check` đã đăng ký ở danh mục Kamelet PH-05 (Phụ lục B); đối tượng đo loại `FLOW_MESSAGE` hoặc loại khác có bật trực tuyến
    Khi PH-08 trả ERR-08-102
    Thì hệ thống từ chối với ERR-08-102
    Và người dùng thấy thông báo "Bước kiểm tra chất lượng trỏ tới đối tượng {mã} chưa bật trực tuyến."

  @US-08-034 @FR-08-034 @S
  Kịch bản: US-08-034 dương · Thống kê kiểm tra trực tuyến
    Biết có lượt kiểm tra trực tuyến
    Khi mở UI-08-20
    Thì hệ thống trả `200`; `series[]`, `topRules[]`, `p95Ms`
    Và sự kiện được phát: EVT-08-13

  @US-08-034 @FR-08-034 @S @âm
  Kịch bản: US-08-034 âm 1 · Khoảng thời gian quá dài
    Biết có lượt kiểm tra trực tuyến
    Khi khoảng thời gian quá dài
    Thì hệ thống từ chối với ERR-08-045 (422)
    Và người dùng thấy thông báo "Khoảng thời gian tối đa {n} ngày với độ phân giải {độ phân giải}."

  @US-08-035 @FR-08-035 @C
  Kịch bản: US-08-035 dương · Cổng chất lượng đầu vào cho PH-06
    Biết đối tượng `MDM_DOMAIN` bật trực tuyến với `gateForSources[]` (danh sách nguồn PH-06 áp cổng)
    Khi PH-06 nhận ứng viên từ nguồn trong danh sách (FR-06-010…013)
    Thì như FR-08-032
    Và sự kiện được phát: EVT-08-13

  @US-08-035 @FR-08-035 @C @âm
  Kịch bản: US-08-035 âm 1 · PH-08 hết ngân sách hoặc phụ thuộc lỗi
    Biết đối tượng `MDM_DOMAIN` bật trực tuyến với `gateForSources[]` (danh sách nguồn PH-06 áp cổng)
    Khi PH-08 hết ngân sách hoặc phụ thuộc lỗi
    Thì hệ thống từ chối với ERR-08-104 (503)
    Và người dùng thấy thông báo "Dịch vụ đối chiếu danh mục tạm thời không khả dụng."

  # ---- EP-08-F · Bản ghi lỗi

  @US-08-036 @FR-08-036 @M
  Kịch bản: US-08-036 dương · Ghi bản ghi lỗi, dấu vân tay, che giá trị
    Biết lần đo đang chạy sinh vi phạm
    Khi bước 5 của FR-08-026
    Thì bản ghi lỗi trong EN-08-17; số mới, còn, hết của lần đo
    Và sự kiện được phát: EVT-08-06

  @US-08-036 @FR-08-036 @M @âm
  Kịch bản: US-08-036 âm 1 · Vượt trần
    Biết lần đo đang chạy sinh vi phạm
    Khi vượt trần
    Thì hệ thống từ chối với ERR-08-110
    Và người dùng thấy thông báo "Quy tắc {mã} có hơn {n} bản ghi lỗi. Chỉ lưu {n} bản ghi đầu, số đếm vẫn đủ."

  @US-08-037 @FR-08-037 @M
  Kịch bản: US-08-037 dương · Tra cứu, lọc bản ghi lỗi
    Biết có bản ghi lỗi
    Khi mở UI-08-13; bấm số lỗi ở thẻ điểm
    Thì hệ thống trả `200`; `items[]` (`findingId`, `assetCode`, `recordKeyMasked`, `ruleCode`, `dimension`, `severity`, `fieldPath`, `maskedValue`, `status`, `firstSeenAt`, `lastSeenAt`, `issueCode`), `groups[]`, `facets`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-037 @FR-08-037 @M @âm
  Kịch bản: US-08-037 âm 1 · Ngoài phạm vi tổ chức
    Biết có bản ghi lỗi
    Khi ngoài phạm vi tổ chức
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Đối tượng {mã} không thuộc tổ chức của anh/chị."

  @US-08-037 @FR-08-037 @M @âm
  Kịch bản: US-08-037 âm 2 · Tham số sai
    Biết có bản ghi lỗi
    Khi tham số sai
    Thì hệ thống từ chối với ERR-08-045 (422)
    Và người dùng thấy thông báo "Tham số {tên} không hợp lệ: {chi tiết}."

  @US-08-038 @FR-08-038 @M
  Kịch bản: US-08-038 dương · Xem chi tiết bản ghi lỗi, nguồn gốc
    Biết bản ghi lỗi tồn tại
    Khi bấm một dòng ở UI-08-13, mở ngăn kéo UI-08-14
    Thì hệ thống trả `200`; lỗi đầy đủ, `rule`, `history[]`, `lineage` (khi có), `suggestedOwnerOrgId`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-038 @FR-08-038 @M @âm
  Kịch bản: US-08-038 âm 1 · Không tìm thấy
    Biết bản ghi lỗi tồn tại
    Khi không tìm thấy
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Không tìm thấy bản ghi lỗi {mã}."

  @US-08-038 @FR-08-038 @M @âm
  Kịch bản: US-08-038 âm 2 · PH-06 không trả nguồn gốc
    Biết bản ghi lỗi tồn tại
    Khi PH-06 không trả nguồn gốc
    Thì hiện thông báo (không mã lỗi, phần còn lại vẫn hiện)
    Và người dùng thấy thông báo "Chưa lấy được nguồn gốc từ PH-06, thử lại sau."

  @US-08-039 @FR-08-039 @S
  Kịch bản: US-08-039 dương · Xuất bản ghi lỗi có duyệt khi có trường Nhạy cảm
    Biết bộ lọc trả ít nhất một lỗi
    Khi nút "Xuất" ở UI-08-13
    Thì hệ thống trả `202`; `exportId`, `status`, `containsSensitive`; tải bằng API-08-077 (`200`, tệp)
    Và EN-08-29 có yêu cầu; tệp xóa sau hạn
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-039 @FR-08-039 @S @âm
  Kịch bản: US-08-039 âm 1 · Tải tệp chưa được chấp thuận hoặc đã hết hạn
    Biết bộ lọc trả ít nhất một lỗi
    Khi tải tệp chưa được chấp thuận hoặc đã hết hạn
    Thì hệ thống từ chối với ERR-08-041 (409)
    Và người dùng thấy thông báo "Tệp xuất {mã} chưa được chấp thuận hoặc đã hết hạn tải."

  @US-08-040 @FR-08-040 @S
  Kịch bản: US-08-040 dương · Ngoại lệ chấp nhận có hạn, có duyệt
    Biết lỗi `OPEN` hoặc quy tắc `ACTIVE`
    Khi nút "Đề nghị ngoại lệ" ở UI-08-14 (một lỗi) hoặc UI-08-13 (nhóm theo bộ lọc)
    Thì hệ thống trả `201`, `200`; `waiverId`, `status`, `affectedFindings`, `validUntil`
    Và lỗi `WAIVED` hoặc trở về `OPEN`
    Và sự kiện được phát: EVT-08-10
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-040 @FR-08-040 @S @âm
  Kịch bản: US-08-040 âm 1 · Hạn quá trần
    Biết lỗi `OPEN` hoặc quy tắc `ACTIVE`
    Khi hạn quá trần
    Thì hệ thống từ chối với ERR-08-033 (422)
    Và người dùng thấy thông báo "Ngoại lệ tối đa {n} ngày và phải có phạm vi lỗi cụ thể."

  # ---- EP-08-G · Khắc phục

  @US-08-041 @FR-08-041 @M
  Kịch bản: US-08-041 dương · Mở phiếu khắc phục từ nhóm lỗi
    Biết lỗi `OPEN` chưa thuộc phiếu mở
    Khi chọn nhiều dòng hoặc một nhóm ở UI-08-13, bấm "Mở phiếu"; tự động khi lần đo cho kết luận `FAIL` và số lỗi `CRITICAL` mới > `08.issue.auto-open-critical` (mặc định 100)
    Thì hệ thống trả `201`; `issueCode`, `status`, `findingCount`, `dueDate`, `ownerOrgId`
    Và lỗi `IN_REMEDIATION`; phiếu `OPEN` hoặc `ASSIGNED`
    Và sự kiện được phát: EVT-08-07
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-041 @FR-08-041 @M @âm
  Kịch bản: US-08-041 âm 1 · Lỗi đã thuộc phiếu khác
    Biết lỗi `OPEN` chưa thuộc phiếu mở
    Khi lỗi đã thuộc phiếu khác
    Thì hệ thống từ chối với ERR-08-034 (409)
    Và người dùng thấy thông báo "Có {n} bản ghi lỗi đã thuộc phiếu {mã}. Bỏ chọn hoặc gắn vào phiếu đó."

  @US-08-041 @FR-08-041 @M @âm
  Kịch bản: US-08-041 âm 2 · Không có chủ quản
    Biết lỗi `OPEN` chưa thuộc phiếu mở
    Khi không có chủ quản
    Thì phiếu vào hàng đợi chung của DS miền, hiện thông báo
    Và người dùng thấy thông báo "Phiếu chưa có tổ chức chủ quản, đang chờ cán bộ phụ trách giao."

  @US-08-042 @FR-08-042 @M
  Kịch bản: US-08-042 dương · Phân công cho tổ chức chủ quản, SLA
    Biết phiếu `OPEN`, `REJECTED` hoặc `ASSIGNED`
    Khi tự động sau FR-08-041; nút "Giao" ở UI-08-16
    Thì hệ thống trả `200`; phiếu với `status`, `ownerOrgId`, `assigneeUserId`, `dueDate`, `overdue`, `slaRemainingDays`; danh sách phiếu (API-08-085) kèm `facets` (số phiếu theo trạng thái và số quá hạn) cho các thẻ của hộp việc
    Và phiếu `ASSIGNED`
    Và sự kiện được phát: EVT-08-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-042 @FR-08-042 @M @âm
  Kịch bản: US-08-042 âm 1 · DO giao người ngoài tổ chức
    Biết phiếu `OPEN`, `REJECTED` hoặc `ASSIGNED`
    Khi DO giao người ngoài tổ chức
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Người được giao không thuộc tổ chức {tên}."

  @US-08-042 @FR-08-042 @M @âm
  Kịch bản: US-08-042 âm 2 · Đổi hạn thiếu lý do
    Biết phiếu `OPEN`, `REJECTED` hoặc `ASSIGNED`
    Khi đổi hạn thiếu lý do
    Thì hệ thống từ chối với ERR-08-007 (422)
    Và người dùng thấy thông báo "Nhập lý do (tối thiểu 20 ký tự)."

  @US-08-043 @FR-08-043 @M
  Kịch bản: US-08-043 dương · Cập nhật tiến độ, trao đổi trên phiếu
    Biết phiếu không ở `VERIFIED`, `CANCELLED`
    Khi nút "Nhận việc", ô trao đổi, "Đính kèm" ở UI-08-16
    Thì hệ thống trả `201`; hoạt động mới; phiếu với `status`
    Và EN-08-20 có thêm hoạt động
    Và sự kiện được phát: EVT-08-08 khi đổi trạng thái
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-043 @FR-08-043 @M @âm
  Kịch bản: US-08-043 âm 1 · Trạng thái không cho thao tác
    Biết phiếu không ở `VERIFIED`, `CANCELLED`
    Khi trạng thái không cho thao tác
    Thì hệ thống từ chối với ERR-08-006 (409)
    Và người dùng thấy thông báo "Không thể cập nhật phiếu đang ở trạng thái {trạng thái}."

  @US-08-043 @FR-08-043 @M @âm
  Kịch bản: US-08-043 âm 2 · Tệp quá lớn
    Biết phiếu không ở `VERIFIED`, `CANCELLED`
    Khi tệp quá lớn
    Thì hệ thống từ chối với ERR-08-046 (413)
    Và người dùng thấy thông báo "Tệp vượt {n} MB."

  @US-08-044 @FR-08-044 @M
  Kịch bản: US-08-044 dương · Xác nhận đã sửa và đo lại kiểm chứng
    Biết phiếu `IN_PROGRESS`
    Khi DO bấm "Đã sửa" ở UI-08-16
    Thì hệ thống trả `202`; `verifyScanId`, phiếu `FIXED`; sau lần đo: `VERIFIED` hoặc `REOPENED`
    Và lỗi `RESOLVED` hoặc vẫn `IN_REMEDIATION`
    Và sự kiện được phát: EVT-08-08, EVT-08-09
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-044 @FR-08-044 @M @âm
  Kịch bản: US-08-044 âm 1 · Thiếu ghi chú
    Biết phiếu `IN_PROGRESS`
    Khi thiếu ghi chú
    Thì hệ thống từ chối với ERR-08-036 (422)
    Và người dùng thấy thông báo "Mô tả việc đã sửa (tối thiểu 20 ký tự) trước khi báo đã sửa."

  @US-08-044 @FR-08-044 @M @âm
  Kịch bản: US-08-044 âm 2 · DO tự xác nhận
    Biết phiếu `IN_PROGRESS`
    Khi DO tự xác nhận
    Thì hệ thống từ chối với ERR-08-035 (403)
    Và người dùng thấy thông báo "Chủ quản không tự xác nhận phiếu. Hệ thống sẽ đo lại để kiểm chứng."

  @US-08-045 @FR-08-045 @S
  Kịch bản: US-08-045 dương · Từ chối, chuyển, leo thang phiếu quá hạn
    Biết phiếu `ASSIGNED`, `IN_PROGRESS` (từ chối); mọi trạng thái chưa kết thúc (chuyển, hủy)
    Khi nút "Từ chối", "Chuyển", "Leo thang", "Hủy" ở UI-08-16; job hằng ngày
    Thì hệ thống trả `200`; phiếu với `status`, `escalationLevel`, `ownerOrgId`
    Và phiếu `REJECTED`, `ASSIGNED`, `CANCELLED` hoặc giữ trạng thái với mức leo thang mới
    Và sự kiện được phát: EVT-08-08
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-045 @FR-08-045 @S @âm
  Kịch bản: US-08-045 âm 1 · Thiếu lý do
    Biết phiếu `ASSIGNED`, `IN_PROGRESS` (từ chối); mọi trạng thái chưa kết thúc (chuyển, hủy)
    Khi thiếu lý do
    Thì hệ thống từ chối với ERR-08-007 (422)
    Và người dùng thấy thông báo "Nhập lý do (tối thiểu 20 ký tự)."

  @US-08-046 @FR-08-046 @S
  Kịch bản: US-08-046 dương · Chuyển lỗi bản ghi vàng sang hàng đợi PH-06
    Biết lỗi thuộc đối tượng `MDM_DOMAIN`
    Khi nút "Chuyển PH-06" ở UI-08-16 hoặc UI-08-14
    Thì hệ thống trả `200`; `stewardItemIds[]`
    Và lỗi có liên kết mục PH-06
    Và sự kiện được phát: EVT-08-08 (khi có phiếu)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-046 @FR-08-046 @S @âm
  Kịch bản: US-08-046 âm 1 · Không phải `MDM_DOMAIN`
    Biết lỗi thuộc đối tượng `MDM_DOMAIN`
    Khi không phải `MDM_DOMAIN`
    Thì hệ thống từ chối với ERR-08-051 (422)
    Và người dùng thấy thông báo "Chỉ lỗi của bản ghi vàng mới chuyển được sang hàng đợi dữ liệu chủ."

  # ---- EP-08-H · Cảnh báo

  @US-08-047 @FR-08-047 @S
  Kịch bản: US-08-047 dương · Khai báo quy tắc cảnh báo
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi "+ Quy tắc cảnh báo" ở UI-08-17
    Thì hệ thống trả `201`, `200`; quy tắc cảnh báo
    Và EN-08-21 cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-047 @FR-08-047 @S @âm
  Kịch bản: US-08-047 âm 1 · Điều kiện sai
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi điều kiện sai
    Thì hệ thống từ chối với ERR-08-037 (422)
    Và người dùng thấy thông báo "Quy tắc cảnh báo {mã} không hợp lệ: {chi tiết}."

  @US-08-048 @FR-08-048 @S
  Kịch bản: US-08-048 dương · Phát cảnh báo qua kênh thông báo PH-13
    Biết quy tắc cảnh báo bật
    Khi sau mỗi lần đo, mỗi lần job SLA, mỗi phút thống kê trực tuyến
    Thì cảnh báo trong EN-08-22; EVT-08-12
    Và cảnh báo `FIRING` hoặc `RESOLVED`
    Và sự kiện được phát: EVT-08-12

  @US-08-048 @FR-08-048 @S @âm
  Kịch bản: US-08-048 âm 1 · PH-13 không nhận
    Biết quy tắc cảnh báo bật
    Khi PH-13 không nhận
    Thì hệ thống từ chối với ERR-08-114
    Và người dùng thấy thông báo "Cảnh báo {mã} chưa gửi được tới kênh thông báo."

  @US-08-049 @FR-08-049 @S
  Kịch bản: US-08-049 dương · Xác nhận, tắt tiếng cảnh báo
    Biết cảnh báo `FIRING` (xác nhận, tắt tiếng) hoặc `SILENCED` (bỏ tắt tiếng)
    Khi nút "Xác nhận", "Tắt tiếng" ở UI-08-17 hoặc từ liên kết trong thông báo
    Thì hệ thống trả `200`; cảnh báo với `status`, `acknowledgedBy`, `silencedUntil`
    Và cảnh báo `ACKNOWLEDGED` hoặc `SILENCED`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-049 @FR-08-049 @S @âm
  Kịch bản: US-08-049 âm 1 · Trạng thái không cho thao tác
    Biết cảnh báo `FIRING` (xác nhận, tắt tiếng) hoặc `SILENCED` (bỏ tắt tiếng)
    Khi trạng thái không cho thao tác
    Thì hệ thống từ chối với ERR-08-006 (409)
    Và người dùng thấy thông báo "Không thể {thao tác} cảnh báo đang ở trạng thái {trạng thái}."

  # ---- EP-08-I · Bảng điều khiển, báo cáo

  @US-08-050 @FR-08-050 @M
  Kịch bản: US-08-050 dương · Bảng điều khiển chất lượng tenant
    Biết người dùng đã đăng nhập với vai trò người xem
    Khi mở UI-08-01 (route `/du-lieu/chat-luong`)
    Thì hệ thống trả `200`; `tenantScore`, `domains[]`, `radar` (kỳ này, kỳ trước), `trend[]`, `counters{}`, `coverage`

  @US-08-050 @FR-08-050 @M @âm
  Kịch bản: US-08-050 âm 1 · Lọc theo tổ chức không thuộc phạm vi của DO
    Biết người dùng đã đăng nhập với vai trò người xem
    Khi lọc theo tổ chức không thuộc phạm vi của DO
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Đối tượng {mã} không thuộc tổ chức của anh/chị."

  @US-08-050 @FR-08-050 @M @âm
  Kịch bản: US-08-050 âm 2 · Chưa có lần đo nào
    Biết người dùng đã đăng nhập với vai trò người xem
    Khi chưa có lần đo nào
    Thì hiện trạng thái trống thông báo (không phải lỗi)
    Và người dùng thấy thông báo "Chưa có số liệu. Đăng ký đối tượng đo và chạy lần đo đầu tiên."

  @US-08-051 @FR-08-051 @M
  Kịch bản: US-08-051 dương · Thẻ điểm theo đối tượng đo, miền, tổ chức
    Biết có ít nhất một ảnh chụp
    Khi mở UI-08-04 tab "Thẻ điểm"; gọi API-08-105, API-08-106
    Thì hệ thống trả `200`; thẻ điểm như trên, `snapshotIds[]`

  @US-08-051 @FR-08-051 @M @âm
  Kịch bản: US-08-051 âm 1 · Không có ảnh chụp
    Biết có ít nhất một ảnh chụp
    Khi không có ảnh chụp
    Thì hệ thống từ chối với ERR-08-001 (404)
    Và người dùng thấy thông báo "Đối tượng {mã} chưa có lần đo nào thành công."

  @US-08-051 @FR-08-051 @M @âm
  Kịch bản: US-08-051 âm 2 · HTTT đọc dữ liệu không thuộc mình
    Biết có ít nhất một ảnh chụp
    Khi HTTT đọc dữ liệu không thuộc mình
    Thì hệ thống từ chối với ERR-08-032 (403)
    Và người dùng thấy thông báo "Đối tượng {mã} không thuộc tổ chức của anh/chị."

  @US-08-052 @FR-08-052 @M
  Kịch bản: US-08-052 dương · Sinh báo cáo kỳ
    Biết mỗi đối tượng trong phạm vi có ít nhất một lần đo `SUCCEEDED` hoặc `PARTIAL` trong kỳ (đối tượng thiếu được liệt kê)
    Khi "+ Báo cáo" ở UI-08-18
    Thì hệ thống trả `201`; `reportCode` (`BC-DQ-2026-11-T68`), `status = DRAFT`, `missingAssets[]`, `recommendations[]`
    Và báo cáo `DRAFT`
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-052 @FR-08-052 @M @âm
  Kịch bản: US-08-052 âm 1 · Không đối tượng nào có lần đo trong kỳ
    Biết mỗi đối tượng trong phạm vi có ít nhất một lần đo `SUCCEEDED` hoặc `PARTIAL` trong kỳ (đối tượng thiếu được liệt kê)
    Khi không đối tượng nào có lần đo trong kỳ
    Thì hệ thống từ chối với ERR-08-056 (422)
    Và người dùng thấy thông báo "Không có lần đo thành công nào trong kỳ {kỳ} để lập báo cáo."

  @US-08-052 @FR-08-052 @M @âm
  Kịch bản: US-08-052 âm 2 · Sinh báo cáo lỗi
    Biết mỗi đối tượng trong phạm vi có ít nhất một lần đo `SUCCEEDED` hoặc `PARTIAL` trong kỳ (đối tượng thiếu được liệt kê)
    Khi sinh báo cáo lỗi
    Thì hệ thống từ chối với ERR-08-112
    Và người dùng thấy thông báo "Không sinh được báo cáo {mã}. Thử lại sau."

  @US-08-053 @FR-08-053 @M
  Kịch bản: US-08-053 dương · Duyệt và công bố báo cáo
    Biết báo cáo `DRAFT` có khối khuyến nghị không rỗng
    Khi "Gửi duyệt" ở UI-08-18; việc trong "Việc của tôi" cho DA
    Thì hệ thống trả `200`; `reportCode`, `status`, `contentHash`, `publishedAt`, `approvedBy`
    Và báo cáo `PUBLISHED` bất biến hoặc `DRAFT`, `WITHDRAWN`
    Và sự kiện được phát: EVT-08-11
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-053 @FR-08-053 @M @âm
  Kịch bản: US-08-053 âm 1 · Thiếu khuyến nghị
    Biết báo cáo `DRAFT` có khối khuyến nghị không rỗng
    Khi thiếu khuyến nghị
    Thì hệ thống từ chối với ERR-08-039 (422)
    Và người dùng thấy thông báo "Báo cáo cần ít nhất một khuyến nghị trước khi gửi duyệt."

  @US-08-053 @FR-08-053 @M @âm
  Kịch bản: US-08-053 âm 2 · Tự duyệt
    Biết báo cáo `DRAFT` có khối khuyến nghị không rỗng
    Khi tự duyệt
    Thì hệ thống từ chối với ERR-08-005 (403)
    Và người dùng thấy thông báo "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt."

  @US-08-054 @FR-08-054 @M
  Kịch bản: US-08-054 dương · Báo cáo chính thức hằng năm
    Biết năm báo cáo đã có ít nhất một lần đo; danh sách đối tượng trong phạm vi (mặc định mọi đối tượng có CDE)
    Khi "+ Báo cáo năm" ở UI-08-18; nhắc tự động ngày 1/12 hằng năm
    Thì hệ thống trả `201`; `reportCode` (`BC-DQ-2026-NAM-T68`), `readiness{ready, missingFull[], incomplete[], sampleOnly[]}`
    Và báo cáo `ANNUAL` `DRAFT` rồi `PUBLISHED`
    Và sự kiện được phát: EVT-08-11, EVT-08-14 (qua FR-08-053, FR-08-057)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-054 @FR-08-054 @M @âm
  Kịch bản: US-08-054 âm 1 · Không đủ điều kiện
    Biết năm báo cáo đã có ít nhất một lần đo; danh sách đối tượng trong phạm vi (mặc định mọi đối tượng có CDE)
    Khi không đủ điều kiện
    Thì hệ thống từ chối với ERR-08-038 (422)
    Và người dùng thấy thông báo "Chưa đủ điều kiện báo cáo chính thức năm {năm}: {n} đối tượng thiếu lần đo toàn bộ hoặc có điểm thiếu chiều."

  @US-08-054 @FR-08-054 @M @âm
  Kịch bản: US-08-054 âm 2 · Thiếu khuyến nghị
    Biết năm báo cáo đã có ít nhất một lần đo; danh sách đối tượng trong phạm vi (mặc định mọi đối tượng có CDE)
    Khi thiếu khuyến nghị
    Thì hệ thống từ chối với ERR-08-039 (422)
    Và người dùng thấy thông báo "Báo cáo cần ít nhất một khuyến nghị trước khi gửi duyệt."

  @US-08-055 @FR-08-055 @S
  Kịch bản: US-08-055 dương · Xuất báo cáo PDF, XLSX, ký số
    Biết báo cáo `PUBLISHED` (bản chính thức) hoặc `DRAFT` (bản xem trước có dấu "Dự thảo")
    Khi nút "Xuất PDF", "Xuất XLSX", "Ký số" ở UI-08-18
    Thì hệ thống trả `202` (chạy nền) hoặc `200`; `exportId`, `fileUrl` (khi xong), `signatureRef`
    Và tệp xuất gắn báo cáo; nội dung báo cáo không đổi
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-055 @FR-08-055 @S @âm
  Kịch bản: US-08-055 âm 1 · Ký thất bại
    Biết báo cáo `PUBLISHED` (bản chính thức) hoặc `DRAFT` (bản xem trước có dấu "Dự thảo")
    Khi ký thất bại
    Thì hệ thống từ chối với ERR-08-048 (422)
    Và người dùng thấy thông báo "Không ký số được báo cáo {mã}: {nguyên nhân}."

  @US-08-056 @FR-08-056 @S
  Kịch bản: US-08-056 dương · Phân phối báo cáo, đăng ký nhận
    Biết báo cáo `PUBLISHED`
    Khi EVT-08-11; màn "Đăng ký nhận" ở UI-08-18
    Thì hệ thống trả `201` (đăng ký); biên bản `distribution[]` trong chi tiết báo cáo
    Và EN-08-24 cập nhật; biên bản gắn báo cáo
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-056 @FR-08-056 @S @âm
  Kịch bản: US-08-056 âm 1 · PH-13 không nhận
    Biết báo cáo `PUBLISHED`
    Khi PH-13 không nhận
    Thì hệ thống từ chối với ERR-08-114
    Và người dùng thấy thông báo "chưa gửi"

  @US-08-057 @FR-08-057 @S
  Kịch bản: US-08-057 dương · Đẩy chỉ số sang PH-16, PH-13
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi sau mỗi ảnh chụp đầy đủ; sau báo cáo công bố; hằng ngày 06:00 cho chỉ số phiếu
    Thì EVT-08-14; API-08-122 (`200`, danh sách KPI)
    Và hộp gửi đã giao
    Và sự kiện được phát: EVT-08-14

  @US-08-057 @FR-08-057 @S @âm
  Kịch bản: US-08-057 âm 1 · Hộp gửi không giao được quá 24 giờ
    Biết người dùng đã đăng nhập với vai trò cán bộ quản lý dữ liệu
    Khi hộp gửi không giao được quá 24 giờ
    Thì hệ thống từ chối với ERR-08-113
    Và người dùng thấy thông báo "Chưa đẩy được {n} bản tin KPI chất lượng dữ liệu sang PH-16."

  # ---- EP-08-J · Quản trị

  @US-08-058 @FR-08-058 @M
  Kịch bản: US-08-058 dương · Tham số chất lượng theo tenant
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi mở UI-08-19 tab "Tham số"
    Thì hệ thống trả `200`; `settings[]` (`key`, `value`, `default`, `max`, `updatedBy`, `updatedAt`)
    Và EN-08-26 cập nhật
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-058 @FR-08-058 @M @âm
  Kịch bản: US-08-058 âm 1 · Ngoài miền hoặc vượt trần
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi ngoài miền hoặc vượt trần
    Thì hệ thống từ chối với ERR-08-042 (422)
    Và người dùng thấy thông báo "Giá trị {giá trị} của {khóa} ngoài khoảng cho phép {miền}."

  @US-08-058 @FR-08-058 @M @âm
  Kịch bản: US-08-058 âm 2 · Sửa đồng thời
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi sửa đồng thời
    Thì hệ thống từ chối với ERR-08-004 (409)
    Và người dùng thấy thông báo "Tham số đã được người khác sửa. Tải lại để xem thay đổi."

  @US-08-059 @FR-08-059 @M
  Kịch bản: US-08-059 dương · Lưu giữ và dọn dữ liệu đo
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi job hằng ngày; nút "Xem trước dọn" ở UI-08-19
    Thì hệ thống trả `200`; `retentionRuns[]`, xem trước `estimates{}`
    Và dữ liệu quá hạn đã xóa
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-059 @FR-08-059 @M @âm
  Kịch bản: US-08-059 âm 1 · Đặt lưu giữ dưới sàn
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi đặt lưu giữ dưới sàn
    Thì hệ thống từ chối với ERR-08-043 (422)
    Và người dùng thấy thông báo "Thời gian lưu {loại} không được dưới {n} {đơn vị}."

  @US-08-059 @FR-08-059 @M @âm
  Kịch bản: US-08-059 âm 2 · Dọn lỗi
    Biết người dùng đã đăng nhập với vai trò quản trị tỉnh
    Khi dọn lỗi
    Thì hệ thống từ chối với ERR-08-117
    Và người dùng thấy thông báo "Lần dọn dữ liệu {ngày} chưa hoàn tất: {nguyên nhân}."

  @US-08-060 @FR-08-060 @M
  Kịch bản: US-08-060 dương · Nhật ký kiểm toán PH-08
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi mọi thao tác có "Kiểm toán
    Thì hệ thống trả `200`; `items[]` bản ghi kiểm toán
    Và bản ghi kiểm toán bất biến
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-060 @FR-08-060 @M @âm
  Kịch bản: US-08-060 âm 1 · Không ghi được kiểm toán
    Biết người dùng đã đăng nhập với vai trò cán bộ ATTT
    Khi không ghi được kiểm toán
    Thì hệ thống từ chối với ERR-08-054 (503)
    Và người dùng thấy thông báo "Hệ thống tạm thời không ghi được nhật ký. Thao tác chưa được thực hiện."

  @US-08-061 @FR-08-061 @C
  Kịch bản: US-08-061 dương · So sánh liên tenant tổng hợp ẩn danh
    Biết tenant bật tham gia `08.benchmark.opt-in`; chỉ đối tượng dùng quy tắc mẫu `COMMON` (cùng phép đo) được so
    Khi mở UI-08-01 chế độ "So sánh" (PA hoặc TA)
    Thì hệ thống trả `200`; `median`, `p25`, `p75`, `participants`, `myPercentile` (TA)
    Và nhật ký kiểm toán ghi nhận thao tác

  @US-08-061 @FR-08-061 @C @âm
  Kịch bản: US-08-061 âm 1 · Nhóm quá nhỏ
    Biết tenant bật tham gia `08.benchmark.opt-in`; chỉ đối tượng dùng quy tắc mẫu `COMMON` (cùng phép đo) được so
    Khi nhóm quá nhỏ
    Thì hệ thống từ chối với ERR-08-044 (422)
    Và người dùng thấy thông báo "Chưa đủ {n} tỉnh tham gia để so sánh ẩn danh."
